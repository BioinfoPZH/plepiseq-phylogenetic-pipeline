process prepare_MST {
    container  = params.main_image
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}_MST.{html,tsv}"
    containerOptions "--volume ${params.db_absolute_path_on_host}:/db"

    tag "Preparing minimum spanning tree"
    cpus { params.threads > 10 ? 10 : params.threads }
    memory "120 GB" 
    time "30m"
    input:
    path(metadata)
    output:
    path("${params.results_prefix}_MST.html"), emit: html
    path("${params.results_prefix}_MST.tsv"), emit: edges
    script:
    """
    if [[ "${params.genus}" == *"Salmo"* ]]; then
      profile_public_path="/db/cgmlst/Salmonella/profiles.list"
      profile_local_path="/db/cgmlst/Salmonella/local/profiles_local.list"
    elif [[ "${params.genus}" == *"Escher"* ]]; then
      profile_public_path="/db/cgmlst/Escherichia/profiles.list"
      profile_local_path="/db/cgmlst/Escherichia/local/profiles_local.list"
    elif [ "${params.genus}" == "Campylobacter" ]; then
      profile_public_path="/db/cgmlst/Campylobacter/jejuni/profiles.list"
      profile_local_path="/db/cgmlst/Campylobacter/jejuni/local/profiles_local.list"  
    fi

    python3 /opt/docker/custom_scripts/calculate_allelic_distance_and_plot_MST.py --metadata ${metadata} \
                                                                                  --profiles \${profile_public_path} \
                                                                                  --local-profiles \${profile_local_path} \
                                                                                  --plot ${params.results_prefix}_MST.html \
                                                                                  --output ${params.results_prefix}_distance.tsv \
                                                                                  --mst-output ${params.results_prefix}_MST.tsv \
                                                                                  --threads ${task.cpus} \
                                                                                  --color-by "HC5"

    """

}
