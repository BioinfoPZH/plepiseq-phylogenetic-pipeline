process find_country_coordinates {
    // use Open Street Map api to request geographical objects coordinates
    container  = params.main_image
    tag "Preparing geo data for analyzed data"
    cpus 1
    memory "20 GB"
    time "2h"
    input:
    path(metadata)
    output:
    path("longlang.txt")
    script:
    """
    python /opt/docker/custom_scripts/extract_geodata.py  --input_metadata ${metadata} \
                                                          --output_metadata tmp.txt \
                                                          --features country \
                                                          --features city
    # sort file using feature name
    cat tmp.txt | sort -k1 > longlang.txt
    """

}
