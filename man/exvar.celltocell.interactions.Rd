% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CSIDE_utils.R
\name{exvar.celltocell.interactions}
\alias{exvar.celltocell.interactions}
\title{Constructs an explanatory variable representing density of a cell type}
\usage{
exvar.celltocell.interactions(myRCTD, barcodes, cell_type, radius = 50)
}
\arguments{
\item{myRCTD}{an \code{\linkS4class{RCTD}} object with annotated cell types e.g. from the \code{\link{run.RCTD}} function.}

\item{barcodes}{the barcodes, or pixel names, of the \code{\linkS4class{SpatialRNA}} object to be used when creating the explanatory variable.}

\item{cell_type}{the cell type (character) for which to compute density.}

\item{radius}{(default 50) the radius of the exponential filter. Approximately, the distance considered to be a
relevant interaction.}
}
\value{
explanatory.variable a named numeric vector representing the explanatory variable used for explaining differential expression in RCTDE. Names of the variable
are the \code{\linkS4class{SpatialRNA}} pixel names, and values  are standardized between 0 and 1. This variable represents density of the selected cell type.
}
\description{
This explanatory variable can be used with RCTDE to detect cell-to-cell interactions. Density
is computing using an exponentially-decaying filter. Currently only works for doublet mode RCTD.
}
