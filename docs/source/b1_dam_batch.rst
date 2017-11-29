B1_DAM map:  Double-Angle Method for B1+ mapping
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
   </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#3">DESCRIPTION</a></li><li ><a href="#4">Load dataset</a></li><li ><a href="#5">Check data and fitting (Optional)</a></li><li ><a href="#6">Create Quantitative Maps</a></li><li ><a href="#7">Check the results</a></li><li ><a href="#8">AUXILIARY SECTION - (OPTIONAL) -----------------------------------------</a></li><li ><a href="#9">STEP|CREATE MODEL OBJECT -----------------------------------------------</a></li><li ><a href="#10">STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------</a></li><li ><a href="#11">STEP |LOAD PROTOCOL ----------------------------------------------------</a></li><li ><a href="#12">STEP |LOAD EXPERIMENTAL DATA -------------------------------------------</a></li><li ><a href="#13">STEP |FIT DATASET ------------------------------------------------------</a></li><li ><a href="#14">STEP |CHECK FITTING RESULT IN A VOXEL - (OPTIONAL) ---------------------</a></li><li ><a href="#15">STEP |SAVE -------------------------------------------------------------</a></li></ul></div><pre class="codeinput"> HEAD
   </pre><pre class="codeinput"><span class="comment">%Place in the right folder to run</span>
   cdmfile(<span class="string">'B1_DAM_batch.m'</span>);
   
   warning(<span class="string">'off'</span>,<span class="string">'all'</span>);
   </pre><h2 id="3">DESCRIPTION</h2><pre class="codeinput">help <span class="string">B1_DAM</span>
   <span class="comment">% Batch to generate B1map with Double-Angle Method (DAM) without qMRLab GUI (graphical user interface)</span>
   <span class="comment">% Run this script line by line</span>
   <span class="comment">% Written by: Ian Gagnon, 2017</span>
   </pre><h2 id="4">Load dataset</h2><p >Load your parameters to create your Model load('MODELPamameters.mat');</p><pre class="codeinput">load(<span class="string">'B1_DAMParameters.mat'</span>);
   </pre><h2 id="5">Check data and fitting (Optional)</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- GENERATE FILE STRUCT</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "file" that contains the NAME of all data's FILES</span>
   <span class="comment">% file.DATA = 'DATA_FILE';</span>
   file = struct;
   file.SF60 = <span class="string">'SF60.nii.gz'</span>;
   file.SF120 = <span class="string">'SF120.nii.gz'</span>;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% II- CHECK DATA AND FITTING</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">%qMRLab(Model,file);</span>
   </pre><h2 id="6">Create Quantitative Maps</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- LOAD EXPERIMENTAL DATA</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "data" that contains all the data</span>
   <span class="comment">% .MAT file : load('DATA_FILE');</span>
   <span class="comment">%             data.DATA = double(DATA);</span>
   <span class="comment">% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));</span>
   data.SF60 = double(load_nii_data(<span class="string">'SF60.nii.gz'</span>));
   data.SF120  = double(load_nii_data(<span class="string">'SF120.nii.gz'</span>));
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% II- FIT DATASET</span>
   <span class="comment">%**************************************************************************</span>
   FitResults       = FitData(data,Model,1); <span class="comment">% 3rd argument plots a waitbar</span>
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% III- SAVE</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% .MAT file : FitResultsSave_mat(FitResults,folder);</span>
   <span class="comment">% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);</span>
   FitResultsSave_nii(FitResults,<span class="string">'SF60.nii.gz'</span>);
   <span class="comment">%save('Parameters.mat','Model');</span>
   </pre><h2 id="7">Check the results</h2><p >Load them in qMRLab</p><pre class="codeinput">=======
   <span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
   <span class="comment">% purposes and Octave.</span>
   
   <span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
   <span class="comment">% processing for b1_dam on CLI.</span>
   
   <span class="comment">% This m-file has been automatically generated.</span>
   
   <span class="comment">% Written by: Agah Karakuzu, 2017</span>
   <span class="comment">% =========================================================================</span>
   </pre><h2 id="8">AUXILIARY SECTION - (OPTIONAL) -----------------------------------------</h2><p >-------------------------------------------------------------------------</p><pre class="codeinput">qMRinfo(<span class="string">'b1_dam'</span>); <span class="comment">% Display help</span>
   [pathstr,fname,ext]=fileparts(which(<span class="string">'b1_dam_batch.m'</span>));
   cd (pathstr);
   </pre><h2 id="9">STEP|CREATE MODEL OBJECT -----------------------------------------------</h2><pre >(1) |- This section is a one-liner.
   -------------------------------------------------------------------------</pre><pre class="codeinput">Model = b1_dam; <span class="comment">% Create model object</span>
   </pre><h2 id="10">STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------</h2><pre >(2)	|- This section will pop-up the options GUI. (MATLAB Only)</pre><pre class="codeinput"><span class="comment">%		|- Octave is not GUI compatible.</span>
   <span class="comment">% -------------------------------------------------------------------------</span>
   
   <span class="keyword">if</span> not(moxunit_util_platform_is_octave) <span class="comment">% --- If MATLAB</span>
   Custom_OptionsGUI(Model);
   Model = getappdata(0,<span class="string">'Model'</span>);
   <span class="keyword">end</span>
   </pre><h2 id="11">STEP |LOAD PROTOCOL ----------------------------------------------------</h2><pre >(3)	|- Respective command lines appear if required by b1_dam.
   -------------------------------------------------------------------------</pre><pre class="codeinput"><span class="comment">% This object does not have protocol attributes.</span>
   </pre><h2 id="12">STEP |LOAD EXPERIMENTAL DATA -------------------------------------------</h2><pre >(4)	|- Respective command lines appear if required by b1_dam.
   -------------------------------------------------------------------------
   b1_dam object needs 2 data input(s) to be assigned:</pre><pre class="codeinput"><span class="comment">% SF60</span>
   <span class="comment">% SF120</span>
   <span class="comment">% --------------</span>
   
   data = struct();
   <span class="comment">% SF120.nii.gz contains [64  64] data.</span>
   data.SF120=double(load_nii_data(<span class="string">'SF120.nii.gz'</span>));
   <span class="comment">% SF60.nii.gz contains [64  64] data.</span>
   data.SF60=double(load_nii_data(<span class="string">'SF60.nii.gz'</span>));
   </pre><h2 id="13">STEP |FIT DATASET ------------------------------------------------------</h2><pre >(5)  |- This section will fit data.
   -------------------------------------------------------------------------</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
   
   FitResults.Model = Model; <span class="comment">% qMRLab output.</span>
   </pre><h2 id="14">STEP |CHECK FITTING RESULT IN A VOXEL - (OPTIONAL) ---------------------</h2><pre class="language-matlab">(6)	|- To observe <span class="string">outputs</span>, please <span class="string">execute</span> <span class="string">this</span> <span class="string">section.</span>
   -------------------------------------------------------------------------
   </pre><pre class="codeinput"><span class="comment">% Read output  ---</span>
   <span class="comment">%{
   </span><span class="comment">outputIm = FitResults.(FitResults.fields{1});
   </span><span class="comment">row = round(size(outputIm,1)/2);
   </span><span class="comment">col = round(size(outputIm,2)/2);
   </span><span class="comment">voxel           = [row, col, 1]; % Please adapt 3rd index if 3D.
   </span><span class="comment">%}
   </span>
   <span class="comment">% Show plot  ---</span>
   <span class="comment">% Warning: This part may not be available for all models.</span>
   <span class="comment">%{
   </span><span class="comment">figure();
   </span><span class="comment">FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
   </span><span class="comment">dataVox         = extractvoxel(data,voxel);
   </span><span class="comment">Model.plotModel(FitResultsVox,dataVox)
   </span><span class="comment">%}
   </span>
   <span class="comment">% Show output map ---</span>
   <span class="comment">%{
   </span><span class="comment">figure();
   </span><span class="comment">imagesc(outputIm); colorbar(); title(FitResults.fields{1});
   </span><span class="comment">%}</span>
   </pre><h2 id="15">STEP |SAVE -------------------------------------------------------------</h2><pre >	(7) |- Save your outputs.
   -------------------------------------------------------------------------</pre><pre class="codeinput"><span class="keyword">if</span> moxunit_util_platform_is_octave <span class="comment">% --- If Octave</span>
   
   save <span class="string">-mat7-binary</span> <span class="string">'b1_dam_FitResultsOctave.mat'</span> <span class="string">'FitResults'</span>;
   
   <span class="keyword">else</span> <span class="comment">% --- If MATLAB</span>
   
   qMRsaveModel(Model,<span class="string">'b1_dam.qMRLab.mat'</span>);
   
   <span class="keyword">end</span>
   
   <span class="comment">% You can save outputs in Nifti format using FitResultSave_nii function:</span>
   <span class="comment">% Plase see qMRinfo('FitResultsSave_nii')</span>
   </pre><pre class="codeinput"> 2ee6d2dbaf24f87e1f346d1412f3361c6f9206e2
   </pre><pre class="codeoutput error">Error using dbstatus
   Error: File: C:\Users\gab_b\Desktop\NeuroPoly\qMRLab\Data\B1_DAM_demo\B1_DAM_batch.m Line: 1 Column: 1
   Unexpected MATLAB operator.
   </pre><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017a</a><br ></p></div>
