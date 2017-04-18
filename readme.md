# TODO for paper

- import dataset
- create non-npm dataset
- redo clone finder so that we have confidence in the data
- redo the graphs
- 


# Reproducing the GitHub Analysis 

This repository contains the necessary information to reproduce the github analysis paper for the languages presented. 

## Workflow

Many of the steps mentioned below take unfeasible ammounts of time for the review process. We therefore provide input data for each step as well so that users can recreate only those steps they are interested in.

> TODO how do we provide the data? Download from ginger, disk space permits might be the easiest? We can install some torrent thingy there...

- [download and tokenize the projects from github](docs/data_acquisition.md)

> This step takes *very* long time. For JavaScript, the running time was 20 days. Bottlenecks are internet speed and git performance when cloning the repositories.

- [import the data to MySQL database](docs/mysql_import.md)

> Reasonably performant machine with ideally a lot of RAM helps a lot. JavaScript took about 6 hours to import & index the basic database, another 5 hours for the non-NPM dataset. 

- [download projects metadata](docs/metadata.md)

- [create project clones information](docs/project_clones.md)

> Project cloning information for all non-empty files took around 5 hours. Data import is another 7 hours.

- run SourcererCC clone detection

> this needs huge machine

- do aggretation & graphs, visualization

> Detailed information in `scripts/` in `graphs.Rmd` and `heatmaps.Rmd`

## Datasets

### `cpp`, `java`, `python`

Respective languages, bits & pieces of the database required for local visualization:

- `commits.txt` = gh_id -> # of commits
- `stars.txt` = gh_id -> # of stars 
- `files.csv` = dump of the files table, modulo local path
- `files.csv.h2i` = fileHash replaced with unique id
- `heatmap.csv` = computed heatmap
- `m.csv` = path to db_id to gh_id to url conversion
- `project_clones.csv` = project clones info as calculated at UCI
- `scc_groups_uci.txt` = size of sourcererCC groups as calculated at UCI

### `jsHalf`

Main dataset for JavaScript used in the paper, contains roughly 47% of Github projects. For aggregations, 03/1999 is the first month, each line represents end of next month

- `aggregated.files.csv` = files of various types aggregated over time
- `aggregated.projects.*.csv` = aggregated counts of projects in respective languages over time. 
- `files_nm.csv` = information about files wrt NPM, bower, tests, minjs, etc. 
- `groups_ccc.csv` = SourcererCC clone groups calculated by us

Other files like other language datasets if present. 

The folder also includes the tokenizer output files in `unmerged`

### `jsHalf_nonpm`

Contains clone finder results for the non npm subset.

### `js`

This is entire github downloaded in 20 strides. Not used for paper because we are missing sourcererCC results. Also contains unmerged tokenizer results in `unmerged`. 

### `js_nonpm`

Contains clone finder subset for the non npm full github dataset. 

### `npm`

This is not a dataset, but contains downloaded `project.json` file for those projects from jsHalf which have it. It can be used to see how many projects use NPM w/o including the packages. 



## Hardware Requirements

### Disk Requirements

At least 1TB of disk space is recommended, if all steps are to be followed for all languages, more may be needed. For instance, raw data from the JavaScript tokenizer amount to `170GB`, which shrinks to  `100GB` after merging. The database alone has similar requirements. 

> This does not include space needed to obtain *all* C++, Java and Python projects. 

### Machines Used

#### `ginger`

i7-6700K, 64GB RAM, 1TB NvMe SSD, 4TB HDD, Ubuntu 16.04 LTS

This machine was used for: JavaScript download & tokenization, database, projects clone analysis, visualization

#### `styx`

???

This machine was used for running SourcererCC clone detection.










