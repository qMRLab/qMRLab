function test_suite=SimTest_montecarlo_test
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
    
    function TestSetup
    setenv('ISDISPLAY','0') % go faster! Fit only 2 voxels in FitData.m
    setenv('ISCITEST','1')
    
    function test_Sim
    disp('===========================================')
    disp('Running simulation test for charmed');
    disp('testing Simulation Single Voxel Curve...');
    
    
    Model = str2func('charmed'); Model = Model();
    savedModel_fname = fullfile(fileparts(which('qMRLab')),'Test','MoxUnitCompatible','static_savedModelsforRetrocompatibility',['charmed.qmrlab.mat']);
    if ~exist(savedModel_fname,'file')
    Model.saveObj(savedModel_fname);
    else
    Model = Model.loadObj(savedModel_fname);
    end
    
    load('pack_testing.mat'); % load a predefined packing
    numelparticle = 10;
    permeability = 0;
    D = 1.5;
    SignalMC = Model.Sim_MonteCarlo_Diffusion(numelparticle, permeability, D, packing, axons);

    disp ..ok
    
    
    function TestTeardown
    setenv('ISDISPLAY','')
    setenv('ISCITEST','')% go faster! Fit only 2 voxels in FitData.m
    