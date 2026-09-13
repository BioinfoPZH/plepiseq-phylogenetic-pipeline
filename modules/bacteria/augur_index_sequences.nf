process augur_index_sequences {
    container  = params.main_image
    tag "Indexing sequences with augur"
    cpus 1
    memory "30 GB"
    time "1h"
    
    input:
    tuple path(fasta), path(embl)

    output:
    tuple path(fasta), path(embl), path("index.csv")

    script:
    """
    augur index --sequences ${fasta} --output index.csv
    """
}
