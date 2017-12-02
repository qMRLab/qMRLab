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
   </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#1">DESCRIPTION</a></li><li ><a href="#2">Load dataset</a></li><li ><a href="#3">Check data and fitting (Optional)</a></li><li ><a href="#4">Create Quantitative Maps</a></li><li ><a href="#5">Check the results</a></li></ul></div><h2 id="1">DESCRIPTION</h2><pre class="codeinput">help <span class="string">bSSFP</span>
   
   <span class="comment">% Batch to process bSSFP_modulaire data without qMRLab GUI (graphical user interface)</span>
   <span class="comment">% Run this script line by line</span>
   <span class="comment">% Written by: Ian Gagnon, 2017</span>
   </pre><pre class="codeoutput"> -----------------------------------------------------------------------------------------------------
     bSSFP : qMT using Balanced Steady State Free Precession acquisition
    -----------------------------------------------------------------------------------------------------
    -------------%
     ASSUMPTIONS %
    -------------% 
     (1) FILL
     (2) 
     (3) 
     (4) 
    
    -----------------------------------------------------------------------------------------------------
    --------%
     INPUTS %
    --------%
       1) MTdata : Magnetization Transfert data
       2) R1map  : 1/T1map (OPTIONAL but RECOMMANDED Boudreau 2017 MRM)
       3) Mask   : Binary mask to accelerate the fitting (OPTIONAL)
    
    -----------------------------------------------------------------------------------------------------
    ---------%
     OUTPUTS %
    ---------%
       Fitting Parameters
           * F   : Ratio of number of restricted pool to free pool, defined 
                   as F = M0r/M0f = kf/kr.
           * kr  : Exchange rate from the free to the restricted pool 
                   (note that kf and kr are related to one another via the 
                   definition of F. Changing the value of kf will change kr 
                   accordingly, and vice versa).
           * R1f : Longitudinal relaxation rate of the free pool 
                   (R1f = 1/T1f).
           * R1r : Longitudinal relaxation rate of the restricted pool 
                   (R1r = 1/T1r).
           * T2f : Tranverse relaxation time of the free pool (T2f = 1/R2f).
           * M0f : Equilibrium value of the free pool longitudinal 
                   magnetization.
    
       Additional Outputs
           * M0r    : Equilibrium value of the restricted pool longitudinal 
                      magnetization.
           * kf     : Exchange rate from the restricted to the free pool.
           * resnorm: Fitting residual.
    
    -----------------------------------------------------------------------------------------------------
    ----------%
     PROTOCOL %
    ----------%
       MTdata
           * Alpha : Flip angle of the RF pulses (degree)
           * Trf   : Duration of the RF pulses (s)
    
    -----------------------------------------------------------------------------------------------------
    ---------%
     OPTIONS %
    ---------%
       RF Pulse
           * Shape          : Shape of the RF pulses.
                              Available shapes are:
                              - hard
                              - gaussian
                              - gausshann (gaussian pulse with Hanning window)
                              - sinc
                              - sinchann (sinc pulse with Hanning window)
                              - singauss (sinc pulse with gaussian window)
                              - fermi
           * # of RF pulses : Number of RF pulses applied before readout.
    
       Protocol Timing
           * Fix TR        : Select this option and enter a value in the text 
                             box below to set a fixed repetition time.
           * Fix TR - Trf  : Select this option and enter a value in the text 
                             box below to set a fixed free precession time
                             (TR - Trf).
           * Prepulse      : Perform an Alpha/2 - TR/2 prepulse before each 
                             series of RF pulses.
    
       R1
           * Use R1map to  : By checking this box, you tell the fitting 
             constrain R1f   algorithm to check for an observed R1map and use
                             its value to constrain R1f. Checking this box 
                             will automatically set the R1f fix box to true in            
                             the Fit parameters table.                
           * Fix R1r = R1f : By checking this box, you tell the fitting
                             algorithm to fix R1r equal to R1f. Checking this 
                             box will automatically set the R1r fix box to 
                             true in the Fit parameters table.
    
       Global
           * G(0)          : The assumed value of the absorption lineshape of
                             the restricted pool.
    
    -----------------------------------------------------------------------------------------------------
     Written by: Ian Gagnon, 2017
     Reference: FILL
    -----------------------------------------------------------------------------------------------------
   
       Reference page in Doc Center
          doc bSSFP
   
   
   </pre><h2 id="2">Load dataset</h2><pre class="codeinput">[pathstr,fname,ext]=fileparts(which(<span class="string">'bSSFP_batch.m'</span>));
   cd (pathstr);
   
   <span class="comment">% Load your parameters to create your Model</span>
   <span class="comment">% load('MODELPamameters.mat');</span>
   <span class="comment">%load('bSSFPParameters.mat');</span>
   Model = bSSFP
   </pre><pre class="codeoutput">
   Model = 
   
     bSSFP with properties:
   
                              MRIinputs: {'MTdata'  'R1map'  'Mask'}
                                 xnames: {'F'  'kr'  'R1f'  'R1r'  'T2f'  'M0f'}
                              voxelwise: 1
                                     st: [0.1000 30 1 1 0.0400 1]
                                     lb: [0 0 0.2000 0.2000 0.0100 0]
                                     ub: [0.3000 100 3 3 0.2000 2]
                                     fx: [0 0 1 1 0 0]
                                   Prot: [11 struct]
                                buttons: {125 cell}
                                options: [11 struct]
         Sim_Single_Voxel_Curve_buttons: {16 cell}
       Sim_Sensitivity_Analysis_buttons: {'# of run'  [5]}
   
   </pre><h2 id="3">Check data and fitting (Optional)</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- GENERATE FILE STRUCT</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "file" that contains the NAME of all data's FILES</span>
   <span class="comment">% file.DATA = 'DATA_FILE';</span>
   file = struct;
   file.MTdata = <span class="string">'MTdata.nii.gz'</span>;
   file.R1map = <span class="string">'R1map.nii.gz'</span>;
   file.Mask = <span class="string">'Mask.nii.gz'</span>;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% II- CHECK DATA AND FITTING</span>
   <span class="comment">%**************************************************************************</span>
   qMRLab(Model,file);
   </pre><img src="_static/bSSFP_batch_01.png" vspace="5" hspace="5" alt=""> <img src="_static/bSSFP_batch_02.png" vspace="5" hspace="5" alt=""> <h2 id="4">Create Quantitative Maps</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- LOAD PROTOCOL</span>
   <span class="comment">%**************************************************************************</span>
   
   <span class="comment">% MTdata</span>
   Alpha = [ 5      ; 10     ; 15     ; 20     ; 25     ; 30     ; 35     ; 40     ; 35     ; 35     ; 35     ; 35     ; 35     ; 35     ; 35    ; 35     ];
   Trf   = [ 2.7e-4 ; 2.7e-4 ; 2.7e-4 ; 2.7e-4 ; 2.7e-4 ; 2.7e-4 ; 2.7e-4 ; 2.7e-4 ; 2.3e-4 ; 3.0e-4 ; 4.0e-4 ; 5.8e-4 ; 8.4e-4 ; 0.0012 ;0.0012 ; 0.0021 ];
   Model.Prot.MTdata.Mat = [Alpha,Trf];
   <span class="comment">% *** To change other option, go directly in qMRLab ***</span>
   
   <span class="comment">% Use R1map to constrain R1f and R1r</span>
   Model.options.R1_UseR1maptoconstrainR1f=true;
   Model.options.R1_FixR1rR1f = true;
   <span class="comment">% Update the model</span>
   Model = Model.UpdateFields;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% II- LOAD EXPERIMENTAL DATA</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "data" that contains all the data</span>
   <span class="comment">% .MAT file : load('DATA_FILE');</span>
   <span class="comment">%             data.DATA = double(DATA);</span>
   <span class="comment">% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));</span>
   data = struct;
   data.MTdata = double(load_nii_data(<span class="string">'MTdata.nii.gz'</span>));
   data.R1map = double(load_nii_data(<span class="string">'R1map.nii.gz'</span>));
   data.Mask   = double(load_nii_data(<span class="string">'Mask.nii.gz'</span>));
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% III- FIT DATASET</span>
   <span class="comment">%**************************************************************************</span>
   FitResults       = FitData(data,Model,1); <span class="comment">% 3rd argument plots a waitbar</span>
   delete(<span class="string">'FitTempResults.mat'</span>);
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% IV- CHECK FITTING RESULT IN A VOXEL</span>
   <span class="comment">%**************************************************************************</span>
   figure
   voxel           = [50, 70, 1];
   FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
   dataVox         = extractvoxel(data,voxel);
   Model.plotmodel(FitResultsVox,dataVox)
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% V- SAVE</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% .MAT file : FitResultsSave_mat(FitResults,folder);</span>
   <span class="comment">% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);</span>
   FitResultsSave_nii(FitResults,<span class="string">'MTdata.nii.gz'</span>);
   save(<span class="string">'bSSFPParameters.mat'</span>,<span class="string">'Model'</span>);
   </pre><pre class="codeoutput">Warning: Directory already exists. 
   </pre><img src="_static/bSSFP_batch_03.png" vspace="5" hspace="5" alt=""> <h2 id="5">Check the results</h2><p >Load them in qMRLab</p><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017a</a><br ></p></div>
