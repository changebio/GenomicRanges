\name{range-squeezers}

\alias{range-squeezers}

\alias{granges}
\alias{grglist}
\alias{rglist}

\alias{grglist,Pairs-method}
\alias{rglist,Pairs-method}

\title{Squeeze the ranges out of a range-based object}

\description{
  S4 generic functions for squeezing the ranges out of a range-based object.

  \code{granges} returns them as a \link{GRanges} object, \code{grglist}
  as a \link{GRangesList} object, and \code{rglist} as a
  \link[IRanges]{RangesList} object.
}

\usage{
granges(x, use.mcols=FALSE, ...)
grglist(x, use.mcols=FALSE, ...)
rglist(x, use.mcols=FALSE, ...)
}

\arguments{
  \item{x}{
    A range-based object e.g. a
    \link[SummarizedExperiment]{RangedSummarizedExperiment},
    \link[GenomicAlignments]{GAlignments},
    \link[GenomicAlignments]{GAlignmentPairs},
    \link[GenomicAlignments]{GAlignmentsList} or a
    \link[S4Vectors:Pairs-class]{Pairs} object containing ranges.
  }
  \item{use.mcols}{
    \code{TRUE} or \code{FALSE} (the default).
    Whether the metadata columns on \code{x} (accessible with \code{mcols(x)})
    should be propagated to the returned object or not.
  }
  \item{...}{
    Additional arguments, for use in specific methods.
  }
}

\details{
  The \pkg{GenomicRanges}, \pkg{SummarizedExperiment}, and
  \pkg{GenomicAlignments} packages define and document methods
  for various types of range-based objects (e.g. for
  \link[SummarizedExperiment]{RangedSummarizedExperiment},
  \link[GenomicAlignments]{GAlignments},
  \link[GenomicAlignments]{GAlignmentPairs}, and
  \link[GenomicAlignments]{GAlignmentsList} objects).
  Other Bioconductor packages might as well.

  Note that these functions can be seen as a specific kind of \emph{object
  getters} as well as functions performing coercion.
  For some objects (e.g. \link[GenomicAlignments]{GAlignments}),
  \code{as(x, "GRanges")}, \code{as(x, "GRangesList")}, and
  \code{as(x, "RangesList")}, are equivalent to
  \code{granges(x, use.mcols=TRUE)}, \code{grglist(x, use.mcols=TRUE)},
  and \code{rglist(x, use.mcols=TRUE)}, respectively.
}

\value{
  A \link{GRanges} object for \code{granges}.

  A \link{GRangesList} object for \code{grglist}.

  A \link[IRanges]{RangesList} object for \code{rglist}.

  If \code{x} is a vector-like object (e.g.
  \link[GenomicAlignments]{GAlignments}), the returned object is expected
  to be \emph{parallel} to \code{x}, that is, the i-th element in the output
  corresponds to the i-th element in the input. If \code{x} has names on it,
  they're propagated to the returned object. If \code{use.mcols} is TRUE and
  \code{x} has metadata columns on it (accessible with \code{mcols(x)}),
  they're propagated to the returned object.
}

\author{H. Pagès}

\seealso{
  \itemize{
    \item \link{GRanges} and \link{GRangesList} objects.

    \item \link[IRanges]{RangesList} objects in the \pkg{IRanges} package.

    \item \link[SummarizedExperiment]{RangedSummarizedExperiment} objects
          in the \pkg{SummarizedExperiment} packages.

    \item \link[GenomicAlignments]{GAlignments},
          \link[GenomicAlignments]{GAlignmentPairs},
          and \link[GenomicAlignments]{GAlignmentsList} objects in the
          \pkg{GenomicAlignments} package.
  }
}

\examples{
## See ?GAlignments in the GenomicAlignments package for some
## examples.
}

\keyword{methods}
