function addtryfunc(listobj)
% listobj = findobj('Type','uicontrol');

for iuic=1:length(listobj)
    CB = get(listobj(iuic),'Callback');
    if ~isempty(CB)
        if ischar(CB)
            CB = ['try, ' CB ', catch err, qMR_reportBug(err); end'];
            set(listobj(iuic),'Callback', CB)
        else
            switch nargin(CB)
                case 1
                    set(listobj(iuic),'Callback', @(a) tryfunc(CB, a))
                case 2
                    set(listobj(iuic),'Callback', @(a,b) tryfunc(CB, a, b))
                case 3
                    set(listobj(iuic),'Callback', @(a, b, c) tryfunc(CB, a, b, c))
                case 4
                    set(listobj(iuic),'Callback', @(a, b, c, d) tryfunc(CB, a, b, c, d))
                case 0
                    set(listobj(iuic),'Callback', @() tryfunc(CB))
            end
        end
    end
end