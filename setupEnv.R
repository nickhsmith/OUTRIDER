BTYPE <- "both"
NCPUS <- 6
START_TIME <- Sys.time()

print_log <- function(...){
    hash_line <- paste0(rep("#", 10), collapse="")
    message("\n", hash_line, "\n### ", date(), ": ", 
            ..., "\n", hash_line, "\n")
}

installIfReq <- function(p, type=BTYPE, Ncpus=NCPUS, ...){
    p <- p[!p %in% installed.packages()[,"Package"]]
    print_log("Install ", paste(p, collapse=", "))
    INSTALL(p, type=type, Ncpus=Ncpus, ...)
}

# install Bioconductor dependent on the R version
print_log(paste(R.Version()[c("major", "minor")], collapse="."))
print_log("Install BiocManager")
install.packages("BiocManager", Ncpus=NCPUS, repo="http://cran.rstudio.com/")
INSTALL <- BiocManager::install

# because of https://github.com/r-windows/rtools-installer/issues/3
if("windows" == .Platform$OS.type){
    print_log("Install XML on windows ...")
    BTYPE <- "both"
    installIfReq(p=c("XML", "xml2", "RSQLite", "progress", "AnnotationDbi",
            "BiocCheck", "GenomeInfoDbData", "org.Hs.eg.db", 
            "TxDb.Hsapiens.UCSC.hg19.knownGene"))
} else {
    BTYPE <- "source"
}

# install needed packages
# add testthat to pre installation dependencies due to: 
# https://github.com/r-lib/pkgload/issues/89
installIfReq("testthat")
installIfReq(p=c("XML", "xml2", "devtools", "covr", "roxygen2", 
        "BiocCheck", "R.utils", "GenomeInfoDbData", "rtracklayer", "hms"))

# install OUTRIDER with its dependencies with a timeout due to 
# travis (50 min) and appveyor (60 min) set installation warmup to 30 min max
maxTime <- max(30, (60*30 - difftime(Sys.time(), START_TIME, units="sec")))
R.utils::withTimeout(timeout=maxTime, {
    try({
        print_log("Update packages")
        INSTALL(ask=FALSE, type=BTYPE, Ncpus=NCPUS)
    
        print_log("Install OUTRIDER")
        devtools::install(".", dependencies=TRUE, upgrade=TRUE, 
                type=BTYPE, Ncpus=NCPUS)
    })
})
