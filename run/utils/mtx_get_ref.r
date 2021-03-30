#!/usr/bin/env Rscript
#Aim: to output the REF mtx based on AD and DP mtx.

#@abstract  Parse mtx file to get mtx info.
#@param fn  Name of mtx file [STR]
#@return    A list with four elements if success, NULL otherwise [list]
#           The four elements are:
#             $nrow     Number of rows [INT]
#             $ncol     Number of columns [INT]
#             $nval     Number of values [INT]
#             $data     The matrix data without header [tibble]
#@note      The mtx file of general format has 3 columns: <row> <col> <value>.
#           In this case, the 3 columns are: <snp> <cell> <value>
parse_mtx <- function(fn) {
  if (! file.exists(fn)) { return(NULL) }
  df <- read.table(fn, header = F, comment.char = "%")
  if (nrow(df) < 2) { return(NULL) }
  colnames(df)[1:3] <- c("row", "col", "value")
  return(list(
    nrow = df[1, 1],
    ncol = df[1, 2],
    nval = df[1, 3],
    data = df[-1, ] %>% as_tibble()
  ))
}

#@abstract   Write the mtx data to the mtx file.
#@param mtx  The mtx data [list]
#@param fn   Name of mtx file [STR]
#@return     Void.
write_mtx <- function(mtx, fn) {
  write("%%MatrixMarket matrix coordinate integer general", file = fn)
  write("%", file = fn, append = T)
  write(paste(c(mtx$nrow, mtx$ncol, mtx$nval), collapse = "\t"),
        file = fn, append = T)
  write.table(mtx$data, fn, append = T, sep = "\t", row.names = F,
              col.names = F)
}


# parse command line args.
args <- commandArgs(trailingOnly = TRUE)
if (0 == length(args)) {
  print("use -h or --help for help on argument.")
  quit("no", 1)
}

library(argparse)
library(tibble)

parser <- ArgumentParser(
  description = "", 
  formatter_class = "argparse.RawTextHelpFormatter"
)
parser$add_argument("--ad", type = "character", help = "The AD mtx file.")
parser$add_argument("--dp", type = "character", help = "The DP mtx file.")
parser$add_argument("-o", "--outfile", type = "character", help = "The REF mtx file.")
args <- parser$parse_args()

# core part
ad <- parse_mtx(args$ad)
dp <- parse_mtx(args$dp)
if (ad$nrow != dp$nrow || ad$ncol != dp$ncol || ad$nval > dp$nval) {
  write("Error: the headers of AD and DP mtx are not compatible!", file = stderr())
  quit("no", 3)
}

# substract ad from dp to get values of ref.
mdata <- merge(ad$data, dp$data, by = c("row", "col"), all = T, 
               suffixes = c("_ad", "_dp"), sort = T)

nna <- sum(is.na(mdata$value_dp))   # Each records in ad mtx should have a match in dp mtx. 
if (nna > 0) {
  msg <- paste0("Error: AD mtx has ", nna, " records that are not in DP mtx!")
  write(msg, file = stderr())
  quit("no", 5)
}

mdata$value_ad[is.na(mdata$value_ad)] <- 0
mdata$value_ref <- mdata$value_dp - mdata$value_ad
ref_data <- mdata[mdata$value_ref > 0, c("row", "col", "value_ref")]

# output to file.
mtx_ref <- list(
  nrow = ad$nrow,
  ncol = ad$ncol,
  nval = nrow(ref_data),
  data = ref_data
)
write_mtx(mtx_ref, args$outfile)

