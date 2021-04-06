#!/usr/bin/env Rscript
#Aim: to visualize the efficiency of tools
#Note: modified from https://github.com/shenwei356/seqkit/blob/master/benchmark/plot.R

# tools
#"#b79d1a", "#ff7600", "#d20015", "#00824c", "#00518b"
#gray yellow, orange red, red, green, blue
all_colors <- c("#00518b", "#ff7600", "#00824c", "#d20015", "#b79d1a")

# default settings
def_width <- 8
def_height <- 6
def_dpi <- 300

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
parser$add_argument("-i", "--infile", type = "character",
                    help = "Efficiency file.")
parser$add_argument("-o", "--outfile", type = "character",
                    default = "", help = "[Optional] Result summary file.")
parser$add_argument("-f", "--outfig", type = "character",
                    default = "", help = "Result figure file.")
parser$add_argument("--time", type = "character",
                    help = "cpu (for cpu_time) or wall (for wall-clock time).")
parser$add_argument("--title", type = "character",
                    help = "Title of output figure.")
parser$add_argument("--width", type = "double",
                    default = def_width, help = paste0("Result file width [", def_width, "]"))
parser$add_argument("--height", type = "double",
                    default = def_height, help = paste0("Result file height [", def_height, "]"))
parser$add_argument("--dpi", type = "integer",
                    default = def_dpi, help = paste0("DPI [", def_dpi, "]"))
parser$add_argument("--xlegend", type = "double",
                    help = "[Optional] A float range between 0 and 1, the x position of legend")
parser$add_argument("--ylegend", type = "double",
                    help = "[Optional] A float range between 0 and 1, the y position of legend")
args <- parser$parse_args()
outfig <- args$outfig
title <- args$title

library(dplyr)
library(ggplot2)
library(ggrepel)

# load data
raw_dat <- read.table(args$infile, header = T, sep = "\t")

dat <- raw_dat %>% 
  as_tibble()
if (args$time == "cpu") {
  dat <- dat %>% 
    select(-wall_time) %>%
    rename(time = cpu_time)
  time_label <- "User CPU Time"
} else {
  dat <- dat %>% 
    select(-cpu_time) %>%
    rename(time = wall_time)
  time_label <- "Wall Clock Time"
}
    
# grouping and calc mean and sd values of each group
dat <- dat %>%
  mutate(ncore_f = factor(ncore, levels = sort(unique(ncore)))) %>%
  group_by(app, ncore_f) %>%
  summarise(time_mean = mean(time), time_sd = sd(time),
            mem_mean = mean(memory), mem_sd = sd(memory)) %>%
  ungroup()

if (length(args$outfile) > 0 && args$outfile != "") {
  dat_out <- dat %>%
    mutate(time_mean = round(time_mean, digits = 0)) %>%
    mutate(time_sd = round(time_sd, digits = 0)) %>%
    mutate(mem_mean = round(mem_mean, digits = 0)) %>%
    mutate(mem_sd = round(mem_sd, digits = 0)) %>%
    arrange(ncore_f, app)
  write.table(dat_out, args$outfile, quote = F, sep = "\t", row.names = F)
  print(paste0("The output summary file is saved as '", args$outfile, "'"))
}

# humanize time unit
max_time <- max(dat$time_mean)
time_unit <- "s"
if (max_time > 3600) {
  dat <- dat %>% mutate(time_mean2 = time_mean / 3600)
  time_unit <- "h"
} else if (max_time > 60) {
  dat <- dat %>% mutate(time_mean2 = time_mean / 60)
  time_unit <- "m"
} else {
  dat <- dat %>% mutate(time_mean2 = time_mean / 1)
  time_unit <- "s"
}

# humanize mem unit
max_mem <- max(dat$mem_mean)
mem_unit <- "KB"
if (max_mem > 1024 * 1024) {
  dat <- dat %>% mutate(mem_mean2 = mem_mean / 1024 / 1024)
  mem_unit <- "GB"
} else if (max_mem > 1024) {
  dat <- dat %>% mutate(mem_mean2 = mem_mean / 1024)
  mem_unit <- "MB"
} else {
  dat <- dat %>% mutate(mem_mean2 = mem_mean / 1)
  mem_unit <- "KB"
}

# visualize the mean values
all_tools <- sort(unique(dat$app))
tool_colors <- all_colors[1:length(all_tools)]
p <- dat %>%
  ggplot(aes(x = mem_mean2, y = time_mean2, color = app, 
             shape = ncore_f, label = app)) +
  geom_point(size = 1.5) +
  geom_hline(aes(yintercept = time_mean2, color = app), size = 0.1, alpha = 0.4) +
  geom_vline(aes(xintercept = mem_mean2, color = app), size = 0.1, alpha = 0.4) +
  geom_text_repel(size = 3, max.iter = 400000) +
  scale_color_manual(values = tool_colors) +
  xlim(0, max(dat$mem_mean2)) +
  ylim(0, max(dat$time_mean2)) +
  xlab(paste0("Peak Memory (", mem_unit, ")")) +
  ylab(paste0(time_label, " (", time_unit, ")")) +
  labs(shape = "Ncores") +
  guides(color = F)

p <- p +
  theme_bw() +
  theme(
    panel.border = element_rect(color = "black", size = 1.2),
    panel.background = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks.y = element_line(size = 0.8),
    axis.ticks.x = element_line(size = 0.8),
    
    strip.background = element_rect(
      colour = "white", fill = "white",
      size = 0.2
    ),
    
    legend.title = element_text(size = 9),
    legend.text = element_text(size = 9),
    legend.background = element_rect(fill = "transparent"),
    legend.key.size = unit(0.5, "cm"),
    legend.key = element_blank(),
    legend.text.align = 0,
    legend.box.just = "left",
    strip.text.x = element_text(angle = 0, hjust = 0),
    
    text = element_text(
      #size = 14, family = "arial", face = "bold"
      size = 9, face = "bold"
    )
  )

if ((! is.null(args$xlegend)) && (! is.null(args$ylegend))) {
  p <- p + theme(legend.position = c(args$xlegend, args$ylegend))
}

if (! is.null(title) && title != "") {
  p <- p + labs(title = title) +
    theme(plot.title = element_text(size = 10, hjust = 0.5))
}

if (grepl("tiff?$", outfig, perl = TRUE, ignore.case = TRUE)) {
  ggsave(outfig, p, width = args$width, height = args$height, dpi = args$dpi, compress="lzw")
} else {
  ggsave(outfig, p, width = args$width, height = args$height, dpi = args$dpi)
}
print(paste0("The output figure file is saved as '", outfig, "'"))

