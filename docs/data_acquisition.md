# Data Acquisition

Because of GitHub search API limitations, we use the [GHTorrent](http://ghtorrent.org) as our source. Notably, only the `projects.csv` table, which contains the url's, names, ids and programming language specified for the project. This is enough information for the downloader & tokenizer stages to determine which projects to download. 

> Note that the GHTorrent data are not clean. Notably, several projects are defined twice (i.e. same url, different name/id) and some projects that GHTorrent says should be available, are in fact not. When downloading them, GitHub reports 404, which may mean either that the project has been deleted w/o GHTorrent noticing, or that the project has become private. There is no way we can determine which is the case. 

> Furthermore, the GHTorrent statistics are somewhat incomplete, this can be seen in the time-lapse graphs of projects reported by GHTorrent and by GitHub. GhTorrent has dents while GitHub follows exponential curve. 

## JavaScript

Due to the size of the projects, JavaScript projects are downloaded and tokenized in a single step and the downloaded data is immediately discarded. The tokenizer & downloader can be built using branch `merger` of the [`js-tokenizer`](https://github.com/reactorlabs/js-tokenizer/tree/merger/src) project.

    ./tokenizer MAX STRIDE NAME
    
where `MAX` is total number of strides, `STRIDE` is stride to execute and `NAME` is prefix to be used for the results. 

> This is not too user friendly - the path to outputs and to the input projects file is hardcoded. 

Once the strides are downloaded, they need to be merged. Download the `ght` tool and build its branch [`stridemerger`](), then run it:

    ./ght MIN MAX PATH
    
where `MIN` is the minimum stride number (usually 0), `MAX` is the maximum stride number (say 19) and `PATH` is the path to the tokenizer outputs. 

Because SourcererCC expects the file ids in its input to be ascending, we have created a simple tool that verifies this property. Download the `ght` tool and build its branch [`sccsorter`](https://github.com/reactorlabs/ght-pipeline/tree/sccsorter), then run:

    ./ght PATH
  
where `PATH` is path to file which contains the tokenized files. You should get *PASSED* on the console output.

