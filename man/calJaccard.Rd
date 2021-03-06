% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calJaccard.R
\name{calJaccard}
\alias{calJaccard}
\title{Calcualte Jaccard Index Matrix}
\usage{
calJaccard(object, mat = c("bmat", "pmat", "gmat"), ncell.chunk = 5000,
  max.var = 5000, seed.use = 10, norm.method = c("normOVE", "normOVN"),
  k = 15, row.center = TRUE, row.scale = TRUE, low.threshold = -5,
  high.threshold = 5, keep.jmat = FALSE, do.par = FALSE, num.cores = 1)
}
\arguments{
\item{object}{A Snap object}

\item{max.var}{A numeric variable indicates the how many dimentions for jaccard index to be calcualted [5000]}

\item{seed.use}{A numeric variable indicates the random seed to use [10]}

\item{cell.pcore}{A numeric class that indicates the number of cells to calculate per processing core [1000]}

\item{ncore}{A numeric class that indicates the number of cores to use for calculation [1]}

\item{norm}{A logic variable indicates the whether to normalize the jaccard index matrix [TRUE]}
}
\value{
Returns a Snap object with the jaccard index matrix stored in object@jmat
}
\description{
To conquar the challenge of sparsity, we first converted the sparse binary matrix 
into a jaccard index matrix in which each entry Jij equals the intersection over the 
union between cell i and cell j. The end result is a symmetric matrix with each
element representing the similarity between two cells.
}
\details{
Calculating jaccard index becomes exponentially time-consuming and also memory 
intense with the increase of cell number. To solve this problem, we first divided 
the cells into groups and calculated a sub jaccard index matrix, which are combined
to create the full jaccard index matrix.

For instance, given that there are 50,000 cells in total, we first split the cells into 
10 chunks with each chunk containing 5,000 cells. Then we calculated the pairwise sub 
jaccard index matrix for each chunk. Finally, we created the entire jaccard index matrix 
by combining all sub jaccard matrices.

To further speed up the calculation and avoid of storing a huge unsparse matrix, 
we allow for calculating a partial jaccard matrix.
}
