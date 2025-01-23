#!/usr/bin/env Rscript

# get number of available CPUs
cpuNo = system("grep -c 'processor' /proc/cpuinfo", intern=TRUE)
Sys.setenv(MAKEFLAGS=paste0("-j",cpuNo))

pkgs = commandArgs(trailingOnly=TRUE)

BiocManager::repositories()

for (p in pkgs) {

    BiocManager::install(p, force=FALSE, clean=TRUE, Ncpus=4)

    if ( ! library(p, character.only=TRUE, logical.return=TRUE) ) {
        quit(status=1, save='no')
    }
}
