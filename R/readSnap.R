#' Create a Snap object from a snap file
#'
#' Import a snap file as a snap object.
#'
#' @param file A character object for the snap-format file name which the data are to be read from.
#' @param metaData a logical value indicates weather to read the meta data [TRUE].
#' @return A snap object
#' @examples
#' snap_file <- system.file("extdata", "Fang.3C1.snap", package = "SNAPATAC");
#' showBinSizes(snap_file);
#' x.sp <- createSnap(snap_file, metaData=TRUE);
#' @export

createSnap <- function(file, ...) {
  UseMethod("createSnap", file);
}

#' @describeIn createSnap Default Interface
#' @export
createSnap.default <- function(file, metaData=TRUE){	
	# close the previously opened H5 file
	H5close();
	# check the input
	if(!file.exists(file)){stop(paste("Error @readSnap: ", file, " does not exist!", sep=""))};
	if(!isSnapFile(file)){stop(paste("Error @readSnap: ", file, " is not a snap-format file!", sep=""))};
	if(!(is.logical(metaData))){stop(paste("Error @readSnap: metaData is not a logical variable!", sep=""))};
	# create an empty snap object
	res = newSnap();
	############################################################################
	message("Epoch: reading the barcode session ...");
	barcode = as.character(tryCatch(barcode <- h5read(file, '/BD/name'), error = function(e) {print(paste("Warning @readSnap: 'BD/name' not found in ",file)); return(vector(mode="character", length=0))}));	
	if(metaData){
		metaData = readMetaData(file);
		if(any((metaData$barcode == barcode) == FALSE)){stop(paste("Error @readSnap: meta data does not match with barcode name!", sep=""))};
		res@metaData = metaData;
	}else{
		metaData = data.frame(barcode=barcode, TN=0, UM=0, PP=0, UQ=0, CM=0);
		res@metaData = metaData;
	}
	nBarcode = length(barcode);
	if(nBarcode == 0){stop("Error @readSnap: barcode is empty! Does not support reading an empty snap file")}
	res@barcode = barcode;
	H5close();
	return(res);	
}


#' Add cell-by-bin matrix
#' @export
addBmat <- function(obj,...) {
  UseMethod("addBmat", obj);
}

#' @describeIn addBmat Default Interface
#' @export
addBmat.default <- function(obj, file, binSize=5000){	
	# close the previously opened H5 file
	H5close();
	# check the input
	if(class(obj) != "snap"){stop(paste("Error @addBmat: ", file, " does not exist!", sep=""))}
	if(!file.exists(file)){stop(paste("Error @addBmat: ", file, " does not exist!", sep=""))};
	if(!isSnapFile(file)){stop(paste("Error @addBmat: ", file, " is not a snap-format file!", sep=""))};
	if(!(binSize %in% showBinSizes(file))){stop(paste("Error @addBmat: binSize ", binSize, " does not exist in ", file, "\n", sep=""))};
	obj@bmat = Matrix(0,0,0);
	message("Epoch: reading cell-bin count matrix session ...");
	############################################################################
	barcode = as.character(tryCatch(barcode <- h5read(file, '/BD/name'), error = function(e) {print(paste("Warning @addBmat: 'BD/name' not found in ",file)); return(vector(mode="character", length=0))}));	

	binSizeList = showBinSizes(file);
	if(length(binSizeList) == 0){stop("Error @addBmat: binSizeList is empty! Does not support reading empty snap file")}
	if(!(binSize %in% binSizeList)){stop(paste("Error @addBmat: ", binSize, " does not exist in binSizeList, valid binSize includes ", toString(binSizeList), "\n", sep=""))}
	
	options(scipen=999);
	binChrom = tryCatch(binChrom <- h5read(file, paste("AM", binSize, "binChrom", sep="/")), error = function(e) {stop(paste("Warning @readaddBmatSnap: 'AM/binSize/binChrom' not found in ",file))})
	binStart = tryCatch(binStart <- h5read(file, paste("AM", binSize, "binStart", sep="/")), error = function(e) {stop(paste("Warning @addBmat: 'AM/binSize/binStart' not found in ",file))})
	if(binSize == 0){
		binEnd = tryCatch(binEnd <- h5read(file, paste("AM", binSize, "binEnd", sep="/")), error = function(e) {stop(paste("Warning @addBmat: 'AM/binSize/binStart' not found in ",file))})		
	}else{
		binEnd = binStart + as.numeric(binSize) -1
	}
	if((length(binChrom) == 0) || (length(binStart) == 0)){stop("Error @addBmat: bin is empty! Does not support empty snap file")}
	if(length(binChrom) != length(binStart)){
		stop(paste("Error @addBmat: ", "binChrom and binStart has different length!", sep=""))
	}else{
		nBin = length(binChrom);
	}
	bins = GRanges(binChrom, IRanges(as.numeric(binStart),binEnd), name=paste(paste(binChrom, binStart, sep=":"), binEnd, sep="-"));				
	rm(binChrom, binStart);
	obj@feature = bins;
	idx = as.numeric(tryCatch(idx <- h5read(file, paste("AM", binSize, "idx", sep="/")), error = function(e) {stop(paste("Warning @addBmat: 'AM/binSize/idx' not found in ",file))}));
	idy = as.numeric(tryCatch(idy <- h5read(file, paste("AM", binSize, "idy", sep="/")), error = function(e) {stop(paste("Warning @addBmat: 'AM/binSize/idy' not found in ",file))}));
	count = as.numeric(tryCatch(count <- h5read(file, paste("AM", binSize, "count", sep="/")), error = function(e) {stop(paste("Warning @addBmat: 'AM/binSize/count' not found in ",file))}));	

	if(!all(sapply(list(length(idx),length(idy),length(count)), function(x) x == length(count)))){stop("Error: idx, idy and count has different length in the snap file")}	
	ind.sel = which(idx %in% which(barcode %in% obj@barcode));		
	idx = match(idx[ind.sel], sort(unique(idx[ind.sel])));	
	idy = idy[ind.sel];
	count = count[ind.sel];

	M = Matrix(0, nrow=length(obj@barcode), ncol=nBin, sparse=TRUE);
	M[cbind(idx,idy)] = count;	
	obj@bmat = M;
	rm(M, idx, idy, count);
	H5close();
	return(obj);
}

#' Add cell-by-peak matrix
#' @export
addPmat <- function(obj,file, ...) {
  UseMethod("addPmat");
}

#' @export
addPmat.default <- function(obj, file){
        # close the previously opened H5 file
        H5close();
        # check the input
        if(class(obj) != "snap"){stop(paste("Error @addPmat: ", file, " does not exist!", sep=""))}
        if(!file.exists(file)){stop(paste("Error @addPmat: ", file, " does not exist!", sep=""))};
        if(!isSnapFile(file)){stop(paste("Error @addPmat: ", file, " is not a snap-format file!", sep=""))};

        message("Epoch: reading cell-peak count matrix session ...");
        ############################################################################
		barcode = as.character(tryCatch(barcode <- h5read(file, '/BD/name'), error = function(e) {print(paste("Warning @addBmat: 'BD/name' not found in ",file)); return(vector(mode="character", length=0))}));
        options(scipen=999);
        binChrom = tryCatch(binChrom <- h5read(file, "PM/peakChrom"), error = function(e) {stop(paste("Warning @addPmat: 'PM/peakChrom' not found in ",file))})
        binStart = tryCatch(binStart <- h5read(file, "PM/peakStart"), error = function(e) {stop(paste("Warning @addPmat: 'PM/peakStart' not found in ",file))})
        binEnd = tryCatch(binEnd <- h5read(file, "PM/peakEnd"), error = function(e) {stop(paste("Warning @addPmat: 'PM/peakEnd' not found in ",file))})

        if((length(binChrom) == 0) || (length(binStart) == 0)){stop("Error @readSnap: bin is empty! Does not support empty snap file")}
        if(length(binChrom) != length(binStart)){
                stop(paste("Error @addPmat: ", "binChrom and binStart has different length!", sep=""))
        }else{
                nBin = length(binChrom);
        }

        bins = GRanges(binChrom, IRanges(as.numeric(binStart),binEnd), name=paste(paste(binChrom, binStart, sep=":"), binEnd, sep="-"));
        rm(binChrom, binStart);
        obj@peak = bins;

        idx = as.numeric(tryCatch(idx <- h5read(file, "PM/idx"), error = function(e) {stop(paste("Warning @readSnap: 'PM/idx' not found in ",file))}))
        idy = as.numeric(tryCatch(idy <- h5read(file, "PM/idy"), error = function(e) {stop(paste("Warning @readSnap: 'PM/idy' not found in ",file))}))
        count = as.numeric(tryCatch(count <- h5read(file, "PM/count"), error = function(e) {stop(paste("Warning @readSnap: 'PM/count' not found in ",file))}))

        if(!all(sapply(list(length(idx),length(idy),length(count)), function(x) x == length(count)))){stop("Error: idx, idy and count has different length in the snap file")}
        ind.sel = which(idx %in% which(barcode %in% obj@barcode));
        idx = match(idx[ind.sel], sort(unique(idx[ind.sel])));
        idy = idy[ind.sel];
        count = count[ind.sel];

        M = Matrix(0, nrow=length(obj@barcode), ncol=nBin, sparse=TRUE);
        M[cbind(idx,idy)] = count;
        obj@pmat = M;
        rm(M, idx, idy, count);
        H5close();
        return(obj);

}

#' Add cell-by-gene matrix
#' @export

addGmat <- function(obj,file, ...) {
  UseMethod("addGmat");
}

#' @export
addGmat.default <- function(obj, file){
        # close the previously opened H5 file
        H5close();
        # check the input
        if(class(obj) != "snap"){stop(paste("Error @addGmat: ", file, " does not exist!", sep=""))}
        if(!file.exists(file)){stop(paste("Error @addGmat: ", file, " does not exist!", sep=""))};
        if(!isSnapFile(file)){stop(paste("Error @addGmat: ", file, " is not a snap-format file!", sep=""))};

        message("Epoch: reading cell-gene count matrix session ...");
        ############################################################################
		barcode = as.character(tryCatch(barcode <- h5read(file, '/BD/name'), error = function(e) {print(paste("Warning @addBmat: 'BD/name' not found in ",file)); return(vector(mode="character", length=0))}));
        geneName = tryCatch(geneName <- h5read(file, "GM/name"), error = function(e) {stop(paste("Warning @addGmat: 'GM/name' not found in ",file))})

        if(length(geneName) == 0){
			stop("Error @addGmat: GM is empty")
		}

        idx = as.numeric(tryCatch(idx <- h5read(file, "GM/idx"), error = function(e) {stop(paste("Warning @addGmat: 'GM/idx' not found in ",file))}))
        idy = as.numeric(tryCatch(idy <- h5read(file, "GM/idy"), error = function(e) {stop(paste("Warning @addGmat: 'GM/idy' not found in ",file))}))
        count = as.numeric(tryCatch(count <- h5read(file, "GM/count"), error = function(e) {stop(paste("Warning @addGmat: 'GM/count' not found in ",file))}))

        if(!all(sapply(list(length(idx),length(idy),length(count)), function(x) x == length(count)))){stop("Error: idx, idy and count has different length in the snap GM session")}
        ind.sel = which(idx %in% which(barcode %in% obj@barcode));
        idx = match(idx[ind.sel], sort(unique(idx[ind.sel])));
        idy = idy[ind.sel];
        count = count[ind.sel];
		
        M = Matrix(0, nrow=length(obj@barcode), ncol=length(geneName), sparse=TRUE);
        M[cbind(idx,idy)] = count;
		colnames(M) = geneName;
        obj@gmat = M;
        rm(M, idx, idy, count);
        H5close();
        return(obj);
}

#' Create a snap object from cell-by-bin matrix
#' @export
createSnapFromBmat <- function(mat, barcodes, bins) {
  UseMethod("createSnapFromBmat");
}

#' @export
createSnapFromBmat.default <- function(mat, barcodes, bins){
	if(missing(mat) || missing(barcodes) || missing(bins)){
		stop("mat or barcodes or bins is missing");
	}

	if(!(class(mat) == "dsCMatrix" || class(mat) == "dgCMatrix")){
		stop("'mat' is not a sparse matrix");
	}

	if(length(barcodes) != nrow(mat)){
		stop("'mat' has different number of rows with number of barcodes");
	}
	
	if(class(bins) != "GRanges"){
		stop("'bins' is not a GRanges object")
	}
	if(length(bins) != ncol(mat)){
		stop("'mat' has different number of columns with number of bins");
	}
	
	obj = newSnap();
	obj@bmat = mat;
	obj@barcode = barcodes;
	obj@feature = bins;
	return(obj);
}

#' Create a snap object from cell-by-peak matrix
#' @export
createSnapFromPmat <- function(mat, barcodes, peaks) {
  UseMethod("createSnapFromPmat");
}

#' @export
createSnapFromPmat.default <- function(mat, barcodes, peaks){
	if(missing(mat) || missing(barcodes) || missing(peaks)){
		stop("mat or barcodes or peaks is missing");
	}

	if(!(class(mat) == "dsCMatrix" || class(mat) == "dgCMatrix")){
		stop("'mat' is not a sparse matrix");
	}

	if(length(barcodes) != nrow(mat)){
		stop("'mat' has different number of rows with number of barcodes");
	}
	
	if(class(peaks) != "GRanges"){
		stop("'peaks' is not a GRanges object")
	}
	if(length(peaks) != ncol(mat)){
		stop("'mat' has different number of columns with number of peaks");
	}
	
	obj = newSnap();
	obj@pmat = mat;
	obj@barcode = barcodes;
	obj@peak = peaks;
	return(obj);
}

#' Create a snap object from cell-by-gene matrix
#' @export
createSnapFromGmat <- function(mat, barcodes, geneNames) {
  UseMethod("createSnapFromGmat");
}

#' @export
createSnapFromGmat.default <- function(mat, barcodes, geneNames){
	if(missing(mat) || missing(barcodes) || missing(geneNames)){
		stop("mat or barcodes or geneNames is missing");
	}

	if(!(class(mat) == "dsCMatrix" || class(mat) == "dgCMatrix")){
		stop("'mat' is not a sparse matrix");
	}

	if(length(barcodes) != nrow(mat)){
		stop("'mat' has different number of rows with number of barcodes");
	}
	
	if(class(geneNames) != "character"){
		stop("'geneNames' is not a character object")
	}
	if(length(geneNames) != ncol(mat)){
		stop("'mat' has different number of columns with number of geneNames");
	}
	
	obj = newSnap();
	obj@gmat = mat;
	obj@barcode = barcodes;
	colnames(obj@gmat) = geneNames;
	return(obj);
}


#' Combine snap objects
#'
#' Takes two snap objects and combines them.
#'
#' @param obj1 a snap object
#' @param obj2 a snap object
#' @return a combined snap object
#' @export
rBind <- function(obj1, obj2){
  UseMethod("rBind", obj1);
}

rBind.default <- function(obj1, obj2){
	# only the following slots can be combined
	# barcode, feature, metaData, cmat, bmat
	# among these slots, barcode, feature, cmat are enforced, the others are optional
	# the rest slots must be set to be empty
	
	if(!is.snap(obj1)){stop(paste("Error @rBind: obj1 is not a snap object!", sep=""))};
	if(!is.snap(obj2)){stop(paste("Error @rBind: obj2 is not a snap object!", sep=""))};

	# barcode from obj1 and obj2
	barcode1 = obj1@barcode;
	barcode2 = obj2@barcode;	
	
	# check barcode name, if there exists duplicate barcode raise error and exist
	if(length(unique(c(barcode1, barcode2))) < length(barcode1) + length(barcode2)){
		stop("Error: @rBind: identifcal barcodes found in obj1 and obj2!")
	}
	barcode = c(barcode1, barcode2);
	
	# check meta data
	if(nrow(obj1@metaData) > 0 && nrow(obj2@metaData) > 0){
		metaData = rbind(obj1@metaData, obj2@metaData);		
	}else{
		metaData = data.frame();
	}
	
	# check feature
	feature1 = obj1@feature;
	feature2 = obj2@feature;
	if((length(feature1) == 0) != (length(feature2) == 0)){
		stop("different feature found in obj1 and obj2!")
	}else{
		if(length(feature1) > 0){
			if(FALSE %in% (feature1$name == feature2$name)){
				stop("Error: @rBind: different feature found in obj1 and obj2!")
			}
			feature = feature1;					
		}else{
			feature = feature1;								
		}
	}
	
	# check peak
	peak1 = obj1@peak;
	peak2 = obj2@peak;
	if((length(peak1) == 0) != (length(peak2) == 0)){
		stop("different peak found in obj1 and obj2!")
	}else{
		if(length(peak1) > 0){
			if(FALSE %in% (peak1$name == peak2$name)){
				stop("Error: @rBind: different feature found in obj1 and obj2!")
			}
			peak = peak1;					
		}else{
			peak = peak1;								
		}
	}
	
	# check bmat	
	bmat1 = obj1@bmat;
	bmat2 = obj2@bmat;
	if((length(bmat1) == 0) != (length(bmat2) == 0)){
		stop("bmat has different dimentions in obj1 and obj2!")
	}else{
		bmat = Matrix::rBind(bmat1, bmat2);
	}

	# check gmat	
	gmat1 = obj1@gmat;
	gmat2 = obj2@gmat;
	if((length(gmat1) == 0) != (length(gmat2) == 0)){
		stop("gmat has different dimentions in obj1 and obj2!")
	}else{
		gmat = Matrix::rBind(gmat1, gmat2);
	}

	# check pmat	
	pmat1 = obj1@pmat;
	pmat2 = obj2@pmat;
	if((length(pmat1) == 0) != (length(pmat2) == 0)){
		stop("pmat has different dimentions in obj1 and obj2!")
	}else{
		pmat = Matrix::rBind(pmat1, pmat2);
	}

	res = newSnap();
	res@barcode = barcode;
	res@metaData = metaData;
	res@bmat = bmat;
	res@pmat = pmat;
	res@feature = feature;
	res@peak = peak;
	res@gmat = gmat;
	return(res)
}

