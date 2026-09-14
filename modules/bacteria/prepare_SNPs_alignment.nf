process prepare_SNPs_alignment {
    container  = params.main_image
    tag "Preparing SNPs alignment"
    cpus params.threads
    memory "10 GB"
    time "2h"

    input:
    tuple path(fasta), path(embl)
    output:
    tuple path("alignment_SNPs.fasta"), path("partition.txt")

    script:
    """
    # --max_gap exclude from the analysis genes for which at least one sample missing more than 30% of sequence
    # --merge_genes partition file wont have many entries, one for each gene, but rather a single entry
    # for an entire genome + total number of constant sites observed in the initial alignment
    # this significantly speeds up the calculations by raxml as there are no partitions
    python /opt/docker/custom_scripts/prep_SNPs_alignment_and_partition.py --input_fasta ${fasta} \
                                                                           --input_fasta_annotation ${embl} \
                                                                           --model ${params.model} \
                                                                           --output_fasta alignment_SNPs.fasta \
                                                                           --output_partition partition.txt \
                                                                           --cpus ${task.cpus} \
                                                                           --max_gap 30 \
                                                                           --merge_genes

    """
}
