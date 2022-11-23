function repro_jsoniterator_largefile_failure
  
large_file_url = 'https://github.com/json-iterator/test-data/raw/master/large-file.json';
tempfile = [tempname '-largefile.json'];
urlwrite (large_file_url, tempfile);
json_str = fileread (tempfile);

octave_data = jsondecode (json_str);

end
