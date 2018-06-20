function opts = button_handle2opts(optsHandles)
% Read buttons values generated using GenerateButtons
% opts = button_handle2opts(optsHandles)
% See also: GenerateButtons
ff=fieldnames(optsHandles);
N = length(ff);
for ii = 1:N
    if strcmp(get(optsHandles.(ff{ii}),'type'),'uitable')
        opts.(ff{ii}) = get(optsHandles.(ff{ii}),'Data');
    else
    switch get(optsHandles.(ff{ii}),'Style')
        case 'edit'
            opts.(ff{ii}) = str2num(get(optsHandles.(ff{ii}),'String'));
        case 'checkbox'
            opts.(ff{ii}) = get(optsHandles.(ff{ii}),'Value');
        case 'popupmenu'
            list = get(optsHandles.(ff{ii}),'String');
            opts.(ff{ii}) = list{get(optsHandles.(ff{ii}),'Value')};
        case 'togglebutton'
            opts.(ff{ii}) = get(optsHandles.(ff{ii}),'Value');
            set(optsHandles.(ff{ii}),'Value',0);
    end
    end
end