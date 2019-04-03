function dat = setviewplane(dat,viewplane)
if nargin<2 || isempty(viewplane), viewplane = 'axial'; end
if ~iscell(dat), dat = {dat}; numericdat = true; 
else
    numericdat = false;
end
switch viewplane
    case 'sagittal'
        dat = cellfun(@(x) permute(x,[2 3 1 4 5]),dat,'UniformOutput',false);
    case 'coronal'
        dat = cellfun(@(x) permute(x,[1 3 2 4 5]),dat,'UniformOutput',false);
end

if numericdat, dat = dat{1}; end
