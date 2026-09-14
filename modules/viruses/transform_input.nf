process transform_input {
    container  = params.main_image
    cpus 1
    memory "30 GB"
    time "1h"
    input:
    path input_dir

    output:
    path "*.fasta", emit: fastas

    script:
    """
    samples=(\$(ls -d ${input_dir}/*/))
    segments=(PB2 PB1 PA HA NP NA MP NS)

    for idx in \$(seq 1 8); do
        segment=\${segments[\$((idx-1))]}
        infile="output_chr\${idx}_\${segment}.fasta"
        outname="\${segment}.fasta"

        for sample in "\${samples[@]}"; do
            cat "\${sample}/\${infile}" >> \$outname
        done
    done
    """
}

process transform_input_novel {
    container  = params.main_image
    cpus 1
    memory "30 GB"
    time "1h"
    input:
    path input_dir

    output:
    path "*.fasta", emit: fastas

    script:
    """

    # Copy all gzipped FASTA files from input_dir into the local workdir
    cp ${input_dir}/*.fasta.gz .

    # Decompress all .fasta.gz files
    for f in *.fasta.gz; do
        gunzip "\$f"
    done

    # original data are stored in samples dir
    mkdir samples
    mv *.fasta samples/ || true

    # Collect segment names from the first decompressed sample
    cd samples
    first_sample=\$(ls *.fasta | head -1)
    segments=\$(grep "^>" "\$first_sample" | sed 's/>//' | cut -d'|' -f1 | sed s'|/|_|g' | sort | uniq)
    cd ..

    # Initialize empty FASTA files for each segment
    for seg in \$segments; do
        seg_name=\$(echo \$seg | cut -d "|" -f1 | tr -d ">")
        touch \${seg_name}.fasta
    done

    # Append sequences for each segment from each sample
    for f in samples/*.fasta; do
        sample_id=\$(basename "\$f" .fasta)

        awk -v sid="\$sample_id" '
            /^>/ {
                split(\$0, parts, "|")
                seg = substr(parts[1], 2)
                gsub("/", "_", seg)
                out = seg ".fasta"
                print ">" sid >> out
                next
            }
            {  print >> out }
        ' "\$f"

    done
    rm -rf samples

    """
}