### =========================================================================
### GRangesList objects
### -------------------------------------------------------------------------
###

setClass("GRangesList",
    contains=c("CompressedList", "GenomicRangesList"),
    representation(
        unlistData="GRanges",
        elementMetadata="DataFrame"
    ),
    prototype(
        elementType="GRanges"
    )
)

setClassUnion("GenomicRangesORGRangesList", c("GenomicRanges", "GRangesList"))


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity.
###

.valid.GRangesList.mcols <- function(x)
{
    msg <- NULL
    x_mcols <- x@elementMetadata
    if (nrow(x_mcols) != length(x))
        msg <- "'mcols(x)' has an incorrect number of rows"
    if (any(c("seqnames", "ranges", "strand", "start", "end", "width",
              "element") %in% colnames(x_mcols)))
        msg <-
          c(msg,
            paste("'mcols(x)' cannot have columns named \"seqnames\", ",
                  "\"ranges\", \"strand\", \"start\", \"end\", \"width\", ",
                  "or \"element\""))
    if (!is.null(rownames(x_mcols)))
        msg <- c(msg, "'mcols(x)' cannot have row names")
    msg
}

.valid.GRangesList <- function(x)
{
    c(.valid.GRangesList.mcols(x))
}

setValidity2("GRangesList", .valid.GRangesList)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructors.
###

GRangesList <- function(...)
{
    listData <- list(...)
    if (length(listData) == 1L && is.list(listData[[1L]]))
        listData <- listData[[1L]]
    if (length(listData) == 0L) {
        unlistData <- GRanges()
    } else {
        if (!all(sapply(listData, is, "GRanges")))
            stop("all elements in '...' must be GRanges objects")
        unlistData <- suppressWarnings(do.call("c", unname(listData)))
    }
    relist(unlistData, PartitioningByEnd(listData))
}

### Typically, the field values will come from a file that needs to be loaded
### into a data.frame first.
makeGRangesListFromFeatureFragments <- function(seqnames=Rle(factor()),
                                                fragmentStarts=list(),
                                                fragmentEnds=list(),
                                                fragmentWidths=list(),
                                                strand=character(0),
                                                sep=",")
{
    fragmentStarts <- normargListOfIntegers(fragmentStarts, sep,
                                            "fragmentStarts")
    nfrag_per_feature <- elementNROWS(fragmentStarts)
    start <- unlist(fragmentStarts, recursive=FALSE, use.names=FALSE)

    fragmentEnds <- normargListOfIntegers(fragmentEnds, sep,
                                          "fragmentEnds")
    nend_per_elt <- elementNROWS(fragmentEnds)
    if (length(nend_per_elt) != 0L) {
        if (length(nfrag_per_feature) == 0L)
            nfrag_per_feature <- nend_per_elt
        else if (!identical(nend_per_elt, nfrag_per_feature))
            stop("'fragmentStarts' and 'fragmentEnds' have ",
                 "incompatible \"shapes\"")
    }
    end <- unlist(fragmentEnds, recursive=FALSE, use.names=FALSE)

    fragmentWidths <- normargListOfIntegers(fragmentWidths, sep,
                                            "fragmentWidths")
    nwidth_per_elt <- elementNROWS(fragmentWidths)
    if (length(nwidth_per_elt) != 0L) {
        if (length(nfrag_per_feature) == 0L)
            nfrag_per_feature <- nwidth_per_elt
        else if (!identical(nwidth_per_elt, nfrag_per_feature))
            stop("\"shape\" of 'fragmentWidths' is incompatible ",
                 "with \"shape\" of 'fragmentStarts' or 'fragmentEnds'")
    }
    width <- unlist(fragmentWidths, recursive=FALSE, use.names=FALSE)

    ranges <- IRanges(start=start, end=end, width=width)
    nfrag <- sum(nfrag_per_feature)
    if (nfrag != length(ranges))
        stop("GenomicRanges internal error in makeGRangesListFromFields(): ",
             "nfrag != length(ranges). This should never happen. ",
             "Please report.")
    if (nfrag == 0L) {
        ## Cannot blindly subset by FALSE because it doesn't work on a
        ## zero-length Rle.
        if (length(seqnames) != 0L)
            seqnames <- seqnames[FALSE]
        if (length(strand) != 0L)
            strand <- strand[FALSE]
    } else {
        if (length(seqnames) != length(nfrag_per_feature) ||
            length(strand) != length(nfrag_per_feature))
            stop("length of 'seqnames' and/or 'strand' is incompatible ",
                 "with fragmentStarts/Ends/Widths")
        seqnames <- rep.int(seqnames, nfrag_per_feature)
        strand <- rep.int(strand, nfrag_per_feature)
    }
    unlistData <- GRanges(seqnames=seqnames, ranges=ranges, strand=strand)
    partitioning <- PartitioningByEnd(cumsum(nfrag_per_feature), names=NULL)
    relist(unlistData, partitioning)
}

setMethod("updateObject", "GRangesList",
    function(object, ..., verbose=FALSE)
    {
        if (verbose)
            message("updateObject(object = 'GRangesList')")
        if (is(try(validObject(object@unlistData, complete=TRUE), silent=TRUE),
               "try-error")) {
            object@unlistData <- updateObject(object@unlistData)
            return(object)
        }
        object
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors.
###

setMethod("seqnames", "GRangesList",
    function(x)
    {
        unlisted_x <- unlist(x, use.names=FALSE)
        relist(seqnames(unlisted_x), x)
    }
)

### NOT exported but used in GenomicAlignments package.
replaceSeqnamesList <- function(x, value)
{
    if (!is(value, "AtomicList") ||
        !identical(elementNROWS(x), elementNROWS(value)))
        stop("replacement 'value' is not an AtomicList with the same ",
             "elementNROWS as 'x'")
    value <- unlist(value, use.names = FALSE)
    if (!is(value, "Rle"))
        value <- Rle(factor(value))
    else if (!is.factor(runValue(value)))
        runValue(value) <- factor(runValue(value))
    seqnames(x@unlistData) <- value
    x
}
setReplaceMethod("seqnames", "GRangesList", replaceSeqnamesList)

setMethod("ranges", "GRangesList",
    function(x, use.mcols=FALSE)
    {
        if (!isTRUEorFALSE(use.mcols))
            stop("'use.mcols' must be TRUE or FALSE")
        unlisted_x <- unlist(x, use.names=FALSE)
        unlisted_ans <- unlisted_x@ranges
        if (use.mcols)
            mcols(unlisted_ans) <- mcols(unlisted_x)
        ans <- relist(unlisted_ans, x)
        if (use.mcols)
            mcols(ans) <- mcols(x)
        ans
    }
)

setReplaceMethod("ranges", "GRangesList",
    function(x, value) 
    {
        if (!is(value, "RangesList") ||
            !identical(elementNROWS(x), elementNROWS(value)))
            stop("replacement 'value' is not a RangesList with the same ",
                 "elementNROWS as 'x'")
        ranges(x@unlistData) <- as(unlist(value, use.names = FALSE), "IRanges")
        x
    }
)

### Same as for CompressedIRangesList.
setMethod("start", "GRangesList",
    function(x, ...)
    {
        unlisted_x <- unlist(x, use.names=FALSE)
        relist(start(unlisted_x), x)
    }
)

setReplaceMethod("start", "GRangesList",
    function(x, ..., value)
    {
        if (!is(value, "IntegerList") ||
            !identical(elementNROWS(x), elementNROWS(value)))
            stop("replacement 'value' is not an IntegerList with the same ",
                 "elementNROWS as 'x'")
        value <- unlist(value, use.names = FALSE)
        start(x@unlistData, ...) <- value
        x
    }
)

### Same as for CompressedIRangesList.
setMethod("end", "GRangesList",
    function(x, ...)
    {
        unlisted_x <- unlist(x, use.names=FALSE)
        relist(end(unlisted_x), x)
    }
)

setReplaceMethod("end", "GRangesList",
    function(x, ..., value)
    {
        if (!is(value, "IntegerList") ||
            !identical(elementNROWS(x), elementNROWS(value)))
            stop("replacement 'value' is not an IntegerList with the same ",
                 "elementNROWS as 'x'")
        value <- unlist(value, use.names = FALSE)
        end(x@unlistData, ...) <- value
        x
    }
)

### Same as for CompressedIRangesList.
setMethod("width", "GRangesList",
    function(x)
    {
        unlisted_x <- unlist(x, use.names=FALSE)
        relist(width(unlisted_x), x)
    }
)

setReplaceMethod("width", "GRangesList",
    function(x, ..., value)
    {
        if (!is(value, "IntegerList") ||
            !identical(elementNROWS(x), elementNROWS(value)))
            stop("replacement 'value' is not an IntegerList with the same ",
                 "elementNROWS as 'x'")
        value <- unlist(value, use.names = FALSE)
        width(x@unlistData, ...) <- value
        x
    }
)

setMethod("strand", "GRangesList",
    function(x)
    {
        unlisted_x <- unlist(x, use.names=FALSE)
        relist(strand(unlisted_x), x)
    }
)

### NOT exported but used in GenomicAlignments package.
replaceStrandList <- function(x, value)
{
    if (!is(value, "AtomicList") ||
        !identical(elementNROWS(x), elementNROWS(value)))
        stop("replacement 'value' is not an AtomicList with the same ",
             "elementNROWS as 'x'")
    value <- unlist(value, use.names = FALSE)
    if (!is(value, "Rle"))
        value <- Rle(strand(value))
    else if (!is.factor(runValue(value)) ||
             !identical(levels(runValue(value)), levels(strand())))
        runValue(value) <- strand(runValue(value))
    strand(x@unlistData) <- value
    x
}
setReplaceMethod("strand", c("GRangesList", "ANY"), replaceStrandList)
setReplaceMethod("strand", c("GRangesList", "character"), 
    function(x, ..., value)
    {
        if (length(value) > 1L)
            stop("length(value) must be 1")
        strand(x@unlistData) <- value
        x
    }
)

### NOT exported but used in GenomicAlignments package.
getElementMetadataList <- 
    function(x, use.names=FALSE, level = c("between", "within"), ...)
{
    if (!isTRUEorFALSE(use.names))
        stop("'use.names' must be TRUE or FALSE")
    level <- match.arg(level)
    if (level == "between") {
        ans <- x@elementMetadata
        if (use.names)
            rownames(ans) <- names(x)
        return(ans)
    }
    unlisted_x <- unlist(x, use.names=FALSE)
    unlisted_ans <- unlisted_x@elementMetadata
    if (use.names)
        rownames(unlisted_ans) <- names(unlisted_x)
    relist(unlisted_ans, x)
}
setMethod("elementMetadata", "GRangesList", getElementMetadataList)

### NOT exported but used in GenomicAlignments package.
replaceElementMetadataList <- 
    function(x, level = c("between", "within"), ..., value)
{
        level <- match.arg(level)
    if (level == "between") {
        if (is.null(value))
            value <- S4Vectors:::make_zero_col_DataFrame(length(x))
        else if (!is(value, "DataFrame"))
            value <- DataFrame(value)
        if (!is.null(rownames(value)))
            rownames(value) <- NULL
        n <- length(x)
        k <- nrow(value)
        if (k != n) {
            if ((k == 0) || (k > n) || (n %% k != 0))
                stop(k, " rows in value to replace ", n, "rows")
            value <- value[rep(seq_len(k), length.out = n), , drop=FALSE]
        }
        x@elementMetadata <- value
    } else {
        if (is.null(value)) {
            value <- S4Vectors:::make_zero_col_DataFrame(length(x@unlistData))
        } else {
            if (!is(value, "SplitDataFrameList") ||
                !identical(elementNROWS(x), elementNROWS(value))) {
                stop("replacement 'value' is not a SplitDataFrameList with ",
                        "the same elementNROWS as 'x'")
            }
            value <- unlist(value, use.names = FALSE)
        }
        elementMetadata(x@unlistData) <- value
    }
    x
}
setReplaceMethod("elementMetadata", "GRangesList", replaceElementMetadataList)

setMethod("seqinfo", "GRangesList", function(x) seqinfo(x@unlistData))

### NOT exported but used in GenomicAlignments package.
replaceSeqinfoList <- function(x, new2old=NULL, force=FALSE, value)
{
    if (!is(value, "Seqinfo"))
        stop("the supplied 'seqinfo' must be a Seqinfo object")
    dangling_seqlevels <- GenomeInfoDb:::getDanglingSeqlevels(x,
                              new2old=new2old, force=force,
                              seqlevels(value))
    if (length(dangling_seqlevels) != 0L) {
        dropme <- which(seqnames(x@unlistData) %in% dangling_seqlevels)
        x <- x[-unique(togroup(PartitioningByWidth(x), j=dropme))]
    }
    seqinfo(x@unlistData, new2old=new2old) <- value
    x
}
setReplaceMethod("seqinfo", "GRangesList", replaceSeqinfoList)

setMethod("score", "GRangesList", function(x) {
  mcols(x)$score
})

setReplaceMethod("score", "GRangesList", function(x, value) {
  mcols(x)$score <- value
  x
})


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion.
###

setAs("GRangesList", "CompressedIRangesList",
    function(from) ranges(from, use.mcols=TRUE)
)
setAs("GRangesList", "IRangesList",
    function(from) ranges(from, use.mcols=TRUE)
)
setAs("GRangesList", "RangesList",
    function(from) ranges(from, use.mcols=TRUE)
)

setAs("GRanges", "GRangesList", function(from) as(from, "List"))

setAs("RangedDataList", "GRangesList",
      function(from) GRangesList(lapply(from, as, "GRanges")))


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Subsetting.
###

.sBracketSubsetGRList <- function(x, i, j, ..., drop)
{
    if (!missing(i)) {
        x <- callNextMethod(x = x, i = i)
    }
    if (!missing(j)) {
        if (!is.character(j))
            stop("'j' must be a character vector")
        withinLevel <- (j %in% colnames(x@unlistData@elementMetadata))
        if (any(withinLevel) && !all(withinLevel))
            stop("'j' cannot mix between and within metadata column names")
        if (any(withinLevel)) {
            mcols(x, level="within") <-
              mcols(x, level="within")[, j, drop=FALSE]
        } else {
            mcols(x) <- mcols(x)[, j, drop=FALSE]
        }
    }
    x
}
setMethod("[", "GRangesList", .sBracketSubsetGRList)

.sBracketReplaceGRList <- function(x, i, j, ..., value)
{
    if (!is(value, class(x)[1]))
        stop(paste0("replacement value must be a ", class(x)[1], " object"))
    if (!missing(i))
        i <- extractROWS(setNames(seq_along(x), names(x)), i)
    if (!missing(j)) {
        if (!is.character(j))
            stop("'j' must be a character vector")
        withinLevel <- (j %in% colnames(x@unlistData@elementMetadata))
        if (any(withinLevel) && !all(withinLevel))
            stop("'j' cannot mix between and within metadata column names")
        if (missing(i)) {
            if (any(withinLevel)) {
                mcols(x, level="within")[, j] <-
                  mcols(x, level="within")
            } else {
                mcols(x)[, j] <- mcols(x)
            }
        } else {
            if (any(withinLevel)) {
                mcols(x, level="within")[i, j] <-
                        mcols(x, level="within")
            } else {
                mcols(x)[i, j] <- mcols(x)
            }
        }
    }
    callNextMethod(x = x, i = i, value = value)
}
setReplaceMethod("[", "GRangesList", .sBracketReplaceGRList)

.dBracketReplaceGRList <- function(x, i, j, ..., value)
{
    nameValue <- if (is.character(i)) i else ""
    i <- S4Vectors:::normargSubset2_iOnly(x, i, j, ...,
             .conditionPrefix=paste0("[[<-,", class(x)[1], "-method: "))
    len <- length(x)
    if (i > len) {
        value <- list(value)
        if (nzchar(nameValue))
            names(value) <- nameValue
        x <- c(x, do.call(getFunction(class(x)), value))
    } else {
        x <- callNextMethod(x, i, ..., value=value)
    }
    validObject(x)
    x
}
setReplaceMethod("[[", "GRangesList", .dBracketReplaceGRList)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Going from GRanges to GRangesList with extractList() and family.
###

setMethod("relistToClass", "GRanges", function(x) "GRangesList")


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### show method.
###

### NOT exported but used in GenomicAlignments package.
showList <- function(object, showFunction, print.classinfo)
{
    k <- length(object)
    cumsumN <- cumsum(elementNROWS(object))
    N <- tail(cumsumN, 1)
    cat(class(object), " object of length ", k, ":\n", sep = "")
    if (k == 0L) {
        cat("<0 elements>\n\n")
    } else if ((k == 1L) || ((k <= 3L) && (N <= 20L))) {
        nms <- names(object)
        defnms <- paste0("[[", seq_len(k), "]]")
        if (is.null(nms)) {
            nms <- defnms
        } else {
            empty <- nchar(nms) == 0L
            nms[empty] <- defnms[empty]
            nms[!empty] <- paste0("$", nms[!empty])
        }
        for (i in seq_len(k)) {
            cat(nms[i], "\n")
            showFunction(object[[i]], margin="  ",
                         print.classinfo=print.classinfo)
            if (print.classinfo)
                print.classinfo <- FALSE
            cat("\n")
        }
    } else {
        sketch <- function(x) c(head(x, 3), "...", tail(x, 3))
        if (k >= 3 && cumsumN[3L] <= 20)
            showK <- 3
        else if (k >= 2 && cumsumN[2L] <= 20)
            showK <- 2
        else
            showK <- 1
        diffK <- k - showK
        nms <- names(object)[seq_len(showK)]
        defnms <- paste0("[[", seq_len(showK), "]]")
        if (is.null(nms)) {
            nms <- defnms
        } else {
            empty <- nchar(nms) == 0L
            nms[empty] <- defnms[empty]
            nms[!empty] <- paste0("$", nms[!empty])
        }
        for (i in seq_len(showK)) {
            cat(nms[i], "\n")
            showFunction(object[[i]], margin="  ",
                         print.classinfo=print.classinfo)
            if (print.classinfo)
                print.classinfo <- FALSE
            cat("\n")
        }
        if (diffK > 0) {
            cat("...\n<", k - showK,
                ifelse(diffK == 1, " more element>\n", " more elements>\n"),
                sep="")
        }
    }
    cat("-------\n")
    cat("seqinfo: ", summary(seqinfo(object)), "\n", sep="")
}

setMethod("show", "GRangesList",
    function(object)
        showList(object, show_GenomicRanges, TRUE)
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Deconstruction/reconstruction of a GRangesList into/from a GRanges
### object.
###
### For internal use only (not exported).
###

### Unlist GRangesList object 'x' into a GRanges object but the differences
### with the "unlist" method for GRangesList objects are:
###   - The sequence names of the returned GRanges object are modified by
###     embedding the "grouping by top-level element" information in them.
###   - The seqinfo is modified accordingly.
deconstructGRLintoGR <- function(x, expand.levels=FALSE)
{
    ans <- x@unlistData
    f1 <- rep.int(seq_len(length(x)), elementNROWS(x))
    f2 <- as.integer(seqnames(ans))
    f12 <- paste(f1, f2, sep="|")

    ## Compute 'ans_seqinfo'.
    if (expand.levels) {
        x_nlev <- length(seqlevels(x))
        i1 <- rep(seq_len(length(x)), each=x_nlev)
        i2 <- rep.int(seq_len(x_nlev), length(x))
    } else {
        oo <- orderIntegerPairs(f1, f2)
        of1 <- f1[oo]
        of2 <- f2[oo]
        ## TODO: Support 'method="presorted"' in duplicatedIntegerPairs() for
        ## when the 2 input vectors are already sorted.
        notdups <- !duplicatedIntegerPairs(of1, of2)
        i1 <- of1[notdups]
        i2 <- of2[notdups]
    }
    x_seqinfo <- seqinfo(x)
    ans_seqlevels <- paste(i1, i2, sep="|")
    ans_seqlengths <- unname(seqlengths(x_seqinfo))[i2]
    ans_isCircular <- unname(isCircular(x_seqinfo))[i2]
    ans_seqinfo <- Seqinfo(ans_seqlevels, ans_seqlengths, ans_isCircular)

    ## The 2 following modifications must be seen as a single atomic
    ## operation since doing the 1st without doing the 2nd would leave 'ans'
    ## in a broken state.
    ans@seqnames <- Rle(factor(f12, ans_seqlevels))
    ans@seqinfo <- ans_seqinfo
    ans
}

### The "inverse" transform of deconstructGRLintoGR().
### More precisely, reconstructGRLfromGR() transforms GRanges object 'gr'
### with sequence names in the "f1|f2" format (as produced by
### deconstructGRLintoGR() above) back into a GRangesList object with the
### same length & names & metadata columns & seqinfo as 'x'.
### The fundamental property of this deconstruction/reconstruction mechanism
### is that, for any GRangesList object 'x':
###
###   reconstructGRLfromGR(deconstructGRLintoGR(x), x) is identical to x
###
reconstructGRLfromGR <- function(gr, x)
{
    snames <- strsplit(as.character(seqnames(gr)), "|", fixed=TRUE)
    m12 <- matrix(as.integer(unlist(snames)), ncol=2, byrow=TRUE)

    ## Restore the real sequence names.
    f2 <- m12[ , 2L]
    x_seqlevels <- seqlevels(x)
    ## The 2 following modifications must be seen as a single atomic
    ## operation since doing the 1st without doing the 2nd would leave 'ans'
    ## in a broken state.
    gr@seqnames <- Rle(factor(x_seqlevels[f2], x_seqlevels))
    gr@seqinfo <- seqinfo(x)

    ## Split.
    f1 <- m12[ , 1L]
    ans <- split(gr, factor(f1, levels=seq_len(length(x))))
    names(ans) <- names(x)
    metadata(ans) <- metadata(x)
    mcols(ans) <- mcols(x)
    ans
}

