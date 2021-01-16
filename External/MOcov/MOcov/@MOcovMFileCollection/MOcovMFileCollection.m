function obj=MOcovMFileCollection(root_dir, method, monitor, exclude_pat)
% instantiate MOcovMFileCollection
%
% obj=MOcovMFileCollection(root_dir, method, monitor)
%
% Inputs:
%   root_dir                root directory containing m-files to be
%                           covered.
%   method                  Coverage method, one of:
%                           - 'file'    rewrite m-files after adding
%                                       statements that record which lines
%                                       are covered
%                           - 'profile' use Matlab profiler
%                           default: 'file'
%   monitor                 optional MOcovProgressMonitor instance
%   exclude_pat             Optional cell array of patterns to exclude.
%
% See also: mocov

    if nargin<4 || isempty(exclude_pat)
        exclude_pat={};
    end

    if nargin<3 || isempty(monitor)
        monitor=MOcovProgressMonitor();
    end

    if nargin<2 || isempty(method);
        method='file';
    end

    props=struct();
    props.root_dir=root_dir;
    props.monitor=monitor;
    props.exclude_pat=exclude_pat;
    props.mfiles=[];
    props.orig_path=[];
    props.temp_dir=[];
    props.method=method;
    obj=class(props,'MOcovMFileCollection');

