mwf :  Myelin Water Fraction from Multi-Exponential T2w data
============================================================

.. image:: https://mybinder.org/badge_logo.svg
 :target: https://mybinder.org/v2/gh/qMRLab/doc_notebooks/master?filepath=mwf_demo.ipynb
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
    </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- DESCRIPTION</a></li><li ><a href="#3">II- MODEL PARAMETERS</a></li><li ><a href="#4">a- create object</a></li><li ><a href="#5">b- modify options</a></li><li ><a href="#6">III- FIT EXPERIMENTAL DATASET</a></li><li ><a href="#7">a- load experimental data</a></li><li ><a href="#8">b- fit dataset</a></li><li ><a href="#9">c- show fitting results</a></li><li ><a href="#10">d- Save results</a></li><li ><a href="#11">V- SIMULATIONS</a></li><li ><a href="#12">a- Single Voxel Curve</a></li><li ><a href="#13">b- Sensitivity Analysis</a></li></ul></div><pre class="codeinput"><span class="comment">% This m-file has been automatically generated using qMRgenBatch(mwf)</span>
    <span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
    <span class="comment">% purposes and Octave.</span>
    <span class="comment">%</span>
    <span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
    <span class="comment">% processing for mwf on CLI.</span>
    <span class="comment">%</span>
    <span class="comment">% Demo files are downloaded into mwf_data folder.</span>
    <span class="comment">%</span>
    <span class="comment">% Written by: Agah Karakuzu, 2017</span>
    <span class="comment">% =========================================================================</span>
    </pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'mwf'</span>); <span class="comment">% Describe the model</span>
    </pre><pre class="codeoutput">  mwf :  Myelin Water Fraction from Multi-Exponential T2w data

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
    MET2data   [TE1 TE2 ...] % list of echo times [ms]

    Example of command line usage:
    Model = mwf;  % Create class from model
    Model.Prot.MET2data.Mat=[10:10:320];
    data = struct;  % Create data structure
    data.MET2data ='MET2data.mat';  % Load data
    data.Mask = 'Mask.mat';
    FitResults = FitData(data,Model); %fit data
    FitResultsSave_mat(FitResults);

    For more examples: a href="matlab: qMRusage(mwf);"qMRusage(mwf)/a

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
    doc mwf


    </pre><h2 id="3">II- MODEL PARAMETERS</h2><h2 id="4">a- create object</h2><pre class="codeinput">Model = mwf;
    </pre><h2 id="5">b- modify options</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
    |- Octave is not GUI compatible. Modify Model.options directly.</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
    </pre><img src="_static/mwf_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">III- FIT EXPERIMENTAL DATASET</h2><h2 id="7">a- load experimental data</h2><pre >         |- mwf object needs 2 data input(s) to be assigned:
    |-   MET2data
    |-   Mask</pre><pre class="codeinput">data = struct();

    <span class="comment">% MET2data.mat contains [64  64   1  32] data.</span>
    load(<span class="string">'mwf_data/MET2data.mat'</span>);
    <span class="comment">% Mask.mat contains [64  64] data.</span>
    load(<span class="string">'mwf_data/Mask.mat'</span>);
    data.MET2data= double(MET2data);
    data.Mask= double(Mask);
    </pre><h2 id="8">b- fit dataset</h2><pre >           |- This section will fit data.</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
    </pre><pre class="codeoutput">Starting to fit data.
    </pre><h2 id="9">c- show fitting results</h2><pre >         |- Output map will be displayed.
    |- If available, a graph will be displayed to show fitting in a voxel.
    |- To make documentation generation and our CI tests faster for this model,
    we used a subportion of the data (40X40X40) in our testing environment.
    |- Therefore, this example will use FitResults that comes with OSF data for display purposes.
    |- Users will get the whole dataset (384X336X224) and the script that uses it for demo
    via qMRgenBatch(qsm_sb) command.</pre><pre class="codeinput">FitResults_old = load(<span class="string">'FitResults/FitResults.mat'</span>);
    qMRshowOutput(FitResults_old,data,Model);
    </pre><img src="_static/mwf_batch_02.png" vspace="5" hspace="5" alt=""> <img src="_static/mwf_batch_03.png" vspace="5" hspace="5" alt=""> <h2 id="10">d- Save results</h2><pre >         |-  qMR maps are saved in NIFTI and in a structure FitResults.mat
    that can be loaded in qMRLab graphical user interface
    |-  Model object stores all the options and protocol.
    It can be easily shared with collaborators to fit their
    own data or can be used for simulation.</pre><pre class="codeinput">FitResultsSave_nii(FitResults);
    Model.saveObj(<span class="string">'mwf_Demo.qmrlab.mat'</span>);
    </pre><pre class="codeoutput">Warning: Directory already exists. 
    </pre><h2 id="11">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for mwf.</pre><h2 id="12">a- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
    (1) use equation to generate synthetic MRI data
    (2) add rician noise
    (3) fit and plot curve</pre><pre class="codeinput">      x = struct;
    x.MWF = 50.0001;
    x.T2MW = 20.0001;
    x.T2IEW = 120;
    <span class="comment">% Set simulation options</span>
    Opt.SNR = 200;
    Opt.T2Spectrumvariance_Myelin = 5;
    Opt.T2Spectrumvariance_IEIntraExtracellularWater = 20;
    <span class="comment">% run simulation</span>
    figure(<span class="string">'Name'</span>,<span class="string">'Single Voxel Curve Simulation'</span>);
    FitResult = Model.Sim_Single_Voxel_Curve(x,Opt);
    </pre><img src="_static/mwf_batch_04.png" vspace="5" hspace="5" alt=""> <h2 id="13">b- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
    (1) vary fitting parameters from lower (lb) to upper (ub) bound.
    (2) run Sim_Single_Voxel_Curve Nofruns times
    (3) Compute mean and std across runs</pre><pre class="codeinput">      <span class="comment">%              MWF           T2MW          T2IEW</span>
    OptTable.st = [50            20            1.2e+02]; <span class="comment">% nominal values</span>
    OptTable.fx = [0             1             1]; <span class="comment">%vary MWF...</span>
    OptTable.lb = [0.0001        0.0001        40]; <span class="comment">%...from 0.0001</span>
    OptTable.ub = [1e+02         40            2e+02]; <span class="comment">%...to 100</span>
    <span class="comment">% Set simulation options</span>
    Opt.SNR = 200;
    Opt.T2Spectrumvariance_Myelin = 5;
    Opt.T2Spectrumvariance_IEIntraExtracellularWater = 20;
    Opt.Nofrun = 5;
    <span class="comment">% run simulation</span>
    SimResults = Model.Sim_Sensitivity_Analysis(OptTable,Opt);
    figure(<span class="string">'Name'</span>,<span class="string">'Sensitivity Analysis'</span>);
    SimVaryPlot(SimResults, <span class="string">'MWF'</span> ,<span class="string">'MWF'</span> );
    </pre><img src="_static/mwf_batch_05.png" vspace="5" hspace="5" alt=""> <p class="footer"><br ><a href="https://www.mathworks.com/products/matlab/">Published with MATLAB R2018a</a><br ></p></div>
