function state=mocov_line_covered(varargin)
% sets a line in an mfile to 'covered' state
%
% Usages:
%   1) state=mocov_line_covered();
%
%      Queries the current state; state is a struct with fields:
%       .keys           Nx1 cell containing n filenames
%       .line_count    Nx1 cell containing how often each line for each
%                       filename was executed
%
%   2) mocov_line_covered(state)
%
%      Sets the state; state must be a cell with fields .keys and
%      .line_count
%
%   3) mocov_line_covered(idx, fn, line_number, count)
%
%      Add count times that line with line_mumber in file fn is covered.
%      To avoid lookup time, it is required that in the internal state,
%      .keys{index}==fn.
%
% Notes:
%   - this function is used to keep track of which files have been executed
%     across a set of .m files.
%
% NNO May 2014


    persistent cached_keys;
    persistent cached_line_count;

    % initialize persistent variables, if necessary
    if isnumeric(cached_keys)
        cached_keys=cell(0);
        cached_line_count=cell(0);
    end

    switch nargin
        case 0
            % query the state
            state=struct();
            state.keys=cached_keys;
            state.line_count=cached_line_count;
            return;

        case 1
            % set the state
            state=varargin{1};
            if isempty(state)
                state=struct();
                state.keys=cell(0);
                state.line_count=cell(0);
            end

            cached_keys=state.keys;
            cached_line_count=state.line_count;
            return

        case 4
            % add a line covered
            index=varargin{1};
            key=varargin{2};
            line=varargin{3};
            count=varargin{4};

            state=[];

        otherwise
            error('illegal input');
    end

    cached_keys_too_small=numel(cached_keys)<index;
    if cached_keys_too_small
        cached_keys{2*index}=[];
        cached_line_count{2*index}=[];
    end

    if cached_keys_too_small || isempty(cached_keys{index})
        cached_keys{index}=key;
        cached_line_count{index}=zeros(10,1);
    elseif ~isequal(cached_keys{index},key)
        error('Key mismatch, %s ~= %s', cached_keys{index}, key);
    end

    if numel(cached_line_count{index})<line
        cached_line_count{index}(2*line)=0;
    end
    cached_line_count{index}(line)=cached_line_count{index}(line)+count;
