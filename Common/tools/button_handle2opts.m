function opts = button_handle2opts(optsHandles)
ff=fieldnames(optsHandles);
N = length(ff);
for ii = 1:N
    switch get(optsHandles.(ff{ii}),'Style')
        case 'edit'
            opts.(ff{ii}) = str2num(get(optsHandles.(ff{ii}),'String'));
        case 'checkbox'
            opts.(ff{ii}) = get(optsHandles.(ff{ii}),'Value');
        case 'popupmenu'
            list = get(optsHandles.(ff{ii}),'String');
            opts.(ff{ii}) = list{get(optsHandles.(ff{ii}),'Value')};
    end
end