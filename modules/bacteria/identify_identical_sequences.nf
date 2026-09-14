process identify_identical_sequences {
    container  = params.main_image
    tag "Preparing SNPs alignment"
    // publishDir "${params.results_dir}/${params.results_prefix}/subschemas", mode: 'copy', pattern: "alignment_SNPs_sequence_clustering_data.json"
    cpus params.threads
    memory "10 GB"
    time "2h"

    input:
    tuple path(fasta), path(partition)
    output:
    tuple path("alignment_SNPs_unique.fasta"), path(partition),  emit: to_raxml
    path("alignment_SNPs_ident_seq.csv"), emit: identical_sequences_mapping
    path('alignment_SNPs_sequence_clustering_data.json'), emit: json
    script:
    """
    python /opt/docker/custom_scripts/find_identical_sequences.py --input ${fasta} \
                                                                   --output_dir . \
                                                                   --output_prefix alignment_SNPs \
                                                                   --threshold 1 \
                                                                   --segment_name bacterial_genome

    """

}
