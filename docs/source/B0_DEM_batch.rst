B0_DEM
======

.. raw:: html

   
   <div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">DESCRIPTION</a></li><li ><a href="#3">Load dataset</a></li><li ><a href="#4">Check data and fitting (Optional)</a></li><li ><a href="#5">Create Quantitative Maps</a></li><li ><a href="#6">Check the results</a></li></ul></div><pre class="codeinput">warning(<span class="string">'off'</span>,<span class="string">'all'</span>);
   </pre><h2 id="2">DESCRIPTION</h2><pre class="codeinput">help <span class="string">B0_DEM</span>
   <span class="comment">% Batch to generate B0map with Dual Echo Method (DEM) without qMRLab GUI (graphical user interface)</span>
   <span class="comment">% Run this script line by line</span>
   <span class="comment">% Written by: Ian Gagnon, 2017</span>
   </pre><pre class="codeoutput">  B0_DEM map :  Dual Echo Method for B0 mapping
    
     Assumptions:
       Compute B0 map based on 2 phase images with different TEs
    
     Inputs:
       Phase       4D phase image, 2 different TEs in time dimension
       Magn        3D magnitude image
    
     Outputs:
    	B0map       B0 field map [Hz]
    
     Protocol:
       Time
           deltaTE     Difference in TE between 2 images [ms]            
    
     Options:
       Magn thresh lb  Lower bound to threshold the magnitude image for use as a mask
    
     Example of command line usage (see also a href="matlab: showdemo B0_DEM_batch"showdemo B0_DEM_batch/a):
       Model = B0_DEM;  % Create class from model 
       Model.Prot.Time.Mat = 1.92e-3; % deltaTE [s]
       data.Phase = double(load_nii_data('Phase.nii.gz'));%Load 4D data, 2 frames with different TE
       data.Magn  = double(load_nii_data('Magn.nii.gz'));
       FitResults       = FitData(data,Model);
       FitResultsSave_nii(FitResults,'Phase.nii.gz'); %save nii file using Phase.nii.gz as template
        
       For more examples: a href="matlab: qMRusage(B0_DEM);"qMRusage(B0_DEM)/a
    
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
          doc B0_DEM
   
   
   </pre><h2 id="3">Load dataset</h2><pre class="codeinput">[pathstr,fname,ext]=fileparts(which(<span class="string">'B0_DEM_batch.m'</span>));
   cd (pathstr);
   
   <span class="comment">% Load your parameters to create your Model</span>
   Model = B0_DEM;
   </pre><h2 id="4">Check data and fitting (Optional)</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- GENERATE FILE STRUCT</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "file" that contains the NAME of all data's FILES</span>
   <span class="comment">% file.DATA = 'DATA_FILE';</span>
   file = struct;
   file.Phase = <span class="string">'Phase.nii.gz'</span>;
   file.Magn = <span class="string">'Magn.nii.gz'</span>;
   </pre><h2 id="5">Create Quantitative Maps</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% I- LOAD PROTOCOL</span>
   <span class="comment">%**************************************************************************</span>
   
   <span class="comment">% Echo (time in millisec)</span>
   TE2 = 1.92e-3;
   Model.Prot.Time.Mat = TE2;
   
   <span class="comment">% Update the model</span>
   Model = Model.UpdateFields;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% II- LOAD EXPERIMENTAL DATA</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% Create a struct "data" that contains all the data</span>
   <span class="comment">% .MAT file : load('DATA_FILE');</span>
   <span class="comment">%             data.DATA = double(DATA);</span>
   <span class="comment">% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));</span>
   data.Phase = double(load_nii_data(<span class="string">'Phase.nii.gz'</span>));
   data.Magn  = double(load_nii_data(<span class="string">'Magn.nii.gz'</span>));
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% III- FIT DATASET</span>
   <span class="comment">%**************************************************************************</span>
   FitResults       = FitData(data,Model,1); <span class="comment">% 3rd argument plots a waitbar</span>
   FitResults.Model = Model;
   
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% IV- SAVE</span>
   <span class="comment">%**************************************************************************</span>
   <span class="comment">% .MAT file : FitResultsSave_mat(FitResults,folder);</span>
   <span class="comment">% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);</span>
   FitResultsSave_nii(FitResults,<span class="string">'Phase.nii.gz'</span>);
   <span class="comment">%save('Parameters.mat','Model');</span>
   </pre><h2 id="6">Check the results</h2><p >Load them in qMRLab</p><pre class="codeinput">qMRLab(Model,file) <span class="comment">%view the model parameters and input</span>
   imagesc(FitResults.B0map, [-50 50]) <span class="comment">%view output map</span>
   colorbar
   </pre><img src="_static/B0_DEM_batch_01.png" vspace="5" hspace="5" alt=""> <img src="_static/B0_DEM_batch_02.png" vspace="5" hspace="5" alt=""> <p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017a</a><br ></p></div>
