mtv :  Macromolecular Tissue Volume
===================================

.. raw:: html

   
   <div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">DESCRIPTION</a></li><li ><a href="#3">Load dataset</a></li><li ><a href="#4">Check data and fitting (Optional)</a></li><li ><a href="#5">Create Quantitative Maps</a></li><li ><a href="#6">Check the results</a></li></ul></div><pre class="codeinput"><span class="comment">% Batch to process MTV data without qMRLab GUI (graphical user interface)</span>
   <span class="comment">% Run this script line by line</span>
   <span class="comment">% Written by: Ian Gagnon, 2017</span>
   </pre><h2 id="2">DESCRIPTION</h2><pre class="codeinput">help <span class="string">MTV</span>
   </pre><pre class="codeoutput">Contents of MTV:
   
   mtv_compute_m0_t1              - function function [M0 T1] = fitData_MTV (data, flipAngles, TR [, b1Map, roi, fixT1, verbose])
   mtv_fit3dpolynomialmodel       - data_smooth = mtv_fit3dpolynomialmodel(data,mask,order)
   mtv_fit3dsplinemodel           - data_smooth = mtv_fit3dsplinemodel(data,mask,smooth)
   
   
   MTV is both a directory and a function.
   
    -----------------------------------------------------------------------------------------------------
     MTV :  Macromolecular Tissue Volume
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
       1) SPGR    : Spoiled Gradient Echo data
       2) B1map   : Excitation (B1+) field map. Used to correct flip angle
       3) CSFMask : CerebroSpinal Fluid Mask. Used for proton density
                    normalization (assuming ProtonCSF = 1)
    
    -----------------------------------------------------------------------------------------------------
    ---------%
     OUTPUTS %
    ---------%
    	* T1       : Longitudinal relaxation time
    	* CoilGain : Reception profile of the antenna (B1- map)
    	* PD       : Proton Density
    	* MTV      : Macromolecular Tissue Volume
    
    -----------------------------------------------------------------------------------------------------
    ----------%
     PROTOCOL %
    ----------%
    	* Flip Angle (degree)
    	* TR : Repetition time of the whole sequence (s)
    
    -----------------------------------------------------------------------------------------------------
    ---------%
     OPTIONS %
    ---------%
       NONE
    
    -----------------------------------------------------------------------------------------------------
     Written by: Ian Gagnon, 2017
     Reference: FILL
    -----------------------------------------------------------------------------------------------------
   
       Reference page in Doc Center
          doc MTV
   
   
   </pre><h2 id="3">Load dataset</h2><pre class="codeinput">[pathstr,fname,ext]=fileparts(which(<span class="string">'MTV_batch.m'</span>));
   cd (pathstr);
   
   <span class="comment">% Load your parameters to create your Model</span>
   <span class="comment">% load('MODELPamameters.mat');</span>
   <span class="comment">%load('MTVParameters.mat');</span>
   Model = MTV
   </pre><pre class="codeoutput">
   Model = 
   
     MTV with properties:
   
       MRIinputs: {'SPGR'  'B1map'  'CSFMask'}
          xnames: {}
       voxelwise: 0
            Prot: [11 struct]
         buttons: {111 cell}
         options: [11 struct]
   
   </pre><h2 id="4">Check data and fitting (Optional)</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
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
   </pre><img src="_static/MTV_batch_01.png" vspace="5" hspace="5" alt=""> <img src="_static/MTV_batch_02.png" vspace="5" hspace="5" alt=""> <h2 id="5">Create Quantitative Maps</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
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
   </pre><pre class="codeoutput">
   ans =
   
       'loop over voxels...
        
        
      100%
   ...done
   </pre><h2 id="6">Check the results</h2><p >Load them in qMRLab</p><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017a</a><br ></p></div>
