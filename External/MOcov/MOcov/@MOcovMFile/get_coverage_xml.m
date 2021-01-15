function xml=get_coverage_xml(obj, root_dir)
% Get XML coverage representation
%
% xml=get_coverage_json(obj, root_dir)
%
% Inputs:
%   obj                 MOcovMFile instance
%   root_dir            git root directory in which the file represented
%                       by obj resides
%
% Output:
%   json                XML string representation of coverage, with
%                       line-rate set according to coverage and branch-rate
%                       set to zero.
%
% Notes:
%   - this output can be used by the shippable.com online service
%
    relative_fn=mocov_get_relative_path(root_dir,obj.filename);

    [pth,nm,ext]=fileparts(relative_fn);

    r=get_coverage_ratio(obj);

    % for now, consider all functions as being in one package
    % and treat them all as one big file
    header=sprintf(['<class name="%s" filename="%s" '...
                        'line-rate="%.3f" '...
                        'branch-rate="0.0">\n'...
                        '<methods></methods>'],...
                    nm,relative_fn,r);
    footer='</class>';

    body=get_reportable_lines_xml(obj);
    xml=sprintf('%s',header,body,footer);



function xml=get_reportable_lines_xml(obj)
    idxs=find(get_lines_executable(obj));
    n=numel(idxs);

    executed_count=get_lines_executed_count(obj);
    lines=cell(1,n);
    for k=1:n
        idx=idxs(k);
        hits=executed_count(idx);
        lines{k}=sprintf('<line number="%d" hits="%d" branch="false"/>',...
                        idx,hits);
    end

    xml=sprintf('%s\n','<lines>',lines{:},'</lines>');


function r=get_coverage_ratio(obj)
    executable=get_lines_executable(obj);
    numerator = sum(get_lines_executed(obj) & executable);
    denominator = sum(executable);
    if denominator==0
        r=1;
    else
        r=numerator/denominator;
    end
