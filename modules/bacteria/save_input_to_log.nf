process save_input_to_log {
  tag "Dummy process"
  cpus 1
  memory "1 GB"
  time "1m"
  input:
  path(x)
  output:
  stdout
  script:
  """
  echo ${x} >> log
  """
}
