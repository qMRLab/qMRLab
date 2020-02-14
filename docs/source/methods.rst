Methods available
-------------------------------------------------------------------------------

FieldMaps
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* b1_dam map:  Double-Angle Method for B1+ mapping

* b0_dem map :  Dual Echo Method for B0 mapping

T2_relaxometry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.. toctree::
	:maxdepth: 1

	mono_t2_batch

* mwf :  Myelin Water Fraction from Multi-Exponential T2w data

Processing
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* filter_map:   Applies spatial filtering (2D or 3D)

T1_relaxometry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* mp2rage: Compute a T1 map using MP2RAGE

* vfa_t1: Compute a T1 map using Variable Flip Angle

* inversion_recovery: Compute a T1 map using Inversion Recovery data

Magnetization_transfer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* qmt_bssfp : qMT using Balanced Steady State Free Precession acquisition

* qmt_spgr:  quantitative Magnetizatoion Transfer (qMT) using Spoiled Gradient Echo (or FLASH)

* mt_sat :  Correction of Magnetization transfer for RF inhomogeneities and T1

* mt_ratio :  Magnetization transfer ratio (MTR)

* qmt_sirfse:  qMT using Inversion Recovery Fast Spin Echo acquisition

Diffusion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* dti: Compute a tensor from diffusion data

* amico:   Accelerated Microstructure Imaging via Convex Optimization

* noddi:   Neurite Orientation Dispersion and Density Imaging

* charmed: Composite Hindered and Restricted Model for Diffusion

QSM
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* qsm_sb: Compute a T1 map using Variable Flip Angle

UnderDevelopment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Name your Model

* mtv :  Macromolecular Tissue Volume

Noise
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* denoising_mppca :  4d image denoising and noise map estimation by exploiting

* noise_level :  Noise histogram fitting within a noise mask

