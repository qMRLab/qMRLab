MTV_batch_example
=================

.. raw:: html

   
   
   <!DOCTYPE html
     PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
   <html><head>
         <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <!--
   This HTML was auto-generated from MATLAB code.
   To make changes, update the MATLAB code and republish this document.
         --><title>MTV_batch</title><meta name="generator" content="MATLAB 9.2"><link rel="schema.DC" href="http://purl.org/dc/elements/1.1/"><meta name="DC.date" content="2017-10-12"><meta name="DC.source" content="MTV_batch.m"><style type="text/css">
   html,body,div,span,applet,object,iframe,h1,h2,h3,h4,h5,h6,p,blockquote,pre,a,abbr,acronym,address,big,cite,code,del,dfn,em,font,img,ins,kbd,q,s,samp,small,strike,strong,sub,sup,tt,var,b,u,i,center,dl,dt,dd,ol,ul,li,fieldset,form,label,legend,table,caption,tbody,tfoot,thead,tr,th,td{margin:0;padding:0;border:0;outline:0;font-size:100%;vertical-align:baseline;background:transparent}body{line-height:1}ol,ul{list-style:none}blockquote,q{quotes:none}blockquote:before,blockquote:after,q:before,q:after{content:'';content:none}:focus{outine:0}ins{text-decoration:none}del{text-decoration:line-through}table{border-collapse:collapse;border-spacing:0}
   
   html { min-height:100%; margin-bottom:1px; }
   html body { height:100%; margin:0px; font-family:Arial, Helvetica, sans-serif; font-size:10px; color:#000; line-height:140%; background:#fff none; overflow-y:scroll; }
   html body td { vertical-align:top; text-align:left; }
   
   h1 { padding:0px; margin:0px 0px 25px; font-family:Arial, Helvetica, sans-serif; font-size:1.5em; color:#d55000; line-height:100%; font-weight:normal; }
   h2 { padding:0px; margin:0px 0px 8px; font-family:Arial, Helvetica, sans-serif; font-size:1.2em; color:#000; font-weight:bold; line-height:140%; border-bottom:1px solid #d6d4d4; display:block; }
   h3 { padding:0px; margin:0px 0px 5px; font-family:Arial, Helvetica, sans-serif; font-size:1.1em; color:#000; font-weight:bold; line-height:140%; }
   
   a { color:#005fce; text-decoration:none; }
   a:hover { color:#005fce; text-decoration:underline; }
   a:visited { color:#004aa0; text-decoration:none; }
   
   p { padding:0px; margin:0px 0px 20px; }
   img { padding:0px; margin:0px 0px 20px; border:none; }
   p img, pre img, tt img, li img, h1 img, h2 img { margin-bottom:0px; } 
   
   ul { padding:0px; margin:0px 0px 20px 23px; list-style:square; }
   ul li { padding:0px; margin:0px 0px 7px 0px; }
   ul li ul { padding:5px 0px 0px; margin:0px 0px 7px 23px; }
   ul li ol li { list-style:decimal; }
   ol { padding:0px; margin:0px 0px 20px 0px; list-style:decimal; }
   ol li { padding:0px; margin:0px 0px 7px 23px; list-style-type:decimal; }
   ol li ol { padding:5px 0px 0px; margin:0px 0px 7px 0px; }
   ol li ol li { list-style-type:lower-alpha; }
   ol li ul { padding-top:7px; }
   ol li ul li { list-style:square; }
   
   .content { font-size:1.2em; line-height:140%; padding: 20px; }
   
   pre, code { font-size:12px; }
   tt { font-size: 1.2em; }
   pre { margin:0px 0px 20px; }
   pre.codeinput { padding:10px; border:1px solid #d3d3d3; background:#f7f7f7; }
   pre.codeoutput { padding:10px 11px; margin:0px 0px 20px; color:#4c4c4c; }
   pre.error { color:red; }
   
   @media print { pre.codeinput, pre.codeoutput { word-wrap:break-word; width:100%; } }
   
   span.keyword { color:#0000FF }
   span.comment { color:#228B22 }
   span.string { color:#A020F0 }
   span.untermstring { color:#B20000 }
   span.syscmd { color:#B28C00 }
   
   .footer { width:auto; padding:10px 0px; margin:25px 0px 0px; border-top:1px dotted #878787; font-size:0.8em; line-height:140%; font-style:italic; color:#878787; text-align:left; float:none; }
   .footer p { margin:0px; }
   .footer a { color:#878787; }
   .footer a:hover { color:#878787; text-decoration:underline; }
   .footer a:visited { color:#878787; }
   
   table th { padding:7px 5px; text-align:left; vertical-align:middle; border: 1px solid #d6d4d4; font-weight:bold; }
   table td { padding:7px 5px; text-align:left; vertical-align:top; border:1px solid #d6d4d4; }
   
   
   
   
   
     </style></head><body><div class="content"><h2>Contents</h2><div><ul><li><a href="#2">Load dataset</a></li><li><a href="#3">Check data and fitting (Optional)</a></li><li><a href="#4">Create Quantitative Maps</a></li><li><a href="#5">Check the results</a></li></ul></div><pre class="codeinput"><span class="comment">% Batch to process MTV data without qMRLab GUI (graphical user interface)</span>
   <span class="comment">% Run this script line by line</span>
   <span class="comment">% Written by: Ian Gagnon, 2017</span>
   </pre><h2 id="2">Load dataset</h2><pre class="codeinput">[pathstr,fname,ext]=fileparts(which(<span class="string">'MTV_batch.m'</span>));
   cd (pathstr);
   
   <span class="comment">% Load your parameters to create your Model</span>
   <span class="comment">% load('MODELPamameters.mat');</span>
   load(<span class="string">'MTVParameters.mat'</span>);
   </pre><h2 id="3">Check data and fitting (Optional)</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- GENERATE FILE STRUCT</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "file" that contains the NAME of all data's FILES</span>
   <span class="comment">% file.DATA = 'DATA_FILE';</span>
   file = struct;
   file.SPGR = <span class="string">'SPGR.mat'</span>;
   file.B1map = <span class="string">'B1map.mat'</span>;
   file.CSFMask = <span class="string">'CSFMask.mat'</span>;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% II- CHECK DATA AND FITTING</span>
   <span class="comment">%**************************************************************************</span>
   qMRLab(Model,file);
   </pre><img vspace="5" hspace="5" src="_static/MTV_batch_01.png" alt=""> <img vspace="5" hspace="5" src="_static/MTV_batch_02.png" alt=""> <h2 id="4">Create Quantitative Maps</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- LOAD PROTOCOL</span>
   <span class="comment">%**************************************************************************</span>
   
   <span class="comment">% Echo (time in millisec)</span>
   FlipAngle = [ 4 ; 10 ; 20];
   TR        = 0.025 * ones(length(FlipAngle),1);
   Model.Prot.MTV.Mat = [ FlipAngle , TR ];
   
   <span class="comment">% Update the model</span>
   Model = Model.UpdateFields;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% II- LOAD EXPERIMENTAL DATA</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "data" that contains all the data</span>
   <span class="comment">% .MAT file : load('DATA_FILE');</span>
   <span class="comment">%             data.DATA = double(DATA);</span>
   <span class="comment">% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));</span>
   load(<span class="string">'SPGR.mat'</span>);
   data.SPGR    = double(SPGR);
   load(<span class="string">'B1map.mat'</span>);
   data.B1map   = double(B1map);
   load(<span class="string">'CSFMask.mat'</span>);
   data.CSFMask = double(CSFMask);
   
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% III- FIT DATASET</span>
   <span class="comment">%**************************************************************************</span>
   FitResults       = FitData(data,Model);
   FitResults.Model = Model;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% IV- SAVE</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% .MAT file : FitResultsSave_mat(FitResults,folder);</span>
   <span class="comment">% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);</span>
   FitResultsSave_mat(FitResults);
   save(<span class="string">'Parameters.mat'</span>,<span class="string">'Model'</span>);
   </pre><pre class="codeoutput error">Reference to non-existent field 'CoilGain_Fitting_Polynomial'.
   
   Error in MTV/UpdateFields (line 73)
               if obj.options.CoilGain_Fitting_Polynomial &amp;&amp; obj.options.CoilGain_Fitting_Spline
   
   Error in MTV_batch (line 44)
   Model = Model.UpdateFields;
   </pre><h2 id="5">Check the results</h2><p>Load them in qMRLab</p><p class="footer"><br><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB&reg; R2017a</a><br></p></div><!--
   ##### SOURCE BEGIN #####
   % Batch to process MTV data without qMRLab GUI (graphical user interface)
   % Run this script line by line
   % Written by: Ian Gagnon, 2017
   
   %% Load dataset
   
   [pathstr,fname,ext]=fileparts(which('MTV_batch.m'));
   cd (pathstr);
   
   % Load your parameters to create your Model
   % load('MODELPamameters.mat');
   load('MTVParameters.mat');
   
   %% Check data and fitting (Optional)
   
   %**************************************************************************
   % I- GENERATE FILE STRUCT
   %**************************************************************************
   % Create a struct "file" that contains the NAME of all data's FILES
   % file.DATA = 'DATA_FILE';
   file = struct;
   file.SPGR = 'SPGR.mat';
   file.B1map = 'B1map.mat';
   file.CSFMask = 'CSFMask.mat';
   
   %**************************************************************************
   % II- CHECK DATA AND FITTING
   %**************************************************************************
   qMRLab(Model,file);
   
   
   %% Create Quantitative Maps
   
   %**************************************************************************
   % I- LOAD PROTOCOL
   %**************************************************************************
   
   % Echo (time in millisec)
   FlipAngle = [ 4 ; 10 ; 20];
   TR        = 0.025 * ones(length(FlipAngle),1);
   Model.Prot.MTV.Mat = [ FlipAngle , TR ];
   
   % Update the model
   Model = Model.UpdateFields;
   
   %**************************************************************************
   % II- LOAD EXPERIMENTAL DATA
   %**************************************************************************
   % Create a struct "data" that contains all the data
   % .MAT file : load('DATA_FILE');
   %             data.DATA = double(DATA);
   % .NII file : data.DATA = double(load_nii_data('DATA_FILE'));
   load('SPGR.mat');
   data.SPGR    = double(SPGR);
   load('B1map.mat');
   data.B1map   = double(B1map);
   load('CSFMask.mat');
   data.CSFMask = double(CSFMask);
   
   
   %**************************************************************************
   % III- FIT DATASET
   %**************************************************************************
   FitResults       = FitData(data,Model);
   FitResults.Model = Model;
   
   %**************************************************************************
   % IV- SAVE
   %**************************************************************************
   % .MAT file : FitResultsSave_mat(FitResults,folder);
   % .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
   FitResultsSave_mat(FitResults);
   save('Parameters.mat','Model');
   
   %% Check the results
   % Load them in qMRLab
   
   ##### SOURCE END #####
   --></body></html>