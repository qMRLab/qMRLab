function obj=add_lines_executed_count(obj, lines)
% increase line executed counter
%
% obj=add_lines_executed_count(obj, lines)
%
% Inputs:
%   obj                 MOcovMFile instance
%   lines               Nx1 vector with counts that a line represented
%                       by obj was executed
%
% Output:
%   obj                 MOcovMFile instance with the counts increased


    n=find(lines>0,1,'last');

    obj_n=numel(get_lines(obj));
    if obj_n<n
        error(['Cannot set line %d to be executed, as '...
                '%s has only %d lines'],...
                n, get_filename(obj), obj_n);
    end

    obj.executed_count(1:n)=obj.executed_count(1:n)+lines(1:n);
