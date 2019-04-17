mt_sat :  Correction of Magnetization transfer for RF inhomogeneities and T1
============================================================================

.. image:: https://mybinder.org/badge_logo.svg
 :target: https://mybinder.org/v2/gh/qMRLab/doc_notebooks/master?filepath=mt_sat_notebook.ipynb
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
    </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- DESCRIPTION</a></li><li ><a href="#3">II- MODEL PARAMETERS</a></li><li ><a href="#4">a- create object</a></li><li ><a href="#5">b- modify options</a></li><li ><a href="#6">III- FIT EXPERIMENTAL DATASET</a></li><li ><a href="#7">a- load experimental data</a></li><li ><a href="#8">b- fit dataset</a></li><li ><a href="#9">c- show fitting results</a></li><li ><a href="#10">d- Save results</a></li><li ><a href="#11">V- SIMULATIONS</a></li><li ><a href="#12">a- Single Voxel Curve</a></li><li ><a href="#13">b- Sensitivity Analysis</a></li></ul></div><pre class="codeinput"><span class="comment">% This m-file has been automatically generated using qMRgenBatch(mt_sat)</span>
    <span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
    <span class="comment">% purposes and Octave.</span>
    <span class="comment">%</span>
    <span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
    <span class="comment">% processing for mt_sat on CLI.</span>
    <span class="comment">%</span>
    <span class="comment">% Demo files are downloaded into mt_sat_data folder.</span>
    <span class="comment">%</span>
    <span class="comment">% Written by: Agah Karakuzu, 2017</span>
    <span class="comment">% =========================================================================</span>
    </pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'mt_sat'</span>); <span class="comment">% Describe the model</span>
    </pre><pre class="codeoutput">  mt_sat :  Correction of Magnetization transfer for RF inhomogeneities and T1

    Assumptions:
    MTsat is a semi-quantitative method. MTsat values depend on protocol parameters.

    Inputs:
    MTw     3D MT-weighted data. Spoiled Gradient Echo (or FLASH) with MT
    pulse
    T1w     3D T1-weighted data. Spoiled Gradient Echo (or FLASH)
    PDw     3D PD-weighted data. Spoiled Gradient Echo (or FLASH)
    (B1map)  B1+ map. B1map = 1 : perfectly accurate flip angle. Optional.
    (Mask)   Binary mask. DOES NOT ACCELERATE FITTING. Just for visualisation

    Outputs:
    MTSAT         MT saturation map (%), T1-corrected
    T1            T1 map (s)

    Options:
    B1 correction factor     Correction factor (empirical) for the transmit RF. Only
    corrects MTSAT, not T1.
    Weiskopf, N., Suckling, J., Williams, G., CorreiaM.M., Inkster, B., Tait, R., Ooi, C., Bullmore, E.T., Lutti, A., 2013. Quantitative multi-parameter mapping of R1, PD(*), MT, and R2(*) at 3T: a multi-center validation. Front. Neurosci. 7, 95.

    Protocol:
    MTw    [FA  TR  Offset]  flip angle [deg], TR [s], Offset Frequency [Hz]
    T1w    [FA  TR]          flip angle [deg], TR [s]
    PDw    [FA  TR]          flip angle [deg], TR [s]

    Example of command line usage:
    Model = mt_sat;  % Create class from model
    Model.Prot.MTw.Mat = txt2mat('MT.txt');  % Load protocol
    Model.Prot.T1w.Mat = txt2mat('T1.txt');
    Model.Prot.PDw.Mat = txt2mat('PD.txt');
    data = struct;  % Create data structure
    data.MTw = load_nii_data('MTw.nii.gz');
    data.T1w = load_nii_data('T1w.nii.gz');
    data.PDw = load_nii_data('PDw.nii.gz');  % Load data
    FitResults = FitData(data,Model); %fit data
    FitResultsSave_nii(FitResults,'MTw.nii.gz'); % Save in local folder: FitResults/

    For more examples: a href="matlab: qMRusage(mt_sat);"qMRusage(mt_sat)/a

    Author: Pascale Beliveau (pascale.beliveau@polymtl.ca)

    References:
    Please cite the following if you use this module:
    Helms, G., Dathe, H., Kallenberg, K., Dechent, P., 2008. High-resolution maps of magnetization transfer with inherent correction for RF inhomogeneity and T1 relaxation obtained from 3D FLASH MRI. Magn. Reson. Med. 60, 1396?1407.
    In addition to citing the package:
    Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

    Reference page in Doc Center
    doc mt_sat


    </pre><h2 id="3">II- MODEL PARAMETERS</h2><h2 id="4">a- create object</h2><pre class="codeinput">Model = mt_sat;
    </pre><h2 id="5">b- modify options</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
    |- Octave is not GUI compatible. Modify Model.options directly.</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
    </pre><img src="_static/mt_sat_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">III- FIT EXPERIMENTAL DATASET</h2><h2 id="7">a- load experimental data</h2><pre >         |- mt_sat object needs 5 data input(s) to be assigned:
    |-   MTw
    |-   T1w
    |-   PDw
    |-   B1map
    |-   Mask</pre><pre class="codeinput">data = struct();
    <span class="comment">% MTw.nii.gz contains [128  128   96] data.</span>
    data.MTw=double(load_nii_data(<span class="string">'mt_sat_data/MTw.nii.gz'</span>));
    <span class="comment">% T1w.nii.gz contains [128  128   96] data.</span>
    data.T1w=double(load_nii_data(<span class="string">'mt_sat_data/T1w.nii.gz'</span>));
    <span class="comment">% PDw.nii.gz contains [128  128   96] data.</span>
    data.PDw=double(load_nii_data(<span class="string">'mt_sat_data/PDw.nii.gz'</span>));
    </pre><h2 id="8">b- fit dataset</h2><pre >           |- This section will fit data.</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
    </pre><pre class="codeoutput">...done
    </pre><h2 id="9">c- show fitting results</h2><pre >         |- Output map will be displayed.
    |- If available, a graph will be displayed to show fitting in a voxel.
    |- To make documentation generation and our CI tests faster for this model,
    we used a subportion of the data (40X40X40) in our testing environment.
    |- Therefore, this example will use FitResults that comes with OSF data for display purposes.
    |- Users will get the whole dataset (384X336X224) and the script that uses it for demo
    via qMRgenBatch(qsm_sb) command.</pre><pre class="codeinput">FitResults_old = load(<span class="string">'FitResults/FitResults.mat'</span>);
    qMRshowOutput(FitResults_old,data,Model);
    </pre><img src="_static/mt_sat_batch_02.png" vspace="5" hspace="5" alt=""> <h2 id="10">d- Save results</h2><pre >         |-  qMR maps are saved in NIFTI and in a structure FitResults.mat
    that can be loaded in qMRLab graphical user interface
    |-  Model object stores all the options and protocol.
    It can be easily shared with collaborators to fit their
    own data or can be used for simulation.</pre><pre class="codeinput">FitResultsSave_nii(FitResults, <span class="string">'mt_sat_data/MTw.nii.gz'</span>);
    Model.saveObj(<span class="string">'mt_sat_Demo.qmrlab.mat'</span>);
    </pre><pre class="codeoutput">Warning: Directory already exists. 
    </pre><h2 id="11">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for mt_sat.</pre><h2 id="12">a- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
    (1) use equation to generate synthetic MRI data
    (2) add rician noise
    (3) fit and plot curve</pre><pre class="codeinput"><span class="comment">% Not available for the current model.</span>
    </pre><h2 id="13">b- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
    (1) vary fitting parameters from lower (lb) to upper (ub) bound.
    (2) run Sim_Single_Voxel_Curve Nofruns times
    (3) Compute mean and std across runs</pre><pre class="codeinput"><span class="comment">% Not available for the current model.</span>
    </pre><p class="footer"><br ><a href="https://www.mathworks.com/products/matlab/">Published with MATLAB R2018a</a><br ></p></div>
