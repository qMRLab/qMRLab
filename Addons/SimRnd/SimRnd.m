function SimRndResults = SimRnd(Model, RndParam, Opt)
%VaryRndParam Multi Voxel simulation of normally distributed parameters

fields = Model.xnames;
for ii = 1:length(fields)
    SimRndResults.(fields{ii}) = zeros(n,1);
end

% Create waitbar
h = waitbar(0, sprintf('Data 0/%0.0f',n), 'Name', 'Simulating data',...
    'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)
setappdata(0,'Cancel',0);

tic;
for ii = 1:n
    
    Fit = Model.Sim_Single_Voxel_Curve(RndParam(:,1),Opt);
    fields = fieldnames(Fit);
    
    for jj = 1:length(fields)
        SimRndResults.(fields{jj})(ii) = Fit.(fields{jj});
    end
        
    % Update waitbar
    if getappdata(h,'canceling');  break;  end
    waitbar(ii/n,h,sprintf('Data %0.0f/%0.0f',ii,n));
end

delete(h);
SimRndResults.time = toc
SimRndResults.fields = fields;
end