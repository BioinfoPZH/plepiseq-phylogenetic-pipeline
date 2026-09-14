process run_prokka {
  container  = params.prokka_image
  tag "Predicting genes for sample $x"
  cpus { params.threads > 25 ? 25 : params.threads }
  memory "10 GB"
  time "20m"
  input:
  tuple val(x), path(fasta)
  output:
  path("${x}.gff")
  script:
  """
    fasta="${fasta}"
    # If the input is gzipped fasta file we need to unzip it
    if [[ "${fasta}" == *.gz ]]; then
        new_name="${fasta.getName().replace('.gz', '')}"
        gunzip -c ${fasta} > \${new_name}
        fasta="\${new_name}"
    fi

    prokka --metagenome --cpus ${task.cpus} --outdir prokka_out --prefix prokka_out --compliant --kingdom Bacteria \${fasta}
    # echo -e "{\\"status\\": \\"tak\\", \
    #          \\"prokka_gff\\": \\"${params.results_dir}/${x}/${x}_prokka.gff\\", \
    #          \\"prokka_ffn\\": \\"${params.results_dir}/${x}/${x}_prokka.ffn\\"}" >> prokka.json
    # Following files are useful for phylogenetic analysis
    mv prokka_out/prokka_out.gff ${x}.gff
    mv prokka_out/prokka_out.ffn ${x}.ffn
  """
}
