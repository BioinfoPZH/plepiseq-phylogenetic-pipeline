process merge_jsons {
  // Generic function to merge jsons
  tag "merge jsons for $id"
  container  = params.main_image
  cpus 1
  memory "1 GB"
  time "5m"
  input:
    tuple val(id), path(jsons)

  output:
    path("${id}_merged.json")

  script:
    """

    jq -s 'reduce .[] as \$item ({}; . * \$item)' ${jsons} > ${id}_merged.json

    """
}
