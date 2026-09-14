process augur_filter_sequences {
    container  = params.main_image
    // publishDir "${params.results_dir}/${params.results_prefix}/subschemas", mode: 'copy', pattern: "sequence_filtering_data.json"
    tag "Filtering out sequences with augur"
    cpus 1
    memory "30 GB"
    time "1h"

    input:
    tuple path(fasta), path(embl), path(index)
    path(metadata)
    output:
    tuple path("valid_sequences.fasta"), path(embl), emit: to_SNPs_alignment
    tuple path("valid_sequences.fasta"), path(metadata), emit: alignment_and_metadata
    path("sequence_filtering_data.json"), emit: json

    script:
    """
    # For NOW we are liberal when it comes to sequences quality
    # the script only checks columns 5 and 6 in $index i.e. Ns and ambiguous
    python /opt/docker/custom_scripts/identify_low_quality_sequences.py --output_dir . \
                                                                        --threshold_Ns ${params.threshold_Ns} \
                                                                        --threshold_ambiguities ${params.threshold_ambiguities} \
                                                                        --json_out sequence_filtering_data.json \
                                                                        --input $index
    # TO DO add a script that can retain only biologically valid entries from a set of sequences
    # This should be based on specific REQUIRED column in metadata file ( our NGS pipeline return this info)
    # Salmonella - predicted serovar level (e.g. only Montevideo)
    # Campylobacter - TO DO 
    # E.coli - serotype 
    # Influenza - subtype level (e.g. only H1N1pdm09)
    # SARS-Cov-2 no filters 
    # RSV type level (only A ot only B) 
    
    # For now we use augur filter to prepare fasta file without invalid_strains.txt prepared with filter_low_quality_sequences script
    # Other useful options --min-length --max-length  --group-by which we do not use for now
    augur filter \
        --sequences ${fasta} \
        --sequence-index ${index} \
        --metadata ${metadata} \
        --exclude invalid_strains.txt \
        --output-sequences valid_sequences.fasta
    """
}
