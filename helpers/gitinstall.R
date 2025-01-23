#!/usr/bin/env Rscript

pkgs = commandArgs(trailingOnly=TRUE)

for (p in pkgs) {

    devtools::install_github(p)

    #if ( ! library(p, character.only=TRUE, logical.return=TRUE) ) {
    #    quit(status=1, save='no')
    #}
}
