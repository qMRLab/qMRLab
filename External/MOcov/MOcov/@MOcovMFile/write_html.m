function write_html(obj, fn, index_fn)
% Write HTML coverage report for single m-file
%
% write_html(obj, fn, index_fn)
%
% Inputs:
%   obj                 MOcovMFile instance
%   fn                  HTML Output filename
%   index_fn            HTML index output filename
%
% Notes:
%   - this function writes the HTML file fn containing coverage for the
%     file represented by obj. The HTML file has a link to index_fn.

    mfile_fn=obj.filename;

    fid=fopen(fn,'w');
    cleaner=onCleanup(@()fclose(fid));


    fprintf(fid,['<!DOCTYPE html>\n'...
                        '<html><head><title>%s</title>'...
                        '<STYLE TYPE="text/css"><!--'...
                        'TD{font-family: "Courier New", '...
                            'Courier, monospace; font-size: 10pt;}'...
                        '---></STYLE>'...
                        '</head>'...
                        '<body>'...
                        '<p>(Back to <a href="%s">index</a>)</p>'...
                        '<h1>%s</h1>'...
                        '<p style="font-family:'...
                        '''Courier New''">'...
                        '<table>\n'],...
                        mfile_fn,index_fn,mfile_fn);
    fprintf(fid,'<tr><th>Line</th><th>Code</th></tr>\n');

    lines=get_lines(obj);
    missed=get_lines_executable(obj) & ~get_lines_executed(obj);

    html_red_color='#FF0000';
    html_white_color='#FFFFFF';

    for k=1:numel(lines)
        line=convert_raw_to_html(lines{k});

        if missed(k)
            html_color=html_red_color;
        else
            html_color=html_white_color;
        end

        fprintf(fid,'<tr><td>%d</td><td bgcolor="%s">%s</td></tr>\n',...
                        k,html_color,line);
    end
    fprintf(fid,'</table></p></body></html>');


function line=convert_raw_to_html(line)
	orig_new= {'&','&amp;';...
                ' ','&nbsp;';...
                '<','&lt;';...
                '>','&gt;';...
                };

    n_replacements=size(orig_new,1);
    for k=1:n_replacements
        line=strrep(line,orig_new{k,1},orig_new{k,2});
    end
