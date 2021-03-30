#!/usr/bin/env python
#-*-coding:utf-8-*-
#Aim: to extract allele depth of A,C,G,T(,N) from bcftools.vcf.gz to
#     create a SNP x Sample matrix with allele depths being the values
#An example of output:
#  #Allele Depth in the order of A,C,G,T
#  #Chr Pos     Sample0 Sample1 Sample3
#  File:
#	1    1000    10,10,0,0       12,13,0,0       10,12,0,0
#	3    2000    20,0,30,0       15,0,13,0       30,0,25,0

import pysam
import sys
import os
import getopt

def bcf2depth(vcff, out_file, countN):
    """
    @abstract        to extract allele depth of A,C,G,T(,N) from bcftools.vcf.gz to
                     create a SNP x Sample matrix with allele depths being the values
    @param vcff      Path to bcftools.vcf.gz [str]
    @param out_file  Path to output file [str]
    @param countN    If true, base N will be counted [bool]
    @return          0 if success, -1 otherwise [int]
    """
    try:
        vf = pysam.VariantFile(vcff)
    except:
        return -1
    target_alleles = ("A", "C", "G", "T", "N") if countN else ("A", "C", "G", "T") 
    fp = open(out_file, "w")
    for rec in vf.fetch():
        chrom, pos = rec.contig, rec.pos   # pos is 1-based
        items = [chrom, str(pos)]
        # iter each sample
        for smp_i, smp in enumerate(rec.samples.values()):
            smp_ad = smp.get("AD", None)
            assert smp_ad, "Error: %s:%d in Sample %d has no field AD" % (chrom, pos, smp_i + 1)
            assert len(smp_ad) == len(rec.alleles), "Error: %s:%d in Sample %d has invalid field AD" % (chrom, pos, smp_i + 1)
            allele_ad = {k:v for k, v in zip(rec.alleles, smp_ad)}
            items.append(",".join([str(allele_ad.get(a, 0)) for a in target_alleles]))
        fp.write("\t".join(items) + "\n")
    fp.close()
    vf.close()
    return 0

def usage(fp = sys.stderr):
    msg = "\n"
    msg += "This script is aimed to extract allele depth of A,C,G,T(,N) from\n" \
           "bcftools.vcf.gz to create a SNP x Sample matrix with allele\n"     \
           "depths being the values\n"                \
           "\n"
    msg += "Usage: %s [options]\n" % sys.argv[0]
    msg += "\n"                                           \
           "Options:\n"                                   \
           "  --vcf FILE       Path to bcftools.vcf.gz\n"          \
           "  --countN         If use, base N would be counted\n"                       \
           "  --outfile FILE   Path to output file\n"   \
           "  -h, --help       Print this message\n"                  \
           "\n"
    fp.write(msg)

if __name__ == "__main__":    
    if len(sys.argv) < 3:
        usage()
        sys.exit(1)
    try:
        opts, args = getopt.getopt(sys.argv[1:], "h", ["vcf=", "countN", "outfile=", "help"])
    except getopt.GetoptError as e:
        print(str(e))
        usage()
        sys.exit(2)
    vcf = out_file = None
    countN = False
    for opt, value in opts:
        if opt == "--vcf": vcf = value
        elif opt == "--countN": countN = True
        elif opt == "--outfile": out_file = value
        elif opt in ("-h", "--help"): usage(); sys.exit(3)
        else: assert False, "unhandled option"
    ret = bcf2depth(vcf, out_file, countN)
    if ret < 0:
        sys.stderr.write("Error: failed to run bcf2depth.\n")
        sys.exit(1)

