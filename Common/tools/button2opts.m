function options = button2opts(opts,all)
if ~exist('all','var'), all=false; end % output all possible options
io=1;
options = struct();
while io < length(opts)
    if strcmp(opts{io},'PANEL')
        PanelName = opts{io+1}; panelNum = opts{io+2};
        io = io+3;
        for ii=1:panelNum            
            if iscell(opts{io+1})
                [options(:).(genvarname_v2([PanelName '_' opts{io}]))] = deal(opts{io+1}{1});
                if all
                    for iall=2:length(opts{io+1})
                        options(end+1) = options(1);
                        options(end).(genvarname_v2([PanelName '_' opts{io}]))=opts{io+1}{iall};
                    end
                end
                io = io+2;
            elseif strcmp(opts{io+1},'pushbutton')
                [options(:).(genvarname_v2([PanelName '_' opts{io}]))] = deal(false);
                io = io+2;
            else
                [options(:).(genvarname_v2([PanelName '_' opts{io}]))] = deal(opts{io+1});
                if all && islogical(opts{io+1})
                    options(end+1) = options(1);
                    options(end).(genvarname_v2([PanelName '_' opts{io}]))=~opts{io+1}; 
                end
                io = io+2;
            end
        end
    else
        if iscell(opts{io+1})
            [options(:).(genvarname_v2(opts{io}))] = deal(opts{io+1}{1});
            if all
                for iall=2:length(opts{io+1})
                    options(end+1) = options(1);
                    options(end).(genvarname_v2(opts{io}))=opts{io+1}{iall};
                end
            end
        elseif strcmp(opts{io+1},'pushbutton')
            [options(:).(genvarname_v2(opts{io}))] = deal(false);
        else
            [options(:).(genvarname_v2(opts{io}))] = deal(opts{io+1});
            if all && islogical(opts{io+1})
                options(end+1) = options(1);
                options(end).(genvarname_v2(opts{io}))=~opts{io+1};
            end
        end
        io = io+2;
    end
end
