charmed: Composite Hindered and Restricted Model for Diffusion
==============================================================

.. raw:: html

   
   <div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">DESCRIPTION</a></li><li ><a href="#3">I- LOAD MODEL</a></li><li ><a href="#4">II - Perform Simulations</a></li><li ><a href="#5">III - MRI Data Fitting</a></li><li ><a href="#6">Check the results</a></li></ul></div><pre class="codeinput"><span class="comment">%Place in the right folder to run</span>
   cdmfile(<span class="string">'CHARMED_batch.m'</span>);
   </pre><h2 id="2">DESCRIPTION</h2><p >Batch to process CHARMED data without qMRLab GUI (graphical user interface) Run this script line by line</p><pre class="codeinput">qMRinfo(<span class="string">'CHARMED'</span>); <span class="comment">% Display help</span>
   <span class="comment">%**************************************************************************</span>
   </pre><pre class="codeoutput"> charmed: Composite Hindered and Restricted Model for Diffusion
    a href="matlab: figure, imshow charmed.png ;"Pulse Sequence Diagram/a
    
    
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
                                                              axonal diameter (sqrt(2*Dr*Delta)8m).
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
         |G| (T/m)         Diffusion gradient magnitude
         Delta (s)         Diffusion separation
         delta (s)         Diffusion duration
         TE (s)            Echo time
    
     Options:
       Rician noise bias               Used if no SigmaNoise map is provided.
         'Compute Sigma per voxel'     Sigma is estimated by computing the STD across repeated scans.
         'fix sigma'                   Use scd_noise_std_estimation to measure noise level. Use 'value' to fix Sigma.
       Display Type
         'q-value'                     abscissa for plots: q = gamma.delta.G (m-1)
         'b-value'                     abscissa for plots: b = (2.pi.q)^2.(Delta-delta/3) (s/mm2)
       S0 normalization
         'Use b=0'                     Use b=0 images. In case of variable TE, your dataset requires a b=0 for each TE.
         'Single T2 compartment'       In case of variable TE acquisition:
                                       fit single T2 using data acquired at b1000s/mm2 (assuming Gaussian diffusion))
       Time-dependent models
         'Burcaw 2015'                 XXX
         'Ning MRM 2016'               XXX
    
     Example of command line usage (see also a href="matlab: showdemo charmed_batch"showdemo charmed_batch/a):
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
   
   
   </pre><h2 id="3">I- LOAD MODEL</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   
   <span class="comment">% Create Model object</span>
   Model = charmed;
   <span class="comment">% Load Diffusion Protocol</span>
   <span class="comment">% TODO: Explain how Protocol.txt should be created</span>
   Model.Prot.DiffusionData.Mat = txt2mat(<span class="string">'Protocol.txt'</span>);
   
   <span class="comment">%**************************************************************************</span>
   </pre><pre class="codeoutput">**************
   * Protocol.txt
   * read mode: auto
   * 815 data lines analysed
   * 3 header line(s)
   * 7 data column(s)
   * 0 string replacement(s)
   **************
   </pre><h2 id="4">II - Perform Simulations</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% See info/usage of Sim_Single_Voxel_Curve</span>
   qMRusage(Model,<span class="string">'Sim_Single_Voxel_Curve'</span>)
   
   <span class="comment">% Let's try Sim_Single_Voxel_Curve</span>
   opt.SNR = 50;
   x.fr = .5;
   x.Dh = .7; <span class="comment">% um2/ms</span>
   x.diameter_mean = 6; <span class="comment">% um</span>
   x.fcsf = 0;
   x.lc=0;
   x.Dcsf=3;
   x.Dintra = 1.4;
   FitResults = Model.Sim_Single_Voxel_Curve(x,opt);
   <span class="comment">% compare FitResults and input x</span>
   SimResult = table(struct2mat(x,Model.xnames)',struct2mat(FitResults,Model.xnames)',<span class="string">'RowNames'</span>,Model.xnames,<span class="string">'VariableNames'</span>,{<span class="string">'input_x'</span>,<span class="string">'FitResults'</span>})
   
   <span class="comment">% to try other Simulations methods, type:</span>
   <span class="comment">% qMRusage(Model,'Sim_*')</span>
   
   <span class="comment">%**************************************************************************</span>
   </pre><pre class="codeoutput">strongSim_Single_Voxel_Curve/strong
      Simulates Single Voxel curves:
         (1) use equation to generate synthetic MRI data
         (2) add rician noise
         (3) fit and plot curve
      USAGE:
        FitResults = ModelObj.Sim_Single_Voxel_Curve(x)
        FitResults = ModelObj.Sim_Single_Voxel_Curve(x, Opt,display)
      INPUT:
        x: [struct] OR [vector] containing fit results: 'fr', 'Dh', 'diameter_mean', 'fcsf', 'lc', 'Dcsf', 'Dintra'
        display: [binary] 1=display, 0=nodisplay
        Opt:  a href="matlab:helpPopup struct" style="font-weight:bold"struct/a with fields:
   
       SNR: 50
   
   
      EXAMPLE:
            ModelObj = charmed
            x = struct;
            x.fr = 0.5;
            x.Dh = 0.7;
            x.diameter_mean = 6;
            x.fcsf = 0;
            x.lc = 0;
            x.Dcsf = 3;
            x.Dintra = 1.4;
            % Get all possible options
            Opt = button2opts(ModelObj.Sim_Single_Voxel_Curve_buttons,1);
            % run simulation using options `Opt(1)`
            ModelObj.Sim_Single_Voxel_Curve(x,Opt(1))
    
   
   ans =
   
       '
              ModelObj = charmed
              x = struct;
              x.fr = 0.5;
              x.Dh = 0.7;
              x.diameter_mean = 6;
              x.fcsf = 0;
              x.lc = 0;
              x.Dcsf = 3;
              x.Dintra = 1.4;
              % Get all possible options
              Opt = button2opts(ModelObj.Sim_Single_Voxel_Curve_buttons,1);
              % run simulation using options `Opt(1)`
              ModelObj.Sim_Single_Voxel_Curve(x,Opt(1))'
   
   
   SimResult =
   
     72 table
   
                        input_x    FitResults
                        _______    __________
   
       fr               0.5        0.50276   
       Dh               0.7        0.72865   
       diameter_mean      6         6.0027   
       fcsf               0              0   
       lc                 0              0   
       Dcsf               3              3   
       Dintra           1.4            1.4   
   
   </pre><img src="_static/CHARMED_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="5">III - MRI Data Fitting</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% load data</span>
   data = struct;
   data.DiffusionData = load_nii_data(<span class="string">'DiffusionData.nii.gz'</span>);
   data.Mask=load_nii_data(<span class="string">'Mask.nii.gz'</span>);
   
   <span class="comment">% plot fit in one voxel</span>
   voxel = [32 29];
   datavox.DiffusionData = squeeze(data.DiffusionData(voxel(1),voxel(2),:,:));
   FitResults = Model.fit(datavox)
   Model.plotModel(FitResults,datavox)
   
   <span class="comment">% fit all voxels (coffee break)</span>
   FitResults = FitData(data,Model,1);
   <span class="comment">% save maps</span>
   <span class="comment">% .MAT file : FitResultsSave_mat(FitResults,folder);</span>
   <span class="comment">% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);</span>
   <span class="comment">% FitResultsSave_nii(FitResults,'DiffusionData.nii.gz');</span>
   <span class="comment">%save('CHARMEDParameters.mat','Model');</span>
   FitResultsSave_nii(FitResults,<span class="string">'DiffusionData.nii.gz'</span>);
   </pre><pre class="codeoutput">
   FitResults = 
   
     struct with fields:
   
                  fr: 0.1594
                  Dh: 0.8886
       diameter_mean: 5.3655
                fcsf: 0
                  lc: 0
                Dcsf: 3
              Dintra: 1.4000
             S0_TE62: 1.2139e+05
             S0_TE57: 1.2525e+05
             S0_TE52: 1.3174e+05
             S0_TE47: 1.3278e+05
             S0_TE46: 1.3871e+05
             S0_TE36: 1.4916e+05
                  fh: 0.8406
             residue: 1.5655e+05
          SigmaNoise: 431.5808
   
   ...done   0%
   Warning: Directory already exists. 
   </pre><img src="_static/CHARMED_batch_02.png" vspace="5" hspace="5" alt=""> <h2 id="6">Check the results</h2><p >Load them in qMRLab</p><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017a</a><br ></p></div>
