vcgPlyRead <-function (file,updateNormals=TRUE,clean=TRUE)
{
  ncfile <- nchar(file)
  ext <- substr(file,ncfile-2,ncfile)
  if (ext != "ply" && ext != "PLY")
    stop("please select PLY file")
### get infos from file header
  x <- file
  A <- readLines(x, n = 100, warn=FALSE)
  end <- which(A == "end_header")
  infos <- A[1:end]
  vertinfo <- strsplit(A[grep("element vertex", infos)], " ")
  faceinfo <- strsplit(A[grep("element face", infos)], " ")
  vertbegin <- grep("element vertex",infos)
  facebegin <- grep("element face",infos)
  allvertinfo <- infos[vertbegin:(facebegin-1)]
  allfaceinfo <- infos[facebegin:(end-1)]

### set flags
  upNorm <- FALSE
  hasQuality <- FALSE
  hasNormals <- FALSE
  hasFaces <- FALSE
  hasVertices <- FALSE
  hasColor <- FALSE
  if (length(grep("property float nx",allvertinfo)) > 0)
    hasNormals <- TRUE
  fn <- as.numeric(faceinfo[[1]][3])
  if (fn > 0)
    {
      hasFaces <- TRUE
      if (updateNormals)
        {
          hasNormals <- TRUE
          upNorm <- TRUE
        }
    }
  vn <- as.numeric(vertinfo[[1]][3])
  if (vn > 0)
    hasVertices <- TRUE
  color <- grep("property uchar red", infos)
  colvec <- 0
  if (length(color) > 0)
    {
      hasColor <- TRUE
      colvec <- matrix(0,3,vn)
      storage.mode(colvec) <- "integer"
      
    }
 ### initialize mesh elements in R
  texinfo<-NULL
  colmat <- NULL
  material <- NULL

  mesh <- list()
  class(mesh) <- "mesh3d"
  vb <- matrix(0,3,vn)
  it <- 0
  quality <- 0
  if (hasFaces)
    it <- matrix(0,3,fn)
  storage.mode(it) <- "integer"
  storage.mode(vn) <- "integer"
  storage.mode(fn) <- "integer"
  normals <- 0
  if (hasNormals)
    normals <- vb

### import file ###
  out <- .C("RPlyRead",file,vb,vn,it,fn,normals,as.integer(hasNormals),as.integer(upNorm),quality,as.integer(hasColor),colvec,as.integer(clean))

### fill mesh with imported data
  mesh$vb <- rbind(out[[2]][,1:out[[3]]],1)
  if (hasFaces)
    mesh$it <- out[[4]][,1:out[[5]]]+1
  if (hasNormals)
    mesh$normals <- rbind(out[[6]][,1:out[[3]]],1)
  if (hasColor)
    {
      colvec <- out[[11]][,1:out[[3]]]
      mesh$material <- list()
      colvec <- rgb(colvec[1,],colvec[2,],colvec[3,],maxColorValue=255)
      colfun <- function(x)
        {
          x <- colvec[x]
          return(x)
        }
      mesh$material$color <- matrix(colfun(mesh$it),dim(mesh$it))
    }
  return(mesh)
}

