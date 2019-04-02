b1_dam map:  Double-Angle Method for B1+ mapping
================================================

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
   </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- DESCRIPTION</a></li><li ><a href="#3">II- MODEL PARAMETERS</a></li><li ><a href="#4">a- create object</a></li><li ><a href="#5">b- modify options</a></li><li ><a href="#6">III- FIT EXPERIMENTAL DATASET</a></li><li ><a href="#7">a- load experimental data</a></li><li ><a href="#8">b- fit dataset</a></li><li ><a href="#9">c- show fitting results</a></li><li ><a href="#10">d- Save results</a></li><li ><a href="#11">V- SIMULATIONS</a></li><li ><a href="#12">a- Single Voxel Curve</a></li><li ><a href="#13">b- Sensitivity Analysis</a></li></ul></div><pre class="codeinput"><span class="comment">% This m-file has been automatically generated using qMRgenBatch(b1_dam)</span>
   <span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
   <span class="comment">% purposes and Octave.</span>
   <span class="comment">%</span>
   <span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
   <span class="comment">% processing for b1_dam on CLI.</span>
   <span class="comment">%</span>
   <span class="comment">% Demo files are downloaded into b1_dam_data folder.</span>
   <span class="comment">%</span>
   <span class="comment">% Written by: Agah Karakuzu, 2017</span>
   <span class="comment">% =========================================================================</span>
   </pre><h2 >I- DESCRIPTION<a name="2"></a></h2><pre class="codeinput">qMRinfo(<span class="string">'b1_dam'</span>); <span class="comment">% Describe the model</span>
   </pre><pre class="codeoutput">  b1_dam map:  Double-Angle Method for B1+ mapping
    
     Assumptions:
       Compute a B1map using 2 SPGR images with 2 different flip angles (alpha, 2xalpha)
       Smoothing can be done with different filters and optional size
       Spurious B1 values and those outside the mask (optional) are set to a constant before smoothing
    
     Inputs:
       SFalpha            SPGR data at a flip angle of Alpha degree
       SF2alpha           SPGR data at a flip angle of AlphaX2 degree
       (Mask)             Binary mask to exclude non-brain voxels (better when smoothing)
    
     Outputs:
    	B1map_raw          Excitation (B1+) field map
       B1map_filtered     Smoothed B1+ field map using Gaussian, Median, Spline or polynomial filter (see FilterClass.m for more info)
       Spurious           Map of datapoints that were set to 1 prior to smoothing
    
     Protocol:
    	NONE
    
     Options:
       (inherited from FilterClass)
    
     Example of command line usage:
       Model = b1_dam;% Create class from model
       data.SFalpha = double(load_nii_data('SFalpha.nii.gz')); %load data
       data.SF2alpha  = double(load_nii_data('SF2alpha.nii.gz'));
       Model.Smoothingfilter_Type = 'gaussian'; %apply gaussian smoothing in 3D with fwhm=3
       Model.Smoothingfilter_Type = '3D';
       Model.Smoothingfilter_sizex = 3;
       Model.Smoothingfilter_sizey = 3;
       Model.Smoothingfilter_sizez = 3;
       FitResults       = FitData(data,Model); % fit data
       FitResultsSave_nii(FitResults,'SFalpha.nii.gz'); %save nii file using SFalpha.nii.gz as template
    
       For more examples: a href="matlab: qMRusage(b1_dam);"qMRusage(b1_dam)/a
    
     Author: Ian Gagnon, 2017
    
     References:
       Please cite the following if you use this module:
         Insko, E.K., Bolinger, L., 1993. Mapping of the Radiofrequency Field.
         J. Magn. Reson. A 103, 82?85.
       In addition to citing the package:
         Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
         Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
         Stikov N. (2016), Quantitative magnetization transfer imaging made
         easy with qMTLab: Software for data simulation, analysis, and
         visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
   
       Reference page for b1_dam
   
   </pre><h2 >II- MODEL PARAMETERS<a name="3"></a></h2><h2 >a- create object<a name="4"></a></h2><pre class="codeinput">Model = b1_dam;
   </pre><h2 >b- modify options<a name="5"></a></h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
            |- Octave is not GUI compatible. Modify Model.options directly.</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
   </pre><img src="_static/b1_dam_batch_01.png" vspace="5" hspace="5" style="width:488px;height:694px;" alt=""> <h2 >III- FIT EXPERIMENTAL DATASET<a name="6"></a></h2><h2 >a- load experimental data<a name="7"></a></h2><pre >         |- b1_dam object needs 3 data input(s) to be assigned:
            |-   SFalpha
            |-   SF2alpha
            |-   Mask</pre><pre class="codeinput">data = struct();
   <span class="comment">% SFalpha.nii.gz contains [64  64] data.</span>
   data.SFalpha=double(load_nii_data(<span class="string">'b1_dam_data/SFalpha.nii.gz'</span>));
   <span class="comment">% SF2alpha.nii.gz contains [64  64] data.</span>
   data.SF2alpha=double(load_nii_data(<span class="string">'b1_dam_data/SF2alpha.nii.gz'</span>));
   </pre><h2 >b- fit dataset<a name="8"></a></h2><pre >           |- This section will fit data.</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
   </pre><pre class="codeoutput">...done
   </pre><h2 >c- show fitting results<a name="9"></a></h2><pre >         |- Output map will be displayed.
            |- If available, a graph will be displayed to show fitting in a voxel.</pre><pre class="codeinput">qMRshowOutput(FitResults,data,Model);
   </pre><img src="_static/b1_dam_batch_02.png" vspace="5" hspace="5" style="width:560px;height:420px;" alt=""> <h2 >d- Save results<a name="10"></a></h2><pre >         |-  qMR maps are saved in NIFTI and in a structure FitResults.mat
                 that can be loaded in qMRLab graphical user interface
            |-  Model object stores all the options and protocol.
                 It can be easily shared with collaborators to fit their
                 own data or can be used for simulation.</pre><pre class="codeinput">FitResultsSave_nii(FitResults, <span class="string">'b1_dam_data/SFalpha.nii.gz'</span>);
   Model.saveObj(<span class="string">'b1_dam_Demo.qmrlab.mat'</span>);
   </pre><pre class="codeoutput">Warning: Directory already exists. 
   </pre><h2 >V- SIMULATIONS<a name="11"></a></h2><pre >   |- This section can be executed to run simulations for b1_dam.</pre><h2 >a- Single Voxel Curve<a name="12"></a></h2><pre >         |- Simulates Single Voxel curves:
                 (1) use equation to generate synthetic MRI data
                 (2) add rician noise
                 (3) fit and plot curve</pre><pre class="codeinput"><span class="comment">% Not available for the current model.</span>
   </pre><h2 >b- Sensitivity Analysis<a name="13"></a></h2><pre >         |-    Simulates sensitivity to fitted parameters:
                   (1) vary fitting parameters from lower (lb) to upper (ub) bound.
                   (2) run Sim_Single_Voxel_Curve Nofruns times
                   (3) Compute mean and std across runs</pre><pre class="codeinput"><span class="comment">% Not available for the current model.</span>
   </pre><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2015b</a><br ></p></div>
