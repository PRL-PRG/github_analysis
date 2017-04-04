---
title: "Finding Project Clones"
output: html_notebook
---

First we must create the `clone_finder.csv` file which contains for each file a project it belongs to, its tokenHash and number of tokens the file has. This can be done by calling the `exportCloneFinderData` function from `functions.R`, which takes the database with the dataset and output folder as its arguments:

    exportCloneFinderData("js", "/datasets/js")
    
Optional `threshold` argument can be set to ignore any files witch fewer or equal than `threshold` total tokens. Default value is `0` which ignores only empty files.      

When done, get the [`clone_finder`](https://github.com/reactorlabs/clone_finder), build it and execute:

    git clone git@github.com:reactorlabs/clone_finder.git
    cd clone_finder
    mkdir build
    cd build
    cmake ..
    make
    ./clone_finder NUM_THREADS FOLDER THRESHOLD
    
where `NUM_THREADS` is the number of treads clone finder can use (setting this to the number of logical processors works the best), `FOLDER` is the folder where the `clone_finder.csv` file is, and where the clone finder results will be placed. `THRESHOLD` is the minimal number of tokens (inclusive) that a file must have to be considered by the clone finder. 

> Note that the clone finder script expects that all its data will fit in memory. This should not be a problem though, for JavaScript, ~250m records, 10G of RAM is used. 

## Importing results to the database

Each thread of the clone finder produces its own output file and they all must be imported. The schema of the file is the following:

- clone id (pid)
- clone cloned files
- clone total files
- clone cloning percent
- host id (pid)
- host affected files
- host total files
- host affected percent

To import the data back into the database, use the `importCloneFinderData` function, which takes the database name, input folder which contains the `clone_finder` outputs and number of threads to import as arguments:

    importCloneFinderData("js", "/datasets/js", 8)


## Technical Details

The original version of the clone finder script has been produced by UCI and can be found [here](https://github.com/Mondego/SourcererCC/blob/master/tokenizers/file-level/db-importer/clone_finder.py). The C++ version this page describes differs from it in the following:

- database is not queried for the data, nor are results stored to it (filesystem is faster)
- file id's are ignored, files in projects are aggregated by token hashes (much smaller searchspace)
- search space is further pruned for only project with viable files


