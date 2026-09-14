process iqtree {
    container  = params.main_image
    // publishDir "${params.results_dir}/${params.results_prefix}/subschemas", mode: 'copy', pattern: "${segmentId}_filogram_data.json"
    tag "Creating filogram for ${segmentId}"
    cpus params.threads
    memory "50 GB"
    time "2h"
    input:
    tuple val(segmentId), path(aln)

    output:
    tuple val(segmentId), path("${aln}.contree"), emit: out
    tuple val(segmentId), path("${segmentId}_filogram_data.json"), emit: json

    script:
    """
    #  Updated iqtree execution with following parameters
    # -bb Performs ultrafast bootstrap (UFBoot2)
    # -alrt Runs the SH-aLRT test to improve branch support calculations
    # -wsr Runs weighted Shimodaira–Hasegawa-like to improve final tree topology
    # -ninit Sets the number of starting trees
    # -T AUTO --threads-max caps parallelism instead of forcing task.cpus

    iqtree2 -T AUTO --threads-max ${task.cpus} \
            -s ${aln} \
            -m ${params.model} \
            -bb ${params.bootstrap} \
            -alrt ${params.bootstrap} \
            -con \
            -bnni \
            -minsup ${params.min_support} \
            -ninit ${params.starting_trees}


    ### Section for json ###
    ID=`grep ">" ${aln} | sed s'|>||g' | tr "\\n" ","`
    VERSION=`iqtree2 -V | awk '/version/ {print \$4}'`

    echo "{'${segmentId}' :
        {'id_filogram':'\${ID}',
        'program_name':'iqtree2',
        'program_version' : '\${VERSION}',
        'phylogenetic_model' : '${params.model}',
        'phylogenetic_bootstrap' : ${params.bootstrap},
        'phylogenetic_min_support' : ${params.min_support},
        'phylogenetic_starting_trees' : ${params.starting_trees}}
        }" >> ${segmentId}_filogram_data.json

    cat ${segmentId}_filogram_data.json|  tr "\\'" "\\"" > tmp
    mv tmp ${segmentId}_filogram_data.json

    """
}