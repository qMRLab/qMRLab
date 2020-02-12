function [dat,hdr,list] = nii_load(filename,untouch,intrp,applyslope)
% [dat,hdr,list] = nii_load(filename,untouch) loads nifti files in
% LPI orientation
%
% if multiple files, the first image is used as reference
% INPUT
%   filename        char (handles wildcards **/ and *) or cell array of char
%   untouch         if false or empty, matrix is rotated to be in LPI
%                    orientation
%
% OUTPUT
%   dat             cell array of 4D matrix
%   hdr             header of the reference image (first image)
%   list            cell array of char listing filenames (useful if wildcards were used)
%
% EXAMPLE
%   [dat,hdr,list] = nii_load('**\*.nii.gz')
%   img = cat(5,dat{:});
%   img = mean(img,5);
%   nii_save(img,hdr,'Tmean.nii.gz')
%
% See also: nii_save, nii_get_orient, nii_set_orient, nii_reset_orient

if ~isdeployed
    A = which('nii_tool');
    if isempty(A)
        error('Dependency to Xiangrui Li NIFTI tools is missing. http://www.mathworks.com/matlabcentral/fileexchange/42997');
    end
end

if ~exist('intrp','var'), intrp = 'linear'; end
if ~exist('applyslope','var'), applyslope = []; end % ask the user

outputtype='cell';
if isstruct(filename)% nii structure loaded with nii_tool?
    filename = {filename};
end

if ~iscell(filename) % not a cell array of filenames
    if strcmp(filename(1:min(3,end)),'**/') || strcmp(filename(1:min(3,end)),'**\')
        list = tools_ls(filename(4:end),1,1,2,1);
    else
        list = tools_ls(filename,1,1,2,0);
    end
    if isempty(strfind(filename,'*'))
        outputtype='matrix';
    end
else
    list = filename;
end
list(cellfun(@ischar,list)) = cellfun(@(X) X{1},cellfun(@(X) strsplit(X,','),list(cellfun(@ischar,list)),'uni',0),'uni',0);

if isempty(list)
    error(['no files match ' filename])
end

dat = {};
for ff=1:length(list)
    if isstruct(list{ff}) && ~isfield(list{ff},'img') % skip... header only
        continue
    end
    
    % LOAD AND RESLICE
    hdr_ref = nii_reset_orient(list{1}); % Set hdr.dim back to initial orientation
    if ff==1
        nii = nii_tool('load',list{ff});
    else
        nii = nii_xform(list{ff},hdr_ref,[],intrp);
    end
    
    if nargin==1 || (~isempty(untouch) && ~untouch)
        orient = nii_get_orient(nii.hdr);
        nii = nii_set_orient(nii);
    end
    if ff==1
        hdr = nii.hdr;
    end
    if ~ismember(nii.hdr.scl_slope, [0,1]) || nii.hdr.scl_inter ~= 0
        warning(sprintf(['\nScaling factor detected in the Nifty header (field ''scl_slope'')\n\nScaling slope y = %.2g x + %.2g\n\n(Data will be converted from %s to double > memory intensive)\n'],nii.hdr.scl_slope,nii.hdr.scl_inter,class(nii.img)))
        if isempty(applyslope) 
            if numel(nii.img)*8/1e6 < 300 % 300 Mb limit to auto apply slope
                applyslope = true;
            else
                if isstruct(list{ff})
                    Name = list{ff}.hdr.file_name;
                else
                    Name = list{ff};
                end
                applyslope = questdlg(sprintf('Scaling factor detected in the Nifty header (field ''scl_slope'')\n\nApply scaling slope y = %.2g x + %.2g?\n\n(Data will be converted from %s to double > %g Mb free memory is required)',nii.hdr.scl_slope,nii.hdr.scl_inter,class(nii.img),numel(nii.img)*8/1e6), Name,'Yes','No','Yes');
            end
        end
    else
        applyslope = 0;
    end
    switch applyslope
        case {'Yes',1}
            nii = nii.hdr.scl_slope*double(nii.img)+nii.hdr.scl_inter;
        case {'No',0}
            nii = nii.img;
    end
    
    dat(end+1:end+size(nii(:,:,:,:,:),5)) = mat2cell(nii(:,:,:,:,:),size(nii,1),size(nii,2),size(nii,3),size(nii,4),ones(1,size(nii(:,:,:,:,:),5)));
end
if strcmp(outputtype,'matrix')
    dat = dat{1};
end


function [list, path]=tools_ls(fname, keeppath, keepext, folders,arborescence,select)
% [list, path]=tools_ls(fname, keeppath?, keepext?, folders?,recursive?)
% Example: tools_ls('ep2d*')
% example 2: tools_ls('*',[],[],1) --> folders only
% example 3: tools_ls('*',[],[],2) --> files only

if nargin < 2, keeppath=0; end
if nargin < 3, keepext=1; end
if nargin < 4 || isempty(folders), folders=0; end
if nargin < 6 || isempty(select), select=0; end
if nargin < 5, arborescence=0; end

% [list, path]=tools_ls('*T.txt);
list=dir(fname);
[path,name,ext]= fileparts(fname); 
path=[path filesep]; name = [name ext];
if strcmp(path,filesep)
    path=['.' filesep];
end

if folders==1
    list=list(cat(1,list.isdir));
elseif folders==2
    list=list(~cat(1,list.isdir));
end

% sort by name
list=sort_nat({list.name})';


% remove files starting with .
list(cellfun(@(x) strcmp(x(1),'.'), list))=[];
if keeppath
    for iL=1:length(list)
        list{iL}=[path list{iL}];
    end
end
pathcur = path;
path = repmat({path},[length(list),1]);

if ~keepext
    list=cellfun(@(x) sct_tool_remove_extension(x,keeppath),list,'UniformOutput',false);
end

if arborescence
    listdir = tools_ls(pathcur,1,1,1);
    for idir = 1:length(listdir)
        [listidir, pathidir]=tools_ls([listdir{idir} filesep name], keeppath, keepext, folders,arborescence,0);
        list = [list; listidir];
        path = cat(1,path, pathidir{:});
    end
end

if select, list=list{select}; end

function [cs,index] = sort_nat(c,mode)
%sort_nat: Natural order sort of cell array of strings.
% usage:  [S,INDEX] = sort_nat(C)
%
% where,
%    C is a cell array (vector) of strings to be sorted.
%    S is C, sorted in natural order.
%    INDEX is the sort order such that S = C(INDEX);
%
% Natural order sorting sorts strings containing digits in a way such that
% the numerical value of the digits is taken into account.  It is
% especially useful for sorting file names containing index numbers with
% different numbers of digits.  Often, people will use leading zeros to get
% the right sort order, but with this function you don't have to do that.
% For example, if C = {'file1.txt','file2.txt','file10.txt'}, a normal sort
% will give you
%
%       {'file1.txt'  'file10.txt'  'file2.txt'}
%
% whereas, sort_nat will give you
%
%       {'file1.txt'  'file2.txt'  'file10.txt'}
%
% See also: sort

% Version: 1.4, 22 January 2011
% Author:  Douglas M. Schwarz
% Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
% Real_email = regexprep(Email,{'=','*'},{'@','.'})


% Set default value for mode if necessary.
if nargin < 2
	mode = 'ascend';
end

% Make sure mode is either 'ascend' or 'descend'.
modes = strcmpi(mode,{'ascend','descend'});
is_descend = modes(2);
if ~any(modes)
	error('sort_nat:sortDirection',...
		'sorting direction must be ''ascend'' or ''descend''.')
end

% Replace runs of digits with '0'.
c2 = regexprep(c,'\d+','0');

% Compute char version of c2 and locations of zeros.
s1 = char(c2);
z = s1 == '0';

% Extract the runs of digits and their start and end indices.
[digruns,first,last] = regexp(c,'\d+','match','start','end');

% Create matrix of numerical values of runs of digits and a matrix of the
% number of digits in each run.
num_str = length(c);
max_len = size(s1,2);
num_val = NaN(num_str,max_len);
num_dig = NaN(num_str,max_len);
for i = 1:num_str
	num_val(i,z(i,:)) = sscanf(sprintf('%s ',digruns{i}{:}),'%f');
	num_dig(i,z(i,:)) = last{i} - first{i} + 1;
end

% Find columns that have at least one non-NaN.  Make sure activecols is a
% 1-by-n vector even if n = 0.
activecols = reshape(find(~all(isnan(num_val))),1,[]);
n = length(activecols);

% Compute which columns in the composite matrix get the numbers.
numcols = activecols + (1:2:2*n);

% Compute which columns in the composite matrix get the number of digits.
ndigcols = numcols + 1;

% Compute which columns in the composite matrix get chars.
charcols = true(1,max_len + 2*n);
charcols(numcols) = false;
charcols(ndigcols) = false;

% Create and fill composite matrix, comp.
comp = zeros(num_str,max_len + 2*n);
comp(:,charcols) = double(s1);
comp(:,numcols) = num_val(:,activecols);
comp(:,ndigcols) = num_dig(:,activecols);

% Sort rows of composite matrix and use index to sort c in ascending or
% descending order, depending on mode.
[unused,index] = sortrows(comp);
if is_descend
	index = index(end:-1:1);
end
index = reshape(index,size(c));
cs = c(index);

