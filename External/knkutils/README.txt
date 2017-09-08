This is a collection of MATLAB utilities developed by Kendrick Kay (kendrick@post.harvard.edu, http://kendrickkay.net).  The philosophy of the code is to maximize power (i.e. the ability to perform many different things) and generality (i.e. the ability to re-use code for many different situations).  Let me know if you have comments.

Some of the code uses random-number generation, so it is recommended that you have something like
  rand('state',sum(100*clock));
  randn('state',sum(100*clock));
in your MATLAB startup.m file.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CHANGE HISTORY

Below we document major code changes.  Minor code changes and tweaks that have no significant impact are not mentioned here (e.g. things like cosmetic adjustments, code speed-ups, making functions more general by adding optional input arguments, fixing bugs that would have result in code crashes, etc.).  Major changes include things that make the code backwards-incompatible and things that change actual analysis results.

History of major code changes:
2014/07/31 - in constructpolynomialmatrix.m, we now make the polynomials orthogonal and unit length. this changes previous behavior!
2013/11/18 - use a smoother canonical HRF in getcanonicalhrf.m
2013/09/07 - fix bug in fitnonlinearmodel (if polynomials or extra regressors were used in multiple runs, then they were not getting fit properly).
2013/08/18 - in makedirid.m, occurrences of '-' are now replaced with '_'
2013/08/18 - in projectionmatrix.m, in the cases of empty <X>, we now return 1 instead of [].
2012/06/14 - in constructpolynomialmatrix2d.m and constructpolynomialmatrix3d.m, we now sort the char representation of the basis functions.  the reason is that previously, different machine architectures would give different orders for the basis functions.  this is horrible, as it means that different machines would have different parameter orders.  the fix (which hopefully is robust) is to sort the basis function character-wise, explicitly.  please be aware of this change!
2012/01/23 - in viewimage.m, no longer make a new window and no longer return the figure number
2011/12/10 - in applymultiscalegaussianfilters.m, we now make the default mode to be 0 (center on pixels).  this changes previous behavior.
2011/10/13 - in pton.m, now always generate a CLUT at 8-bit (256 rows)
2011/10/09 - in fitprfstatic.m, <outputfcn> no longer accepts all those special inputs; it is now a usual OutputFcn.
2011/09/22 - add required argument to copyxform_nii
2011/09/16 - the default behavior in dicomloaddir has changed.  we now match all files and perform numerical sorting.
2011/09/13 - make the yellow color in cmapdistinct slightly darker
2011/08/30 - in fitprf.m, we now use stepwise fitting in the nonlinear case (i.e. <mode> is not 0 nor {0}).  this should improve the avoidance of local minima problems, but does change previous behavior!!
2011/07/11 - in dicomloaddir.m, we now have the extra assumption that all files are DICOM files when <filenameformat> is supplied
2011/07/01 - we now use nanmedian and nanmean in calcmdse.m
2011/06/29 - in printnice.m, we now temporarily change PaperPositionMode to auto before printing.  this should make rasterized image output better (in terms of getting the resolution right).
2011/06/27 - in olsmatrix.m, we now explicitly handle the case of all-zero regressors.  previously, NaNs would result.  now, we just ensure that these all-zero regressors get returned a zero weight.
2011/05/26 - in scatterb.m, we weren't drawing the main line.  weird.  we have changed it now to do the right thing.  this modifies old behavior.
2011/04/26 - in constructorientationfilter.m, fixed major bug. orientation was interpreted wrongly and filters were peaked at the wrong orientation.
2011/04/02 - in matchfiles.m, time-sorting behavior did not work (it would always give alphabetical order).  fixed now.
2011/03/09 - in defineellipse3d.m, we now show a maximum of 25 slices.
2011/03/08 - for alignvolumedata.m, make much faster (using ba_interp3), take less memory, remove spline interpolation option, ensure that the alignvolumedata_auto_outputfcn runs at optimization completion.
2011/03/08 - smoothvolumes handles NaNs intelligently now.  this changes old behavior.
2011/03/06 - complete revamp of calcnoiseceiling.m.
2011/02/24 - in matchfiles.m, we now properly match patterns that have spaces in them (since we now escape the spaces using \).  previous behavior was to simply not match those cases.
2011/02/02 - in zerodiv.m, in the case that y is not a scalar and wantcaution is set to 0, we were allowing division by 0 to result in Inf and *notreplaced with val as desired.  big mistake.  we have now fixed this.  utilities that could have used this buggy behavior of zerodiv include calccod, calccorrelation, calcentropy, calcsparseness, calczscore, l1unitlength, unitlength.
2011/01/21 - in matchfiles.m, we explicitly use MATLAB's sort function (for alphabetical ordering) to ensure consistency across platforms.  this might change the alphabetical ordering of matches!
2010/01/17 - completely change cmapdistinct.m; leave JVM on by default in runmatlabinbg.pl
2010/01/05 - in scatterline.m, we now attempt to use nanmean and nanstd to allow more cases in.  see code for details.
2010/12/27 - in divnorm.m, we now explicitly handle cases where the numerator is Inf.  the goal is to try to keep outputs finite when possible.
2010/12/16 - circlewithin.m changed from binary (all within or not) to a graded response
2010/12/06 - in fitprf.m, change initial seeds for certain basis function cases (in particular, we no longer force weights to 1. it seems that nonlinear fitting can operate successfully even if there is a gain ambiguity)
2010/12/03 - in fitprf.m, changed the form of the input <hrfnormfun> (this requires changes to how the function is called); 
2010/12/02 - in fitprf.m and fitprfmulti.m, a number of significant changes: [<ar> input has been deprecated; <arfile> input has been removed; the <meanint>,<driftstd>,<signalrms>,<noiserms> outputs have been removed (I no longer think they are useful); fix bug --- the signal and drift outputs were not getting assigned in the re-do calls of the [A B C] case of <maxiter>]; removed evaluateprfmodel.m
2010/11/24 - remove hrfsample1, remove hrfsample2 [these were obsolete]
2010/11/23 - in calccod.m, change the output range to percentages (R^2).  thus the range is (-Inf,100]. also, we removed the <wantr> input since it was dumb. also, please note that many functions that rely on calccod.m inherit this change to percentages. thus, this was a big global code change.
2010/10/24 - we now impose assumption in rowfun.m that each result has the same size
2010/10/22 - in fitprf.m, fix bug concerning exitflag and maxiters.  if there were multiple resamplings, then we were checking only the last exitflag when deciding to re-do the fitting process.  now, we do the right thing --- we check to see if any of the resamplings stopped because they reached the max number of iterations.
2010/10/22 - in fitprf.m, change initial seed for prfmodel and hrfmodel basis functions to 0!
2010/10/09 - remove showmulticlass.m
2010/10/05 - fixed bugs in sortnumerical.m.  previous calls may have crashed or failed to produce correct answer.
2010/10/02 - fot defineellipse3d.m, change initial visualization state
2010/10/02 - for fitgaussian3d.m, new default initial seed. more liberal tolerance. explicitly guard against nans.
2010/10/02 - in defineellipse3d.m, the fitted Gaussian no longer has a dc fixed to 0 but has an exponent now.
2010/09/27 - zerodiv.m no longer issues warnings when not <wantcaution>
2010/08/25 - explicitly put /home/knk in queuedaemon.  this should be revisited eventually...
2010/08/25 - for outputfcnplot, we revamped this function [hack out ratio check; hack out <restol>; hack out NaN case for <numiters>]
2010/08/11 - queuedaemon, runme have been revamped and are not backwards-compatible.
2010/06/22 - unix_wrapper.m now reports status and result to the command window.
2010/06/15 - start using calccod.m instead of calccorrelation.m where appropriate (see subspaceapprox, fitprf, fitprfmulti, fitgabor2d, fitorientedgaussian2d, fitrbf2d)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SUMMARY OF FUNCTIONS

Here is a short summary of each function so that you can do a simple text search to see if there is a function that already does what you need.

matrix/
  addvectors - add vectors of unequal sizes
  blob - sum over successive groups along a certain dimension of a matrix
  catcell - concatenate elements of a cell matrix
  catmatrix - concatenate matrices (possibly unequal in size)
  cellfunfirst - apply function to first element of a cell matrix (or the matrix itself)
  cropvalidvolume - extract a subvolume of a matrix based on valid values
  equalizematrixdimensions - make two matrices the same dimensions by expanding
  fillout - repeat a matrix to fill a desired size
  filterout - remove elements of a matrix according to a simple boolean operation
  flatten - make into a row vector
  fillmatrix - take a vector and fill a matrix with it
  flipdims - flip some dimensions of a matrix
  insertelt - insert element(s) in a vector
  placematrix - place a 2D matrix inside another 2D matrix at an arbitrary position
  placematrix2 - place a matrix inside another matrix
  placematrixmulti - repeatedly randomly place a 2D matrix inside another 2D matrix
  reshape2D - get into 2D for convenient manipulation
  reshape2D_undo - undo what reshape2D does
  reshapesquare - reshape a vector into a square matrix
  rotatematrix - 2D rotation for an arbitrary matrix
  sizefull - get size of a matrix for a certain number of dimensions
  splitmatrix - take slices of a matrix and put them into a cell vector
  splitruns - find runs of non-NaN numbers in a vector
  squeezedim - remove a specific dimension that has only one element
  squish - squish together the first n dimensions of a matrix
  upsamplematrix - change the dimensionality of a matrix by upsampling
  vflatten - make into a column vector

indexing/
  calcposition - calculate the position of elements relative to a list
  chunking - split a vector into chunks
  firstel - return first element of a matrix
  firstelc - return first element of a cell matrix
  indexall - return an indexing helper for cell vectors
  lastel - return last element of a matrix
  linspacecircular - get equally spaced points in a circular domain
  linspacefixeddiff - get equally spaced points given a fixed difference
  linspacepixels - get equally spaced points that can be treated as centers of pixels
  matrixindex - return different slices through a matrix based on an indexing matrix
  permutedim - shuffle a matrix along a certain dimension or globally
  picksubset - return a random subset of the elements in a matrix
  removerepeats - get rid of runs of consecutive items
  resamplingindices - get indices corresponding to the process of resampling
  slicematrix - return a slice from a matrix
  subscript - get elements using a vector or cell vector of indices
  vectorsplit - split a vector into chunks

programming/
  allocatememory - force allocation of a certain amount of memory (to induce swapping)
  alwaysone - always return 1
  alwayszero - always return 0
  assignseparatevars - split a matrix and assign it to multiple variables
  assigntobaseworkspace - assign all variables to the base workspace
  checkmemoryworkspace - figure how much memory is being used in the caller's workspace
  checkpathconflicts - check for .m file conflicts
  choose - functional form of if-else
  copymatrix - make a copy of a matrix with a subscript assignment on-the-fly
  consolidatemat - consolidate results from multiple .mat files into a single .mat file
  consolidatematdir - consolidate results from .mat files in a directory
  decodenum - undo encodenum.m
  defaultoptimset - return a default optimset options structure
  encapsulate - evaluate a function at multiple values and encapsulate results into a cell vector
  encodenum - encode a number as a string of uppercase letters
  enforcenan - set cases with all 0 to NaN
  evalme - evaluate multi-line input in the MATLAB workspace
  gethostname - get the hostname
  getpid - get the process ID for this instance of MATLAB
  gettimestring - return the current date/time as a simple integer string
  GPUconv - convert to GPU format
  GPUok - return whether we should try to use the GPU
  gunziptemp - gunzip a file on the fly
  identity - return an argument unchanged
  infiniteloop - do nothing forever
  inputmulti - take multi-line string input from stdin
  isfinitenum - evaluate whether each element is finite and numeric
  isint - evaluate whether each element is an integer
  isrowvector - evaluate whether matrix is 1 x n (where n >= 0)
  maketempdir - make a new empty temporary directory and return the path to it.
  mergestructs - merge one struct into another
  mkdirquiet - make a directory, suppressing warnings
  mtimesmulti - multiply arguments together
  passmulti - pass multiple arguments to a function from a cell vector
  pause2 - pause but also return an output
  playalarm - play an alarm to get the user's attention
  plusmulti - add arguments together
  processchunks - perform an operation on successive chunks of a big matrix to save on memory usage
  promptforfile - get a .mat file name from the user
  repeatuntil - call a function until a condition is satisfied
  reportmemoryandtime - use a warning to report the current memory usage and the current time
  rowfun - apply a function to each row of a 2D matrix
  runmatlabinbg.pl - run MATLAB in the background for a single function/script call
  saveemptymat - save an empty .mat file
  setrandstate - induce randomness by (randomly) setting the seed of rand and randn
  sgerun2 - run MATLAB code using the Sun Grid Engine (SGE)
  statusdots - write out dots (.) indicating progress of code execution
  subsetfun - apply a function to successive subsets of a vector
  swap - swap two arguments
  unix_wrapper - a nice wrapper for unix.m

string/
  cell2str - convert 2D cell matrix into string representation
  cell2str2 - convert cell vector of strings into a single string that names each string
  fixstr - fix string for use with MATLAB's figure functions
  makedirid - return a string with elements of a path joined with '_'
  makeletters - generate a cell vector of letter characters
  mat2cellstr - convert a matrix of numbers into a cell matrix of strings
  matchword - return the first word found in a string
  randomword - generate a random word consisting of capital letters
  sortnumerical - sort a cell vector of strings according to trailing integers
  strsplit - split a string based on a pattern

io/
  absolutepath - return the absolute path to a given file
  clearexcept - clear all variables except certain variables
  getextension - get the extension (e.g. '.txt') of a filename
  loadbinary - load numbers from a binary file
  loadexcept - load variables from a .mat file, excluding certain variables
  loadmaybe - load variable from a .mat file, but failing gracefully
  loadmulti - concatenate or merge a single variable from multiple .mat files
  loadmulti2 - load multiple variables from one .mat file
  loadtext - load strings from a text file
  matchfiles - return strings containing paths to matched files and/or directories
  multifile - apply a function to multiple files
  niiload - load specific voxels from NIFTI files containing 4D data
  raw2dload - load specific columns from binary files containing 2D data
  savebinary - save numbers to a binary file
  saveexcept - save all variables to a .mat file, excluding certain variables
  savetext - save strings to a text file
  shuffletext - shuffle lines in a text file
  stripext - remove the extension from a file name
  stripfile - remove the file name from a string

math/
  addnoise - add some noise to a matrix
  allzero - check whether all elements are equal to zero within some tolerance
  ang2complex - convert angles to unit-magnitude complex numbers
  chunkfun - apply a function to successive chunks of a vector
  chunknormalize - subtract mean of successive chunks of a matrix
  calccod - calculate coefficient of determination (R^2)
  calccodcell - calccod for cell vectors of matrices
  calccorrelation - calculate Pearson's correlation coefficient (r)
  calcmdse - calculate the median and the standard error on the median
  calcmdsepct - calculate the median and percentiles on bootstraps of the median
  calcsparseness - calculate sparseness
  calczscore - convert to z-scores
  circularavg - average numbers, respecting circularity
  circulardiff - difference between two values defined in a circular domain
  circularshiftandsum - take a vector, circularly shift it multiple times, and sum
  clipoutliers - clip the outliers of a matrix
  count - sum all elements of a matrix
  countinstances - count how many 1s, 2s, etc. are in a matrix
  discretize - round elements of a matrix to one of two values
  divnorm - apply divisive normalization to a matrix
  matchgain - figure out scalar factor to match one set of data to another
  meanandse - calculate the mean and standard error
  meancell - take the mean for data that are split into cell matrices
  mod2 - like mod.m but return 0 outputs as the modulus itself
  mod4 - like mod.m but restrict outputs to the range [-modulus/2,modulus/2]
  mtimescell - do matrix multiplication but with an argument split into a cell vector
  nanreplace - replace NaNs with a specified value
  nanreplace2 - replace NaNs with a specified value (alternative mode of operation)
  nantoclosest - replace NaNs with the nearest valid values
  negrect - negative-rectify
  negreplace - replace negative values with a specified value
  normalizerange - scale to fit within a specific range
  normalizemax - scale such that max value is 1
  posnegrect - positive- and negative-rectify
  posrect - positive-rectify
  restrictrange - truncate values to fit within a range
  robustrange - calculate a robust range of a set of values
  signedarraypower - take the array power but preserve sign
  signforce - return +1 for positive or zero elements; -1 for negative elements
  stdquartile - return something like std but in the percentile sense
  unitlength - normalize to have unit length (L2-norm is 1)
  unitlengthfast - normalize to have unit length (L2-norm is 1)
  l1unitlength - normalize to have unit length (L1-norm is 1)
  vectorlength - calculate vector length (L2-norm)
  l1vectorlength - calculate vector length (L1-norm)
  zerodiv - divide but with special handling for division by zero
  zeromean - subtract off the mean

stats/
  applyfiltermultidim - apply filters for the case of images with multiple features
  bootstrap - apply a function to bootstrap samples drawn from a vector (useful for computing standard error)
  bootstrapdim - more general version of bootstrap
  calcconfusionmatrix - calculate a confusion matrix (i.e. covariance, cross-product, etc.)
  calcentropy - calculate entropy based on a matrix with counts
  calcggaussianlikelihood - calculate likelihood of a set of points assuming independent generalized Gaussian distributions
  calcintrinsicdim - calculate number of eigenvectors needed to achieve a certain amount of the variance in a matrix
  calcmutualinformation - calculate mutual information between two matrices
  calcmutualinformationcontinuous - calculate mutual information between two matrices in a continuous way
  calcnoiseceiling - calculate how well a set of data can be predicted, taking into account the intrinsic noisiness of the data
  calcoptimalhistbins - calculate the optimum number of bins to use for hist.m
  calcrbflikelihood - calculate likelihood of a set of points given a collection of RBFs
  calcrectlikelihood - calculate likelihood of a set of points given a collection of directions (half-squared responses)
  calcrobustsummary - calculate the median and one-half of the central 68% range
  calcsurfaceareanball - calculate surface area of a unit n-ball
  centerofmass - calculate the center-of-mass of a matrix
  constructdctmatrix - construct a matrix with DCT-II basis functions in the columns
  constructdftmatrix - construct a matrix with DFT basis functions in the columns
  constructfiltersubsample - construct 2D filters according to a subsampling scheme
  constructfiltertiling - construct filters by tiling a single 2D filter
  constructpolynomialmatrix - construct a matrix with polynomials in the columns
  constructpolynomialmatrix2d - evaluate polynomial basis functions defined in 2D at some locations
  constructpolynomialmatrix3d - evaluate polynomial basis functions defined in 3D at some locations
  evaldivnorm - evaluate divisive-normalization function at some values
  evalgaussian1d - evaluate 1D Gaussian function at some coordinates
  evalgaussian2d - evaluate 2D Gaussian function at some coordinates
  evalgaussian3d - evaluate 3D Gaussian function at some coordinates
  evalgeneralizedgaussian - evaluate generalized Gaussian pdf
  filter2subsample - apply filter2 and then subsample the result
  findlocal - find points that are close to a given point
  fit2dpolynomialmodel - use polynomial basis functions to fit a surface defined in 2D, allowing scale factor for different cases
  fit3dpolynomialmodel - use polynomial basis functions to fit a surface defined in 3D, allowing scale factor for different cases
  fit3dpolynomialmodel2 - use polynomial basis functions to fit a surface defined in 3D, allowing DC offset for different cases
  fitdivnorm - fit divisive-normalization function
  fitgaussian1d - fit 1D Gaussian function
  fitgaussian2d - fit 2D Gaussian function
  fitgaussian3d - fit 3D Gaussian function
  fitl1line - perform linear regression but use an L1-error metric 
  fitline2derror - fit a line to a set of 2D points using an error metric that is sensitive to both x and y
  fitnonlinearmodel - a useful wrapper around MATLAB's lsqcurvefit.m function
  fitnonlinearmodel_consolidate - consolidate .mat files written by fitnonlinearmodel
  fitnonlinearmodel_helper - a helper function for fitnonlinearmodel.m
  fitrbfpdf - fit a simplified mixture-of-Gaussians probability density function model using k-means
  fitrectpdf - fit a rectified squared model using k-means and interpret as a PDF
  fitrectdensity - fit a rectified squared model using k-means and interpret more like ANN
  gradientdescent - perform gradient descent or forward stagewise regression
  gradientdescent_wrapper - perform n-fold averaging technique for gradientdescent.m
  localregression - given a degree, kernel, and bandwidth, use local regression to predict values (surface defined on one dimension)
  localregression2d - given a degree, kernel, and bandwidth, use local regression to predict values (surface defined on two dimensions)
  localregression3d - given a degree, kernel, and bandwidth, use local regression to predict values (surface defined on three dimensions)
  localregression4d - given a degree, kernel, and bandwidth, use local regression to predict values (surface defined on four dimensions)
  localregressionbandwidth - cross-validate to determine the optimal bandwidth for local regression
  olscontrol - perform ordinary least-squares regression while controlling for some given regressors
  olsmatrix - perform ordinary least-squares regression
  olsmatrix2 - perform ordinary least-squares regression (fast mode)
  outputfcnplot - plot parameter history during an optimization
  outputfcnsanitycheck - explicit check on the size of the residuals to prevent infinite computation
  performfreqwhitening - flatten the average amplitude spectra of a set of images
  performpcawhitening - whiten a matrix in the PCA sense
  projectionmatrix - project out a linear subspace using ordinary least-squares regression
  randgg - generate random numbers from a generalized Gaussian
  randintrange - randomly choose integers within a given range
  randnmulti - generate random numbers from a multivariate Gaussian
  randomization - calculate p-values using randomization
  randomorthogonalbasis - generate a random set of orthogonal basis functions
  resamplingtransform - a utility function to deal with cross-validation ordering as used in fitnonlinearmodel.m
  roundpvalue - round p-value up to have the form Xe-Y
  runkmeans - run the k-means clustering algorithm
  subspaceapprox - calculate correlation between a subspace and a vector

timeseries/
  calcpeak - calculate the peak of some time-series data (using interpolation)
  constructbutterfilter1D - construct a Fourier-domain Butterworth filter
  conv2run - convolve but keep runs separate
  deconvolvevectors - deconvolve one vector from another vector
  fouriertospace1D - convert magnitude filter in Fourier domain to the space domain
  generatepinknoise1D - generate samples of pink noise
  processmulti1D - apply a function that expects a single vector to multiple vectors
  sincshift - shift time-series data using sinc interpolation and padding
  tseriesinterp - interpolate time-series to achieve a new sampling rate
  tsfilter - filter time-series data with a Fourier-defined magnitude-based filter

imageprocessing/
  applymultiscalegaborfilters - filter images with a set of multi-scale Gabor filters
  applymultiscalegaussianfilters - filter images with a set of multi-scale Gaussian or Difference-of-Gaussians filters
  ba_interp3_wrapper - convenient wrapper for the 3D interpolation toolbox ba_interp3
  calcamplitudespectrum - calculate a smooth function relating spatial frequency to amplitude
  calccpfov - return number of cycles per FOV associated with fft2 after fftshifting
  calccpfov1D - return number of cycles per FOV associated with fft after fftshifting
  calcimagecoordinates - return coordinates of the pixels of an image
  calcpositiondifferentfov - determine the coordinates of a new image with respect to an original image
  calcunitcoordinates - return coordinates of points equally spaced within the square bounded by -.5 and .5
  checkimagesize - inspect pixel dimensions of a batch of image files
  chtoim - reshape image(s) from images x res*res to res x res x images
  concatimages - concatenate multiple images together
  constructbutterfilter - construct a Fourier-domain Butterworth filter
  constructcosinefilter - construct a Fourier-domain cosine-tapered filter
  constructorientationfilter - construct a Fourier-domain orientation filter (von Mises distribution)
  constructsmoothingfilter - construct a space-domain 2D or 3D Gaussian filter
  constructwhiteningfilter - construct a Fourier-domain whitening filter
  detectedges - detect edges in an image using simple scheme
  evaldog2d - evaluate 2D Difference-of-Gaussians function at some coordinates
  evalgabor2d - evaluate 2D Gabor function at some coordinates
  evalgrating2d - evaluate 2D sinusoidal grating function at some coordinates
  evalorientedgaussian2d - evaluate oriented 2D Gaussian at some coordinates
  evalrbf2d - evaluate 2D radial basis function at some coordinates
  extractwindow - easily pull out different chunks of an image
  fitgabor2d - fit 2D Gabor function
  fitorientedgaussian2d - fit oriented 2D Gaussian
  fitrbf2d - fit 2D radial basis function
  fftshift2 - apply fftshift along the first two dimensions
  flattenspectra - apply spatial frequency filtering to flatten the spectra of some images
  fouriertospace - convert magnitude filter in Fourier domain to the space domain
  gabortransform - perform Gabor transformation on one or more images
  generatepinknoise - generate samples of pink noise
  generaterandomphase - generate random phases suitable for multiplication with output of fft2
  generatewinnermap - compress multidimensional data by using hue and brightness to represent the maximum value along a dimension
  getsamplebrain - return a brain volume
  getsampleimage - return a 500x500 grayscale natural image
  ifftshift2 - apply ifftshift along the first two dimensions
  imagefilter - filter images with a Fourier-defined magnitude-based filter
  imagesearch - search through image space to minimize some cost function
  imagesequencetomovie - make a QT movie from images
  imreadmulti - load in multiple images
  imresizedifferentfov - resize an image but use a different field-of-view
  imresizememory - call imresize on a bunch of images, minimizing memory usage
  imwritemulti - write multiple images to multiple files
  imtoch - reshape image(s) from res x res x images to images x res*res
  makecircleimage - draw a circle as an image
  makecolorimagestack - convert a 4D matrix containing multiple color images into a 3D matrix
  makeconcentricgrating2d - make a concentric 2D sinusoidal grating
  makedog2d - make a 2D Difference-of-Gaussians
  makegabor2d - make a 2D Gabor
  makegaussian2d - make a 2D Gaussian
  makegaussian3d - make a 3D Gaussian
  makegrating2d - make a 2D sinusoidal grating
  makegratings2d - make a set of 2D sinusoidal gratings
  makeimagestack - convert a 3D matrix containing multiple images into a 2D matrix
  makeimagestack_wrapper - run makeimagestack for multiple 3D matrices
  makeimagestack3dfiles - like makeimagestack but write out some convenient .png files
  makeorientedgaussian2d - make an oriented 2D Gaussian
  makesquareimage - draw a square as an image
  maskmultiscalegaborfilters - modify results of applymultiscalegaborfilters according to a binary mask
  phasescrambleimage - blend image with random-phase image
  placeimageintosquare - place an image anywhere within another image
  processimages - perform some function on many image files
  processmulti - apply a function that expects a single image to multiple images
  scrambleimage - scramble an image, preserving chunks of a certain size
  smoothvolumes - use a Gaussian filter to smooth one or more 3D volumes
  socmodel - compute the response of the SOC model to some stimuli
  splitimages - split images into chunks
  unitlengthfft2 - unit-length-normalize a Fourier domain filter
  varycontrast - vary the contrast of an image
  viewimage - do some visualizations for a given image
  viewimages - visualize many images at once
  viewmovie - view a series of images as a movie (or write a series of image files)
  visualizemultiscalegaborfilters- visualize points associated with applymultiscalegaborfilters

figure/
  addlogticks - add logarithmic ticks to a figure whose data have already been log-transformed
  axissquarify - make axis equal-aspect, square, and origin-centered and draw unity line
  errorbar2 - draw error bars (as lines)
  errorbar3 - draw error bars (as a polygon)
  figureprep - make an invisible figure window
  figurewrite - write the invisible figure window to an image file
  getcolorchar - take an integer and get a color character
  getfigurepos - return figure position (in normalized units)
  hist1dimage - draw a histogram as a vertical 1D image
  histrobust - run hist but ensuring a robust range
  imageactual - draw an image at its native resolution
  imagescmulti - make separate figure windows for multiple images
  plotorientedbar - plot an oriented bar
  plotrectangle - plot a rectangle
  printnice - print figure window to file
  setaxispos - set axis position (without mangling the Units setting)
  setfigurepos - set figure position (without mangling the Units setting)
  scatterb - do a binned scatterplot
  scatterline - use local linear regression to summarize a scatterplot
  scattersparse - do a scatterplot but limit the number of points
  scatterimagesparse - do a image scatterplot and limit the number of points
  squarify - figure out a roughly evenly balanced number of rows and columns necessary to fit a certain number of elements
  straightline - draw horizontal or vertical lines
  subplotresize - make the subplots of a figure as big as possible

colormap/
  cmapang - hue-based colormap suitable for circular ranges (e.g. angles)
  cmapangLR - like cmapang.m but left-right flipped
  cmapangLVF - like cmapang.m but focused on the left visual field
  cmapangRVF - like cmapang.m but focused on the right visual field
  cmapdistinct - hue-based colormap for cases where you want maximally distinct colors
  cmaplookup - take values and get colors from colormap
  cmaphue - hue-based colormap suitable for circular ranges
  cmapsign - blue-black-red colormap suitable for ranges like [-X X]
  cmapsign2 - blue-white-red colormap suitable for ranges like [-X X]
  cmapsign3 - blue-lightgray-red colormap suitable for ranges like [-X X]
  cmapsign4 - cyan-blue-black-red-yellow colormap suitable for ranges like [-X X]
  colorinterpolate - make a colormap by interpolating between key colors
  drawcolorbar - draw a colorbar on the current figure
  drawcolorbarcircular - draw a circular colorbar on the current figure

graphic/
  calcdistpointline - calculate the distance between one or more points and a line
  circlewithin - determine whether one or more circles are contained within a certain circle
  coordangle - calculate coordinates of an angle
  coordpolygon - calculate coordinates of an equilateral polygon
  createrescalingmatrix - construct a transformation matrix that rescales with respect to (0.5,0.5,0.5)
  defineellipse3d - allow user to define a 3D ellipse on a 3D volume
  drawarrow - draw an arrow (in two dimensions)
  drawbar - draw an oriented bar
  drawbars - draw a set of oriented bars
  drawbartexture - draw a random array of oriented bars
  drawcheckerboard - draw an oriented checkerboard
  drawcheckerboards - draw a set of oriented checkerboards
  drawclosedcontour - draw a generic closed contour shape
  drawclosedcontours - render several closed contours
  drawdartboard - draw a radial checkerboard (dartboard)
  drawellipse - draw a complete or partial ellipse (includes circles and arcs as special cases)
  drawmultiscale - place objects at multiple scales on a pink-noise background
  drawpolargrid - draw a polar grid consisting of rings and spokes
  drawrectangle - draw a rectangle
  drawsector - draw a sector
  drawtext - draw a word
  drawtexts - render several words
  renderfigure - render the current figure into an image (assumed to be square)
  xyzscale - construct a scaling transformation matrix
  xyztranslate - construct a translating transformation matrix

mri/
  calchrfpeak - estimate the peak (positive or negative) value of an HRF
  computetemporalsnr - compute the stability of a series of 3D volumes over time
  constructhrfmodeldct - return a matrix of DCT-II basis functions for modeling HRFs
  constructhrfmodeldelta - return a matrix of delta basis functions for modeling HRFs
  constructhrfmodelspline - return an spline-based HRF model
  constructstimulusmatrices - construct design matrix for a finite impulse response (FIR) model
  copyxform_nii - propagate transformation-related fields from one NII file to others
  coregistervolumes - coregister one volume to another
  createspmmatrix - return the default SPM transformation matrix
  dicomloaddir - load volumes and voxel-size information from a DICOM directory
  evaldoublegamma - evaluate double-gamma function at some x-values
  expdesignefficiency - calculate efficiency of an experimental design
  fmriquality - write figures to inspect the spatial quality of fMRI volumes
  fstoint - go from FreeSurfer space to our internal space
  getcanonicalhrf - return a canonical HRF (based on empirical data) for arbitrary duration and TR
  getsamplehrf - return some sample HRFs estimated from actual fMRI data
  homogenizevolumes - homogenize a set of 3D volumes by dividing by fitted 3D polynomials
  inttofs - go from our internal space to FreeSurfer space
  motioncorrectvolumes - perform motion correction for some volumes
  preconditionvolume - precondition a 3D volume by clipping outliers and removing low-frequency signal variations
  settr_nii - set the TR in the header information of an NII structure
  surfaceslice2 - figure out information relating voxels to vertices
  undistortvolumes - resample volumes in order to correct for motion and distortion
  write3dstack - write out extracted slices in three orientations from a 3D matrix
  writespmfiles - write a series of volumes to individual SPM/ANALYZE files

pt/
  pton - initialize PsychToolbox stuff
  ptoff - uninitialize PsychToolbox stuff
  ptviewimage - show one or more images and allow user to position the images
  ptviewmovie - show a stimulus movie
  ptviewmoviecheck - check the results of ptviewmovie.m
  runretinotopy - script for retinotopy experiment
  showmulticlass - helper function for various experiments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COPYRIGHT

Copyright (c) 2013, Kendrick Kay
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

The name of its contributors may not be used to endorse or promote products 
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
