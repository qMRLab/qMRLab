MTSAT :  Correction of Magnetization transfer for RF inhomogeneities and T1
===========================================================================

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
   </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#1">DESCRIPTION</a></li><li ><a href="#2">I- LOAD DATASET</a></li><li ><a href="#3">II - MRI Data Fitting</a></li><li ><a href="#4">III- SAVE</a></li><li ><a href="#5">Check the results</a></li></ul></div><h2 id="1">DESCRIPTION</h2><pre class="codeinput">help <span class="string">MTSAT</span>
   
   <span class="comment">% Batch to process MT_SAT</span>
   <span class="comment">% Run this script line by line</span>
   </pre><pre class="codeoutput">  MTSAT :  Correction of Magnetization transfer for RF inhomogeneities and T1
    
     Assumptions:
       MTsat is a semi-quantitative method. MTsat values depend on protocol parameters.
    
     Inputs:
       MTw     3D MT-weighted data
       T1w     3D T1-weighted data
       PDw     3D PD-weighted data
    
     Outputs:
       MTSAT   MT saturation map, T1-corrected
    
     Options:
    
     Protocol:
       3 vectors
         MT    [FA  TR  Offset] %acquisition flip angle [deg], TR [s], Offset Frequency [Hz]
         T1    [FA  TR]  %flip angle [deg], TR [s]
         PD    [FA  TR]  %flip angle [deg], TR [s]
    
     Example of command line usage (see also a href="matlab: showdemo MTSAT_batch"showdemo MTSAT_batch/a):
       Model = MTSAT;  % Create class from model
       Model.Prot.PD.Mat = [6  28e-3]; % FA, TR
       Model.Prot.MT.Mat = [6  28e-3 1000]; % FA, TR, Offset
       Model.Prot.T1.Mat = [20 18e-3]; % FA, TR
       data = struct;  % Create data structure
       data.MTw = load_nii_data('MTw.nii.gz');
       data.T1w = load_nii_data('T1w.nii.gz');
       data.PDw = load_nii_data('PDw.nii.gz');  % Load data
       FitResults = FitData(data,Model); %fit data
       FitResultsSave_nii(FitResults,'MTw.nii.gz'); % Save in local folder: FitResults/
    
       For more examples: a href="matlab: qMRusage(MTSAT);"qMRusage(MTSAT)/a
    
     Author: Pascale Beliveau (pascale.beliveau@polymtl.ca)
    
     References:
       Please cite the following if you use this module:
         Helms, G., Dathe, H., Kallenberg, K., Dechent, P., 2008. High-resolution maps of magnetization transfer with inherent correction for RF inhomogeneity and T1 relaxation obtained from 3D FLASH MRI. Magn. Reson. Med. 60, 1396?1407.
       In addition to citing the package:
         Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
   
       Reference page in Doc Center
          doc MTSAT
   
   
   </pre><h2 id="2">I- LOAD DATASET</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   [pathstr,fname,ext]=fileparts(which(<span class="string">'MTSAT_batch.m'</span>));
   cd (pathstr);
   
   <span class="comment">% Create Model object</span>
   Model = MTSAT;
   <span class="comment">% Define Protocol</span>
   disp(Model.Prot.PD.Format)
   Model.Prot.PD.Mat = [6  28e-3]; <span class="comment">% FA, TR</span>
   Model.Prot.MT.Mat = [6  28e-3 1000]; <span class="comment">% FA, TR, Offset</span>
   Model.Prot.T1.Mat = [20 18e-3]; <span class="comment">% FA, TR</span>
   
   <span class="comment">%**************************************************************************</span>
   </pre><pre class="codeoutput">    'Flip Angle'    'TR'
   
   </pre><h2 id="3">II - MRI Data Fitting</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% list required inputs</span>
   disp(Model.MRIinputs)
   <span class="comment">% load data</span>
   data = struct;
   data.MTw = load_nii_data(<span class="string">'MTw.nii.gz'</span>);
   data.T1w = load_nii_data(<span class="string">'T1w.nii.gz'</span>);
   data.PDw = load_nii_data(<span class="string">'PDw.nii.gz'</span>);
   
   <span class="comment">% plot fit in one voxel</span>
   FitResults = FitData(data,Model);
   delete(<span class="string">'FitTempResults.mat'</span>);
   
   <span class="comment">%**************************************************************************</span>
   </pre><pre class="codeoutput">    'MTw'    'T1w'    'PDw'    'Mask'
   
   Warning: File 'FitTempResults.mat' not found. 
   Warning: File 'FitTempResults.mat' not found. 
   </pre><h2 id="4">III- SAVE</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% .MAT file : FitResultsSave_mat(FitResults,folder);</span>
   <span class="comment">% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);</span>
   FitResultsSave_nii(FitResults,<span class="string">'MTw.nii.gz'</span>);
   save(<span class="string">'MTSATParameters.mat'</span>,<span class="string">'Model'</span>);
   </pre><pre class="codeoutput">Warning: Directory already exists. 
   </pre><h2 id="5">Check the results</h2><p >Load them in qMRLab</p><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017a</a><br ></p></div>
