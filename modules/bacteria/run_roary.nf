process run_roary {
  container  = params.main_image
  tag "Predicting pangenome with roary"
  cpus { params.threads > 25 ? 25 : params.threads }
  memory "30 GB"
  time "1h"
  input:
  path(gff)
  output:
  tuple path("core_genes_alignment.fasta"), path("core_genes_alignment.embl")
  script:
  """
  # -f to nazwa katalogu z wynikiem
  # -e create a multiFASTA alignment
  # -n fast core gene alignment with MAFFT, use with -e
  # -v verbose
  # -p liczba rdzeni
  # -i minimum percentage identity for blastp [95]
  # -cd FLOAT percentage of isolates a gene must be in to be core [99]
  roary -p ${task.cpus} -i 95 -cd 95  -f ./roary_output -e -n *.gff
  cp roary_output/core_gene_alignment.aln core_genes_alignment.fasta
  cp roary_output/core_alignment_header.embl core_genes_alignment.embl
  """
}
