# SPM Reliability Toolbox

## SPMRT

The toolbox provides a series of matlab functions for reliability analyses that work with the [SPM software](http://www.fil.ion.ucl.ac.uk/spm/). By reliability, I mean overall consistency of a measure - typically obtained by some sort of test-retest.

The toolbox is intended to work with brain/spine MRI images although many functions can be used completely separatly from that - in particular low level stats functions (only vizualization assumes some specific world structure).

## Single subject reliability

At the indivudual level, 2 measurements are compared using either Pearson correlations or concordance correlations. The Concordance correlation is usually more useful for reliability because it estimates how much variation from the 45 degree line we have (by using the covariance), which means that not only test and retest scale to each other (Pearson), but also the absolute values are the same (see Lin, L.I. 1989. A Corcordance Correlation Coefficient to Evaluate Reproducibility. [Biometrics 45, 255-268](https://www.jstor.org/stable/2532051?seq=1#page_scan_tab_contents)). In some cases like fMRI for which t-values for instance are not necessarily centrered the same between two sessions, Pearson makes more sense.

Reliability is computed for the whole image, and for each tissue type: grey matter, white matter and CSF. Because there is no ideal way to distinguish GM, WM, CSF, those classes are typically defined as probabilities such as for any given voxel, there is some probability to be GM, WM and CSF (and more depending on the how many tissue classes are defined in the model - see e.g. Ashburner & Friston 2005 Unified Segmentation [NeuroImage 26](http://www.fil.ion.ucl.ac.uk/~karl/Unified%20segmentation.pdf)). To account for this dependency on probability to belong to a tissue class, correlation curves are computed from 0 to 1 (with a step of 0.1) for each tissue class.

### Measuring incertainty

Having only two images, incertainty is computed by [bootstrapping](https://en.wikipedia.org/wiki/Bootstrapping_(statistics)) pairs of voxels. It is likely that in any given measurement, some voxels departs from the bulk due to motion (for alive specimen) and scanner issues like field inhomogenity. By resampling the data, such voxels will or not be picked up in the bootstrap sample, giving an overall amount of variability. Practically, pairs of voxels from two images are sampled, and the correlations computed. This is repeated a 1000 times and (adjusted) 95% confidence intervals (CI) are computed. The adjustment for correlation curves corresponds to a Bonferroni adjustement i.e. a 99.5% CI.

## Group level reliability

There are many ways test-retest reliability can be computed: from the raw measurement to the thresholded maps (see e.g. Gorgolewski et al 2013 Single subject fMRI test-retest reliability metrics and confounding factors [NeuroImage, 69](https://www.ncbi.nlm.nih.gov/pubmed/23153967)). The toolbox provides an array of tools to do just that: raw data, t or F value maps, and thresholded maps.

### Reliability of 'raw' data

For raw measurements (e.g. two quantitative MRI images or two realigned time series), the single subject approach is first used (see above) to compute correlations between images. At the group level, the mean and median correlations (within subjects) are compared to the between subjects mean and median correlations for which each other pairs (from one subject image to all other subject images) are computed. This allows testing if the test-retest correlations are meaningful, i.e. bigger than any pairing of images (assuming they are all in the same normalized space). The assumption behind this test is that all images have a minimal correlations because all subjects are from the same population and all brains/spines are roughly similar. A test-retest correlation is therefore meaningful only if its value is bigger than any pairing between two images taken at random.

_Note on time series: while for individual images, correlations are computed among voxels, times series correlations correspond to the median of all correlations of time series computed for each voxels_

### Reliability of statistical images

We use here two different approaches, the mean square difference between images and Intra Class Correlation (ICC); the two methods being related to each other.

_Mean square difference:_ this is equivalent to the between session component of the ICC. For each voxel, take the square diffence, then average over all voxels. The statistic derived from that is the same as for raw data, i.e. compare the within subjects vs between subjects values using a percentile bootsrrap - if data are reliable, within subjects is expected to be significantly better than between subjects.

_ICC_: implement the ICC(3,1) as in [Shrout & Fleiss (1979)](https://www.ncbi.nlm.nih.gov/pubmed/18839484) computed from a repeted measure ANOVA. The ANOVA allows to the get SS subjects and SS of repeating the measurement. Under the assumption that SS total = SS subjects + SS effect + SS between subjects, we can derive the ICC as ((MS between-MS within) ./ (MS between + df * MS within)). Whilst ICC is not typically associated with a test of significance, this can be obtained easily by shuffling subjects. This allows deriving a null distribution since the within and between subjects should be equivalent and from the null threshold the observed ICC values.

### Reliability of thresholded images

[to do]
