vfa_t1: Compute a T1 map using Variable Flip Angle
==================================================

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
   </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- DESCRIPTION</a></li><li ><a href="#3">II- INITIALIZE MODEL OBJECT</a></li><li ><a href="#4">A- CREATE MODEL OBJECT</a></li><li ><a href="#5">B- MODIFY OPTIONS</a></li><li ><a href="#6">C- LOAD PROTOCOL</a></li><li ><a href="#7">III- FIT EXPERIMENTAL DATASET</a></li><li ><a href="#8">A- LOAD EXPERIMENTAL DATA</a></li><li ><a href="#9">B- FIT DATASET</a></li><li ><a href="#10">C- SHOW FITTING RESULTS</a></li><li ><a href="#11">IV- SAVE MAPS AND OBJECT</a></li><li ><a href="#12">V- SIMULATIONS</a></li><li ><a href="#13">A- Single Voxel Curve</a></li><li ><a href="#14">B- Sensitivity Analysis</a></li></ul></div><pre class="codeinput"><span class="comment">% This m-file has been automatically generated.</span>
   <span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
   <span class="comment">% purposes and Octave.</span>
   <span class="comment">%</span>
   <span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
   <span class="comment">% processing for vfa_t1 on CLI.</span>
   <span class="comment">%</span>
   <span class="comment">% Demo files are downloaded into vfa_t1_data folder.</span>
   <span class="comment">%</span>
   <span class="comment">%</span>
   <span class="comment">% Written by: Agah Karakuzu, 2017</span>
   <span class="comment">% =========================================================================</span>
   </pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'vfa_t1'</span>); <span class="comment">% Display help</span>
   </pre><pre class="codeoutput">  vfa_t1: Compute a T1 map using Variable Flip Angle
    
     Assumptions:
     
     Inputs:
       VFAData         spoiled Gradient echo data, 4D volume with different flip angles in time dimension
       (B1map)         excitation (B1+) fieldmap. Used to correct flip angles. (optional)
       (Mask)          Binary mask to accelerate the fitting (optional)
    
     Outputs:
       T1              Longitudinal relaxation time [s]
       M0              Equilibrium magnetization
    
     Protocol:
       VFAData Array [nbFA x 2]:
           [FA1 TR1; FA2 TR2;...]      flip angle [degrees] TR [s]
    
     Options:
       None
    
     Example of command line usage (see also a href="matlab: showdemo vfa_t1_batch"showdemo vfa_t1_batch/a):
       Model = vfa_t1;  % Create class from model 
       Model.Prot.VFAData.Mat=[3 0.015; 20 0.015]; %Protocol: 2 different FAs
       data = struct;  % Create data structure 
       data.VFAData = load_nii_data('VFAData.nii.gz');
       data.B1map = load_nii_data('B1map.nii.gz');
       FitResults = FitData(data,Model); %fit data
       FitResultsSave_mat(FitResults);
    
       For more examples: a href="matlab: qMRusage(vfa_t1);"qMRusage(vfa_t1)/a
    
     
     Author: Ian Gagnon, 2017
    
     References:
       Please cite the following if you use this module:
         Fram, E.K., Herfkens, R.J., Johnson, G.A., Glover, G.H., Karis, J.P.,
         Shimakawa, A., Perkins, T.G., Pelc, N.J., 1987. Rapid calculation of
         T1 using variable flip angle gradient refocused imaging. Magn. Reson.
         Imaging 5, 201?208
       In addition to citing the package:
         Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
         Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
         Stikov N. (2016), Quantitative magnetization transfer imaging made
         easy with qMTLab: Software for data simulation, analysis, and
         visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
   
       Reference page in Doc Center
          doc vfa_t1
   
   
   </pre><h2 id="3">II- INITIALIZE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><h2 id="4">A- CREATE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><pre class="codeinput">Model = vfa_t1;
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="5">B- MODIFY OPTIONS</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
            |- Octave is not GUI compatible. Modify Model.options directly.
   -------------------------------------------------------------------------</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><img src="_static/vfa_t1_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">C- LOAD PROTOCOL</h2><pre class="language-matlab">	   |- Respective command <span class="string">lines</span> <span class="string">appear</span> <span class="string">if</span> <span class="string">required</span> <span class="string">by</span> <span class="string">vfa_t1.</span>
   -------------------------------------------------------------------------
   </pre><pre class="codeinput"><span class="comment">% vfa_t1 object needs 1 protocol field(s) to be assigned:</span>
   
   
   <span class="comment">% VFAData</span>
   <span class="comment">% --------------</span>
   <span class="comment">% FlipAngle is a vector of [2X1]</span>
   FlipAngle = [3.0000; 20.0000];
   <span class="comment">% TR is a vector of [2X1]</span>
   TR = [0.0150; 0.0150];
   Model.Prot.VFAData.Mat = [ FlipAngle TR];
   <span class="comment">% -----------------------------------------</span>
   </pre><h2 id="7">III- FIT EXPERIMENTAL DATASET</h2><p >-------------------------------------------------------------------------</p><h2 id="8">A- LOAD EXPERIMENTAL DATA</h2><pre >         |- Respective command lines appear if required by vfa_t1.
   -------------------------------------------------------------------------
   vfa_t1 object needs 3 data input(s) to be assigned:</pre><pre class="codeinput"><span class="comment">% VFAData</span>
   <span class="comment">% B1map</span>
   <span class="comment">% Mask</span>
   <span class="comment">% --------------</span>
   
   data = struct();
   <span class="comment">% VFAData.nii.gz contains [128  128    1    2] data.</span>
   data.VFAData=double(load_nii_data(<span class="string">'vfa_t1_data/VFAData.nii.gz'</span>));
   <span class="comment">% B1map.nii.gz contains [128  128] data.</span>
   data.B1map=double(load_nii_data(<span class="string">'vfa_t1_data/B1map.nii.gz'</span>));
   <span class="comment">% Mask.nii.gz contains [128  128] data.</span>
   data.Mask=double(load_nii_data(<span class="string">'vfa_t1_data/Mask.nii.gz'</span>));
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="9">B- FIT DATASET</h2><pre >           |- This section will fit data.
   -------------------------------------------------------------------------</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
   
   FitResults.Model = Model; <span class="comment">% qMRLab output.</span>
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><pre class="codeoutput">Fitting voxel     3/4668
   ...done   0%
   </pre><h2 id="10">C- SHOW FITTING RESULTS</h2><pre >         |- Output map will be displayed.</pre><pre class="codeinput"><span class="comment">%			|- If available, a graph will be displayed to show fitting in a voxel.</span>
   <span class="comment">% -------------------------------------------------------------------------</span>
   
   qMRshowOutput(FitResults,data,Model);
   </pre><pre class="codeoutput">          M0: 2.5567e+03
          Model: [11 vfa_t1]
       Protocol: [11 struct]
             T1: 1.3447
           Time: 0.0626
        Version: [2 0 8]
       computed: [128128 double]
         fields: {'T1'  'M0'}
   
   </pre><img src="_static/vfa_t1_batch_02.png" vspace="5" hspace="5" alt=""> <img src="_static/vfa_t1_batch_03.png" vspace="5" hspace="5" alt=""> <h2 id="11">IV- SAVE MAPS AND OBJECT</h2><pre class="codeinput">Model.saveObj(<span class="string">'vfa_t1_Demo.qmrlab.mat'</span>);
   FitResultsSave_nii(FitResults, <span class="string">'vfa_t1_data/VFAData.nii.gz'</span>);
   
   <span class="comment">% Tip: You can load FitResults.mat in qMRLab graphical user interface</span>
   </pre><h2 id="12">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for 'vfa_t1.
   -------------------------------------------------------------------------</pre><h2 id="13">A- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
                 (1) use equation to generate synthetic MRI data
                 (2) add rician noise
                 (3) fit and plot curve
   -------------------------------------------------------------------------</pre><pre class="codeinput">      x = struct;
         x.M0 = 2000;
         x.T1 = 0.7;
         <span class="comment">% Get all possible options</span>
         Opt = button2opts(Model.Sim_Single_Voxel_Curve_buttons,1);
         <span class="comment">% run simulation using options `Opt(1)`</span>
         figure(<span class="string">'Name'</span>,<span class="string">'Single Voxel Curve Simulation'</span>);
         FitResult = Model.Sim_Single_Voxel_Curve(x,Opt(1));
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><pre class="codeoutput">    T1: 0.6985
       M0: 1.8919e+03
   
   </pre><img src="_static/vfa_t1_batch_04.png" vspace="5" hspace="5" alt=""> <h2 id="14">B- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
                   (1) vary fitting parameters from lower (lb) to upper (ub) bound.
                   (2) run Sim_Single_Voxel_Curve Nofruns times
                   (3) Compute mean and std across runs
   -------------------------------------------------------------------------</pre><pre class="codeinput">      <span class="comment">%              M0            T1</span>
         OptTable.st = [2e+03         0.7]; <span class="comment">% nominal values</span>
         OptTable.fx = [0             1]; <span class="comment">%vary M0...</span>
         OptTable.lb = [0             1e-05]; <span class="comment">%...from 0</span>
         OptTable.ub = [6e+03         5]; <span class="comment">%...to 6000</span>
          Opt.SNR = 50;
          Opt.Nofrun = 5;
         <span class="comment">% run simulation using options `Opt(1)`</span>
         SimResults = Model.Sim_Sensitivity_Analysis(OptTable,Opt(1));
         figure(<span class="string">'Name'</span>,<span class="string">'Sensitivity Analysis'</span>);
         SimVaryPlot(SimResults, <span class="string">'M0'</span> ,<span class="string">'M0'</span> );
   </pre><img src="_static/vfa_t1_batch_05.png" vspace="5" hspace="5" alt=""> <p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017b</a><br ></p></div>
