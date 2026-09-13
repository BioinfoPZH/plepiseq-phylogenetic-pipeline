# Changelog
All notable changes to this project will be documented in this file.

## [1.4.0] 2026-09-13
### Added
- Runs where every sample shares the same sampling date are no longer rejected. 
- `run_example_salmonella_same_date.sh` and `run_example_influenza_same_date.sh` plus the matching metadata files exercise that path against the existing example FASTA files.
### Changed
- Nextflow processes are now organised by pipeline: `modules/bacteria/`, `modules/viruses/` and `modules/common/` for the three processes both pipelines share.
- The per-genus/per-organism default clock rates are now defined once per process in a `default_clockrate()` helper instead of being repeated across `if`/`elif` branches.
### Fixed
- The Campylobacter branch of the bacterial clock-rate fallback was written as `[ ... == 'Campylobacter']` (no space before `]`), so the process aborted instead of applying the default rate.
- `treetime clock` failing or printing nothing parsable left `CORRELATION`/`CLOCK` empty, which turned the following `awk` comparison into a syntax error and emitted invalid JSON. Both values now fall back to defined defaults.

## [1.3.0] 2026-09-12
### Added
- `WGS2Phylo.py` now passes all columns from a file specified via`--supplemental-file`  (e.g. `age`, `gender`) into `metadata.tsv` as-is, filling empty values with `N/A` and sanitizing values against TSV corruption and spreadsheet formula injection.
- `WGS2Phylo.py` emits `HC0`, `HC2`, `HC5`, `HC10`, `HC20` HierCC clustering columns for bacterial organisms in normal mode; a level missing for a given organism/scheme is written as `Unknown`.
- Validate the `date` metadata column in both wrappers: reject values that are not `YYYY-MM-DD`, and reject runs where every sample shares the same date unless `--clockrate` is provided.
- Add `-with-trace` option to nextflow execution
### Fixed
- `tests/WGS2Phylo` imported a stale duplicate copy of `WGS2Phylo.py` instead of `bin/WGS2Phylo.py`; it now imports from `bin/` directly, like the MST tests already do.
- The Microreact project's metadata table only showed the columns hardcoded in the `.microreact` template, hiding any column not on that list (e.g. `age`/`gender`, extra HierCC levels) and, for viral projects, showing dead bacterial-only columns while hiding `virus`/`type`. `prepare_json_for_microreact.py` now rebuilds the table's column list from the actual metadata file for every run.
- `tests/MST_bacteria` used a second, separately-maintained copy of the `.microreact` template (`data/microreact_config_bacteria.microreact`); it now points at the same `config/microreact_config_bacteria.microreact` used in production.
- `raxml-ng` and `iqtree2` auto-detect a safe thread/worker count instead of always using every allocated CPU.

## [1.2.0] - 2026-08-08
### Added
- Export the bacterial cgMLST MST as an edge list (`*_MST.tsv`) and as a sample-level Newick tree (`*_MST.nwk`), rooted at the weighted graph centre determined with `networkx`.
- Show the MST as a third tree panel (`cgMLST MST`) in the bacterial Microreact project, next to the phylogenetic tree and the time tree.
### Fixed
- Keep sequence types separated by zero allelic differences connected in the MST; `scipy` had been discarding those edges and splitting the tree into a forest.
### Changed
- Name the Microreact tree panels `Phylogenetic tree` and `Time tree` instead of `Tree`.
- Group all trees in a single Microreact pane with one tab per tree instead of tiling them side by side; viral projects degrade to two tabs when no MST is available.
- Load `calculate_allelic_distance_and_plot_MST.py` from `bin/` in the MST tests instead of keeping a second copy under `tests/MST_bacteria/`.
- Default `--db` to the shared NFS resource `/mnt/unity_nfs/external_databases` instead of the host-local `/mnt/raid/external_databases`, so the same command works on every compute node.

## [1.1.0] - 2026-07-28
### Fixed
- Limit MST distance-calculation workers to the number of resolved cgMLST profiles.

## [1.0.2] - 2026-07-27
### Changed
- Skip local CPU-count validation when the `slurm` execution profile is selected.

## [1.0.1] - 2026-07-27
### Changed
- Skip local Docker image validation when the `slurm` execution profile is selected.

## [1.0.0] - 2025-12-22
### Changed
- Mark this as the first production-ready version of the program.
- Updated documentation in the `doc` folder and the `README.md` file 
### Added
- Introduce the `CHANGELOG.md` file.