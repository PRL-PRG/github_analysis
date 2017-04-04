# Reproducing the GitHub Analysis 

This repository contains the necessary information to reproduce the github analysis paper for the languages presented. 

## Workflow

- [download and tokenize the projects from github](docs/data_acquisition.md)

> This step takes *very* long time. For JavaScript, the running time was 20 days. Bottlenecks are internet speed and git performance when cloning the repositories.

- [import the data to MySQL database](docs/mysql_import.md)

> Reasonably performant machine with ideally a lot of RAM helps a lot. JavaScript took about 6 hours to import & index the basic database, another 5 hours for the non-NPM dataset. 

- [create project clones information](docs/project_clones.md)

> Project cloning information for all non-empty files took around 5 hours. Data import is another 7 hours.


- ...


- [create summaries and graphs](docs/visualization.md)

> TODO

## Hardware Requirements








