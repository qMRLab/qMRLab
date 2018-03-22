function test_suite=equation_test
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function TestSetup
setenv('ISDISPLAY','0') % go faster! Fit only 2 voxels in FitData.m

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
        try Model = Model.UpdateFields; end
        try st{iopt} = Model.st; catch, try st{iopt} = mean([Model.lb(:),Model.ub(:)],2); catch, st{iopt} = ones(length(Model.xnames),1); end; end
        Smodel{iopt} = Model.equation(st{iopt});
        % CHECK CONSITENSY WITH PREVIOUS VERSIONS:
        if exist(['value_' class(Model) '.mat'],'file')
            % compare with Ground Truth
            GT = load(['value_' class(Model) '.mat']);
            [~,ModelOpttest,GTModelOpttest]=comp_struct(ModelOpt,GT.ModelOpt);
            if ~isempty(ModelOpttest) || ~isempty(GTModelOpttest)
                msg = [MethodList{im} ' buttons/options has changed' evalc('ModelOpttest, GTModelOpttest')]; 
            else
                msg = '';
            end
            assertVectorsAlmostEqual(st{iopt},GT.st{iopt},'relative',1e-4,[MethodList{im} ' starting point (st) changed... ' msg ' value_' MethodList{im} '.mat has to be regenerated.'])
            assertVectorsAlmostEqual(Smodel{iopt},GT.Smodel{iopt},'relative',1e-2,['Synthetic signal obtained from ' MethodList{im} ' equation is not consistent with previous versions... ' msg])
        elseif iopt == length(ModelOpt)
            save(['value_' class(Model) '.mat'],'Smodel','st','ModelOpt')
        end
    end
end

function TestTeardown
setenv('ISDISPLAY','') % go faster! Fit only 2 voxels in FitData.m
