b0_dem map :  Dual Echo Method for B0 mapping
=============================================

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
   <span class="comment">% processing for b0_dem on CLI.</span>
   <span class="comment">%</span>
   <span class="comment">% Demo files are downloaded into b0_dem_data folder.</span>
   <span class="comment">%</span>
   <span class="comment">%</span>
   <span class="comment">% Written by: Agah Karakuzu, 2017</span>
   <span class="comment">% =========================================================================</span>
   </pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'b0_dem'</span>); <span class="comment">% Display help</span>
   </pre><pre class="codeoutput">  b0_dem map :  Dual Echo Method for B0 mapping
    
     Assumptions:
       Compute B0 map based on 2 phase images with different TEs
    
     Inputs:
       Phase       4D phase image, 2 different TEs in time dimension
       Magn        3D magnitude image
    
     Outputs:
    	B0map       B0 field map [Hz]
    
     Protocol:
       TimingTable
           deltaTE     Difference in TE between 2 images [ms]            
    
     Options:
       Magn thresh     relative threshold for the magnitude (phase is undefined in the background
    
     Example of command line usage (see also a href="matlab: showdemo b0_dem_batch"showdemo b0_dem_batch/a):
       Model = b0_dem;  % Create class from model 
       Model.Prot.TimingTable.Mat = 1.92e-3; % deltaTE [s]
       data.Phase = double(load_nii_data('Phase.nii.gz'));%Load 4D data, 2 frames with different TE
       data.Magn  = double(load_nii_data('Magn.nii.gz'));
       FitResults       = FitData(data,Model);
       FitResultsSave_nii(FitResults,'Phase.nii.gz'); %save nii file using Phase.nii.gz as template
        
       For more examples: a href="matlab: qMRusage(b0_dem);"qMRusage(b0_dem)/a
    
     Author: Ian Gagnon, 2017
    
     References:
       Please cite the following if you use this module:
         Maier, F., Fuentes, D., Weinberg, J.S., Hazle, J.D., Stafford, R.J.,
         2015. Robust phase unwrapping for MR temperature imaging using a
         magnitude-sorted list, multi-clustering algorithm. Magn. Reson. Med.
         73, 1662?1668. Schofield, M.A., Zhu, Y., 2003. Fast phase unwrapping
         algorithm for interferometric applications. Opt. Lett. 28, 1194?1196
       In addition to citing the package:
         Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
         Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
         Stikov N. (2016), Quantitative magnetization transfer imaging made
         easy with qMTLab: Software for data simulation, analysis, and
         visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
   
       Reference page in Doc Center
          doc b0_dem
   
   
   </pre><h2 id="3">II- INITIALIZE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><h2 id="4">A- CREATE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><pre class="codeinput">Model = b0_dem;
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="5">B- MODIFY OPTIONS</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
            |- Octave is not GUI compatible. Modify Model.options directly.
   -------------------------------------------------------------------------</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><img src="_static/b0_dem_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">C- LOAD PROTOCOL</h2><pre class="language-matlab">	   |- Respective command <span class="string">lines</span> <span class="string">appear</span> <span class="string">if</span> <span class="string">required</span> <span class="string">by</span> <span class="string">b0_dem.</span>
   -------------------------------------------------------------------------
   </pre><pre class="codeinput"><span class="comment">% b0_dem object needs 1 protocol field(s) to be assigned:</span>
   
   
   <span class="comment">% TimingTable</span>
   <span class="comment">% --------------</span>
   <span class="comment">% deltaTE is a vector of [1X1]</span>
   deltaTE = [0.0019];
   Model.Prot.TimingTable.Mat = [ deltaTE];
   <span class="comment">% -----------------------------------------</span>
   </pre><h2 id="7">III- FIT EXPERIMENTAL DATASET</h2><p >-------------------------------------------------------------------------</p><h2 id="8">A- LOAD EXPERIMENTAL DATA</h2><pre >         |- Respective command lines appear if required by b0_dem.
   -------------------------------------------------------------------------
   b0_dem object needs 2 data input(s) to be assigned:</pre><pre class="codeinput"><span class="comment">% Phase</span>
   <span class="comment">% Magn</span>
   <span class="comment">% --------------</span>
   
   data = struct();
   <span class="comment">% Phase.nii.gz contains [64  64   1   8] data.</span>
   data.Phase=double(load_nii_data(<span class="string">'/data/mril/mril3/ilana/matlab/qMRLab/Data/b0_dem_demo/b0_dem_data/Phase.nii.gz'</span>));
   <span class="comment">% Magn.nii.gz contains [64  64   1   8] data.</span>
   data.Magn=double(load_nii_data(<span class="string">'/data/mril/mril3/ilana/matlab/qMRLab/Data/b0_dem_demo/b0_dem_data/Magn.nii.gz'</span>));
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="9">B- FIT DATASET</h2><pre >           |- This section will fit data.
   -------------------------------------------------------------------------</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
   
   FitResults.Model = Model; <span class="comment">% qMRLab output.</span>
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><pre class="codeoutput">...done   0%
   </pre><h2 id="10">C- SHOW FITTING RESULTS</h2><pre >         |- Output map will be displayed.</pre><pre class="codeinput"><span class="comment">%			|- If available, a graph will be displayed to show fitting in a voxel.</span>
   <span class="comment">% -------------------------------------------------------------------------</span>
   
   qMRshowOutput(FitResults,data,Model);
   </pre><img src="_static/b0_dem_batch_02.png" vspace="5" hspace="5" alt=""> <h2 id="11">IV- SAVE MAPS AND OBJECT</h2><pre class="codeinput">Model.saveObj(<span class="string">'b0_dem_Demo.qmrlab.mat'</span>);
   FitResultsSave_nii(FitResults, <span class="string">'b0_dem_data/Phase.nii.gz'</span>);
   
   <span class="comment">% Tip: You can load FitResults.mat in qMRLab graphical user interface</span>
   </pre><pre class="codeoutput">Warning: Directory already exists. 
   </pre><h2 id="12">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for 'b0_dem.
   -------------------------------------------------------------------------</pre><h2 id="13">A- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
                 (1) use equation to generate synthetic MRI data
                 (2) add rician noise
                 (3) fit and plot curve
   -------------------------------------------------------------------------</pre><pre class="codeinput"><span class="comment">% Not available for the current model.</span>
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="14">B- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
                   (1) vary fitting parameters from lower (lb) to upper (ub) bound.
                   (2) run Sim_Single_Voxel_Curve Nofruns times
                   (3) Compute mean and std across runs
   -------------------------------------------------------------------------</pre><pre class="codeinput"><span class="comment">% Not available for the current model.</span>
   </pre><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017b</a><br ></p></div>
