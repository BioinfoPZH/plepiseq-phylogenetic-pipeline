process add_temporal_data {
    // adjust branch lengths in tree to position tips by their sample date and infer the most likely time of their ancestors
    // augur refine seems to be a wrapper around treetime
    // Be aware that poor data with poor temporal signal might result in an incorrect tree
    container  = params.main_image
    tag "Adding temporal data to tree"
    // publishDir "${params.results_dir}/${params.results_prefix}/subschemas", mode: 'copy', pattern: "chronogram_data.json"
    publishDir "${params.results_dir}/${params.results_prefix}",  mode: 'copy', pattern: "${params.results_prefix}_chronogram.nwk"
    cpus 1
    memory "20 GB"
    time "5h"
    input:
    path(tree)
    tuple path(alignment), path(metadata)// SNPs alignment would confuse timetree when estimating clock we are using initial full alignment
    output:
    tuple path("tree3_timetree.nwk"), path("branch_lengths.json"), path("traits.json"), emit: to_auspice
    tuple path(tree), path("tree3_rescaled.nwk"), emit: to_microreact
    path("${params.results_prefix}_chronogram.nwk"), emit: to_results
    path('chronogram_data.json'), emit: json
    script:
    """

    run_augur() {
       local CR="\${1}"
       augur refine --tree ${tree} \\
                    --alignment ${alignment} \\
                     --metadata ${metadata} \\
                     --output-tree tree3_timetree.nwk \\
                     --output-node-data branch_lengths.json \\
                     --timetree \\
                     --coalescent opt \\
                     --date-confidence \\
                     --date-inference marginal \\
                     --precision 3 \\
                     --max-iter 10  \\
                     --gen-per-year 250 \\
                     --keep-polytomies \\
                     --clock-rate \${CR}

   }

    # Built-in clock rates, used whenever the alignment cannot tell us a better one
    default_clockrate() {
       case "${params.genus}" in
         Salmonella)    echo "2e-6" ;;
         Escherichia)   echo "8e-9" ;;
         Campylobacter) echo "6e-6" ;;
         *)             echo "2e-6" ;;
       esac
    }

    # Stays empty as long as the clock rate comes from the data or from the user. Anything else
    # means we silently substituted a built-in value, which the JSON must say out loud.
    # Keep the text free of quotes and apostrophes, the JSON below is assembled with tr.
    CLOCKRATE_WARNING=""

    if [ -n "${params.clockrate}"  ]; then
       # use user provided parameters for treetime overwrites all safeguards
       run_augur ${params.clockrate}

       # this will be passed to json
       CORRELATION="-1"
       CLOCK=${params.clockrate}
    elif [ "${params.skip_clockrate_estimation}" == "true" ]; then
       # Every sample shares one sampling date, so "treetime clock" would abort with
       # "No variation in sampling dates!". Go straight to the built-in rate.
       clockrate=\$(default_clockrate)
       run_augur \${clockrate}

       CORRELATION="-1"
       CLOCK=\${clockrate}
       CLOCKRATE_WARNING="All samples share a single sampling date, so the clock rate could not be estimated. The built-in rate for ${params.genus} (\${clockrate}) was used instead."
    else
     
      # Estimate clock rate if correlation is poor use predefined values for a provided genus ... better than nothing i guess
      cat $metadata | tr "\\t" "," >> metadata.csv

      # treetime gives up on data without a usable temporal signal, and it does so by raising
      # (e.g. "LinAlgError: Singular matrix" from the root-to-tip regression when the samples are
      # nearly identical). The task runs under "bash -ue", so its exit status must be caught here
      # or it terminates the whole process before the fallback below is reached.
      TREETIME_STATUS=0
      /usr/local/bin/treetime clock --tree $tree --aln $alignment --dates metadata.csv >> log 2>&1 || TREETIME_STATUS=\$?

      CORRELATION=`cat log  | grep "r^2" | awk '{print \$2}'`
      CLOCK=`cat log  | grep -w "\\-\\-rate"  | awk '{print \$2}'`

      # treetime can fail or print nothing parsable; fall back to the built-in rate
      # rather than feeding an empty string to awk and to the output JSON
      if [ -z "\${CORRELATION}" ]; then
        CORRELATION="-1"
      fi

      if [ "\${TREETIME_STATUS}" -ne 0 ]; then
        echo "WARNING: 'treetime clock' failed with exit status \${TREETIME_STATUS} (see the log file in this work directory). Using the built-in clock rate for ${params.genus}." >&2
        clockrate=\$(default_clockrate)
        CLOCK=\${clockrate}
        CLOCKRATE_WARNING="Clock rate estimation failed, treetime clock exited with status \${TREETIME_STATUS}, most likely because the samples are too similar to carry a temporal signal. The built-in rate for ${params.genus} (\${clockrate}) was used instead."
        run_augur \${clockrate}
      elif awk "BEGIN {if (\${CORRELATION} < 0.5) exit 0; else exit 1}"; then
        # We have poor fitness of our data we provide treetime with own set of parameters ...
        clockrate=\$(default_clockrate)
        CLOCK=\${clockrate}
        CLOCKRATE_WARNING="Weak temporal signal, the root-to-tip correlation r^2 = \${CORRELATION} is below 0.5. The built-in rate for ${params.genus} (\${clockrate}) was used instead of the estimated one."
        run_augur \${clockrate}
      else
        # we run treetime without specifying clock rate, alignment is ok
         
        augur refine --tree ${tree} \\
                    --alignment ${alignment} \\
                    --metadata ${metadata} \\
                    --output-tree tree3_timetree.nwk \\
                    --output-node-data branch_lengths.json \\
                    --timetree \\
                    --coalescent opt \\
                    --date-confidence \\
                    --date-inference marginal \\
                    --precision 3 \\
                    --max-iter 10  \\
                    --gen-per-year 250 \\
                    --keep-polytomies

      fi  # End for CORRELATION estimation
    
    fi # End for user provided clockrate

    # reconstruct ancestral features
    
    augur traits --tree  tree3_timetree.nwk \\
                 --metadata ${metadata} \\
                 --output-node-data traits.json \\
                 --columns "country city" \\
                 --confidence
    
    
    # modify tree3_timetree.nwk by replacing branches length with "time distance" predicted for each leaf and internal node with timetree
    python /opt/docker/custom_scripts/convert_nwk_to_timetree.py --tree tree3_timetree.nwk --branches branch_lengths.json --output tree3_rescaled.nwk
    cp tree3_rescaled.nwk ${params.results_prefix}_chronogram.nwk


    # create json
    # both values are interpolated unquoted into the JSON below, so they must never be empty
    if [ -z "\${CLOCK}" ]; then
      CLOCK=\$(default_clockrate)
    fi
    if [ -z "\${CORRELATION}" ]; then
      CORRELATION="-1"
    fi

    AUGUR_VERSION=`augur version | awk '{print \$2}'`
    TREETIME_VERSION=`treetime version |awk '{print \$2}'`
    ID=`grep ">" ${alignment} | sed s'|>||g' | tr "\\n" ","`

    echo "{'bacterial_genome' :
        {'id_chronogram':'\${ID}',
        'augur_version':'\${AUGUR_VERSION}',
        'treetime_version' : '\${TREETIME_VERSION}',
        'clockrate_value' : \${CLOCK},
        'clockrate_correlation' : \${CORRELATION},
        'clockrate_warning' : '\${CLOCKRATE_WARNING}'}
        }" >> chronogram_data.json

    cat chronogram_data.json |  tr "\\'" "\\"" > tmp
    mv tmp chronogram_data.json

    """
}
