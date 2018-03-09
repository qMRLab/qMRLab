qmt_bssfp : qMT using Balanced Steady State Free Precession acquisition
=======================================================================

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
   <span class="comment">% processing for qmt_bssfp on CLI.</span>
   <span class="comment">%</span>
   <span class="comment">% Demo files are downloaded into qmt_bssfp_data folder.</span>
   <span class="comment">%</span>
   <span class="comment">%</span>
   <span class="comment">% Written by: Agah Karakuzu, 2017</span>
   <span class="comment">% =========================================================================</span>
   </pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'qmt_bssfp'</span>); <span class="comment">% Display help</span>
   </pre><pre class="codeoutput">  qmt_bssfp : qMT using Balanced Steady State Free Precession acquisition
    -----------------------------------------------------------------------------------------------------
     Assumptions:
     
     Inputs:
       MTData        4D Magnetization Transfer data
       (R1map)       1/T1map (optional)
       (Mask)        Binary mask to accelerate the fitting (optional)
    
     Outputs:
         F         Ratio of number of restricted pool to free pool, defined 
                   as F = M0r/M0f = kf/kr.
         kr        Exchange rate from the free to the restricted pool 
                   (note that kf and kr are related to one another via the 
                   definition of F. Changing the value of kf will change kr 
                   accordingly, and vice versa).
         R1f       Longitudinal relaxation rate of the free pool 
                   (R1f = 1/T1f).
         R1r       Longitudinal relaxation rate of the restricted pool 
                   (R1r = 1/T1r).
         T2f       Tranverse relaxation time of the free pool (T2f = 1/R2f).
         M0f       Equilibrium value of the free pool longitudinal 
                   magnetization.
    
       Additional Outputs
         M0r       Equilibrium value of the restricted pool longitudinal 
                      magnetization.
         kf        Exchange rate from the restricted to the free pool.
         resnorm   Fitting residual.
    
     Protocol:
       MTdata      Array [nbVols x 2]:
           Alpha   Flip angle of the RF pulses (degrees)
           Trf     Duration of the RF pulses (s)
    
     Options:
       RF Pulse
           Shape           Shape of the RF pulses.
                              Available shapes are:
                              - hard
                              - gaussian
                              - gausshann (gaussian pulse with Hanning window)
                              - sinc
                              - sinchann (sinc pulse with Hanning window)
                              - singauss (sinc pulse with gaussian window)
                              - fermi
           Nb of RF pulses Number of RF pulses applied before readout.
    
       Protocol Timing
           Fix TR          Select this option and enter a value in the text 
                             box below to set a fixed repetition time.
           Fix TR - Trf	Select this option and enter a value in the text 
                             box below to set a fixed free precession time
                             (TR - Trf).
           Prepulse      Perform an Alpha/2 - TR/2 prepulse before each 
                             series of RF pulses.
    
       R1
           Use R1map to      By checking this box, you tell the fitting 
             constrain R1f   algorithm to check for an observed R1map and use
                             its value to constrain R1f. Checking this box 
                             will automatically set the R1f fix box to true in            
                             the Fit parameters table.                
           Fix R1r = R1f     By checking this box, you tell the fitting
                             algorithm to fix R1r equal to R1f. Checking this 
                             box will automatically set the R1r fix box to 
                             true in the Fit parameters table.
    
       Global
           G(0)              The assumed value of the absorption lineshape of
                             the restricted pool.
    
     References:
       Please cite the following if you use this module:
       
       In addition to citing the package:
           Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
    
   
       Reference page in Doc Center
          doc qmt_bssfp
   
   
   </pre><h2 id="3">II- INITIALIZE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><h2 id="4">A- CREATE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><pre class="codeinput">Model = qmt_bssfp;
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="5">B- MODIFY OPTIONS</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
            |- Octave is not GUI compatible. Modify Model.options directly.
   -------------------------------------------------------------------------</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><img src="_static/qmt_bssfp_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">C- LOAD PROTOCOL</h2><pre class="language-matlab">	   |- Respective command <span class="string">lines</span> <span class="string">appear</span> <span class="string">if</span> <span class="string">required</span> <span class="string">by</span> <span class="string">qmt_bssfp.</span>
   -------------------------------------------------------------------------
   </pre><pre class="codeinput"><span class="comment">% qmt_bssfp object needs 1 protocol field(s) to be assigned:</span>
   
   
   <span class="comment">% MTdata</span>
   <span class="comment">% --------------</span>
   <span class="comment">% Alpha is a vector of [16X1]</span>
   Alpha = [5.0000; 10.0000; 15.0000; 20.0000; 25.0000; 30.0000; 35.0000; 40.0000; 35.0000; 35.0000; 35.0000; 35.0000; 35.0000; 35.0000; 35.0000; 35.0000];
   <span class="comment">% Trf is a vector of [16X1]</span>
   Trf = [0.0003; 0.0003; 0.0003; 0.0003; 0.0003; 0.0003; 0.0003; 0.0003; 0.0002; 0.0003; 0.0004; 0.0006; 0.0008; 0.0012; 0.0016; 0.0021];
   Model.Prot.MTdata.Mat = [ Alpha Trf];
   <span class="comment">% -----------------------------------------</span>
   </pre><h2 id="7">III- FIT EXPERIMENTAL DATASET</h2><p >-------------------------------------------------------------------------</p><h2 id="8">A- LOAD EXPERIMENTAL DATA</h2><pre >         |- Respective command lines appear if required by qmt_bssfp.
   -------------------------------------------------------------------------
   qmt_bssfp object needs 3 data input(s) to be assigned:</pre><pre class="codeinput"><span class="comment">% MTdata</span>
   <span class="comment">% R1map</span>
   <span class="comment">% Mask</span>
   <span class="comment">% --------------</span>
   
   data = struct();
   <span class="comment">% MTdata.nii.gz contains [128  128    1   16] data.</span>
   data.MTdata=double(load_nii_data(<span class="string">'qmt_bssfp_data/MTdata.nii.gz'</span>));
   <span class="comment">% R1map.nii.gz contains [128  128] data.</span>
   data.R1map=double(load_nii_data(<span class="string">'qmt_bssfp_data/R1map.nii.gz'</span>));
   <span class="comment">% Mask.nii.gz contains [128  128] data.</span>
   data.Mask=double(load_nii_data(<span class="string">'qmt_bssfp_data/Mask.nii.gz'</span>));
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="9">B- FIT DATASET</h2><pre >           |- This section will fit data.
   -------------------------------------------------------------------------</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
   
   FitResults.Model = Model; <span class="comment">% qMRLab output.</span>
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><pre class="codeoutput">Fitting voxel     3/4354
   ...done   0%
   </pre><h2 id="10">C- SHOW FITTING RESULTS</h2><pre >         |- Output map will be displayed.</pre><pre class="codeinput"><span class="comment">%			|- If available, a graph will be displayed to show fitting in a voxel.</span>
   <span class="comment">% -------------------------------------------------------------------------</span>
   
   qMRshowOutput(FitResults,data,Model);
   </pre><img src="_static/qmt_bssfp_batch_02.png" vspace="5" hspace="5" alt=""> <img src="_static/qmt_bssfp_batch_03.png" vspace="5" hspace="5" alt=""> <h2 id="11">IV- SAVE MAPS AND OBJECT</h2><pre class="codeinput">Model.saveObj(<span class="string">'qmt_bssfp_Demo.qmrlab.mat'</span>);
   FitResultsSave_nii(FitResults, <span class="string">'qmt_bssfp_data/MTdata.nii.gz'</span>);
   
   <span class="comment">% Tip: You can load FitResults.mat in qMRLab graphical user interface</span>
   </pre><h2 id="12">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for 'qmt_bssfp.
   -------------------------------------------------------------------------</pre><h2 id="13">A- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
                 (1) use equation to generate synthetic MRI data
                 (2) add rician noise
                 (3) fit and plot curve
   -------------------------------------------------------------------------</pre><pre class="codeinput">      x = struct;
         x.F = 0.1;
         x.kr = 30;
         x.R1f = 1;
         x.R1r = 1;
         x.T2f = 0.04;
         x.M0f = 1;
         <span class="comment">% Get all possible options</span>
         Opt = button2opts(Model.Sim_Single_Voxel_Curve_buttons,1);
         <span class="comment">% run simulation using options `Opt(1)`</span>
         figure(<span class="string">'Name'</span>,<span class="string">'Single Voxel Curve Simulation'</span>);
         FitResult = Model.Sim_Single_Voxel_Curve(x,Opt(1));
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><img src="_static/qmt_bssfp_batch_04.png" vspace="5" hspace="5" alt=""> <h2 id="14">B- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
                   (1) vary fitting parameters from lower (lb) to upper (ub) bound.
                   (2) run Sim_Single_Voxel_Curve Nofruns times
                   (3) Compute mean and std across runs
   -------------------------------------------------------------------------</pre><pre class="codeinput">      <span class="comment">%              F             kr            R1f           R1r           T2f           M0f</span>
         OptTable.st = [0.1           30            1             1             0.04          1]; <span class="comment">% nominal values</span>
         OptTable.fx = [0             1             1             1             1             1]; <span class="comment">%vary F...</span>
         OptTable.lb = [0.0001        0.0001        0.2           0.2           0.01          0.0001]; <span class="comment">%...from 0.0001</span>
         OptTable.ub = [0.3           1e+02         3             3             0.2           2]; <span class="comment">%...to 0.3</span>
         <span class="comment">% Get all possible options</span>
         Opt = button2opts([Model.Sim_Single_Voxel_Curve_buttons, Model.Sim_Sensitivity_Analysis_buttons],1);
         <span class="comment">% run simulation using options `Opt(1)`</span>
         SimResults = Model.Sim_Sensitivity_Analysis(OptTable,Opt(1));
         figure(<span class="string">'Name'</span>,<span class="string">'Sensitivity Analysis'</span>);
         SimVaryPlot(SimResults, <span class="string">'F'</span> ,<span class="string">'F'</span> );
   </pre><img src="_static/qmt_bssfp_batch_05.png" vspace="5" hspace="5" alt=""> <p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017b</a><br ></p></div>
