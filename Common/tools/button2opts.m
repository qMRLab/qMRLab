function options = button2opts(opts)
io=1;
options = struct();
while io < length(opts)
    if strcmp(opts{io},'PANEL')
        PanelName = opts{io+1}; panelNum = opts{io+2};
        io = io+3;
        for ii=1:panelNum            
            if iscell(opts{io+1})
                options.(genvarname_v2([PanelName '_' opts{io}])) = opts{io+1}{1};
                io = io+2;
            elseif strcmp(opts{io+1},'pushbutton')
                options.(genvarname_v2([PanelName '_' opts{io}])) = false;
                io = io+2;
            else
                options.(genvarname_v2([PanelName '_' opts{io}])) = opts{io+1};
                io = io+2;
            end
        end
    else
        if iscell(opts{io+1})
            options.(genvarname_v2(opts{io})) = opts{io+1}{1};
        elseif strcmp(opts{io+1},'pushbutton')
            options.(genvarname_v2(opts{io})) = false;
            io = io+2;
        else
            options.(genvarname_v2(opts{io})) = opts{io+1};
        end
        io = io+2;
    end
end
