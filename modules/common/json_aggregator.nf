process json_aggregator {
  tag "Creating json output"
  container  = params.main_image
  publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}.json"
  cpus 1
  memory "1 GB"
  time "5m"
  input:
  tuple path(input_params_json), path(sequence_filtering_json), path(sequence_clustering_json), path(phylogentics_json), path(chronomgram_json)
  val(ExecutionDir)
  output:
  path("${params.results_prefix}.json")
  script:
  """

  python3 /opt/docker/custom_scripts/json_aggregator.py --input_params ${input_params_json} \
                                                        --sequence_filtering_data ${sequence_filtering_json} \
                                                        --sequence_clustering_data ${sequence_clustering_json} \
                                                        --filogram_data ${phylogentics_json} \
                                                        --chronogram_data ${chronomgram_json} \
                                                        --executiondir ${ExecutionDir} \
                                                        --results_prefix ${params.results_prefix}

  """

}

