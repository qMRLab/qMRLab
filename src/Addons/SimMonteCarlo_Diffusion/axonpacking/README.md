
# AxonPacking: Simulator of White Matter Axons Arrangement

author : Tom Mingasson    
contact : mingasson.tom@gmail.com       
institution : University Polytechnique Montreal, NeuroPoly   
date : 2016 

<img src="https://github.com/neuropoly/axonpacking/blob/master/img1.jpeg" width="800px" align="center" />

## Description 

Here is  a new random disks packing algorithm for numerical simulation of the white matter. 

White matter tissue is divided in three compartments:  axons, myelin sheath and extra-axonal space. Axons are assumed to be parallel cylinders, therefore the invariance along the fiber axis makes it possible to consider this problem in 2D. The dense packing of axons is thus equivalent to the generation of random 2-dimensional packing of N perfectly round and non-compressible disks. Axon diameter distributions follow a Gamma distribution (defined by its mean µ and variance σ2). Interestingly the g-ratio is fairly constant across species and white matter regions (31,32) and is dependent mostly on the diameter of the axon according to the relationship presented in (Ikeda M, Oka Y. Brain Behav. 2012):  gratio= 0.220 * log(DIAMETER_unmyelinated) +0.508. 

The different steps to process packing are the following: first, the diameters of the disks are randomly chosen using a gamma or lognormal distribution parameterized with the mean (d_mean), variance (d_var) and number of axons (N).  Then, the positions of disks are initialized on a grid, and they migrate toward the center of the packing area until the maximum disk density is achieved. 


The software packing provides microstructure features (Fiber Volume Fraction FVF, Myelin Volume Fraction MVF, Axon Volume Fraction AVF, fraction restricted FR).

<img src="https://github.com/neuropoly/axonpacking/blob/master/img2.png" width="1000px" align="middle" />

## Scripts

- main.m
- axons_setup.m
- process_packing.m
- compute_gratio.m
- compute_statistics.m
- progressBar.m

## How to use it ?

### INPUTS
In ‘main.m’ change the inputs

- N : the number of disks i.e axons to include in the simulation
- d_mean and d_var : the diameter distribution parameters : mean µ and variance σ² of disk diameters 
- Delta : the fixed gap between the edge of disks Δ 
- iter_max : the number of iterations i.e disk migrations performed by the algorithm before computing the outputs 

#### Help 	
The disk density increases over the migrations and tends toward a limit value. It is necessary to first launch the algorithm with a high number of iterations iter_max. The disk density i.e FVF is calculated every 'iter_fvf' iterations to assess the sufficient number of iterations to reach convergence. 'iter_fvf' is a user defined integer: iter_fvf = iter_max/10 by default. 

When d_mean closed to 3 um, d_var  closed to 1 um : 
 - if N about 1000, iter_max = 30000 is sufficient. 
 - if N about 100, iter_max = 10000 is sufficient. 

#### Example  	
N = 100;            
d_mean = 3;         
d_var  = 1;        
Delta  = 0; 
iter_max = 10000;                            

### OUPUTS
The function ‘computeStatistics.m’ provides MVF, AVF, FVF and FR for each packing image defined by the input combinations. To do that it creates a binary mask.

Outputs are stored in 3 matlab structures. 

- in 'axons.mat' :  the axon features (N, d_mean, d_var, Delta, g_ratio and the drawn diameters d)
- in 'packing.mat' : the packing results (initial positions of disks (initial_positions) and final positions of disks (final_positions))
- in 'stats.mat' : the statistics results with the values for each metric computed in the packing (FVF, FR, MVF, AVF) 

A png image of the final packing with three different labels (intra-axonal, myelin and extra-axonal) is saved by default in the current script folder.
