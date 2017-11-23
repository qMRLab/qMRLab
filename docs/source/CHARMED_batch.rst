CHARMED:
========

.. raw:: html

   
   <div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- LOAD MODEL</a></li><li ><a href="#3">II - Perform Simulations</a></li><li ><a href="#4">III - MRI Data Fitting</a></li><li ><a href="#5">Check the results</a></li></ul></div><pre class="codeinput"><span class="comment">% Batch to process CHARMED data without qMRLab GUI (graphical user interface)</span>
   <span class="comment">% Run this script line by line</span>
   quickdemo = true; <span class="comment">% skip long processing?</span>
   <span class="comment">%**************************************************************************</span>
   </pre><h2 id="2">I- LOAD MODEL</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   
   <span class="comment">% Create Model object</span>
   Model = CHARMED;
   <span class="comment">% Load Diffusion Protocol</span>
   Model.Prot.DiffusionData.Mat = txt2mat(<span class="string">'Protocol.txt'</span>);
   
   <span class="comment">%**************************************************************************</span>
   </pre><pre class="codeoutput">**************
   * Protocol.txt
   * read mode: auto
   * 826 data lines analysed
   * 3 header line(s)
   * 7 data column(s)
   * 0 string replacement(s)
   **************
   </pre><h2 id="3">II - Perform Simulations</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% See info/usage of Sim_Single_Voxel_Curve</span>
   qMRusage(Model,<span class="string">'Sim_Single_Voxel_Curve'</span>)
   
   <span class="comment">% Let's try Sim_Single_Voxel_Curve</span>
   opt.SNR = 50;
   x.fr = .5;
   x.Dh = .7; <span class="comment">% um2/ms</span>
   x.diameter_mean = 6; <span class="comment">% um</span>
   x.fcsf = 0;
   x.lc=0;
   x.Dcsf=3;
   x.Dintra = 1.4;
   FitResults = Model.Sim_Single_Voxel_Curve(x,opt);
   <span class="comment">% compare FitResults and input x</span>
   SimResult = table(struct2mat(x,Model.xnames)',struct2mat(FitResults,Model.xnames)',<span class="string">'RowNames'</span>,Model.xnames,<span class="string">'VariableNames'</span>,{<span class="string">'input_x'</span>,<span class="string">'FitResults'</span>})
   
   <span class="comment">% to try other Simulations methods, type:</span>
   <span class="comment">% qMRusage(Model,'Sim_*')</span>
   
   <span class="comment">%**************************************************************************</span>
   </pre><pre class="codeoutput">strongSim_Single_Voxel_Curve/strong
      Simulates Single Voxel curves
      USAGE:
        FitResults = Sim_Single_Voxel_Curve(obj, x)
        FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
      INPUT:
        x: [struct] OR [vector] containing fit results: 'fr', 'Dh', 'diameter_mean', 'fcsf', 'lc', 'Dcsf', 'Dintra'
        display: [binary] 1=display, 0=nodisplay
        Opt:  a href="matlab:helpPopup struct" style="font-weight:bold"struct/a with fields:
   
       SNR: 50
   
   
    
   
   SimResult = 
   
                        input_x    FitResults
                        _______    __________
   
       fr               0.5        0.49837   
       Dh               0.7        0.70012   
       diameter_mean      6         5.9837   
       fcsf               0              0   
       lc                 0              0   
       Dcsf               3              3   
       Dintra           1.4            1.4   
   
   </pre><img src="_static/CHARMED_batch_01.png" vspace="5" hspace="5" style="width:560px;height:420px;" alt=""> <h2 id="4">III - MRI Data Fitting</h2><pre class="codeinput"><span class="comment">%**************************************************************************</span>
   <span class="comment">% load data</span>
   data = struct;
   data.DiffusionData = load_nii_data(<span class="string">'DiffusionData.nii.gz'</span>);
   data.Mask=load_nii_data(<span class="string">'Mask.nii.gz'</span>);
   
   <span class="comment">% plot fit in one voxel</span>
   voxel = [32 29];
   datavox.DiffusionData = squeeze(data.DiffusionData(voxel(1),voxel(2),:,:));
   FitResults = Model.fit(datavox)
   Model.plotmodel(FitResults,datavox)
   
   <span class="comment">% fit all voxels (coffee break)</span>
   <span class="keyword">if</span> ~quickdemo
   FitResults = FitData(data,Model,1);
   <span class="comment">% save maps</span>
   <span class="comment">% .MAT file : FitResultsSave_mat(FitResults,folder);</span>
   <span class="comment">% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);</span>
   FitResultsSave_nii(FitResults,<span class="string">'DiffusionData.nii.gz'</span>);
   <span class="keyword">end</span>
   </pre><pre class="codeoutput">
   FitResults = 
   
     struct with fields:
   
                  fr: 0.1594
                  Dh: 0.8886
       diameter_mean: 5.3655
                fcsf: 0
                  lc: 0
                Dcsf: 3
              Dintra: 1.4000
             S0_TE62: 1.2139e+05
             S0_TE57: 1.2525e+05
             S0_TE52: 1.3174e+05
             S0_TE47: 1.3278e+05
             S0_TE46: 1.3871e+05
             S0_TE36: 1.4916e+05
                  fh: 0.8406
             residue: 1.5655e+05
          SigmaNoise: 431.5808
   
   </pre><img src="_static/CHARMED_batch_02.png" vspace="5" hspace="5" style="width:560px;height:420px;" alt=""> <h2 id="5">Check the results</h2><p >Load them in qMRLab</p><p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2016b</a><br ></p></div>
