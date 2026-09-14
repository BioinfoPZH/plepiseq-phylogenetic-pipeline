process generate_colors_for_features {
    container  = params.main_image
    cpus 1
    memory "20 GB"
    time "2h"

    input:
    path("longlang.txt")

    output:
    tuple path("longlang.txt"), path("color_data.txt")

    script:
    """
    cat longlang.txt | cut -f1,2 >> tmp.txt
    generate_colors_for_feature.py --input_file tmp.txt --output_file color_data.txt
    rm tmp.txt
    """
}