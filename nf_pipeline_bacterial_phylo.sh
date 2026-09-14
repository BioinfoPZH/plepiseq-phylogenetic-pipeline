#!/bin/bash

# A function used to determine which column in metadatafile has a specific header
get_col_idx() {
    local col_name=$1
    local header_line=$2
    echo "$header_line" | awk -v name="$col_name" -F'\t' '{
        for (i=1; i<=NF; i++) {
            if ($i == name) {
                print i;
                exit
            }
        }
    }'
}

err() {
  # Print error to stderr, show usage if available, and exit non-zero
  echo "Error: $*" >&2
  if type usage >/dev/null 2>&1; then
    echo >&2
    usage >&2
  fi
  exit 1
}

# Simplified script to run bacterial phylogenetic pipeline using SNP data

# required to run .nf script + "modules" should be a subdirectory
projectDir="" # location of main project
db_absolute_path_on_host="/mnt/unity_nfs/external_databases" # shared NFS resource, reachable from every compute node


# docker images required to execute this pipeline
main_image="pzh_pipeline-phylo:latest" # main image used by phylogenetic pipeline
prokka_image="staphb/prokka:latest" # name of the image with prokka software

## Nextflow executor (local or slurm)
profile="local"

# location of input data - USER-provided no defaults
metadata=""
inputDir=""
inputType=""
genus="" # analyzed genus only Salmonella Escherichia and Campylobacter are currently supported
# output - localization of output + prefix added to all results
# as we aggregate multiple files we cannot "guess" it as e.g. we do for NGS pipeline
results_dir="./results"
results_prefix=""

# Pipeline-specific parameters with defaults
# Defaults are hardcoded in this script NOT in the .nf file
model="GTR+G" # Model for raxml
starting_trees=10 # Number of random initial trees
bootstrap=200 # Number of bootstraps
min_support=70 # Minimum support for a branch to keep it in a tree
threads=36 # ilość wątków używanych maksymalnie przez pipeline
# QC params
thresholdN=0.02 # Maksymalny odsetek N w genomie (liczba zmiennoprzecinkowa z przedziału [0, 1])
thresholdAmbiguous=0 # Maksymalny odsetek symboli niejednoznacznych w genomie (liczba zmiennoprzecinkowa z przedziału [0, 1])
# Visualization
map_detail="city"  #  poziom hierarchii na mapie przypisany próbce. Możliwe wartości to country lub city.

# Clockrate estimation
clockrate="" # User can still override any built-in and estimated values fron the alignment. If empty data derived
skip_clockrate_estimation="false"

# Usage function to display help
usage() {
    echo "Użycie: $0 --input_dir ŚCIEŻKA --input_type TYP --results_dir ŚCIEŻKA --db SCIEZKA --profile NAZWA --metadata metadata.txt --genus Salmonella --results_prefix prefiks"
    echo
    echo "Skrypt uruchamia bakteryjny pipeline filogenetyczny oparty na danych SNP."
    echo
    echo "Wymagane parametry:"
    echo "  -m, --metadata ŚCIEŻKA            Ścieżka do pliku z metadanymi (WYMAGANE)"
    echo "  -i, --inputDir ŚCIEŻKA            Ścieżka do katalogu z danymi wejściowymi SNP (WYMAGANE)"
    echo "  -t, --inputType TYP               Typ danych wejściowych: gff lub fasta (WYMAGANE)"
    echo "  -g, --genus NAZWA                 Rodzaj bakterii: Salmonella, Escherichia lub Campylobacter (WYMAGANE)"
    echo "  -p, --results_prefix PREFIKS      Prefiks dodawany do wszystkich plików wynikowych (WYMAGANE)"
    echo "  -d, --projectDir ŚCIEŻKA          Ścieżka do lokalnej wersji repozytorium (WYMAGANE)"
    echo
    echo "Opcjonalne parametry:"
    echo "  --db ŚCIEŻKA                      Sciezka do katalogu z pobranymi zewnetrznymi bazami"
    echo "                                    (domyślnie: /mnt/unity_nfs/external_databases)"
    echo "  -o, --results_dir ŚCIEŻKA         Katalog wynikowy (domyślnie: ./results)"
    echo "  -x, --profile NAZWA               Profil wykonania Nextflow (dozwolone: 'local' lub 'slurm', domyślnie: local)"
    echo "  -r, --clockrate WARTOŚĆ           Stała szybkość zegara molekularnego do TimeTree; jeśli nie podana, szacowana z danych lub ustawiana na wartość domyślną dla rodzaju"
    echo "  --model MODEL                     Model substytucji dla RAxML (domyślnie: GTR+G)"
    echo "  --starting_trees LICZBA            Liczba drzew startowych dla RAxML (domyślnie: 10)"
    echo "  --bootstrap LICZBA                Liczba replikacji bootstrap dla RAxML (domyślnie: 200)"
    echo "  --min_support LICZBA               Minimalne wsparcie gałęzi, by pozostała w końcowym drzewie (domyślnie: 70)"
    echo "  --threads LICZBA                  Liczba rdzeni CPU do wykorzystania (domyślnie: 36, wielkość musi byc iloczynem 12)"
    echo "  --thresholdN LICZBA               Maksymalny odsetek N w genomie (float z przedziału [0, 1]) (domyślnie: 0.02)"
    echo "  --thresholdAmbiguous LICZBA       Maksymalny odsetek symboli niejednoznacznych w genomie (float z przedziału [0, 1]) (domyślnie: 0)"
    echo "  --main_image NAZWA:TAG            Obraz Docker zawierający narzędzia używane przez pipeline"
    echo "  --prokka_image NAZWA:TAG          Obraz Docker z oprogramowaniem Prokka"
    echo "  --map_detail STR                  Informacja czy na mapie próbka przypisana jest do poziomu kraju czy miasta"
    echo "                                    (dozwolone wartości 'country' lub 'city', domyślnie city)."
    echo "                                    Kolumna o tej nazwie w metadanych musi istnieć i nie może być pusta."
    echo "  -h, --help                        Show this help message"
    exit 1
}

# Parse arguments using GNU getopt
TEMP=$(getopt -o hm:i:t:g:p:d:o:x:r: \
--long metadata:,inputDir:,inputType:,genus:,results_prefix:,projectDir:,results_dir:,profile:,clockrate:,model:,starting_trees:,bootstrap:,min_support:,threads:,thresholdN:,thresholdAmbiguous:,main_image:,prokka_image:,map_detail:,db:,help \
-n "$0" -- "$@")

if [ $? != 0 ]; then usage; fi
eval set -- "$TEMP"

# Parse args into variables
while true; do
  case "$1" in
    -m|--metadata) metadata="$2"; shift 2 ;;
    -i|--inputDir) inputDir="$2"; shift 2 ;;
    -t|--inputType) inputType="$2"; shift 2 ;;
    -g|--genus) genus="$2"; shift 2 ;;
    -p|--results_prefix) results_prefix="$2"; shift 2 ;;
    -d|--projectDir) projectDir="$2"; shift 2 ;;
    -o|--results_dir) results_dir="$2"; shift 2 ;;
    -x|--profile) profile="$2"; shift 2 ;;
    -r|--clockrate) clockrate="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --starting_trees) starting_trees="$2"; shift 2 ;;
    --bootstrap) bootstrap="$2"; shift 2 ;;
    --min_support) min_support="$2"; shift 2 ;;
    --threads) threads="$2"; shift 2 ;;
    --thresholdN) thresholdN="$2"; shift 2 ;;
    --thresholdAmbiguous) thresholdAmbiguous="$2"; shift 2 ;;
    --main_image) main_image="$2"; shift 2 ;;
    --prokka_image) prokka_image="$2"; shift 2 ;;
    --map_detail) map_detail="$2"; shift 2 ;;
    --db) db_absolute_path_on_host="$2"; shift 2;; 
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Check required arguments
if [[ -z "$metadata" || -z "$inputDir" || -z "$inputType" || -z "$genus" || -z "$results_prefix" ]]; then
    echo "Błąd: brakuje wymaganych argumentów!"
    usage
fi

# 1. Check if input paths exist
if [ ! -f "$metadata" ]; then
    echo "Błąd: plik metadata '$metadata' nie istnieje."; exit 1
else
    metadata=$(realpath $metadata)
    header=$(head -n 1 "$metadata")
fi

if [ ! -d "$inputDir" ]; then
    echo "Błąd: katalog wejściowy '$inputDir' nie istnieje."; exit 1
else
  inputDir=$(realpath -- $inputDir)
fi

if [ ! -d "$projectDir" ]; then
    echo "Błąd: katalog projektu '$projectDir' nie istnieje."; exit 1
else
  projectDir=$(realpath -- "$projectDir") || {
  echo "Błąd: nie mogę wyznaczyć ścieżki absolutnej dla '$projectDir'." >&2
  exit 1
}
fi

if [ -d "$results_dir" ]; then
  results_dir=$(realpath ${results_dir})
else
  mkdir -p -- "$results_dir" || { echo "Nie mogę utworzyć katalogu: $results_dir" >&2; exit 1; }
  results_dir=$(realpath -- "$results_dir")
fi

if [ ! -d "${db_absolute_path_on_host}" ]; then
    echo "Błąd: katalog z zewnetrznymi bazami '$db_absolute_path_on_host' nie istnieje."; exit 1
fi

# 2. Validate profile
if [[ "$profile" != "local" && "$profile" != "slurm" ]]; then
    echo "Błąd: nieprawidłowy profil Nextflow: '$profile'. Dozwolone: 'local', 'slurm'."; exit 1
fi

# 3. Check Docker images only for local execution
if [[ "$profile" != "slurm" ]]; then
    if ! docker image inspect "$main_image" > /dev/null 2>&1; then
        echo "Błąd: obraz Docker '$main_image' nie istnieje lokalnie."; exit 1
    fi
    if ! docker image inspect "$prokka_image" > /dev/null 2>&1; then
        echo "Błąd: obraz Docker '$prokka_image' nie istnieje lokalnie."; exit 1
    fi
fi

# 4. Validate genus
if [[ "$genus" != "Salmonella" && "$genus" != "Escherichia" && "$genus" != "Campylobacter" ]]; then
    echo "Błąd: nieprawidłowy rodzaj bakterii: '$genus'. Dozwolone: Salmonella, Escherichia, Campylobacter."; exit 1
fi

# 5. Validate inputType
if [[ "$inputType" != "fasta" && "$inputType" != "gff" ]]; then
    echo "Błąd: nieprawidłowy typ danych wejściowych: '$inputType'. Dozwolone: fasta, gff."; exit 1
fi

# 6. Validate thread count
if ! [[ "$threads" =~ ^[0-9]+$ ]] || [ "$threads" -le 0 ]; then
    echo "Błąd: liczba wątków '$threads' jest nieprawidłowa. Musi być dodatnią liczbą całkowitą."; exit 1
fi

if [[ "$profile" != "slurm" ]]; then
    max_cpus=$(nproc)
    if [ "$threads" -gt "$max_cpus" ]; then
        echo "Błąd: liczba wątków '$threads' jest nieprawidłowa. Dozwolone wartości: od 1 do $max_cpus."; exit 1
    fi
fi

if [ $((threads % 12)) -ne 0 ]; then
    echo "Błąd: liczba wątków ($threads) musi być wielokrotnością 12"; exit 1
fi

# 7. Validate map_detail
if [[ "${map_detail}" != "country" && "${map_detail}" != "city" ]]; then
    echo "Błąd: nieprawidłowy typ danych wejściowych: '${map_detail}'. Dozwolone: city, country."; exit 1
fi

# Empty map_detail values are used as a join key against coordinates and
# duplicate every sample (cartesian product of blank/NaN keys).
map_detail_col=$(get_col_idx "$map_detail" "$header")
if [ -z "$map_detail_col" ]; then
    echo "Błąd: Kolumna '$map_detail' nie znaleziona w metadanych (wymagana przez --map_detail)."; exit 1
fi

empty_map_detail_rows=$(awk -v col="$map_detail_col" -F'\t' '
    NR == 1 { next }
    {
        val = $col
        gsub(/\r/, "", val)
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        if (val == "" || val == "NA" || val == "NaN" || val == "nan" || val == ".") {
            n++
        }
    }
    END { if (n > 0) print n }
' "$metadata")
if [ -n "$empty_map_detail_rows" ]; then
    echo "Błąd: Kolumna '$map_detail' zawiera puste wartości ($empty_map_detail_rows wierszy). Wartości w kolumnie wskazanej przez --map_detail nie mogą być puste."; exit 1
fi

# Numerical values
[[ "$min_support" =~ ^[0-9]+$ ]]    || err "--min_support must be integer"
[[ "$starting_trees" =~ ^[0-9]+$ ]] || err "--startingTrees must be integer"

# Validate date column: required format YYYY-MM-DD. TimeTree's clock-rate
# estimation (treetime clock) crashes with "No variation in sampling dates!" when
# every sample shares the same date, before its own fallback logic can kick in.
# We detect that here and tell the pipeline to skip the estimation step and go
# straight to the built-in clock rate for the analysed genus.
date_col=$(get_col_idx "date" "$header")
if [ -z "$date_col" ]; then
    echo "Błąd: Kolumna 'date' nie znaleziona w metadanych."; exit 1
fi

invalid_dates=$(awk -v col="$date_col" -F'\t' '
    NR == 1 { next }
    {
        val = $col
        gsub(/\r/, "", val)
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        if (val !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) {
            n++
        }
    }
    END { if (n > 0) print n }
' "$metadata")
if [ -n "$invalid_dates" ]; then
    echo "Błąd: Kolumna 'date' zawiera wartości niezgodne z wymaganym formatem YYYY-MM-DD ($invalid_dates wierszy)."; exit 1
fi


unique_dates=$(awk -v col="$date_col" -F'\t' 'NR>1 {print $col}' "$metadata" | sort | uniq | wc -l)
if [ "$unique_dates" -lt 2 ] && [ -z "$clockrate" ]; then
    echo "Uwaga: Wszystkie próbki mają identyczną datę pobrania (kolumna 'date'). TimeTree nie jest w stanie oszacować clock rate bez zmienności dat w tej kolumnie - pomijam estymację i używam wbudowanej wartości domyślnej dla rodzaju '${genus}'. Aby użyć innej wartości, podaj --clockrate."
    skip_clockrate_estimation="true"
fi

# 8 Safegurads 
# Restrict the analysis to samples belonging to the same serovar or ST.
# Analysis of samples from different serovars/ST makes no sense

# Determine the safeguard level
safeguard_level="Serovar" # ST for sequence type, None to skip safegurads

# Find Serovar column
serovar_col=$(get_col_idx "Serovar" "$header")
if [ -z "$serovar_col" ]; then
    echo "Błąd: Kolumna 'Serovar' nie znaleziona w metadanych."; exit 1
fi

# Find MLST column
mlst_col=$(get_col_idx "MLST" "$header")
if [ -z "$mlst_col" ]; then
    echo "Błąd: Kolumna 'MLST' nie znaleziona w metadanych."; exit 1
fi

# Checks depending on safeguard_level

if [ "$safeguard_level" = "Serovar" ]; then
    unique_serovars=$(awk -v col="$serovar_col" -F'\t' 'NR>1 {print $col}' "$metadata" | sort | uniq | wc -l)
    if [ "$unique_serovars" -gt 1 ]; then
        echo "Błąd: Wykryto wiele serowarow (Serovar) w metadanych. Program sluzy do analizy probek nalezacych do jednolitego serotypu."; exit 1
    fi
elif [ "$safeguard_level" = "ST" ]; then
    unique_mlst=$(awk -v col="$mlst_col" -F'\t' 'NR>1 {print $col}' "$metadata" | sort | uniq | wc -l)
    if [ "$unique_mlst" -gt 1 ]; then
        echo "Błąd: Wykryto wiele typów sekwencyjnych w metadanych. Program sluzy do analizy probek z jednego typu ST wedlug schematu MLST."; exit 1
    fi
elif  [ "$safeguard_level" = "None" ]; then
    echo 'Warning: safeguard_level is set to None, diverse samples not suitable for phylogenetic analysis might be analyzed together '
else
    echo "Błąd: Nieznany poziom zabezpieczeń: $safeguard_level."; exit 1
fi

# clockrate
if [ -n "$clockrate" ]; then
  [[ "$clockrate" =~ ^[0-9]*\.?[0-9]+$ ]] || err "--clockRate must be a positive float"
  awk "BEGIN{exit !($clockrate>0)}" >/dev/null 2>&1 || err "--clockrate must be > 0"
fi

# ---------- Run Nextflow ----------
args=(
  "--input_dir"                "$inputDir"
  "--metadata"                 "$metadata"
  "--input_type"               "$inputType"
  "--genus"                    "$genus"
  "--results_prefix"           "$results_prefix"
  "--model"                    "$model"
  "--starting_trees"           "$starting_trees"
  "--bootstrap"                "$bootstrap"
  "--min_support"              "$min_support"
  "--threshold_Ns"             "$thresholdN"
  "--threshold_ambiguities"    "$thresholdAmbiguous"
  "--main_image"               "$main_image"
  "--prokka_image"             "$prokka_image"
  "--results_dir"              "$results_dir"
  "--threads"                  "$threads"
  "--map_detail"               "${map_detail}"
  "--db_absolute_path_on_host" "${db_absolute_path_on_host}"
  "--projectDir"               "$projectDir"
  "--skip_clockrate_estimation" "$skip_clockrate_estimation"
)

# Append optional clockrate only if set
[ -n "${clockrate:-}" ] && args+=( "--clockrate" "$clockrate" )

# Trace file lets us see which process failed and its exit status/duration
# without digging through Nextflow's work/ hash directories.
trace_file="${results_dir}/${results_prefix}_trace.txt"

set -x
nextflow run "${projectDir}/nf_bacterial_phylogenetic_pipeline.nf" -profile "$profile" -with-trace "$trace_file" "${args[@]}"

