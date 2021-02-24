function SimVaryResults = SimVary(obj, runs, OptTable, Opts)
% Performs Sensitivity analysis on Model object
% Each Parameter (obj.xnames) is varied in 10 steps between OptTable.lb and OptTable.ub.
% Noise is added N=runs times and simulated MR signals is fitted using obj.Sim_Single_Voxel_Curve
%
% USAGE: SimVaryResults = SimVary(obj, runs, OptTable, Opts)
%
%        obj: qMR Model
%        runs: Number of runs
%        OptTable: structure with vectors defining options for each fitting parameters obj.xnames
%               OptTable.fx: true/false. Vary this parameter?
%               OptTable.st: Nominal Values
%               OptTable.lb: Vary from lb...
%               OptTable.ub: ..to ub value
%        Opts.SNR
%

Nsteps = 10;

if ~exist('OptTable','var') || isempty(OptTable), OptTable = obj; end % use fitting boundaries
if ~exist('Opts','var') || isempty(Opts), Opts.SNR = 50; end
if isempty(getenv('ISCITEST')) || str2double(getenv('ISCITEST'))==0
    waitbarcreate = true;
else
    waitbarcreate = false;
    Nsteps=3;
end

if ~isempty(getenv('ISDOC')), Nsteps=10; end

fx = [OptTable.fx];
st = [OptTable.st];
lb = [OptTable.lb];
ub = [OptTable.ub];

for pp=1:length(fx)
    if ~fx(pp)
        Sens.x = linspace(lb(pp),ub(pp),Nsteps);
        % Create waitbar
        if waitbarcreate
            h = waitbar(0, sprintf('Data 0/%0.0f',length(Sens.x)), 'Name', sprintf('Simulating %s sensitivity data', obj.xnames{pp}),...
                'CreateCancelBtn', 'if ~strcmp(get(gcbf,''Name''),''canceling...''), setappdata(gcbf,''canceling'',1); set(gcbf,''Name'',''canceling...''); else delete(gcbf); end');
            setappdata(h,'canceling',0);
        end
        setappdata(0,'Cancel',0);
        
        for ii=1:length(Sens.x)
            x = st; x(pp)=Sens.x(ii);
            for N=1:runs
                if waitbarcreate && (~ishandle(h) || getappdata(h,'canceling')); setappdata(0,'Cancel',1); break; end
                Fittmp = obj.Sim_Single_Voxel_Curve(x, Opts,0);
                if ~isfield(Sens,'fit')
                    Sens.fit = Fittmp;
                else
                    for ff=fieldnames(Fittmp)'
                        Sens.fit.(ff{1})(ii,N) = Fittmp.(ff{1})(1);
                    end
                end
                %if ~ishandle(h), return; end
            end
            if waitbarcreate && (~ishandle(h) || getappdata(h,'canceling')); break; end
            if waitbarcreate && ishandle(h)
                waitbar(ii/length(Sens.x),h,sprintf('Data %0.0f/%0.0f',ii,length(Sens.x)));
            end
        end
        
        if waitbarcreate
            delete(h)       % DELETE the waitbar; don't try to CLOSE it.
        end
        
        for ff=fieldnames(Sens.fit)'
            Sens.(ff{1}).mean = mean(Sens.fit.(ff{1}),2);
            Sens.(ff{1}).std = std(Sens.fit.(ff{1}),0,2);
            Sens.(ff{1}).GroundTruth = st(strcmp(obj.xnames,ff{1}));
        end
        SimVaryResults.(obj.xnames{pp})=Sens;
    end
end