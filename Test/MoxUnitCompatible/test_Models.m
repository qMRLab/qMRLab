function test_suite=test_Models
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function [MethodList, pathmodels,ModelDir] = list_models
setenv('ISDISPLAY','0')
ModelDir = [fileparts(which('qMRLab.m')) filesep 'Models'];
[MethodList, pathmodels] = sct_tools_ls([ModelDir filesep '*.m'],0,0,2,1);
MethodList = MethodList(~strcmp(MethodList,'CustomExample'));

function test_plotmodel
disp('testing plotmodel...')
MethodList = list_models;
for im = 1:length(MethodList)
    Model = str2func(MethodList{im}); Model = Model();
    if ~Model.voxelwise, continue; end
    disp([class(Model) '...'])
	Model.plotmodel;
end

function test_equation
disp('testing equations...')
MethodList = list_models;
for im = 1:length(MethodList)
    Model = str2func(MethodList{im}); Model = Model();
    if ~Model.voxelwise, continue; end
    disp(class(Model))
    ModelOpt = button2opts(Model.buttons,1);
    clear st Smodel
    for iopt=1:length(ModelOpt) % try all model options
        Model.options = ModelOpt(iopt);
        disp(['Testing ' class(Model) ' option:'])
        disp(Model.options)
        Model = Model.UpdateFields;
        try st{iopt} = Model.st; catch, try st{iopt} = mean([Model.lb(:),Model.ub(:)],2); catch, st{iopt} = ones(length(Model.xnames),1); end; end
        Smodel{iopt} = Model.equation(st{iopt});
        % CHECK CONSITENSY WITH PREVIOUS VERSIONS:
        if exist(['value_' class(Model) '.mat'],'file')
            % compare with Ground Truth
            GT = load(['value_' class(Model) '.mat']);
            [~,ModelOpttest,GTModelOpttest]=comp_struct(ModelOpt,GT.ModelOpt);
            assertTrue(isempty(ModelOpttest) & isempty(GTModelOpttest),evalc('ModelOpttest, GTModelOpttest'))
            assertVectorsAlmostEqual(st{iopt},GT.st{iopt},'relative',1e-4,[MethodList{im} ' changed... value_' MethodList{im} '.mat has to be regenerated'])
            assertVectorsAlmostEqual(Smodel{iopt},GT.Smodel{iopt},'relative',1e-2,['Testing consistency of equation for Model ' MethodList{im}])
        elseif iopt == length(ModelOpt)
            save(['value_' class(Model) '.mat'],'Smodel','st','ModelOpt')
        end
    end
end


function test_Sim
disp('testing Simulation Single Voxel Curve...')
MethodList = list_models;
for im = 1:length(MethodList)
    Model = str2func(MethodList{im}); Model = Model();
    if ~Model.voxelwise, continue; end
    disp(class(Model))
    try Opt = button2opts(Model.Sim_Single_Voxel_Curve_buttons,1); end
    try st = Model.st; catch, try st = mean([Model.lb(:),Model.ub(:)],2); catch, st = ones(length(Model.xnames),1); end; end
    [Opt(:).SNR] = deal(1000);
    for iopt=1:length(Opt) % Test all simulation options
        disp(['Testing ' class(Model) ' simulation option:'])
        disp(Opt(iopt))
        FitResults = Model.Sim_Single_Voxel_Curve(st,Opt(iopt));
        % Compare inputs and outputs
        fnm=fieldnames(FitResults);
        FitResults = rmfield(FitResults,fnm(~ismember(fnm,Model.xnames))); fnm=fieldnames(FitResults);
        [~,FitResults,GroundTruth]=comp_struct(FitResults,mat2struct(st,Model.xnames),[],[],.50);
        assertTrue(isempty(FitResults) & isempty(GroundTruth),evalc('FitResults, GroundTruth'))
    end
    disp ..ok
end
