#!/bin/bash

# Example: Run phylogentic pipline on Salmonella samples that all share one sampling date.
# Reuses the FASTA files of the regular salmonella example, only the metadata differs.
# Because the "date" column has no variance, treetime cannot estimate a clock rate,
# so the pipeline falls back to the built-in rate for the genus instead of refusing to run.
# External databases are NOT part of this repo. The default below is the shared
# NFS resource; override it if your databases live somewhere else.

PATH_TO_EXTERNAL_DATABASES="/mnt/unity_nfs/external_databases"

bash nf_pipeline_bacterial_phylo.sh --metadata data/example_data/salmonella/metadata_salmonella_same_date.txt \
                                    --inputDir data/example_data/salmonella/fastas \
				    --genus Salmonella \
				    --inputType fasta \
				    --projectDir `pwd` \
				    -x "local" \
				    --db "${PATH_TO_EXTERNAL_DATABASES}" \
				    --results_prefix test_salmonella_same_date \
				    --results_dir results
