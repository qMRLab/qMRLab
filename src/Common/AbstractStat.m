classdef (Abstract) AbstractStat
    % AbstractStat:  Properties/Methods shared between all models.
    %
    %   *Methods*
    %   save: save model object properties to a file as an struct.
    %   load: load model properties from a struct-file into the object.
    %   Written by: Agah Karakuzu (2018)
    
    properties
        
        Map
        MapNames
        NumMaps
        
        StatMask
        StatLabels
        StatMaskFolder
        % Numerical vals should also be here
        
        UsrLabels
        StatID
        
        FitMask
        
        ProbMask
        ProbMaskFolder
        
        ModelName
        ModelVersion
        StatVersion
        
        DescriptiveStats
        
    end
    
    properties (Hidden=true)
        
        FitMaskName
        Compliance = struct();
        
    end
    
    methods
        
        function obj = AbstractStat()
            
            obj.StatVersion = qMRLabVer();
        end
        
        
        function obj = loadStatMask(obj,input)
            % A stat mask can be a labeled mask or a binary mask.
            % This function assigns StatMask property.
            %
            % getStatMask method works with:
            %
            % i)   variable from workspace
            % ii)  a file name
            % iii) a directory
            %
            % getStatMask@AbstractStat call is different than calling it
            % directly. Note that this function is not hidden in the
            % superclass. This is why wrapping is neccesary if one would
            % like to keep its function but hide it from the user.
            % For other methods this is way more easier. For this one,
            % please use following snippet in the target subclass:
            %
            % To hide this method in a subclass while keeping its function:
            % ---------------------------------------------------
            %{
  methods (Hidden)

function obj = getStatMask(obj,input)

    W = evalin('caller','whos');

    if ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name]))
      obj = getStatMask@AbstractStat(obj,input);
    else
      obj = getStatMask@AbstractStat(obj,eval('input'));
    end
  end
end
            %}
            % ---------------------------------------------------
            
            W = evalin('caller','whos');
            
            if ~isempty(inputname(2)) && ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name])) % Var from workspace
                
                obj.StatMask = input;
                [obj.StatMask,obj.StatLabels] = AbstractStat.maskAssignByType(obj.StatMask);
                
            elseif exist(input,'file') == 2 % File
                
                obj.StatMask = AbstractStat.loadFile(input);
                [obj.StatMask,obj.StatLabels] = AbstractStat.maskAssignByType(obj.StatMask);
                
            elseif exist(input,'file') == 7 % Folder
                
                % This folder should contain unified format.
                % If len>2 all inputs should be binary.
                
                obj.StatMaskFolder = input;
                [obj.StatMask, obj.StatLabels] = AbstractStat.getFileContent(obj.StatMaskFolder);
                
            else
                
                error('qMRLab: Provided input is NOT i) a variable in workspace, ii) a file or iii) a folder.');
                
            end
            
            
            
        end
        
        
        function obj = loadProbmask(obj,input)
            % Probability masks should be contained isolatedly from binary
            % and labeled masks.
            % This functions assigns ProbMask property by
            %     i) Passing a variable from workspace
            %    ii) Reading a filename/complete path
            %   iii) Looking at a folder (single file)
            %
            % External calls to this function is a bit tricky because of
            % the option (i). Please see details in getStatMask above
            % definition.
            
            W = evalin('caller','whos');
            
            if ~isempty(inputname(2)) && all(ismember(inputname(2),[W(:).name])) % Var from workspace
                
                obj.ProbMask = input;
                
            elseif exist(input,'file') == 2 % File
                
                obj.ProbMask = AbstractStat.loadFile(input);
                
            elseif exist(input,'file') == 7 % Folder
                
                obj.ProbMaskFolder = input;
                [obj.ProbMask, ~] = AbstractStat.getFileContent(input);
                
            else
                
                error('qMRLab: Provided input is NOT i) a variable in workspace, ii) a file or iii) a folder.');
                
            end
            
            
        end
        
        
        function obj = loadByFitResults(obj,filename,varargin)
            % This function assigns following fields w.r.t. a given
            % FitResults file:
            %    i)   obj.Map
            %    ii)  obj.MapNames
            %
            % Assumptions:
            %    i)   FitResults should include Model and Version
            %   ii)   xnames field contains entries that matches to the
            %         names of the quantitative maps FitResults encapsulate.
            %         This is especially important if output maps are
            %         conditional.
            % Call:
            %    i)  obj.loadByFitResults('FitResults.mat')
            %    ii) obj.loadByFitResults('../FitResults.mat','T1')
            %    iii) obj.loadByFitResults('../FitResults.mat','T1','ra'..)
            %
            %    (i)  Loads all the maps (as long as their name is present
            %    in xnames) and assign their names to the obj.MapNames with
            %    the matching order.
            %    (ii) Certain maps can be loaded from a FitResults.
            %    obj.MapName will be assigned w.r.t selection. Any number
            %    of maps can be loaded e.g. (iii).
            %
            % This function can be easily hidden from the users for classes
            % derived from this abstract base class:
            % obj = getStatMask@loadByFitResults(obj,filename,varargin);
            
            results = load(filename);
            fnames = fieldnames(results);
            
            if ~all(ismember({'Model','Version'},fnames))
                
                error('qMRLab: The file is not associated with a qMRLab output.');
                
            end
            
            obj.ModelName = results.Model.ModelName;
            obj.ModelVersion = results.Version;
            
            if ismember({'Files'},fieldnames(results)) && ismember('Mask',fieldnames(results.Files));
                
                obj.FitMaskName = results.Files.Mask;
                
            end
            
            if nargin==2 % Load all maps case
                
                
                
                idx = ismember(results.Model.xnames,fnames);
                obj.MapNames = results.Model.xnames(idx);
                tmp = results.(results.Model.xnames{1});
                
                [mapin, dim] = AbstractStat.getEmptyVolume(size(tmp),length(obj.MapNames));
                
                if dim == 2
                    for ii=1:length(obj.MapNames)
                        
                        mapin(:,:,ii) = results.(obj.MapNames{ii});
                        
                    end
                    
                elseif dim ==3
                    
                    for ii=1:length(obj.MapNames)
                        
                        mapin(:,:,:,ii) = results.(obj.MapNames{ii});
                        
                    end
                    
                end
                
                obj.Map = mapin;
                
            elseif nargin>2 % Load selected maps case
                
                tmp = results.(varargin{1});
                obj.MapNames = varargin;
                
                [mapin, dim] = AbstractStat.getEmptyVolume(size(tmp),length(obj.MapNames));
                
                if dim == 2
                    for ii=1:length(obj.MapNames)
                        
                        mapin(:,:,ii) = results.(obj.MapNames{ii});
                        
                    end
                    
                elseif dim ==3
                    
                    for ii=1:length(obj.MapNames)
                        
                        mapin(:,:,:,ii) = results.(obj.MapNames{ii});
                        
                    end
                    
                end
                
            end
            
            obj.Map = mapin;
            obj.NumMaps = length(obj.MapNames);
            
            
        end
        
        
        function obj = loadFitMask(obj)
            % Version of the loaded FitResults should be at least > 2 0 7
            % Above statement requires further inspection.
            % This function to allow users to use the mask used during fitting
            % process if available. There are certain assumptions:
            %    i)  (Mask) is a binary mask
            %   ii)  FitResults object includes Files
            %   iii) Location indicated in ii is still a valid target.
            % (ii) is checked out by the loadByFitResults
            % This function can be easily hidden from the users for classes
            % derived from this abstract base class:
            % obj = getStatMask@getFitMask(obj);
            
            if isempty(obj.FitMaskName)
                
                error('qMRLab: FitResults is not loaded into statistics object yet, OR Mask is not present in the loaded FitResults.')
                
            end
            
            try
                
                % FitMask is always logical assumption here
                % Change if one day someone is fitting with labeled masks.
                
                obj.FitMask = logical(AbstractStat.loadFile(obj.FitMaskName));
                
            catch
                
                error('qMRLab: The Mask file cannot be located on your computer.');
                
            end
            
            
        end
        
        function obj = getDescriptiveStats(obj)
            % This function declares obj.DescriptiveStats property as a struct
            % and assignes outputs per quantitative parameter contained by the
            % obj.Map property as a field.
            % Adapts output w.r.t to the combination of single/multi maps and
            % mask labels (or binary masks).
            % Table format is kept the same for all combinations.
            % This function can be easily hidden from the users for classes
            % derived from this abstract base class:
            % obj = getStatMask@AbstractStat(obj);
            
            if isempty(obj.StatMask) && isempty(obj.Map);
                error('qMRLab: Map and StatMask are both required');
            end
            
            if length(obj.MapNames)>1 && length(obj.StatLabels)>1
                
                sz = size(obj.MapNames);
                obj.DescriptiveStats = cell2struct(repmat({''},[sz(1),sz(2)]),obj.MapNames,2);
                
                tableBall = [];
                for ii = 1:length(obj.MapNames)
                    for k = 1:length(obj.StatLabels)
                        
                        curT = AbstractStat.getTable(obj.Map(:,:,ii),obj.StatMask,obj.MapNames{ii},obj.StatLabels{k},k);
                        tableBall = [tableBall;curT];
                        
                    end
                    
                    obj.DescriptiveStats.(obj.MapNames{ii}) = tableBall;
                    tableBall = [];
                    
                end
                
            elseif length(obj.MapNames)==1 && (length(obj.StatLabels)==1 || isempty(obj.StatLabels) )
                
                obj.DescriptiveStats = struct();
                obj.DescriptiveStats.(obj.MapNames{1}) = AbstractStat.getTable(obj.Map,obj.StatMask,obj.MapNames,obj.StatLabels);
                
            elseif length(obj.MapNames)>1 && (length(obj.StatLabels)==1 || isempty(obj.StatLabels) )
                
                sz = size(obj.MapNames);
                obj.DescriptiveStats = cell2struct(repmat({''},[sz(1),sz(2)]),obj.MapNames,2);
                
                for ii = 1:length(obj.MapNames)
                    
                    obj.DescriptiveStats.(obj.MapNames{ii}) = AbstractStat.getTable(obj.Map(:,:,ii),obj.StatMask,obj.MapNames{ii},obj.StatLabels);
                    
                end
                
            end
            
        end
        
    end
    
    % HIDDEN METHODS
    
    methods(Hidden)
        
        function obj = evalCompliance(obj)
            
            for ii = 1:length(obj)
                
                obj(ii).Compliance.noMapFlag   = isempty(obj(ii).Map);
                obj(ii).Compliance.noMaskFlag  = isempty(obj(ii).StatMask);
                
                if ~obj(ii).Compliance.noMapFlag && ~obj(ii).Compliance.noMaskFlag
                    
                szMap = size(obj(ii).Map);
                szMask = size(obj(ii).StatMask);
                
            
                if isequal(szMap,szMask) || isequal(szMap(1:end-1),szMask)
                    
                    obj(ii).Compliance.szMismatchFlag  = 0;
                    
                else
                    obj(ii).Compliance.szMismatchFlag = 1;
                end
                
                else
                    
                    obj(ii).Compliance.szMismatchFlag = 1;
                    
                end
                
                
            end
            
            
            
            
            
        end
        
    end
    % STATIC FUNCTIONS ----------------------------------
    
    methods (Static, Hidden=true)
        
        
        
        function fType = getInpFormat(fileName)
            % To extract format of the file provided as the whole dir
            % or filename only.
            % % External call: AbstractStat.getInpFormat.
            
            loc = max(strfind(fileName, '.'));
            
            frm = fileName(loc+1:end);
            
            if strcmp(frm,'gz') || strcmp(frm,'nii')
                
                fType = 'nifti';
                
            elseif strcmp(frm,'mat')
                
                fType = 'matlab';
                
            end
            
        end
        
        
        function type = getMaskType(mask)
            % This function is to distinguish between binary and labeled masks
            % by simply checking their distibution.
            % Terminates if uniform image is passed.
            % % External call: AbstractStat.getMaskType
            
            members = unique(mask(:));
            if length(members) > 2 % labeledmask
                type = 'label';
                
            elseif length(members) == 2
                type = 'binary';
                
            elseif length(members) < 2
                
                error('qMRLab: The image contains one value only. Cannot be used as a mask.')
            end
        end
        
        function [out,labels] = maskAssignByType(mask)
            
            type = AbstractStat.getMaskType(mask);
            
            if strcmp(type,'label') % labeledmask
                
                members = unique(mask(:));
                members(members==0) = []; % Remove 0 from the list
                labels = num2cell(sort(members));
                out = mask;
                
            elseif strcmp(type,'binary')
                
                out = logical(mask);
                labels = [];
                
                
            end
            
            
            
        end
        
        
        
        
        function output = loadFile(input)
            % Load content of a file irrespective of its format.
            % Current formats: mat, nii, nii.gz
            % External call: AbstractStat.loadFile
            
            switch AbstractStat.getInpFormat(input)
                
                
                case 'nifti'
                    
                    try
                        
                        output = load_nii_data(input);
                        
                    catch
                        
                        output = load_nii(input);
                        
                        output = output.img;
                        
                    end
                    
                case 'matlab'
                    
                    im = load(input);
                    output = im.(cell2mat(fieldnames(im)));
                    
            end
            
            
            
            
        end
        
        function [out, label] = getFileContent(path)
            % CHANGE THIS FUNCTIONS NAME TO getFolderContent
            % This function is intended to read one/multiple masks from a
            % given directory.
            %
            % If mask directory contains only one file:
            %     i)  Binary mask --> StatMask   | fname --> StatLabel
            %     ii) Labeled mask  --> StatMask | fname --> StatLabel
            %
            % If mask directory contains multiple files:
            %    i) Assumes that masks are not overlapping
            %   ii) Reads them in dir order
            %  iii) Merges them within a single labeled mask.
            %   iv) StatLabel attains filenames for their corresponding
            %       regions in StatMask.
            %
            % A mask folder can contain .nii and .nii.gz (NiFTI)
            % A mask folder can contain .mat.
            % A mask foler can't contain mat and NifTI formats simultaneously.
            % Other files can sit in this dir, such as JSON.
            % External call: AbstractStat.getFileContent
            
            matList  = dir(fullfile(path,'*.mat'));
            niiList1 = dir(fullfile(path,'*.nii.gz'));
            niiList2 = dir(fullfile(path,'*.nii'));
            
            if isempty(niiList1) && isempty(niiList2) && isempty(matList) % No acceptable format
                
                error('Directory does not contain any files with recognized formats (.mat, .nii.gz, .nii).');
                
            elseif (~isempty(niiList1) || ~isempty(niiList2)) && (isempty(matList)) % Nifti masks
                
                if ~isempty(niiList1) && ~isempty(niiList2)
                    
                    readList = {niiList1.name niiList1.name};
                    [out, label] = AbstractStat.readUniFormat(readList);
                    
                elseif ~isempty(niiList1)
                    
                    readList = {niiList1.name};
                    [out, label] = AbstractStat.readUniFormat(readList);
                    
                elseif ~isempty(niiList2)
                    
                    readList = {niiList2.name};
                    [out, label] = AbstractStat.readUniFormat(readList);
                    
                else
                    
                    
                    
                end
                
            elseif (isempty(niiList1) && isempty(niiList2)) && (~isempty(matList)) % mat masks
                
                readList = {matList.name};
                [out, label] = AbstractStat.readUniFormat(readList);
                
            else
                
                error('Mask folder contents shoud share the same format.');
                
            end
            
            
            
        end
        
        
        function [out, label] = readUniFormat(readlist)
            % Serves as a subfunction for getFolderContent.
            % Combines multiple masks into one mask by reading a list of
            % files of the same format.
            % Size of the mask is adapted to the # of dimensions of the maps.
            % External call: AbstractStat.readUniFormat
            
            if length(readlist) == 1
                
                out = AbstractStat.loadFile(readlist{1});
                [out,label] = AbstractStat.maskAssignByType(out);
                
                if isempty(label)
                    label = AbstractStat.strapFileName(readlist{1});
                end
                
            else
                
                tmp = AbstractStat.loadFile(readlist{1});
                sz = size(tmp);
                label = cell(length(readlist),1);
                
                if length(sz)>2
                    
                    out   = zeros(sz(1),sz(2),sz(3));
                    
                    
                elseif length(sz) == 2
                    
                    out = zeros(sz(1),sz(2));
                    
                end
                
                
                for ii=1:length(readlist)
                    
                    curMask = AbstractStat.loadFile(readlist{ii});
                    
                    % Critical assignment here!
                    out(curMask==1) = ii;
                    label{ii} = AbstractStat.strapFileName(readlist{ii});
                    
                end
                
                
            end
            
        end
        
        
        function  out = strapFileName(in)
            % Filenames are used as mask labels.
            % This function is to extract filename from a filelist containing
            % the filenames only. Not applicable for whole path.
            % Assumes one dat. Can be polished for nii.gz.
            % External call: AbstractStat.strapFieldName
            locpt = strfind(in, '.');
            out = in(1:(locpt-1));
            
            
        end
        
        function [vol, dim] = getEmptyVolume(sz,len)
            % AbstractStat is designed to keep quantitative maps generated by
            % a fit session within the same matrix. e.g. 3D -> 4D | 2D -> 3D
            % where 4D = 3DxN and 3D = 2DxN for N quantitative maps.
            % This function returns empty volume, which is to be filled out
            % elsewhere.
            % External call: AbstractStat.getEmptyVolume
            
            ln = length(sz);
            
            if ln == 2
                
                vol = zeros(sz(1),sz(2),len);
                dim  = 2;
                
            elseif ln>2
                
                vol = zeros(sz(1),sz(2),sz(3),len);
                dim = 3;
            end
            
            
        end
        
        
        function t = getTable(im,mask,mapName,label,varargin)
            % Descriptive statistics are kept in table format for user's
            % convenience.
            % This function returns a table containing Mean, STD 5%, 50%, 95%
            % of the masked data and NaNcontain that indicates if masked area
            % contains any NaN value (IMPORTANT FOR REGRESSIONS).
            % Name of the map and label are also added to the table.
            % Stats are returned regarding the type of the mask (binary|label).
            % Binary mask:  One call.
            % Labeled mask: To be called per label.
            % External call: AbstractStat.getTable
            
            type = AbstractStat.getMaskType(mask);
            
            
            if strcmp(type,'binary')
                
                vec = im(mask);
                
                if nargin==4
                    Region = {label};
                else
                    Region = {'N/A'};
                end
                
                Parameter = {mapName};
                [Mean, STD, prcnt5,prcnt50,prcnt95, NaNcontain]= AbstractStat.getBasicStats(vec);
                
                t = table(Region,Parameter,Mean,STD,prcnt5,prcnt50,prcnt95,NaNcontain);
                
            elseif strcmp(type,'label')
                
                
                vec = im(mask==cell2mat(varargin));
                Region = {label};
                
                Parameter = {mapName};
                [Mean, STD, prcnt5,prcnt50,prcnt95, NaNcontain]= AbstractStat.getBasicStats(vec);
                
                t = table(Region,Parameter,Mean,STD,prcnt5,prcnt50,prcnt95,NaNcontain);
                
            end
            
        end
        
        
        
        function [Mean, STD, prcnt5,prcnt50,prcnt95, NaNcontain] = getBasicStats(vec)
            % Descriptive statistics are kept in table format for user's
            % convenience.
            % This function returns following descriptive statistics:
            % Mean, STD 5%, 50%, 95%
            % NaNcontain indicates if masked area contains NaN
            % Stats are returned regarding the type of the mask (binary|label).
            % Binary mask:  One call.
            % Labeled mask: To be called per label.
            % External call: AbstractStat.getTable
            
            NaNcontain = any(isnan(vec));
            
            if NaNcontain
                Mean = nanmean(vec);
                STD = nanstd(vec);
            else
                Mean = mean(vec);
                STD = std(vec);
            end
            
            prcnt5 = prctile(vec,5);
            prcnt50 = prctile(vec,50);
            prcnt95 = prctile(vec,95);
        end
        
    end
    
    
end
