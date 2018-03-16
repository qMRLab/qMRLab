dti: Compute a tensor from diffusion data
=========================================

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
   </style><div class="content"><h2 >Contents</h2><div ><ul ><li ><a href="#2">I- DESCRIPTION</a></li><li ><a href="#3">II- INITIALIZE MODEL OBJECT</a></li><li ><a href="#4">A- CREATE MODEL OBJECT</a></li><li ><a href="#5">B- MODIFY OPTIONS</a></li><li ><a href="#6">C- LOAD PROTOCOL</a></li><li ><a href="#7">III- FIT EXPERIMENTAL DATASET</a></li><li ><a href="#8">A- LOAD EXPERIMENTAL DATA</a></li><li ><a href="#9">B- FIT DATASET</a></li><li ><a href="#10">C- SHOW FITTING RESULTS</a></li><li ><a href="#11">IV- SAVE MAPS AND OBJECT</a></li><li ><a href="#12">V- SIMULATIONS</a></li><li ><a href="#13">A- Single Voxel Curve</a></li><li ><a href="#14">B- Sensitivity Analysis</a></li></ul></div><pre class="codeinput"><span class="comment">% This m-file has been automatically generated.</span>
   <span class="comment">% Command Line Interface (CLI) is well-suited for automatization</span>
   <span class="comment">% purposes and Octave.</span>
   <span class="comment">%</span>
   <span class="comment">% Please execute this m-file section by section to get familiar with batch</span>
   <span class="comment">% processing for dti on CLI.</span>
   <span class="comment">%</span>
   <span class="comment">% Demo files are downloaded into dti_data folder.</span>
   <span class="comment">%</span>
   <span class="comment">%</span>
   <span class="comment">% Written by: Agah Karakuzu, 2017</span>
   <span class="comment">% =========================================================================</span>
   </pre><h2 id="2">I- DESCRIPTION</h2><pre class="codeinput">qMRinfo(<span class="string">'dti'</span>); <span class="comment">% Display help</span>
   </pre><pre class="codeoutput"> dti: Compute a tensor from diffusion data
    
     Assumptions:
       
     Inputs:
       DiffusionData       4D diffusion weighted dataset
       (SigmaNoise)
       (Mask)              Binary mask to accelerate fitting [optional]
    
     Outputs:
    	FA                  Fractional anisotropy
       D                   Mean diffusivity
       L1                  Principal eigenvalue
       L2                  Second eigenvalue
       L3                  Third eigenvalue
       residue             Residue of the fit
    
     Protocol:
    
     Options
       NONE
    
     Example of command line usage (see also a href="matlab: showdemo dti_batch"showdemo dti_batch/a):
       Model=dti;
       Model.Prot.DiffusionData.Mat = txt2mat('Protocol.txt');  % Load protocol
       data = struct;  % Create data structure
       data.DiffusionData = load_nii_data('DiffusionData.nii.gz');  % Load data
       data.Mask=load_nii_data('Mask.nii.gz');  % Load mask
       FitResults = FitData(data,Model,1);  % Fit each voxel within mask
       FitResultsSave_nii(FitResults,'DiffusionData.nii.gz');  % Save in local folder: FitResults/
    
       For more examples: a href="matlab: qMRusage(dti_dam);"qMRusage(dti_dam)/a
    
    
     Example of command line usage (see also a href="matlab: showdemo dti_batch"showdemo dti_batch/a):
       For more examples: a href="matlab: qMRusage(dti);"qMRusage(dti)/a
    
     Author: FILL
     References:
       Please cite the following if you use this module:
         FILL
       In addition to citing the package:
         Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
   
       Reference page in Doc Center
          doc dti
   
   
   </pre><h2 id="3">II- INITIALIZE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><h2 id="4">A- CREATE MODEL OBJECT</h2><p >-------------------------------------------------------------------------</p><pre class="codeinput">Model = dti;
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="5">B- MODIFY OPTIONS</h2><pre >         |- This section will pop-up the options GUI. Close window to continue.
            |- Octave is not GUI compatible. Modify Model.options directly.
   -------------------------------------------------------------------------</pre><pre class="codeinput">Model = Custom_OptionsGUI(Model); <span class="comment">% You need to close GUI to move on.</span>
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><img src="_static/dti_batch_01.png" vspace="5" hspace="5" alt=""> <h2 id="6">C- LOAD PROTOCOL</h2><pre class="language-matlab">	   |- Respective command <span class="string">lines</span> <span class="string">appear</span> <span class="string">if</span> <span class="string">required</span> <span class="string">by</span> <span class="string">dti.</span>
   -------------------------------------------------------------------------
   </pre><pre class="codeinput"><span class="comment">% dti object needs 1 protocol field(s) to be assigned:</span>
   
   
   <span class="comment">% DiffusionData</span>
   <span class="comment">% --------------</span>
   <span class="comment">% Gx is a vector of [109X1]</span>
   Gx = [0.0000; 0.0000; 0.6528; -0.3734; 0.6595; 0.4251; 0.9307; 0.2346; -0.5629; -0.1656; -0.9726; -0.0150; 0.1463; -0.2313; 0.7377; -0.7661; -0.1051; 0.0000; 0.3909; 0.1496; -0.9334; 0.1903; -0.7039; -0.5217; 0.9662; -0.3714; -0.7828; 0.8305; -0.3302; -0.2348; 0.0253; -0.5469; 0.7053; 0.0000; 0.3198; 0.7962; 0.8699; 0.6890; -0.9299; 0.0387; 0.3218; 0.3582; 0.8944; 0.4384; -0.3516; -0.1507; -0.5361; 0.5114; -0.0808; 0.0000; -0.0261; -0.4804; -0.8220; -0.3674; -0.8059; 0.9937; -0.9844; -0.4309; 0.1316; -0.0096; 0.6996; -0.6609; 0.8179; -0.7977; 0.4352; 0.0000; 0.3330; 0.5147; -0.8173; -0.5177; -0.0540; 0.0108; -0.0691; 0.8929; 0.6656; 0.3998; 0.2992; -0.6774; -0.3221; 0.5112; -0.1681; 0.0000; 0.8415; 0.2496; 0.6320; 0.1861; 0.4758; 0.7481; 0.9338; 0.6610; 0.6125; 0.6137; 0.6817; 0.0996; -0.9739; 0.8386; 0.2920; 0.0000; -0.7056; -0.2181; -0.6203; 0.0020; -0.1074; 0.2822; 0.4012; 0.5307; 0.5323; 0.9651; 0.0000];
   <span class="comment">% Gy is a vector of [109X1]</span>
   Gy = [0.0000; 0.0000; -0.6550; 0.1688; 0.7394; 0.0347; 0.0616; -0.8169; -0.0797; -0.8647; 0.0079; 0.9886; 0.7658; -0.5711; 0.5254; 0.5946; -0.9930; 0.0000; -0.4079; -0.3372; -0.2009; 0.7622; -0.4547; 0.4241; -0.2577; 0.9198; 0.6149; -0.2333; -0.8437; -0.5578; 0.1522; -0.7771; 0.6419; 0.0000; -0.6674; -0.0672; -0.1770; 0.4593; 0.3590; 0.4492; 0.4365; 0.2082; 0.4341; -0.8638; 0.8508; 0.5115; 0.3158; -0.7514; 0.9207; 0.0000; -0.9526; -0.8692; 0.3566; -0.3033; -0.5619; -0.0273; -0.1502; -0.9023; 0.1687; -0.1114; -0.7110; -0.2140; -0.3778; -0.1210; 0.6742; 0.0000; -0.5741; -0.6575; -0.5127; 0.4818; 0.5946; -0.8315; -0.7675; 0.2597; 0.3549; -0.8171; -0.0563; -0.1344; 0.2540; 0.6731; -0.9515; 0.0000; -0.4352; 0.9109; -0.0796; -0.9773; -0.8795; 0.6348; -0.2954; -0.0966; -0.4925; -0.1628; -0.4899; 0.3862; -0.2261; 0.5426; 0.9388; 0.0000; 0.1116; 0.9406; 0.7701; 0.3742; -0.4286; -0.6551; 0.7562; 0.4305; 0.4358; -0.2538; 0.0000];
   <span class="comment">% Gz is a vector of [109X1]</span>
   Gz = [0.0000; 0.0000; 0.3807; 0.9122; 0.1356; -0.9045; 0.3607; -0.5270; -0.8227; 0.4743; 0.2325; -0.1496; -0.6262; -0.7876; -0.4240; 0.2441; 0.0536; 0.0000; 0.8251; 0.9295; -0.2972; 0.6187; 0.5456; 0.7403; -0.0065; -0.1266; 0.0958; 0.5057; -0.4233; 0.7961; 0.9880; 0.3116; 0.3009; 0.0000; 0.6726; -0.6012; -0.4604; 0.5607; -0.0796; 0.8926; -0.8402; 0.9101; -0.1075; -0.2483; 0.3905; 0.8460; -0.7829; 0.4170; -0.3819; 0.0000; -0.3031; 0.1170; 0.4439; -0.8792; -0.1865; 0.1090; 0.0921; 0.0165; -0.9768; 0.9937; 0.0714; 0.7193; 0.4339; -0.5907; -0.5967; 0.0000; -0.7480; -0.5502; -0.2629; -0.7070; -0.8022; 0.5555; -0.6373; -0.3679; 0.6565; 0.4153; 0.9525; 0.7233; 0.9120; 0.5345; -0.2576; 0.0000; 0.3202; -0.3285; -0.7708; -0.1011; 0.0065; -0.1930; -0.2018; 0.7442; 0.6183; -0.7725; -0.5434; 0.9170; -0.0219; -0.0485; 0.1827; 0.0000; -0.6998; 0.2600; 0.1488; 0.9274; 0.8971; -0.7009; -0.5169; 0.7301; -0.7258; 0.0647; 0.0000];
   <span class="comment">% Gnorm is a vector of [109X1]</span>
   Gnorm = [0.0000; 0.0000; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0310; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0000; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0310; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0000; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0310; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0000; 0.0800; 0.0566; 0.0800; 0.0800; 0.0310; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0000; 0.0566; 0.0800; 0.0800; 0.0310; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0000; 0.0800; 0.0800; 0.0310; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0000; 0.0800; 0.0310; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0800; 0.0800; 0.0566; 0.0000];
   <span class="comment">% Delta is a vector of [109X1]</span>
   Delta = [0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308; 0.0308];
   <span class="comment">% delta is a vector of [109X1]</span>
   delta = [0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128; 0.0128];
   <span class="comment">% TE is a vector of [109X1]</span>
   TE = [0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636; 0.0636];
   Model.Prot.DiffusionData.Mat = [ Gx Gy Gz Gnorm Delta delta TE];
   <span class="comment">% -----------------------------------------</span>
   </pre><h2 id="7">III- FIT EXPERIMENTAL DATASET</h2><p >-------------------------------------------------------------------------</p><h2 id="8">A- LOAD EXPERIMENTAL DATA</h2><pre >         |- Respective command lines appear if required by dti.
   -------------------------------------------------------------------------
   dti object needs 3 data input(s) to be assigned:</pre><pre class="codeinput"><span class="comment">% DiffusionData</span>
   <span class="comment">% SigmaNoise</span>
   <span class="comment">% Mask</span>
   <span class="comment">% --------------</span>
   
   data = struct();
   <span class="comment">% DiffusionData.nii.gz contains [74   87   50  109] data.</span>
   data.DiffusionData=double(load_nii_data(<span class="string">'dti_data/DiffusionData.nii.gz'</span>));
   <span class="comment">% Mask.nii.gz contains [74  87  50] data.</span>
   data.Mask=double(load_nii_data(<span class="string">'dti_data/Mask.nii.gz'</span>));
   
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><h2 id="9">B- FIT DATASET</h2><pre >           |- This section will fit data.
   -------------------------------------------------------------------------</pre><pre class="codeinput">FitResults = FitData(data,Model,0);
   
   FitResults.Model = Model; <span class="comment">% qMRLab output.</span>
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><pre class="codeoutput">Fitting voxel       3/164005
   ...done   0%
   </pre><h2 id="10">C- SHOW FITTING RESULTS</h2><pre >         |- Output map will be displayed.</pre><pre class="codeinput"><span class="comment">%			|- If available, a graph will be displayed to show fitting in a voxel.</span>
   <span class="comment">% -------------------------------------------------------------------------</span>
   
   qMRshowOutput(FitResults,data,Model);
   </pre><img src="_static/dti_batch_02.png" vspace="5" hspace="5" alt=""> <img src="_static/dti_batch_03.png" vspace="5" hspace="5" alt=""> <h2 id="11">IV- SAVE MAPS AND OBJECT</h2><pre class="codeinput">Model.saveObj(<span class="string">'dti_Demo.qmrlab.mat'</span>);
   FitResultsSave_nii(FitResults, <span class="string">'dti_data/DiffusionData.nii.gz'</span>);
   
   <span class="comment">% Tip: You can load FitResults.mat in qMRLab graphical user interface</span>
   </pre><pre class="codeoutput">Warning: Directory already exists. 
   </pre><h2 id="12">V- SIMULATIONS</h2><pre >   |- This section can be executed to run simulations for 'dti.
   -------------------------------------------------------------------------</pre><h2 id="13">A- Single Voxel Curve</h2><pre >         |- Simulates Single Voxel curves:
                 (1) use equation to generate synthetic MRI data
                 (2) add rician noise
                 (3) fit and plot curve
   -------------------------------------------------------------------------</pre><pre class="codeinput">      x = struct;
         x.L1 = 2;
         x.L2 = 0.7;
         x.L3 = 0.7;
          Opt.SNR = 50;
         <span class="comment">% run simulation using options `Opt(1)`</span>
         figure(<span class="string">'Name'</span>,<span class="string">'Single Voxel Curve Simulation'</span>);
         FitResult = Model.Sim_Single_Voxel_Curve(x,Opt(1));
   
   <span class="comment">% -------------------------------------------------------------------------</span>
   </pre><img src="_static/dti_batch_04.png" vspace="5" hspace="5" alt=""> <h2 id="14">B- Sensitivity Analysis</h2><pre >         |-    Simulates sensitivity to fitted parameters:
                   (1) vary fitting parameters from lower (lb) to upper (ub) bound.
                   (2) run Sim_Single_Voxel_Curve Nofruns times
                   (3) Compute mean and std across runs
   -------------------------------------------------------------------------</pre><pre class="codeinput">      <span class="comment">%              L1            L2            L3</span>
         OptTable.st = [2             0.7           0.7]; <span class="comment">% nominal values</span>
         OptTable.fx = [0             1             1]; <span class="comment">%vary L1...</span>
         OptTable.lb = [0             0             0]; <span class="comment">%...from 0</span>
         OptTable.ub = [5             5             5]; <span class="comment">%...to 5</span>
          Opt.SNR = 50;
          Opt.Nofrun = 5;
         <span class="comment">% run simulation using options `Opt(1)`</span>
         SimResults = Model.Sim_Sensitivity_Analysis(OptTable,Opt(1));
         figure(<span class="string">'Name'</span>,<span class="string">'Sensitivity Analysis'</span>);
         SimVaryPlot(SimResults, <span class="string">'L1'</span> ,<span class="string">'L1'</span> );
   </pre><img src="_static/dti_batch_05.png" vspace="5" hspace="5" alt=""> <p class="footer"><br ><a href="http://www.mathworks.com/products/matlab/">Published with MATLAB R2017b</a><br ></p></div>
