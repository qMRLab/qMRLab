function write_json_file(obj,output_fn)
% Write JSON coverage report for m-file collection
%
% write_json_file(obj,output_fn)
%
% Inputs:
%   obj                 MOcovMFileCollection instance
%   output_fn           JSON output file
%
% Notes:
%   - this function writes a JSON file with the contents from
%   get_coverage_json
%
% See also: get_coverage_json

    monitor=obj.monitor;
    notify(monitor,sprintf('Writing JSON file to %s',output_fn));

    json=get_coverage_json(obj);
    fid=fopen(output_fn,'w');
    cleaner=onCleanup(@()fclose(fid));
    fprintf(fid,'%s',json);

    notify(monitor,sprintf('Completed writing JSON file to %s',output_fn));
