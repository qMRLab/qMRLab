function combinedReports = mocov_combine(dirPath, outputFileName)
%MOCOV_COMBINE Combine MOcov JSON coverage reports.
%
%   dirPath: (string) Directory containing MOcov JSON coverage reports.
%   
%   (optional) 
%   outputFileName: (string) Filename of combined reports JSON file ? saved in dirPath.
%
%   External dependencies: JSONlab ? https://github.com/fangq/jsonlab

    %% Load JSON files
    %

    if ~strcmp(dirPath(end),'/')
        dirPath = [dirPath,'/'];
    end

    jsonFileNames = dir([dirPath, '*.json']);
    numFiles = length(jsonFileNames);

    for fileIndex = 1:numFiles
        jsonData{fileIndex} = loadjson([dirPath, jsonFileNames(fileIndex).name]);
    end

    %% Setup for loop
    %

    combinedReports = jsonData{1}; % Use first file as a template

    numSrcFiles = length(combinedReports.source_files);

    %% Loop through the coverage count of each line in each tracked files.
    %

    for srcIndex = 1:numSrcFiles
        numCoverage = length(combinedReports.source_files{srcIndex}.coverage);
        
        for covIndex = 1:numCoverage
            if ~isempty(combinedReports.source_files{srcIndex}.coverage{covIndex}) %Skip untracked lines ("NULL")
                
                sumCount = 0;
                for fileIndex = 1:numFiles
                    sumCount = sumCount + jsonData{fileIndex}.source_files{srcIndex}.coverage{covIndex};
                end

                combinedReports.source_files{srcIndex}.coverage{covIndex} = sumCount;
            end
        end
 
    end
    
    %% (optional) Save combined reports to file
    %
    
    if exist('outputFileName', 'var')
        savejson('', combinedReports, [dirPath, outputFileName]);
    end
end
