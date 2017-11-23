B1_DAM
======

.. raw:: html

   
   <div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#1">DESCRIPTION</a></li><li ><a href="#2">Load dataset</a></li><li ><a href="#3">Check data and fitting (Optional)</a></li><li ><a href="#4">Create Quantitative Maps</a></li><li ><a href="#5">Check the results</a></li></ul></div><h2 id="1">DESCRIPTION</h2><pre class="codeinput">help <span class="string">B1_DAM</span>
   <span class="comment">% Batch to generate B1map with Double-Angle Method (DAM) without qMRLab GUI (graphical user interface)</span>
   <span class="comment">% Run this script line by line</span>
   <span class="comment">% Written by: Ian Gagnon, 2017</span>
   </pre><pre class="codeoutput">  B1_DAM map:  Double-Angle Method for B1+ mapping
    
     Assumptions:
       Compute a B1map using 2 SPGR images with 2 different flip angles (60, 120deg)
    
     Inputs:
       SF60            SPGR data at a flip angle of 60 degree
       SF120           SPGR data at a flip angle of 120 degree
    
     Outputs:
    	B1map           Excitation (B1+) field map
    
     Protocol:
    	NONE
    
     Options
       NONE
    
     Example of command line usage (see also a href="matlab: showdemo B1_DAM_batch"showdemo B1_DAM_batch/a):
       Model = B1_DEM;% Create class from model 
       data.SF60 = double(load_nii_data('SF60.nii.gz')); %load data
       data.SF120  = double(load_nii_data('SF120.nii.gz'));
       FitResults       = FitData(data,Model); % fit data
       FitResultsSave_nii(FitResults,'SF60.nii.gz'); %save nii file using SF60.nii.gz as template
    
       For more examples: a href="matlab: qMRusage(B1_DAM);"qMRusage(B1_DAM)/a
    
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
   
       Reference page in Doc Center
          doc B1_DAM
   
   
   </pre><h2 id="2">Load dataset</h2><pre class="codeinput">[pathstr,fname,ext]=fileparts(which(<span class="string">'B1_DAM_batch.m'</span>));
   cd (pathstr);
   
   <span class="comment">% Load your parameters to create your Model</span>
   <span class="comment">% load('MODELPamameters.mat');</span>
   load(<span class="string">'B1_DAMParameters.mat'</span>);
   </pre><h2 id="3">Check data and fitting (Optional)</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
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
   </pre><h2 id="4">Create Quantitative Maps</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
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
   </pre><pre class="codeoutput">Warning: File 'FitTempResults.mat' not found. 
   Warning: Directory already exists. 
   </pre><h2 id="5">Check the results</h2><p >Load them in qMRLab</p><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017a</a><br ></p></div>
