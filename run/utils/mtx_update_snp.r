#!/usr/bin/env Rscript
#Aim: to update mtx with new SNP indexes.
#Note:
#  1. the input mtx file should have 3 columns:
#       <snp> <cell> <value>, both <snp> and <cell> should be 1-based.
#  2. the input index file should have only one column
#       <index>, which is 1-based.


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
library(dplyr)

parser <- ArgumentParser(
  description = "", 
  formatter_class = "argparse.RawTextHelpFormatter"
)
parser$add_argument("--mtx", type = "character", 
                    help = "The mtx file to be updated.")
parser$add_argument("--index", type = "character", 
                    help = "The new SNP indexes.")
parser$add_argument("-N", "--nsnp", type = "integer",
                    help = "Total number of new SNPs, which would be written to mtx header.")
parser$add_argument("-o", "--outfile", type = "character", 
                    help = "Output updated mtx file.")
args <- parser$parse_args()

# core part
lmtx <- parse_mtx(args$mtx)
dindex <- read.table(args$index, header = F)
colnames(dindex) <- c("new_row")
total_snp <- args$nsnp

if (lmtx$nrow != nrow(dindex)) {
  msg <- "Error: number of SNPs in two files are not the same!"
  msg <- paste0(msg, "\n", paste0("Error: nsnp = ", lmtx$nrow, "; nindex = ", nrow(dindex), ";"))
  write(msg, file = stderr())
  quit("no", 3)
}

dindex$row <- 1:nrow(dindex)
dm <- merge(lmtx$data, dindex, by = c("row"), all.x = T, all.y = F, sort = T)

nna <- sum(is.na(dm$new_row))   # Each snp_idx should be within the matching indexes.
if (nna > 0) {
  msg <- paste0("Error: mtx has ", nna, " records that are not in original vcf!")
  write(msg, file = stderr())
  quit("no", 5)
}

# output the mtx whose snp_idxes have been updated.
dm <- dm[, c("new_row", "col", "value")]
colnames(dm)[1] <- "row"
lmtx$data <- dm %>%
  arrange(row, col)
lmtx$nrow <- total_snp
write_mtx(lmtx, args$outfile)

