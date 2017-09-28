function [list, path]=sct_tools_ls(fname, keeppath, keepext, folders,arborescence,select)
% [list, path]=sct_tools_ls(fname, keeppath?, keepext?, folders?,recursive?)
% Example: sct_tools_ls('ep2d*')
% example 2: sct_tools_ls('*',[],[],1) --> folders only
% example 3: sct_tools_ls('*',[],[],2) --> files only

if nargin < 2, keeppath=0; end
if nargin < 3, keepext=1; end
if nargin < 4 || isempty(folders), folders=0; end
if nargin < 6 || isempty(select), select=0; end
if nargin < 5, arborescence=0; end

% [list, path]=sct_tools_ls('*T.txt);
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
    listdir = sct_tools_ls(pathcur,1,1,1);
    for idir = 1:length(listdir)
        [listidir, pathidir]=sct_tools_ls([listdir{idir} filesep name], keeppath, keepext, folders,arborescence,0);
        list = [list; listidir];
        path = cat(1,path, pathidir{:});
    end
end

if select, list=list{select}; end