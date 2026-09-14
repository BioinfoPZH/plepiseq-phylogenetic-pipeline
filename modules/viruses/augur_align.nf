process augur_align {
    container  = params.main_image
    tag "Creating multiple sequence alignment with mafft"
    tag "${segmentId}"
    cpus { params.threads > 25 ? 25 : params.threads }
    memory "30 GB"
    time "1h"
    input:
    tuple val(segmentId), path(fasta)

    output:
    tuple val(segmentId), path("aligned.fasta"), emit: out

    script:
    """
    augur align --sequences ${fasta} \
                --output aligned.fasta \
                --nthreads ${task.cpus}
    """
}