# Creating and Importing Project Metadata

For each project, the following metadata are used:

- number of stars
- number of subscribers
- number of forks
- number of open issues
- number of commits

Numer of commits can be taken either from GHTorrent, or from Github. Due to GitHub API and bandwidth limitations, we use the GHTorrent database dump as source for or commits data. Everything else is directly from GitHub. 

## Downloading Project Statistics

After dataset is imported into database, in `functions.R`, execute the `downloadMetadata`:

    downloadMetadata("js", "/datasets/js", github_api_secrets, user, password, host, stride, strides)
    
where:

- `"js"` is database name from which to take the list of projects
- `"/datasets/js"` is local folder where the `projects_metadata.txt` file with the results will be created
- `github_api_secrets` is a character vector containing the github authorization tokens. If more than one token is supplied, the function cycles through them to bypass the 5000 requests per hour limitation
- `user`, `password` and `host` are the database connection arguments
- `stride` is the current stride and `strides` is the max number of strides, which can be used to run multiple instances at the same time (i.e. each `strides` project will be downloaded, starting from `stride`-th)

To import the data, use the `importMetadata` function in `functions.R`:

    importMetadata("js", "/datasets/js", strides, user, password, host)
    
Where `js` is the database name, where `projects` table will be augmented with the metadata, followed by the path to the downloader outputs, number of strides executed and database connection arguments. 

## Getting Commit Numbers

The number of commits is obtained from GHTorrent's tables. Given the downloaded projects and the GHTorrent commits data (`projects_commits.csv`), we can run the `sccpreprocessor` to calculate the number of commits per project:

    java SccPreprocessor commits PATH_TO_DATASET PATH_TO_PROJECTS_COMMITS_GHTORRENT

To import the data, use the `importCommits` function in `functions.R`:

    importCommits("js", "/datasets/js", user, password, host)
    
Where `js` is the database name, where `projects` table will be augmented with the commits information, followed by the path to the downloader outputs and database connection arguments. 
    

