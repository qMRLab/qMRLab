function obj = button2opts(obj)
opts=obj.buttons;
for io = 1:2:length(opts)
    if iscell(opts{io+1})
        obj.options.(genvarname(opts{io})) = opts{io+1}{1};
    else
        obj.options.(genvarname(opts{io})) = opts{io+1};
    end
end
