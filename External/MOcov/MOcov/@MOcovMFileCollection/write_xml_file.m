function write_xml_file(obj, output_fn)
% Write XML coverage report for m-file collection
%
% write_xml_file(obj,output_fn)
%
% Inputs:
%   obj                 MOcovMFileCollection instance
%   output_fn           XML output file
%
%
% See also: get_coverage_json


    branch_rate=0;

    monitor=obj.monitor;
    notify(monitor,sprintf('Writing xml files in %s', output_fn));

    % write header
    overall_coverage=compute_coverage(obj);
    notify(monitor,sprintf('Overall coverage is %.3f', overall_coverage));
    header=sprintf(['<?xml version="1.0"?>\n'...
                    '<coverage line-rate="%.3f" branch-rate="%.3f">'],...
                    overall_coverage,branch_rate);

    % set sources
    root_dir=obj.root_dir;
    sources=sprintf('<sources><source>%s</source></sources>',...
                        root_dir);

    % set package header
    package_header=sprintf(['<packages>\n'...
                           '<package name="" '...
                            'line-rate="%.3f" '...
                            'branch-rate="%.3f">\n'...
                            '<classes>'],overall_coverage,branch_rate);

    % add for each m-file
    mfiles=obj.mfiles;
    n=numel(mfiles);

    body_cell=cell(n,1);

    for k=1:n
        mfile=mfiles{k};

        body_cell{k}=get_coverage_xml(mfile, root_dir);

        msg=sprintf('Written for %s', get_filename(mfile));
        notify(monitor,'.',msg);
    end


    package_footer='</classes></package></packages>';
    footer='</coverage>';

    % combine all parts
    full_report=sprintf('%s\n',header,sources,package_header,...
                                body_cell{:},...
                                package_footer,footer);

    write_to_file(output_fn,full_report)
    msg=sprintf('written to %s',output_fn);
    notify(monitor,msg);

function write_to_file(fn,s)
    fid=fopen(fn,'w');
    cleaner=onCleanup(@()fclose(fid));
    fprintf(fid,'%s',s);

function coverage=compute_coverage(obj)
% compute overall coverage across all files
    numerator=0;
    denominator=0;

    for k=1:count_mfiles(obj)
        mfile=get_mfile(obj,k);

        executable=get_lines_executable(mfile);
        executed=get_lines_executed(mfile);

        numerator=numerator+sum(executed & executable);
        denominator=denominator+sum(executable);
    end

    if denominator==0
        coverage=1;
    else
        coverage=numerator/denominator;
    end


