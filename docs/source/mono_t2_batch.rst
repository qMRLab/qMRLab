mono_t2: Compute a monoexponential T2 map using multi-echo spin-echo
====================================================================

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
   </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- DESCRIPTION</a></li><li ><a href="#3">II- MODEL PARAMETERS</a></li><li ><a href="#4">a- create object</a></li><li ><a href="#5">b- modify options</a></li><li ><a href="#6">III- FIT EXPERIMENTAL DATASET</a></li><li ><a href="#7">a- load experimental data</a></li><li ><a href="#8">b- fit dataset</a></li><li ><a href="#9">c- show fitting results</a></li><li ><a href="#10">d- Save results</a></li><li ><a href="#11">V- SIMULATIONS</a></li><li ><a href="#12">a- Single Voxel Curve</a></li><li ><a href="#13">b- Sensitivity Analysis</a></li></ul></div><pre class="codeinput"><span class="comment">% This m-file has been automatically generated using qMRgenBatch(mono_t2)</span>
   <span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
   <span class="comment">% purposes and Octave.</span>
   <span class="comment">%</span>
   <span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
   <span class="comment">% processing for mono_t2 on CLI.</span>
   <span class="comment">%</span>
   <span class="comment">% Demo files are downloaded into mono_t2_data folder.</span>
   <span class="comment">%</span>
   <span class="comment">% Written by: Agah Karakuzu, 2017</span>
   <span class="comment">% =========================================================================</span>
   </pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'mono_t2'</span>); <span class="comment">% Describe the model</span>
   </pre><pre class="codeoutput">  mono_t2: Compute a monoexponential T2 map using multi-echo spin-echo
     data
    
     Assumptions:
       Mono-exponential fit
    
     Inputs:
       SEdata          Multi-echo data, 4D volume with different echo times in time dimension
       (Mask)          Binary mask to accelerate the fitting (optional)
    
     Outputs:
       T2              Transverse relaxation time [s]
       M0              Equilibrium magnetization
    
     Protocol:
       TE Array [nbTE]:
       [TE1; TE2;...;TEn]     column vector listing the TEs [ms] 
    
     Options:
       FitType         Linear or Exponential
       DropFirstEcho   `Link Optionally drop 1st echo because of imperfect refocusing https://www.ncbi.nlm.nih.gov/pubmed/26678918`_
       Offset          a href="https://www.ncbi.nlm.nih.gov/pubmed/26678918"Optionally fit for offset parameter to correct for imperfect refocusing/a 
    
     Example of command line usage:
       Model = mono_t2;  % Create class from model
       Model.Prot.SEData.Mat=[10:10:320]'; %Protocol: 32 echo times
       data = struct;  % Create data structure
       data.SEData = load_nii_data('SEData.nii.gz');
       FitResults = FitData(data,Model); %fit data
       FitResultsSave_mat(FitResults);
   
       Reference page in Doc Center
          doc mono_t2
   
   
   </pre><h2 id="3">II- MODEL PARAMETERS</h2><h2 id="4">a- create object</h2><pre class="codeinput">Model = mono_t2;
   </pre><h2 id="5">b- modify options</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
            |- Octave is not GUI compatible. Modify Model.options directly.</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
   </pre><img src="_static/mono_t2_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">III- FIT EXPERIMENTAL DATASET</h2><h2 id="7">a- load experimental data</h2><pre >         |- mono_t2 object needs 2 data input(s) to be assigned:
            |-   SEdata
            |-   Mask</pre><pre class="codeinput">data = struct();
   <span class="comment">% SEdata.nii.gz contains [260  320    1   30] data.</span>
   data.SEdata=double(load_nii_data(<span class="string">'mono_t2_data/SEdata.nii.gz'</span>));
   <span class="comment">% Mask.nii.gz contains [260  320] data.</span>
   data.Mask=double(load_nii_data(<span class="string">'mono_t2_data/Mask.nii.gz'</span>));
   </pre><h2 id="8">b- fit dataset</h2><pre >           |- This section will fit data.</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
   </pre><pre class="codeoutput">=============== qMRLab::Fit ======================
   Operation has been started: mono_t2
   Elapsed time is 0.052560 seconds.
   Operation has been completed: mono_t2
   ==================================================
   </pre><h2 id="9">c- show fitting results</h2><pre >         |- Output map will be displayed.
            |- If available, a graph will be displayed to show fitting in a voxel.
            |- To make documentation generation and our CI tests faster for this model,
               we used a subportion of the data (40X40X40) in our testing environment.
            |- Therefore, this example will use FitResults that comes with OSF data for display purposes.
            |- Users will get the whole dataset (384X336X224) and the script that uses it for demo
               via qMRgenBatch(qsm_sb) command.</pre><pre class="codeinput">FitResults_old = load(<span class="string">'FitResults/FitResults.mat'</span>);
   qMRshowOutput(FitResults_old,data,Model);
   </pre><pre class="codeoutput error">Error using load
   'FitResults/FitResults.mat' is not found in the current folder or on the MATLAB path, but exists in:
       /private/var/folders/7_/92rkmqt51sj07k7hkdrg7_fw0000gn/T/tpf60df1b2_a55b_432c_a2dc_5dfd294d073b/amico_demo
       /Users/Agah/Desktop/neuropoly/mp2rage_demo
       /Users/Agah/Desktop/mono_t2_demo
       /Users/Agah/Desktop/mp2rage_demo
       /Users/Agah/Desktop/filter_map_demo
   
   Change the MATLAB current folder or add its folder to the MATLAB path.
   
   Error in mono_t2_batch (line 55)
   FitResults_old = load('FitResults/FitResults.mat');
   </pre><h2 id="10">d- Save results</h2><pre >         |-  qMR maps are saved in NIFTI and in a structure FitResults.mat
                 that can be loaded in qMRLab graphical user interface
            |-  Model object stores all the options and protocol.
                 It can be easily shared with collaborators to fit their
                 own data or can be used for simulation.</pre><pre class="codeinput">FitResultsSave_nii(FitResults, <span class="string">'mono_t2_data/SEdata.nii.gz'</span>);
   Model.saveObj(<span class="string">'mono_t2_Demo.qmrlab.mat'</span>);
   </pre><h2 id="11">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for mono_t2.</pre><h2 id="12">a- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
                 (1) use equation to generate synthetic MRI data
                 (2) add rician noise
                 (3) fit and plot curve</pre><pre class="codeinput">      x = struct;
         x.T2 = 100;
         x.M0 = 1000;
          Opt.SNR = 50;
         <span class="comment">% run simulation</span>
         figure(<span class="string">'Name'</span>,<span class="string">'Single Voxel Curve Simulation'</span>);
         FitResult = Model.Sim_Single_Voxel_Curve(x,Opt);
   </pre><h2 id="13">b- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
                   (1) vary fitting parameters from lower (lb) to upper (ub) bound.
                   (2) run Sim_Single_Voxel_Curve Nofruns times
                   (3) Compute mean and std across runs</pre><pre class="codeinput">      <span class="comment">%              T2            M0</span>
         OptTable.st = [1e+02         1e+03]; <span class="comment">% nominal values</span>
         OptTable.fx = [0             1]; <span class="comment">%vary T2...</span>
         OptTable.lb = [1             1]; <span class="comment">%...from 1</span>
         OptTable.ub = [3e+02         1e+04]; <span class="comment">%...to 300</span>
          Opt.SNR = 50;
          Opt.Nofrun = 5;
         <span class="comment">% run simulation</span>
         SimResults = Model.Sim_Sensitivity_Analysis(OptTable,Opt);
         figure(<span class="string">'Name'</span>,<span class="string">'Sensitivity Analysis'</span>);
         SimVaryPlot(SimResults, <span class="string">'T2'</span> ,<span class="string">'T2'</span> );
   </pre><p class="footer"><br ><a href="https://www.mathworks.com/products/matlab/">Published with MATLAB R2018a</a><br ></p></div>
