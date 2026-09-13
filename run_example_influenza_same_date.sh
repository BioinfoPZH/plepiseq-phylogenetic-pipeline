#!/bin/bash

# Example: Run viral phylogenetic pipeline on an influenza dataset where all samples
# share one sampling date. Reuses the FASTA files of the regular influenza example,
# only the metadata differs.
# Because the "date" column has no variance, treetime cannot estimate a clock rate,
# so the pipeline falls back to the built-in rate for the organism instead of refusing to run.
# Nextflow will use the local executor to manage process execution.

bash nf_pipeline_viral_phylo.sh -i ./data/example_data/influenza/ \
                                -m ./data/example_data/influenza/influenza_metadata_same_date.tsv \
				-g influenza \
			        -p test_influenza_same_date \
				-d `pwd` \
				--threshold_Ns 0.05 \
				--results_dir results \
				-x local
