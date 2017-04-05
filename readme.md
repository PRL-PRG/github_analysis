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

- ...


- [create summaries and graphs](docs/visualization.md)

> TODO

## Hardware Requirements

### Disk Requirements

At least 1TB of disk space is recommended, if all steps are to be followed for all languages, more may be needed. For instance, raw data from the JavaScript tokenizer amount to `170GB`, which shrinks to  `100GB` after merging. The database alone has similar requirements. 

### Machines Used

#### `ginger`

i7-6700K, 64GB RAM, 1TB NvMe SSD, 4TB HDD, Ubuntu 16.04 LTS

This machine was used for: JavaScript download & tokenization, database, projects clone analysis, visualization

#### `styx`

???

This machine was used for running SourcererCC clone detection.










