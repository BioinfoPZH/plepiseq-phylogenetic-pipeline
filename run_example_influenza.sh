#!/bin/bash

# Example: Run viral phylogenetic pipeline on influenza dataset
# All genomes are stored in a single directory in distinct FASTA files.
# Nextflow will use SLURM to manage process execution.


bash nf_pipeline_viral_phylo.sh -i ./data/example_data/influenza/ \
                                -m ./data/example_data/influenza/influenza_metadata.tsv \
				-g influenza \
			  -p test_influenza \
				-d . \
				--threshold_Ns 0.05 \
				--results_dir results \
				-x slurm 

