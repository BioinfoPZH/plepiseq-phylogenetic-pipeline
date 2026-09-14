process find_country_coordinates {
    // use OpenStreetMap API to request geographical objects coordinates
    container  = params.main_image
    tag "Preparing geo data for analyzed samples"
    cpus 1
    memory "20 GB"
    time "2h"

    input:
    path(metadata)

    output:
    path("longlang.txt")

    script:
    """
    extract_geodata.py  --input_metadata ${metadata} \
                        --output_metadata longlang.txt \
                        --features country \
                        --features city
    """
}
