#!/usr/bin/env Rscript

# get number of available CPUs
cpuNo = system("grep -c 'processor' /proc/cpuinfo", intern=TRUE)
Sys.setenv(MAKEFLAGS=paste0("-j",cpuNo))

pkgs = commandArgs(trailingOnly=TRUE)

for (p in pkgs) {

    install.packages(p, clean=TRUE, Ncpus=4, dependencies=TRUE, 
                    force=FALSE, repos='https://cran.rstudio.com/');

    if ( ! library(p, character.only=TRUE, logical.return=TRUE) ) {
        quit(status=1, save='no')
    }
}
