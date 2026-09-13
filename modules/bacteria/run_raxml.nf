process run_raxml {
    container  = params.main_image
    // publishDir "${params.results_dir}/${params.results_prefix}/subschemas", mode: 'copy', pattern: "filogram_data.json"
    tag "Calculating SNPs tree"
    cpus params.threads
    memory "10 GB"
    time "8h"
    input:
    tuple path(fasta), path(partition)
    output:
    path("tree.raxml.support"), emit: tree
    path("filogram_data.json"), emit: json
    script:
    def ntrees = params.starting_trees
    def nboots = params.bootstrap

    """
    if [ ${task.cpus} -lt 12 ]; then
      WORKERS=1
    else
      WORKERS=\$((${task.cpus} / 12))
    fi

    # Cap threads/workers with auto{}
    # Modified precision to get in nwk even small distances 
    raxml-ng --all \\
             --msa ${fasta} \\
             --precision 15 \\
             --threads auto{${task.cpus}} \\
             --model ${partition} \\
             --site-repeats on \\
             --tree pars{${ntrees}} \\
             --bs-trees ${nboots} \\
             --prefix tree \\
             --force \\
             --workers auto{\${WORKERS}} \\
             --brlen scaled

    ID=`grep ">" ${fasta} | sed s'|>||g' | tr "\\n" ","`
    VERSION=`raxml-ng --version | awk '/RAxML-NG v/ {print \$3; exit}'`
    MODEL=`cat partition.txt | cut -d'{' -f1 | cut -d',' -f1`
    echo "
    {'bacterial_genome' : {
    'id_filogram':'\${ID}',
    'program_name':'raxml-ng',
    'program_version' : '\${VERSION}',
    'phylogenetic_model' : '\${MODEL}',
    'phylogenetic_bootstrap' : ${params.bootstrap},
    'phylogenetic_min_support' : ${params.min_support},
    'phylogenetic_starting_trees' : ${params.starting_trees}
    }
    }
    " >> filogram_data.json

    cat filogram_data.json |  tr "\\'" "\\"" > tmp
    mv tmp filogram_data.json
    """  
}
