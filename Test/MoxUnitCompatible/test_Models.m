function test_suite=test_Models
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function [MethodList, pathmodels,ModelDir] = list_models
ModelDir = [fileparts(which('qMRLab.m')) filesep 'Models'];
[MethodList, pathmodels] = sct_tools_ls([ModelDir filesep '*.m'],0,0,2,1);
MethodList = MethodList(~strcmp(MethodList,'CustomExample'));

function test_plotmodel
disp('testing plotmodel...')
MethodList = list_models;
for im = 1:length(MethodList)
    Model = str2func(MethodList{im}); Model = Model();
    disp([class(Model) '...'])
    if ~moxunit_util_platform_is_octave
        if ismethod(Model,'plotmodel')
            disp ..ok
        else
            disp('..skipped (plotmodel method does not exist)')
        end
    else
        try    Model.plotmodel;
            disp ..ok
        catch err
            if isempty(strfind(err.message,'unknown method or property: plotmodel'))
                Model.plotmodel;
            else
                disp('..skipped (plotmodel method does not exist)')
            end
        end
    end
end

function test_Sim
disp('testing Simulation Single Voxel Curve...')
MethodList = list_models;
for im = 1:length(MethodList)
    Model = str2func(MethodList{im}); Model = Model();
    disp(class(Model))
    try %ismethod(Model,'Sim_Single_Voxel_Curve')
        try Opt = button2opts(Model.Sim_Single_Voxel_Curve_buttons); end
        try st = Model.st; catch, try st = mean([Model.lb(:),Model.ub(:)],2); catch, st = ones(length(Model.xnames),1); end; end
        Opt.SNR = 1000;
        FitResults = Model.Sim_Single_Voxel_Curve(st,Opt);

        % Compare inputs and outputs
        fnm=fieldnames(FitResults);
        FitResults = rmfield(FitResults,fnm(~ismember(fnm,Model.xnames))); fnm=fieldnames(FitResults);
        [~,FitResults,GroundTruth]=comp_struct(FitResults,mat2struct(st,Model.xnames),[],[],.20);
        assertTrue(isempty(FitResults) & isempty(GroundTruth),evalc('FitResults, GroundTruth'))
        disp ..ok
    catch err
        if isempty(strfind(err.message,'No appropriate method, property, or field ''Sim_Single_Voxel_Curve''')) && isempty(strfind(err.message,'unknown method or property: Sim_Single_Voxel_Curve'))
            FitResults = Model.Sim_Single_Voxel_Curve(st,Opt);
            
            % Compare inputs and outputs
            fnm=fieldnames(FitResults);
            FitResults = rmfield(FitResults,fnm(~ismember(fnm,Model.xnames))); fnm=fieldnames(FitResults);
            [~,FitResults,GroundTruth]=comp_struct(FitResults,mat2struct(st,Model.xnames),[],[],.20);
            assertTrue(isempty(FitResults) & isempty(GroundTruth),evalc('FitResults, GroundTruth'))
            disp ..ok
        else
            disp('..skipped (Sim_Single_Voxel_Curve method does not exist)')
        end
    end
end

