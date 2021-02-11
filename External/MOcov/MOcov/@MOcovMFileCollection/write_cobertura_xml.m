function write_cobertura_xml(obj, output_fn)
    monitor=obj.monitor;
    notify(monitor,sprintf('Writing xml files in %s', output_fn));



    overall_coverage=compute_coverage(obj);
    notify(monitor,sprintf('Overall coverage is %.3f', overall_coverage));
    header=sprintf(['<?xml version="1.0"?>\n'...
                    '<coverage line-rate="%.3f" branch-rate="1.0">'],...
                    overall_coverage);

    root_dir=obj.root_dir;
    sources=sprintf('<sources><source>%s</source></sources>',...
                        root_dir);

    package_header=sprintf(['<packages>\n'...
                           '<package name="" '...
                            'line-rate="%.3f" '...
                            'branch-rate="1.0">\n'...
                            '<classes>'],overall_coverage);

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

    numerator=0;
    denominator=0;

    for k=1:numel(obj.mfiles)
        mfile=obj.mfiles{k};

        able=get_lines_executable(mfile);
        ed=get_lines_executed(mfile);

        numerator=numerator+sum(ed & able);
        denominator=denominator+sum(able);
    end

    if denominator==0
        coverage=1;
    else
        coverage=numerator/denominator;
    end


