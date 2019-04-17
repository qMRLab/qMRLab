charmed: Composite Hindered and Restricted Model for Diffusion
==============================================================

.. image:: https://mybinder.org/badge_logo.svg
 :target: https://mybinder.org/v2/gh/qMRLab/doc_notebooks/master?filepath=charmed_demo.ipynb
.. raw:: html


<style type="text/css">
.content { font-size:1.0em; line-height:140%; padding: 20px; }
.content p { padding:0px; margin:0px 0px 20px; }
.content img { padding:0px; margin:0px 0px 20px; border:none; }
.content p img, pre img, tt img, li img, h1 img, h2 img { margin-bottom:0px; }
.content ul { padding:0px; margin:0px 0px 20px 23px; list-style:square; }
.content ul li { padding:0px; margin:0px 0px 7px 0px; }
.content ul li ul { padding:5px 0px 0px; margin:0px 0px 7px 23px; }
.content ul li ol li { list-style:decimal; }
.content ol { padding:0px; margin:0px 0px 20px 0px; list-style:decimal; }
.content ol li { padding:0px; margin:0px 0px 7px 23px; list-style-type:decimal; }
.content ol li ol { padding:5px 0px 0px; margin:0px 0px 7px 0px; }
.content ol li ol li { list-style-type:lower-alpha; }
.content ol li ul { padding-top:7px; }
.content ol li ul li { list-style:square; }
.content pre, code { font-size:11px; }
.content tt { font-size: 1.0em; }
.content pre { margin:0px 0px 20px; }
.content pre.codeinput { padding:10px; border:1px solid #d3d3d3; background:#f7f7f7; overflow-x:scroll}
.content pre.codeoutput { padding:10px 11px; margin:0px 0px 20px; color:#4c4c4c; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word -wrap: break-word;}
.content pre.error { color:red; }
.content @media print { pre.codeinput, pre.codeoutput { word-wrap:break-word; width:100%; } }
.content span.keyword { color:#0000FF }
.content span.comment { color:#228B22 }
.content span.string { color:#A020F0 }
.content span.untermstring { color:#B20000 }
.content span.syscmd { color:#B28C00 }
.content .footer { width:auto; padding:10px 0px; margin:25px 0px 0px; border-top:1px dotted #878787; font-size:0.8em; line-height:140%; font-style:italic; color:#878787; text-align:left; float:none; }
.content .footer p { margin:0px; }
.content .footer a { color:#878787; }
.content .footer a:hover { color:#878787; text-decoration:underline; }
.content .footer a:visited { color:#878787; }
.content table th { padding:7px 5px; text-align:left; vertical-align:middle; border: 1px solid #d6d4d4; font-weight:bold; }
.content table td { padding:7px 5px; text-align:left; vertical-align:top; border:1px solid #d6d4d4; }
::-webkit-scrollbar {
-webkit-appearance: none;
width: 4px;
height: 5px;
}

::-webkit-scrollbar-thumb {
border-radius: 5px;
background-color: rgba(0,0,0,.5);
-webkit-box-shadow: 0 0 1px rgba(255,255,255,.5);
}
</style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- DESCRIPTION</a></li><li ><a href="#3">II- MODEL PARAMETERS</a></li><li ><a href="#4">a- create object</a></li><li ><a href="#5">b- modify options</a></li><li ><a href="#6">III- FIT EXPERIMENTAL DATASET</a></li><li ><a href="#7">a- load experimental data</a></li><li ><a href="#8">b- fit dataset</a></li><li ><a href="#9">c- show fitting results</a></li><li ><a href="#10">d- Save results</a></li><li ><a href="#11">V- SIMULATIONS</a></li><li ><a href="#12">a- Single Voxel Curve</a></li><li ><a href="#13">b- Sensitivity Analysis</a></li></ul></div><pre class="codeinput"><span class="comment">% This m-file has been automatically generated using qMRgenBatch(charmed)</span>
<span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
<span class="comment">% purposes and Octave.</span>
<span class="comment">%</span>
<span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
<span class="comment">% processing for charmed on CLI.</span>
<span class="comment">%</span>
<span class="comment">% Demo files are downloaded into charmed_data folder.</span>
<span class="comment">%</span>
<span class="comment">% Written by: Agah Karakuzu, 2017</span>
<span class="comment">% =========================================================================</span>
</pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'charmed'</span>); <span class="comment">% Describe the model</span>
</pre><pre class="codeoutput"> charmed: Composite Hindered and Restricted Model for Diffusion
a href="matlab: figure, imshow Diffusion.png ;"Pulse Sequence Diagram/a


Assumptions:
Diffusion gradients are applied perpendicularly to the neuronal fibers.
Neuronal fibers model:
geometry                          cylinders
Orientation dispersion            NO
Permeability                      NO
Diffusion properties:
intra-axonal                      restricted in cylinder with Gaussian
Phase approximation
diffusion coefficient (Dr)       fixed by default. this assumption should have
little impact if the average
propagator is larger than
axonal diameter (sqrt(2*Dr*Delta)8?m).
extra-axonal                      Gaussian
diffusion coefficient (Dh)       Constant by default. Time dependence (lc)
can be added

Inputs:
DiffusionData       4D DWI
(SigmaNoise)        map of the standard deviation of the noise per voxel
(Mask)              Binary mask to accelerate the fitting

Outputs:
fr                  Fraction of water in the restricted compartment.
Dh                  Apparent diffusion coefficient of the hindered compartment.
diameter_mean       Mean axonal diameter weighted by the axonal area -- biased toward the larger axons
fixed to 0 -- stick model (recommended if Gmax  300mT/m).
fcsf                Fraction of water in the CSF compartment. (fixed to 0 by default)
lc                  Length of coherence. If  0, this parameter models the time dependence
of the hindered diffusion coefficient Dh.
Els Fieremans et al. Neuroimage 2016.
Interpretation is not perfectly known.
Use option "Time-Dependent Models" to get different interpretations.
(fh)                Fraction of water in the hindered compartment, calculated as: 1 - fr - fcsf
(residue)           Fitting residuals

Protocol:
Various bvalues
diffusion gradient direction perpendicular to the fibers

DiffusionData       Array [NbVol x 7]
Gx                Diffusion Gradient x
Gy                Diffusion Gradient y
Gz                Diffusion Gradient z
Gnorm (T/m)         Diffusion gradient magnitude
Delta (s)         Diffusion separation
delta (s)         Diffusion duration
TE (s)            Echo time

Options:
Rician noise bias               Used if no SigmaNoise map is provided.
'Compute Sigma per voxel'     Sigma is estimated by computing the STD across repeated scans.
'fix sigma'                   Use scd_noise_std_estimation to measure noise level. Use 'value' to fix Sigma.
Display Type
'q-value'                     abscissa for plots: q = gamma.delta.G (?m-1)
'b-value'                     abscissa for plots: b = (2.pi.q)^2.(Delta-delta/3) (s/mm2)
S0 normalization
'Use b=0'                     Use b=0 images. In case of variable TE, your dataset requires a b=0 for each TE.
'Single T2 compartment'       In case of variable TE acquisition:
fit single T2 using data acquired at b1000s/mm2 (assuming Gaussian diffusion))
Time-dependent models
'Burcaw 2015'                 XXX
'Ning MRM 2016'               XXX

Example of command line usage:
Model = charmed;  % Create class from model
Model.Prot.DiffusionData.Mat = txt2mat('Protocol.txt');  % Load protocol
data = struct;  % Create data structure
data.DiffusionData = load_nii_data('DiffusionData.nii.gz');  % Load data
data.Mask=load_nii_data('Mask.nii.gz');  % Load mask
FitResults = FitData(data,Model,1);  % Fit each voxel within mask
FitResultsSave_nii(FitResults,'DiffusionData.nii.gz');  % Save in local folder: FitResults/

For more examples: a href="matlab: qMRusage(charmed);"qMRusage(charmed)/a

Author: Tanguy Duval, 2016

References:
Please cite the following if you use this module:
Assaf, Y., Basser, P.J., 2005. Composite hindered and restricted model of diffusion (CHARMED) MR imaging of the human brain. Neuroimage 27, 48?58.
In addition to citing the package:
Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

Reference page in Doc Center
doc charmed


</pre><h2 id="3">II- MODEL PARAMETERS</h2><h2 id="4">a- create object</h2><pre class="codeinput">Model = charmed;
</pre><h2 id="5">b- modify options</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
|- Octave is not GUI compatible. Modify Model.options directly.</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
</pre><img src="_static/charmed_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">III- FIT EXPERIMENTAL DATASET</h2><h2 id="7">a- load experimental data</h2><pre >         |- charmed object needs 3 data input(s) to be assigned:
|-   DiffusionData
|-   SigmaNoise
|-   Mask</pre><pre class="codeinput">data = struct();
<span class="comment">% DiffusionData.nii.gz contains [64    64     1  1791] data.</span>
data.DiffusionData=double(load_nii_data(<span class="string">'charmed_data/DiffusionData.nii.gz'</span>));
<span class="comment">% Mask.nii.gz contains [64  64] data.</span>
data.Mask=double(load_nii_data(<span class="string">'charmed_data/Mask.nii.gz'</span>));
</pre><h2 id="8">b- fit dataset</h2><pre >           |- This section will fit data.</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
</pre><pre class="codeoutput">Starting to fit data.
</pre><h2 id="9">c- show fitting results</h2><pre >         |- Output map will be displayed.
|- If available, a graph will be displayed to show fitting in a voxel.
|- To make documentation generation and our CI tests faster for this model,
we used a subportion of the data (40X40X40) in our testing environment.
|- Therefore, this example will use FitResults that comes with OSF data for display purposes.
|- Users will get the whole dataset (384X336X224) and the script that uses it for demo
via qMRgenBatch(qsm_sb) command.</pre><pre class="codeinput">FitResults_old = load(<span class="string">'FitResults/FitResults.mat'</span>);
qMRshowOutput(FitResults_old,data,Model);
</pre><img src="_static/charmed_batch_02.png" vspace="5" hspace="5" alt=""> <img src="_static/charmed_batch_03.png" vspace="5" hspace="5" alt=""> <h2 id="10">d- Save results</h2><pre >         |-  qMR maps are saved in NIFTI and in a structure FitResults.mat
that can be loaded in qMRLab graphical user interface
|-  Model object stores all the options and protocol.
It can be easily shared with collaborators to fit their
own data or can be used for simulation.</pre><pre class="codeinput">FitResultsSave_nii(FitResults, <span class="string">'charmed_data/DiffusionData.nii.gz'</span>);
Model.saveObj(<span class="string">'charmed_Demo.qmrlab.mat'</span>);
</pre><pre class="codeoutput">Warning: Directory already exists. 
</pre><h2 id="11">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for charmed.</pre><h2 id="12">a- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
(1) use equation to generate synthetic MRI data
(2) add rician noise
(3) fit and plot curve</pre><pre class="codeinput">      x = struct;
x.fr = 0.5;
x.Dh = 0.7;
x.diameter_mean = 6;
x.fcsf = 0;
x.lc = 0;
x.Dcsf = 3;
x.Dintra = 1.4;
<span class="comment">% Set simulation options</span>
Opt.SNR = 50;
<span class="comment">% run simulation</span>
figure(<span class="string">'Name'</span>,<span class="string">'Single Voxel Curve Simulation'</span>);
FitResult = Model.Sim_Single_Voxel_Curve(x,Opt);
</pre><img src="_static/charmed_batch_04.png" vspace="5" hspace="5" alt=""> <h2 id="13">b- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
(1) vary fitting parameters from lower (lb) to upper (ub) bound.
(2) run Sim_Single_Voxel_Curve Nofruns times
(3) Compute mean and std across runs</pre><pre class="codeinput">      <span class="comment">%              fr            Dh            diameter_mean fcsf          lc            Dcsf          Dintra</span>
OptTable.st = [0.5           0.7           6             0             0             3             1.4]; <span class="comment">% nominal values</span>
OptTable.fx = [0             1             1             1             1             1             1]; <span class="comment">%vary fr...</span>
OptTable.lb = [0             0.3           3             0             0             1             0.3]; <span class="comment">%...from 0</span>
OptTable.ub = [1             3             10            1             8             4             3]; <span class="comment">%...to 1</span>
<span class="comment">% Set simulation options</span>
Opt.SNR = 50;
Opt.Nofrun = 5;
<span class="comment">% run simulation</span>
SimResults = Model.Sim_Sensitivity_Analysis(OptTable,Opt);
figure(<span class="string">'Name'</span>,<span class="string">'Sensitivity Analysis'</span>);
SimVaryPlot(SimResults, <span class="string">'fr'</span> ,<span class="string">'fr'</span> );
</pre><img src="_static/charmed_batch_05.png" vspace="5" hspace="5" alt=""> <p class="footer"><br ><a href="https://www.mathworks.com/products/matlab/">Published with MATLAB R2018a</a><br ></p></div>
