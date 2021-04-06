#!/usr/bin/env Rscript

args <- commandArgs(T)
if (length(args) < 4) {
  write("Usage: plot_accuracy.r <input> <output> <width> <height>", file = stderr())
  quit("no", 1)
}

input <- args[1]
output <- args[2]
width <- as.numeric(args[3])
height <- as.numeric(args[4])
dpi <- 300

library(ggplot2)
library(dplyr)

data <- read.table(input, header = T, sep = "\t", stringsAsFactors = F) %>%
  as_tibble() %>%
  mutate(mtx_type = ifelse(mtx_type == "r", "REF", "ALT"))

breaks <- seq(0.95, 1, 0.005)
labels <- as.character(breaks)
labels[(1:length(labels)) %% 2 == 0] <- ""
labels[labels == "1"] <- "1.00"
p <- data %>%
  ggplot(aes(x = as.character(st_flt), y = row_ratio, group = mtx_type, 
             color = mtx_type)) +
  geom_point() +
  geom_line() +
  scale_color_manual(values = c("red", "blue")) +
  xlab("Correlation Threshold (>)") +
  ylab("Ratio of SNPs above Threshold") +
  labs(title = "Correlation between Cellsnp-lite and VarTrix") +
  labs(color = "Allele Depth") +
  scale_y_continuous(limits = c(0.95, 1), 
                     breaks = breaks,
                     labels = labels)

p <- p +
  theme_bw() +
  theme(
    panel.border = element_rect(color = "black", size = 1),
    panel.background = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks.y = element_line(size = 0.8),
    axis.ticks.x = element_line(size = 0.8),
    
    strip.background = element_rect(
      colour = "white", fill = "white",
      size = 0.2
    ),
    
    legend.text = element_text(size = 10),
    legend.background = element_rect(fill = "transparent"),
    legend.key.size = unit(0.5, "cm"),
    legend.key = element_blank(),
    legend.text.align = 0,
    legend.box.just = "left",
    legend.position = c(0.85, 0.83),
    strip.text.x = element_text(angle = 0, hjust = 0),
    
    text = element_text(
      size = 10, face = "bold"
    ),
 
    plot.title = element_text(size = 10, hjust = 0.5)
  )

if (grepl("tiff?$", output, perl = TRUE, ignore.case = TRUE)) {
  ggsave(output, p, width = width, height = height, dpi = dpi, compress="lzw")
} else {
  ggsave(output, p, width = width, height = height, dpi = dpi)
}

