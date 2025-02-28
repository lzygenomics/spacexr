% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CSIDE_plots.R
\name{plot_gene_regions}
\alias{plot_gene_regions}
\title{Makes a spatial plot of gene expression for a particular gene
This plot is colored by several discrete regions based on a categorical design matrix.
Bold points represent expressed, whereas unbold points represent pixels not expressing the gene.}
\usage{
plot_gene_regions(
  myRCTD,
  cell_type,
  gene,
  pixel_weight_thresh = 0.8,
  expr_thresh = 0
)
}
\arguments{
\item{myRCTD}{\code{\linkS4class{RCTD}} object containing \code{de_results}, after running CSIDE}

\item{cell_type}{cell_type to be plotted (only single cell type pixels)}

\item{gene}{gene to be plotted}

\item{pixel_weight_thresh}{(default 0.8) minimum cell type weight for pixels that are included}

\item{expr_thresh}{(default 0) the minimum expression threshold to clear to be considered to be expressed}
}
\value{
gene expression plot
}
\description{
Makes a spatial plot of gene expression for a particular gene
This plot is colored by several discrete regions based on a categorical design matrix.
Bold points represent expressed, whereas unbold points represent pixels not expressing the gene.
}
