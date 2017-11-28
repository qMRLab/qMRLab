% SOMA - Self-Organizing Migration Algorithm
% visit http://www.ft.utb.cz/people/zelinka/soma/
% written by ibisek, MMV
%
% STRATEGY "ALL-TO-ONE (LEADER)", the basic version

function [retVal] = soma_all_to_one(optimizedFunction, GenerateRandSchemeFunc, CheckSchemeInBoundFunc, migrations, popSize, nV, ProtRef)

hfig=gca;

%%
% optimization parameter (recommanded values : step = 0.11; pathLength =3; prt = 0.1; minDiv = 0;)
opt.step       = 0.11;
opt.pathLength = 3;
opt.prt        = 0.1;
opt.nV = nV;

% create "instance" of optimized function
opt.costFunctionHandle = optimizedFunction;
opt.CheckSchemeInBoundFunc = CheckSchemeInBoundFunc;
RefCost = optimizedFunction(ProtRef);

% random population within borders and cost values
costValues = zeros(1,popSize);
population = zeros(nV,size(GenerateRandSchemeFunc(),2),popSize);
j_progress('Generate Random Protocols...')
for i=1:popSize
    j_progress(i/popSize)
    population(:,:,i) = GenerateRandSchemeFunc();
    individual = population(:,:,i);
    costValues(1,i) = opt.costFunctionHandle( individual);
end
j_progress('...done')

% find the leader ( individual with the lowest cost value )
[~,indexOfLeader] = min(costValues);

globalErrorHistory = zeros(migrations,1);

%%
% Create Wait Bar
h = waitbar(0, sprintf('Migration 0/%0.0f',migrations), 'Name', 'Optimizing CRLB',...
            'CreateCancelBtn','if ~strcmp(get(gcbf,''Name''),''Canceling...''), set(gcbf,''Name'',''Canceling...''), setappdata(gcbf,''canceling'',1), else, delete(gcbf); end');
setappdata(h,'canceling',0);
j_progress('MIGRATIONS IN PROCESS...\n')

% Migrate
for mig = 1:migrations

    j_progress((mig-1)/migrations)
    % migrate individuals to the leader (except leader to himself, of course)
    Leader = population(:,:,indexOfLeader);
    for i = 1:popSize
        if indexOfLeader ~=i
            [costValues(i), population(:,:,i)] = migrationfun(population(:,:,i),Leader,costValues(i),opt);
        end
    end % for i
    
    % find the leader (individual with the lowest cost value)
    [~,indexOfLeader] = min(costValues);
    globalErrorHistory(mig) = costValues(indexOfLeader);
    
    schemeLEADER = population(:,:,indexOfLeader);
    
    LEADER_hist(:,:,mig)=schemeLEADER;
    plot(hfig,linspace(1,mig,mig), globalErrorHistory(1:mig),'-*')
    hold(hfig,'on') ; plot(hfig,[1 mig],[RefCost RefCost],'--r')
    hold(hfig,'off');
    xlabel(hfig,'migrations') ; ylabel(hfig,'CRLB') ; title(hfig,'optimization history : SOMA All to One CRLB')
    legend(hfig,{'Optimized Protocol','Original Protocol'})
    drawnow
    
    if ishandle(h)
        waitbar((mig-1)/migrations,h,sprintf('Migration %0.0f/%0.0f',mig-1,migrations));
        if getappdata(h,'canceling')
            break
        end
    end
end
delete(h)       % DELETE the waitbar; don't try to CLOSE it.


% return values:
retVal.schemeLEADER = schemeLEADER;
retVal.costValue = costValues(1,indexOfLeader);
retVal.history = globalErrorHistory;
retVal.history_scheme = LEADER_hist;



function [costValues, Individual] = migrationfun(Individual,leaderPosition,costValues,opt)
% Check if this individual is not leader. If true, skip it.

% store the individual's start position
startPositionOfIndividual = Individual;

% Let's migrate!
for t=0:opt.step:opt.pathLength
    
    % Generate new PRTVector for each step of this individual
    PRTVector = zeros(opt.nV,size(Individual,2));
    prtVectorContainOnlyZeros = true;
    while(prtVectorContainOnlyZeros)
        for j=1:opt.nV*size(Individual,2)
            if rand<opt.prt
                PRTVector(j) = 1;
                prtVectorContainOnlyZeros = false;
            else
                PRTVector(j) = 0;
            end
        end
    end
    
    %new position for all dimensions:
    tmpIndividual = startPositionOfIndividual + (leaderPosition - startPositionOfIndividual ) .* t .* PRTVector;
    
    %check boundaries
    newtmpIndividual = opt.CheckSchemeInBoundFunc(tmpIndividual);
    tmpIndividual = newtmpIndividual;
    
    tmpCostValue = feval(opt.costFunctionHandle, tmpIndividual);
    
    if tmpCostValue<costValues
        costValues = tmpCostValue;   % store better CV and position
        Individual = tmpIndividual;
    end
    
end % for t

