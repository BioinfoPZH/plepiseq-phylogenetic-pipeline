process run_dummy_refine {
    // This process runs augur refine without tree time. It goal is to produce valid branch_lengths.json file for original nwk tree from raxml-ng
    // So it can visualized alongside actual timetree
    container  = params.main_image
    tag "Adding temporal data to tree"
    cpus 1
    memory "20 GB"
    time "5h"
    input:
    path(tree)
    tuple path(alignment), path(metadata)
    output:
    tuple path("tree3_notimetree.nwk"), path("branch_lengths_notime.json")
    script:
    """

    run_augur() {
       augur refine --tree ${tree} \\
                    --alignment ${alignment} \\
                    --metadata ${metadata} \\
                    --output-tree tree3_notimetree.nwk \\
                    --output-node-data branch_lengths_notime.json \\
                    --branch-length-inference input \\
                    --keep-polytomies \\
                    --keep-root

   }

   # Run castrated augur
   run_augur
   
   """
}
