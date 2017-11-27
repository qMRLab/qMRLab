mwf :  Myelin Water Fraction from Multi-Exponential T2w data
============================================================

.. raw:: html
	pre {		white-space: pre-wrap;       /* css-3 */
		white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */
		white-space: -pre-wrap;      /* Opera 4-6 */
		white-space: -o-pre-wrap;    /* Opera 7 */
		word-wrap: break-word;       /* Internet Explorer 5.5+ */
		)}

   
   <div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">DESCRIPTION</a></li><li ><a href="#3">Load dataset</a></li><li ><a href="#4">Check data and fitting (Optional)</a></li><li ><a href="#5">Create Quantitative Maps</a></li><li ><a href="#6">Check the results</a></li></ul></div><pre class="codeinput">warning(<span class="string">'off'</span>,<span class="string">'all'</span>);
   </pre><h2 id="2">DESCRIPTION</h2><pre class="codeinput">help <span class="string">MWF</span>
   
   <span class="comment">% Batch to process MWF data without qMRLab GUI (graphical user interface)</span>
   <span class="comment">% Run this script line by line</span>
   <span class="comment">% Written by: Ian Gagnon, 2017</span>
   </pre><pre class="codeoutput">  MWF :  Myelin Water Fraction from Multi-Exponential T2w data
    
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
       Vector [1 x nbTEs]:
         [TE1 TE2 ...]     list of echo times [ms]
    
     Example of command line usage (see also a href="matlab: showdemo MWF_batch"showdemo MWF_batch/a):
       Model = MWF;  % Create class from model 
       Model.Prot.Echo.Mat=[10:10:320];
       data = struct;  % Create data structure 
       data.MET2data ='MET2data.mat';  % Load data
       data.Mask = 'Mask.mat';
       FitResults = FitData(data,Model); %fit data
       FitResultsSave_mat(FitResults);
    
           For more examples: a href="matlab: qMRusage(MWF);"qMRusage(MWF)/a
    
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
          doc MWF
   
   
   </pre><h2 id="3">Load dataset</h2><pre class="codeinput">[pathstr,fname,ext]=fileparts(which(<span class="string">'MWF_batch.m'</span>));
   cd (pathstr);
   
   <span class="comment">% Load your parameters to create your Model</span>
   <span class="comment">% load('MWFPamameters.mat');</span>
   Model = MWF;
   </pre><h2 id="4">Check data and fitting (Optional)</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- GENERATE FILE STRUCT</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "file" that contains the NAME of all data's FILES</span>
   <span class="comment">% file.DATA = 'DATA_FILE';</span>
   file = struct;
   file.MET2data = <span class="string">'MET2data.mat'</span>;
   file.Mask = <span class="string">'Mask.mat'</span>;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% II- CHECK DATA AND FITTING</span>
   <span class="comment">%**************************************************************************</span>
   qMRLab(Model,file);
   </pre><img src="_static/MWF_batch_01.png" vspace="5" hspace="5" alt=""> <img src="_static/MWF_batch_02.png" vspace="5" hspace="5" alt=""> <h2 id="5">Create Quantitative Maps</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- LOAD PROTOCOL</span>
   <span class="comment">%**************************************************************************</span>
   
   <span class="comment">% Echo (time in millisec)</span>
   EchoTimes = [10; 20; 30; 40; 50; 60; 70; 80; 90; 100; 110; 120; 130; 140; 150; 160; 170;
               180; 190; 200; 210; 220; 230; 240; 250; 260; 270; 280; 290; 300; 310; 320];
   Model.Prot.Echo.Mat = EchoTimes;
   
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
   load(<span class="string">'MET2data.mat'</span>);
   data.MET2data = double(MET2data);
   load(<span class="string">'Mask.mat'</span>);
   data.Mask     = double(Mask);
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% III- FIT DATASET</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% All voxels</span>
   FitResults       = FitData(data,Model,1); <span class="comment">% 3rd argument plots a waitbar</span>
   delete(<span class="string">'FitTempResults.mat'</span>);
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% IV- CHECK FITTING RESULT IN A VOXEL</span>
   <span class="comment">%**************************************************************************</span>
   figure
   voxel           = [37, 40, 1];
   FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
   dataVox         = extractvoxel(data,voxel);
   Model.plotmodel(FitResultsVox,dataVox)
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% V- SAVE</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% .MAT file : FitResultsSave_mat(FitResults,folder);</span>
   <span class="comment">% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);</span>
   FitResultsSave_mat(FitResults);
   save(<span class="string">'MWFPamameters.mat'</span>,<span class="string">'Model'</span>);
   </pre><img src="_static/MWF_batch_03.png" vspace="5" hspace="5" alt=""> <h2 id="6">Check the results</h2><p >Load them in qMRLab</p><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017a</a><br ></p></div>
