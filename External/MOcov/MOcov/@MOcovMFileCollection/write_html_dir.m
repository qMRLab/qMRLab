function write_html_dir(obj, output_dir)
% Write HTML coverage report for m-file collection
%
% write_html_dir(obj, output_dir)
%
% Inputs:
%   obj                 MOcovMFileCollection instance
%   output_dir          HTML output directory
%
% Notes:
%   - this function writes a file index.html, as well as node*.html files
%     for each individual MOcovMFile.

    if ~isdir(output_dir)
        mkdir(output_dir);
    end

    monitor=obj.monitor;

    index_rel_fn='index.html';
    index_fn=fullfile(output_dir, index_rel_fn);

    mfiles=obj.mfiles;
    n=numel(mfiles);
    mfile_node_fns=cell(n,1);

    % write single HTML file for each m-file
    notify(monitor,'Writing html files in %s', output_dir);

    for k=1:n
        node_rel_fn=sprintf('node%d.html',k);
        mfile_node_fns{k}=node_rel_fn;

        mfile=mfiles{k};
        node_fn=fullfile(output_dir, node_rel_fn);
        write_html(mfile, node_fn, index_rel_fn);

        msg=sprintf('Written to %s', node_fn);
        notify(monitor,'.',msg);
    end

    % write index HTML file
    write_index_html(index_fn, mfiles, mfile_node_fns);
    msg=sprintf('Index written to %s\n', index_fn);
    notify(monitor,msg);


function write_index_html(output_fn, mfiles, mfile_node_fns)
    % build an index html file

    fid=fopen(output_fn,'w');
    cleaner=onCleanup(@()fclose(fid));

    fprintf(fid,['<!DOCTYPE html>\n'...
                        '<html><head><title>Coverage</title></head>'...
                        '<body><table>\n']);
    fprintf(fid,['<tr><th>Lines</th><th>Executable</th>'...
                    '<th>Executed</th><th>Coverage</th>'...
                    '<th>File</th></tr>\n']);

    stats=get_stats(mfiles);

    [unused,i]=sort(stats(:,4));

    n_files=numel(mfiles);

    % pattern with placeholders for:
    % - number of lines
    % - number of executable lines
    % - number of executed lines
    % - string describing the row
    row_pat=['<tr><td align="right">%d</td>'...
                        '<td align="right">%d</td>'...
                        '<td align="right">%d</td>'...
                        '<td align="right">%.1f%%</td>'...
                        '<td>%s</td></tr>\n'];

    % add summary line at top
    overall_stats=sum(stats,1);
    overall_stats(4)=100*overall_stats(3)/overall_stats(2);
    summary_str=sprintf('%d files',n_files);

    fprintf(fid,row_pat,overall_stats,summary_str);

    % add row for each file
    for k=1:numel(mfiles)
        mfile=mfiles{i(k)};
        stat=stats(i(k),:);
        node_fn=mfile_node_fns{i(k)};

        mfile_name=get_filename(mfile);
        mfile_anchor=sprintf('<a href="%s">%s</a>',node_fn,mfile_name);

        fprintf(fid,row_pat,stat,mfile_anchor);
    end

    % add summary line at bottom
    fprintf(fid,row_pat,overall_stats,summary_str);

    fprintf(fid,'</table></body></html>');


function stats=get_stats(mfiles)
    n=numel(mfiles);
    stats=zeros(n,4);
    for k=1:n
        mfile=mfiles{k};

        executable=get_lines_executable(mfile);
        executed=get_lines_executed(mfile);

        executed(~executable)=false;

        if sum(executable)==0
            coverage=100;
        else
            coverage=100*sum(executed)/sum(executable);
        end

        stat=[numel(executable),...
                     sum(executable),...
                     sum(executed),...
                     coverage];
        stats(k,:)=stat;
    end