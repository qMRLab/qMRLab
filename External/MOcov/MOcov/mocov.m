function varargout=mocov(varargin)
% run MOCov coverage
%
% [...]=mocov(...)
%
% Inputs:
%   '-expression', expr         expression for which, when evaluated,
%                               line coverage will be computed. Evaluation
%                               is done as follows:
%                               - If a string, evaluate the expression expr
%                                 using 'eval'
%                               - If a function handle, evaluate expr()
%                               Mutually exclusive with '-profile_info'
%                               option.
%   '-profile_info'             Use coverage based on profile('info'). Not
%                               usable on the GNU Octave platform.
%                               Mutually exclusive with '-expression'
%                               option.
%   '-cover', covd              Find coverage for files in dir covd and all
%                               of its subdirectories
%   '-cover_exclude', pat       (optional) Exclude files and directories
%                               which match this pattern, even if they are
%                               in covd. Can be used multiple times to
%                               specify multiple patterns to match.
%   '-cover_json_file', cj      (optional) Store coverage information in
% `                             file cj in JSON format [use with coveralls]
%   '-cover_xml_file', xc       (optional) Store coverage information in
% `                             file xc [for shippable.com]
%   '-cover_html_dir', h        (optional) Store coverage information in
% `                             directory h
%   '-verbose'                  (optional) Show verbose output
%   '-cover_method', m          (optional) Use method m to determine
%                               coverage, one of:
%                               'file':   before evaluating expr, rewrite
%                                         files in dir covd and add covd
%                                         to the search path; after
%                                         evaluating expr, delete these
%                                         files and remove covd from the
%                                         search path
%                               'profile' use profiler to determine
%                                         coverage. Does not work on Octave
%                                         4.0 (and possibly later versions)
%                               Default: 'file'
%
% Examples:
%   % evaluate 'expr' while monitoring coverage of files in directory
%   % 'dir_to_cover' by rewriting files in that directory to a
%   % temporary directory; write coverage in HTML format in directory
%   % 'html_output'.
%   mocov -cover dir_to_cover -cover_html_dir html_output -e expr
%
%   % As above, but use Matlab profiler to monitor coverage
%   % (not usable on GNU Octave)
%   mocov -cover cover_dir -cover_html_dir output -e expr -v -m profile
%
%
%
% Notes:
% - this function aims to be compatible with Matlab and GNU Octave.
% - coverage reports for unit tests can be made together with MOxUnit.
% - when using the 'file' method, all .m files in the covd directory are
%   parsed, changed to call mocov_line_covered on every executable line,
%   and written to a temporary directory. The search path is updated
%   temporarily to include the temporary directory/
% - coverage may not be supported for new-style object-oriented class
%   files.
%
% Nikolaas N. Oosterhof, 2015-2016


    % store pwd and ensure it is restored afterwards
    orig_pwd=pwd();
    cleaner_pwd=onCleanup(@()cd(orig_pwd));

    % get input arguments
    opt=parse_inputs(varargin{:});

    % store original state of mocov_line_covered, and ensure it is reset
    % afterwards
    line_covered_state=mocov_line_covered();
    cleaner_covered=onCleanup(@()mocov_line_covered(...
                                            line_covered_state));

    % reset lines covered to empty
    mocov_line_covered([]);

    monitor=MOcovProgressMonitor(opt.verbose);
    mfile_collection=MOcovMFileCollection(opt.cover,...
                                                    opt.method,...
                                                    monitor,...
                                                    opt.excludes);
    mfile_collection=prepare(mfile_collection);
    cleaner_collection=onCleanup(@()cleanup(mfile_collection));

    if ~isempty(opt.expression)
        % rewrite m-files (if method='file') and ensure that they are cleaned
        % up afterwards

        % evaluate expression, and assign output variables
        argout=evaluate_expression(opt.expression);
        n=numel(argout);
        varargout=cell(1,n);
        [varargout{:}]=argout{:};
    end

    % see which lines were executed
    mfile_collection=add_lines_executed_count(mfile_collection);

    % reset pwd
    clear cleaner_pwd;

    % write coverage
    coverage_writers=get_coverage_writers_collection();
    write_coverage_results(coverage_writers, mfile_collection, opt);

function coverage_writers=get_coverage_writers_collection
    coverage_writers=struct();
    coverage_writers.cover_html_dir=@write_html_dir;
    coverage_writers.cover_xml_file=@write_xml_file;
    coverage_writers.cover_json_file=@write_json_file;

function write_coverage_results(writers, mfile_collection, opt)
    keys=intersect(fieldnames(writers),fieldnames(opt));

    for k=1:numel(keys)
        key=keys{k};
        file_arg=opt.(key);
        if isempty(file_arg)
            continue;
        end
        abs_file_arg=mocov_get_absolute_path(file_arg);

        writer=writers.(key);
        writer(mfile_collection,abs_file_arg);
    end



function argout=evaluate_expression(the_expression___)
    if isa(the_expression___,'function_handle')
        the_expression_nout___=nargout(the_expression___);
        if the_expression_nout___<0
            % only take first output
            the_expression_nout___=1;
        end
        argout=cell(1,the_expression_nout___);
        [argout{:}]=the_expression___();
    elseif ischar(the_expression___)
        argout={eval(the_expression___)};
    else
        error('unable to evaluate expression of class %s',...
                            class(the_expression___));
    end


function opt=parse_inputs(varargin)
    % process input options

    defaults=struct();
    defaults.coverage_dir=pwd();
    defaults.excludes={};
    defaults.html_dir=[];
    defaults.cobertura_xml=[];
    defaults.coveralls_json=[];
    defaults.verbose=0;
    defaults.method=[];
    defaults.expression=[];
    defaults.info_from_profile=false;

    opt=defaults;

    n=numel(varargin);
    k=0;
    while k<n
        k=k+1;
        arg=varargin{k};

        if ischar(arg)
            switch arg
                case '-cover_html_dir'
                    k=k+1;
                    opt.cover_html_dir=varargin{k};

                case '-cover_xml_file'
                    k=k+1;
                    opt.cover_xml_file=varargin{k};

                case '-cover_json_file'
                    k=k+1;
                    opt.cover_json_file=varargin{k};

                case '-cover'
                    k=k+1;
                    opt.cover=varargin{k};

                case '-cover_exclude'
                    k=k+1;
                    opt.excludes(end+1)=varargin(k);

                case '-verbose'
                    opt.verbose=opt.verbose+1;

                case '-expression'
                    k=k+1;
                    opt.expression=varargin{k};

                case '-cover_method'
                    k=k+1;
                    opt.method=varargin{k};

                case '-profile_info'
                    opt.info_from_profile=true;

                otherwise
                    error('illegal option ''%s''', arg)
            end
        elseif isa(arg,'function_handle')
            opt.expression=arg;
        else
            error('Input argument %d not understood', k);
        end
    end

    if isempty(opt.method)
        if opt.info_from_profile
            opt.method='profile';
        else
            opt.method='file';
        end
    end

    check_inputs(opt);



function check_inputs(opt)
    if ~isdir(opt.coverage_dir)
        error('input dir ''%s'' does not exist', opt.coverage_dir);
    end

    if isempty(opt.expression)
        if opt.info_from_profile
            if ~strcmp(opt.method,'profile')
                error('Option ''-i'' requires ''-m profile''');
            end
        else
            error('Either option ''-e'' or ''i'' must be used');
        end
    elseif opt.info_from_profile
        error('Options ''-e'' or ''i'' are mutually exclusive');
    end
