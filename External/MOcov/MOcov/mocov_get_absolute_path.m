function abs_fn=mocov_get_absolute_path(fn)
% return the absolute path
%
% abs_fn=mocov_get_absolute_path(fn)
%
% Input:
%   fn          filename or path
%
% Output:
%   abs_fn      absolute path of fn
%

    if mocov_is_absolute_path(fn)
        abs_fn=fn;
    else
        abs_fn=fullfile(pwd(), fn);
    end

    abs_fn=clean_path_string(abs_fn);

function clean_abs_fn=clean_path_string(abs_fn)

    re=regexptranslate('escape',filesep());

    while true
        sp=regexp(abs_fn,re,'split');
        n=numel(sp);

        keep=true(1,n);
        for k=1:n
            p=sp{k};

            if strcmp(p,'~')
                sp{k}=getenv('HOME');
                break;
            end


            % remove '.' in path
            if strcmp(p,'.') || (isempty(p) && k>1)
                keep(k)=false;
                break;
            end

            % remove '../p'
            if strcmp(p,'..') && k>1 && ~isempty(sp{k-1}) && ...
                        ~(strcmp(sp{k-1},'..'))
                keep(k+[-1 0])=false;
                break;
            end
        end

        parts=[sp(keep);...
                    repmat({filesep()},1,sum(keep))];

        clean_abs_fn=strrep(cat(2,parts{:}),...
                            [filesep() filesep()], ...
                            filesep());

        % deal with filesep at the end of the path
        while numel(clean_abs_fn)>1 && clean_abs_fn(end)==filesep();
            clean_abs_fn=clean_abs_fn(1:(end-1));
        end

        if strcmp(clean_abs_fn,abs_fn)
            break;
        end

        abs_fn=clean_abs_fn;
    end

