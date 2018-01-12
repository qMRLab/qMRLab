mwf :  Myelin Water Fraction from Multi-Exponential T2w data
============================================================

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
   .content pre.codeinput { padding:10px; border:1px solid #d3d3d3; background:#f7f7f7; }
   .content pre.codeoutput { padding:10px 11px; margin:0px 0px 20px; color:#4c4c4c; }
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
   </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- DESCRIPTION</a></li><li ><a href="#3">II- INITIALIZE MODEL OBJECT</a></li><li ><a href="#4">A- CREATE MODEL OBJECT</a></li><li ><a href="#5">B- MODIFY OPTIONS</a></li><li ><a href="#6">C- LOAD PROTOCOL</a></li><li ><a href="#7">III- FIT EXPERIMENTAL DATASET</a></li><li ><a href="#8">A- LOAD EXPERIMENTAL DATA</a></li><li ><a href="#9">B- FIT DATASET</a></li><li ><a href="#10">C- SHOW FITTING RESULTS</a></li><li ><a href="#11">IV- SAVE MAPS AND OBJECT</a></li><li ><a href="#12">V- SIMULATIONS</a></li><li ><a href="#13">A- Single Voxel Curve</a></li><li ><a href="#14">B- Sensitivity Analysis</a></li></ul></div><pre class="codeinput"><span class="comment">% This m-file has been automatically generated.</span>
   <span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
   <span class="comment">% purposes and Octave.</span>
   <span class="comment">%</span>
   <span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
   <span class="comment">% processing for mwf on CLI.</span>
   <span class="comment">%</span>
   <span class="comment">% Demo files are downloaded into mwf_data folder.</span>
   <span class="comment">%</span>
   <span class="comment">%</span>
   <span class="comment">% Written by: Agah Karakuzu, 2017</span>
   <span class="comment">% =========================================================================</span>
   </pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'mwf'</span>); <span class="comment">% Display help</span>
   </pre><pre class="codeoutput">  mwf :  Myelin Water Fraction from Multi-Exponential T2w data
    
     Assumptions:
    
     Inputs:
       MET2data    Multi-Exponential T2 data
       (Mask)        Binary mask to accelerate the fitting (OPTIONAL)
    
     Outputs:
       MWF       Myelin Wanter Fraction
       T2MW      Spin relaxation time for Myelin Water (MW) [ms]
       T2IEW     Spin relaxation time for Intra/Extracellular Water (IEW) [ms]
    
     Options:
       Cutoff          Cutoff time [ms]
       Sigma           Noise standard deviation. Currently not corrected for rician bias
       Relaxation Type
            'T2'       For a SE sequence
           'T2*'      For a GRE sequence
    
     Protocol:
       1 .txt files or 1 .mat file :
         TE    [TE1 TE2 ...] % list of echo times [ms]
    
     Example of command line usage (see also a href="matlab: showdemo mwf_batch"showdemo mwf_batch/a):
       Model = mwf;  % Create class from model
       Model.Prot.Echo.Mat=[10:10:320];
       data = struct;  % Create data structure
       data.MET2data ='MET2data.mat';  % Load data
       data.Mask = 'Mask.mat';
       FitResults = FitData(data,Model); %fit data
       FitResultsSave_mat(FitResults);
    
           For more examples: a href="matlab: qMRusage(mwf);"qMRusage(mwf)/a
    
     Author: Ian Gagnon, 2017
    
     References:
       Please cite the following if you use this module:
         MacKay, A., Whittall, K., Adler, J., Li, D., Paty, D., Graeb, D.,
         1994. In vivo visualization of myelin water in brain by magnetic
         resonance. Magn. Reson. Med. 31, 673?677.
       In addition to citing the package:
         Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
         Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
         Stikov N. (2016), Quantitative magnetization transfer imaging made
         easy with qMTLab: Software for data simulation, analysis, and
         visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
   
       Reference page in Doc Center
          doc mwf
   
   
   </pre><h2 id="3">II- INITIALIZE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><h2 id="4">A- CREATE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><pre class="codeinput">Model = mwf;
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="5">B- MODIFY OPTIONS</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
            |- Octave is not GUI compatible. Modify Model.options directly.
   -------------------------------------------------------------------------</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><img src="_static/mwf_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">C- LOAD PROTOCOL</h2><pre class="language-matlab">	   |- Respective command <span class="string">lines</span> <span class="string">appear</span> <span class="string">if</span> <span class="string">required</span> <span class="string">by</span> <span class="string">mwf.</span>
   -------------------------------------------------------------------------
   </pre><pre class="codeinput"><span class="comment">% mwf object needs 1 protocol field(s) to be assigned:</span>
   
   
   <span class="comment">% MET2data</span>
   <span class="comment">% --------------</span>
   <span class="comment">% EchoTime (ms) is a vector of [32X1]</span>
   EchoTime  = [10.0000; 20.0000; 30.0000; 40.0000; 50.0000; 60.0000; 70.0000; 80.0000; 90.0000; 100.0000; 110.0000; 120.0000; 130.0000; 140.0000; 150.0000; 160.0000; 170.0000; 180.0000; 190.0000; 200.0000; 210.0000; 220.0000; 230.0000; 240.0000; 250.0000; 260.0000; 270.0000; 280.0000; 290.0000; 300.0000; 310.0000; 320.0000];
   Model.Prot.MET2data.Mat = [ EchoTime ];
   <span class="comment">% -----------------------------------------</span>
   </pre><h2 id="7">III- FIT EXPERIMENTAL DATASET</h2><p >-------------------------------------------------------------------------</p><h2 id="8">A- LOAD EXPERIMENTAL DATA</h2><pre >         |- Respective command lines appear if required by mwf.
   -------------------------------------------------------------------------
   mwf object needs 2 data input(s) to be assigned:</pre><pre class="codeinput"><span class="comment">% MET2data</span>
   <span class="comment">% Mask</span>
   <span class="comment">% --------------</span>
   
   data = struct();
   
   <span class="comment">% MET2data.mat contains [64  64   1  32] data.</span>
    load(<span class="string">'/data/mril/mril3/ilana/matlab/qMRLab/Data/mwf_demo/mwf_data/MET2data.mat'</span>);
   <span class="comment">% Mask.mat contains [64  64] data.</span>
    load(<span class="string">'/data/mril/mril3/ilana/matlab/qMRLab/Data/mwf_demo/mwf_data/Mask.mat'</span>);
    data.MET2data= double(MET2data);
    data.Mask= double(Mask);
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="9">B- FIT DATASET</h2><pre >           |- This section will fit data.
   -------------------------------------------------------------------------</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
   
   FitResults.Model = Model; <span class="comment">% qMRLab output.</span>
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><pre class="codeoutput">Fitting voxel     3/2540
   ...done   0%
   </pre><h2 id="10">C- SHOW FITTING RESULTS</h2><pre >         |- Output map will be displayed.</pre><pre class="codeinput"><span class="comment">%			|- If available, a graph will be displayed to show fitting in a voxel.</span>
   <span class="comment">% -------------------------------------------------------------------------</span>
   
   qMRshowOutput(FitResults,data,Model);
   </pre><img src="_static/mwf_batch_02.png" vspace="5" hspace="5" alt=""> <img src="_static/mwf_batch_03.png" vspace="5" hspace="5" alt=""> <h2 id="11">IV- SAVE MAPS AND OBJECT</h2><pre class="codeinput">Model.saveObj(<span class="string">'mwf_Demo.qmrlab.mat'</span>);
   FitResultsSave_nii(FitResults);
   
   <span class="comment">% Tip: You can load FitResults.mat in qMRLab graphical user interface</span>
   </pre><h2 id="12">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for 'mwf.
   -------------------------------------------------------------------------</pre><h2 id="13">A- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
                 (1) use equation to generate synthetic MRI data
                 (2) add rician noise
                 (3) fit and plot curve
   -------------------------------------------------------------------------</pre><pre class="codeinput">      x = struct;
         x.MWF = 50.0001;
         x.T2MW = 20.0001;
         x.T2IEW = 120;
         <span class="comment">% Get all possible options</span>
         Opt = button2opts(Model.Sim_Single_Voxel_Curve_buttons,1);
         <span class="comment">% run simulation using options `Opt(1)`</span>
         FitResult = Model.Sim_Single_Voxel_Curve(x,Opt(1));
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><img src="_static/mwf_batch_04.png" vspace="5" hspace="5" alt=""> <h2 id="14">B- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
                   (1) vary fitting parameters from lower (lb) to upper (ub) bound.
                   (2) run Sim_Single_Voxel_Curve Nofruns times
                   (3) Compute mean and std across runs
   -------------------------------------------------------------------------</pre><pre class="codeinput">      <span class="comment">%              MWF           T2MW          T2IEW</span>
         OptTable.st = [50            20            1.2e+02]; <span class="comment">% nominal values</span>
         OptTable.fx = [0             1             1]; <span class="comment">%vary MWF...</span>
         OptTable.lb = [0.0001        0.0001        40]; <span class="comment">%...from 0.0001</span>
         OptTable.ub = [1e+02         40            2e+02]; <span class="comment">%...to 100</span>
         <span class="comment">% Get all possible options</span>
         Opt = button2opts([Model.Sim_Single_Voxel_Curve_buttons, Model.Sim_Sensitivity_Analysis_buttons],1);
         <span class="comment">% run simulation using options `Opt(1)`</span>
         SimResults = Model.Sim_Sensitivity_Analysis(OptTable,Opt(1));
         SimVaryPlot(SimResults, <span class="string">'MWF'</span> ,<span class="string">'MWF'</span> );
   </pre><img src="_static/mwf_batch_05.png" vspace="5" hspace="5" alt=""> <p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017b</a><br ></p></div>
