#!/usr/bin/env Rscript
#Aim: to match the SNPs of first file with SNPs of the the second file based on
#  CHROM+POS+REF+ALT, to get the SNP indexes (1-based) in the second file.
#Note:
#  the input file should be either a tsv file which has four columns
#    <chrom> <pos> <ref> <alt>, or a vcf file

get_cols <- function(fn) {
  t1 <- read.table(fn, header = F, sep = "\t", comment.char = "#", nrows = 3)
  if (nrow(t1) < 1) { return(NULL) }
  nc <- ncol(t1)
  if (nc < 4) { return(NULL) }
  if (nc == 4) {  # a tsv file
    d1 <- read.table(fn, header = F, sep = "\t", comment.char = "#")
  } else {        # a vcf file
    col_class <- c("character", "integer", "NULL", "character", "character", rep("NULL", nc - 5))
    d1 <- read.table(fn, header = F, sep = "\t", comment.char = "#", colClasses = col_class)
  }
  colnames(d1) <- c("chrom", "pos", "ref", "alt")
  return(d1)
}

# parse command line args.
args <- commandArgs(trailingOnly = TRUE)
if (0 == length(args)) {
  print("use -h or --help for help on argument.")
  quit("no", 1)
}

library(argparse)
parser <- ArgumentParser(
  description = "", 
  formatter_class = "argparse.RawTextHelpFormatter"
)
parser$add_argument("-1", "--file1", type = "character", 
                    help = "The file containing SNPs to be matched.")
parser$add_argument("-2", "--file2", type = "character", 
                    help = "The file containing SNPs that the matching is based on.")
parser$add_argument("-o", "--outfile", type = "character", 
                    help = "Output file that the matching indexes are written to.")
args <- parser$parse_args()

# core part
d1 <- get_cols(args$file1)
d2 <- get_cols(args$file2)
d2$index <- 1:nrow(d2)

# match SNPs in file1 to file2 to get the matching indexes.
dm <- merge(d1, d2, by = c("chrom", "pos", "ref", "alt"), 
            all.x = T, all.y = F, sort = F)  # keep the order of SNP unchanged.

nna <- sum(is.na(dm$index))  # Each SNP in file1 should have a match in file2.
if (nna > 0) {
  write(paste0("Error: vcf1 has ", nna, " records that are not in vcf2!"), file = stderr())
  quit("no", 3)
}

if (nrow(d1) != nrow(dm)) {
  write("Error: file2 has duplicate records matching file1!", file = stderr())
  quit("no", 5)
}

# output matching indexes.
write.table(dm["index"], file = args$outfile, quote = F, row.names = F, col.names = F, append = F)

