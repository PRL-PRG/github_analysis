# Optimization

The tokenizers use md5 for file and token hashes. When the dataset is finished, this is wasteful and slows down the database. the [`sccpreprocessor`](https://github.com/reactorlabs/sccpreprocessor) tool can thus be used to replace the md5 hashes of these with unique integers:

    javac *.java 
    java SccPreprocessor h2i PATH_TO_DATASET
    
where `PATH_TO_DATASET` is the folder which contains the `files.txt` and `stats.txt` files. When done, two new files (`files.csv.h2i` and `stats.csv.h2i`) will be created. These files are used for the import.

# Database Import

The `functions.R` script contains all the functions one can use to import data into the databases. First, it is best to set the settings variables globally, i.e. set the following in your R session:

    DB_USER = "???"
    DB_PASSWORD = "???"
    # if DB_HOST is different than localhost, you must set it too
    DB_HOST = "???"
    
With these, load the `functions.R` script, preferrably from its directory:

    source("functions.R")
    
You can now call the high-level import functions, which usually take the database name to import to and folder on local disk where to look for the data:

    importDataset("js", "/datasets/js")
    importDataset("cpp", "/datasets/cpp")
    importDataset("python", "/datasets/python")
    importDataset("java", "/datasets/java")

To import SourcererCC, make sure it is stored in `sourcerer.csv` and run the following:

    importSourcerer("js", "/datasets/js")

# Extra Information

## JavaScript Extra Information

JavaScript tokeizer produces extra information for its projects and files, stored in the `projects_extra.txt` and `files_extra.txt` files. When imported, these will add columns to the `projects` and `files` tables. The `importJSExtras` function in `functions.R` does this:

    importJSExtras("js", "/datasets/js")

## NPM files for JavaScript

JavaScript projects contain huge numbers of `node_modules` files, which come from NPM packages which were added to the repositories. These files will obviously be clones when same package is imported and should therefore be discarded. This pass flags those files appropriately together with other useful information:

Run `sccpreprocessor`:

    java SccPreprocessor nm PATH_TO_DATASET
    
where `PATH_TO_DATASET` is the folder which contains the `files.txt` output of the tokenizer. The script creates new file, called `files_nm.csv`, which for each file contains the following information:

- file id
- depth of relative path hierarchy
- depth of NPM module hierarchy (`0` = not a NPM module file)
- `1` if the file is likely to be a test 
- `1` if the file is possibly a locale 
- name of the NPM module which imported the file
- first NPM module in the hierarchy (i.e. at depth `1`)
- name of the file
- extension of the file
- name of the file inside the innermost NPM module

To import the data into the database, use `functions.R` again and run:

    importAndCreateJS_NPM("js_nonpm", "js", "/datasets/js")

where the arguments are:

- name of database that will store only non-NPM package files
- name of database that contains all js files and is already populated
- path to the dataset where the npm info (`files_nm.csv`) exists

The script adds the `npm` and `test` flags to each of the files in origin database, creates `files_nm` table which contains all the extra information described above and creates the `js_nonpm` database which would contain `projects`, `files`, and `stats` tables with only non-NPM package files (all projects will be kept, but their file counts would reflect only non-NPM files).

## Non-Empty Files

Run `createNonEmptyFiles` from `functions.R`, which creates the `files_ne` table containing id's and filehashes of non-empty files only and adds a `files_ne` column to the projects table. 

A file is considered as empty if it has 0 tokens. 
