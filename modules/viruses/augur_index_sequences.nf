process augur_index_sequences {
    container  = params.main_image
    tag "Indexing sequences for segment ${segmentId}"
    cpus 1
    memory "30 GB"
    time "1h"
    input:
    tuple val(segmentId), path(fasta)

    output:
    tuple val(segmentId), path("sequence-index.csv"), emit: sequence_index

    script:
    """
    augur index --sequences ${fasta} --output sequence-index.csv
    """
}