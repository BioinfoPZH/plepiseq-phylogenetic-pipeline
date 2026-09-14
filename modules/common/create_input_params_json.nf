process create_input_params_json {
    // initiate channel for json aggregator for
    tag "Create json with input parameteres"
    container = params.main_image
    cpus 1
    memory "1 GB"
    time "5m"
    // publishDir "${params.results_dir}/${params.results_prefix}/subschemas", mode: 'copy', pattern: "input_params.json"
    input:
    path metadata
    val(ExecutionDir)
    output:
    path "input_params.json", emit: json
    env(QC_status), emit: initial_qc
    script:
    ExecutionDir = ExecutionDir.replace(".", "")
    def organism = (params.organism ?: params.genus ?: '').toString().toLowerCase()
    def genus    = (params.genus    ?: params.organism ?: '').toString().toLowerCase()
    """

    get_col_idx() {
        local col_name=\$1
        local header_line=\$2
        echo "\$header_line" | awk -v name="\$col_name" -F'\t' '{
            for (i=1; i<=NF; i++) {
                if (\$i == name) {
                    print i;
                    exit
                }
            }
        }'
    }

    cp ${metadata} metadata_adjusted.tsv
    header=\$(head -n 1 metadata_adjusted.tsv)
    ids_col=\$(get_col_idx "strain" "\$header")
    LIST_OF_IDS=\$(awk -v col="\${ids_col}" -F'\t' 'NR>1 {print \$col}' metadata_adjusted.tsv | sort | tr "\n" "," )
    DATA_URUCHOMIENIA=`date '+%F %H:%M'`
    VERSION=\$(cat /opt/docker/VERSION)

    bacteria=("salmonella" "escherichia" "campylobacter")
    if [[ ${genus} =~ "\${bacteria}" ]]; then

        echo "
        {
        'pathogen':'${organism}',
        'subcategory_organism':'TBD',
        'main_image':'${params.main_image}',
        'data_uruchomienia':'\${DATA_URUCHOMIENIA}',
        'pipeline_version' : '\${VERSION}',
        'input_data' : '${params.input_dir}',
        'input_metadata' : '${params.metadata}',
        'results_dir' : '${params.results_dir}/${params.results_prefix}',
        'threshold_Ns' : ${params.threshold_Ns},
        'threshold_ambiguities' : ${params.threshold_ambiguities},
        'map_detail' : '${params.map_detail}',
        'phylogenetic_model' : '${params.model}'  ,
        'phylogenetic_bootstrap' : ${params.bootstrap},
        'phylogenetic_min_support' : ${params.min_support},
        'phylogenetic_starting_trees' : ${params.starting_trees},
        'clockrate'  : '${params.clockrate}',
        'input_ids' : '\${LIST_OF_IDS}',
        'input_type_bacteria' : '${params.input_type}',
        'prokka_image' : '${params.prokka_image}'
        }
        " >> input_params.json

    else
        echo "
        {'pathogen':'${organism}',
         'subcategory_organism':'${params.safeguards_status }',
         'main_image':'${params.main_image}',
         'data_uruchomienia':'\${DATA_URUCHOMIENIA}',
         'pipeline_version' : '\${VERSION}',
         'input_data' : '${params.input_dir}',
         'input_metadata' : '${params.metadata}',
         'results_dir' : '${params.results_dir}/${params.results_prefix}',
         'threshold_Ns' : ${params.threshold_Ns},
         'threshold_ambiguities' : ${params.threshold_ambiguities},
         'map_detail' : '${params.map_detail}',
         'phylogenetic_model' : '${params.model}'  ,
         'phylogenetic_bootstrap' : ${params.bootstrap},
         'phylogenetic_min_support' : ${params.min_support},
         'phylogenetic_starting_trees' : ${params.starting_trees},
         'clockrate'  : '${params.clockrate}',
         'input_ids' : '\${LIST_OF_IDS}'
        }
        " >> input_params.json
    fi

    cat input_params.json |  tr "\\'" "\\"" > tmp
    mv tmp input_params.json
    QC_status="tak"
    """
}
