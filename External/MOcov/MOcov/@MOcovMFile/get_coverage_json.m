function json=get_coverage_json(obj, root_dir)
% Get JSON coverage representation
%
% json=get_coverage_json(obj, root_dir)
%
% Inputs:
%   obj                 MOcovMFile instance
%   root_dir            git root directory in which the file represented
%                       by obj resides
%
% Output:
%   json                JSON String representation of coverage, with
%                       elements:
%                       'name'          filename, relative to root_dir
%                       'source_digest' MD5 checksum of file contents
%                       'coverage'      Array with number of times each
%                                       line was executed; or null for
%                                       lines that cannot not be executed.
%
% Notes:
%   - this output can be used by the coveralls.io online coverage service
%     in combination with travis-ci

    name=mocov_get_relative_path(root_dir,obj.filename);
    source_digest=mocov_util_md5(obj.filename);
    coverage=get_coverage(obj);

    json=sprintf(['{ "name": "%s",\n',...
                    '"source_digest": "%s",\n'...
                    '"coverage": %s\n }\n'],...
                    name,source_digest,coverage);


function json_coverage=get_coverage(obj)
    executable=get_lines_executable(obj);
    executed_count=get_lines_executed_count(obj);

    n=numel(executable);

    json_parts=cell(1,2*n+1);
    json_parts{1}='[';
    for k=1:n
        line_executable=executable(k);

        if line_executable
            coverage_str=sprintf('%d',executed_count(k));
        else
            coverage_str='null';
        end

        json_parts{2*k}=coverage_str;
        if k<n
            suffix=',';
        else
            suffix=']';
        end

        json_parts{2*k+1}=suffix;
    end

    json_coverage=sprintf('%s',json_parts{:});