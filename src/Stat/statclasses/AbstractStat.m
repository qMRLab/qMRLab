classdef (Abstract) AbstractStat
    % AbstractStat:  Properties/Methods shared between all models.
    %
    %   *Methods*
    %   save: save model object properties to a file as an struct.
    %   load: load model properties from a struct-file into the object.
    %   Written by: Agah Karakuzu (2018)
    % ===============================================================
    properties
        
        Map
        MapNames
        NumMaps
        
        FigureOption = 'osd';
        SignificanceLevel = 5/100; 

        StatMask
        StatLabels
        LabelIdx
        StatMaskInfo
        
        UsrLabels
        StatID
        
        FitMask
        
        ProbMask
        ProbMaskFolder
        
        ModelName
        ModelVersion
        StatVersion
        
        DescriptiveStats
        
        % Statistics visualization data structure. 
        % This may become an object in the future. 
        
        svds = struct('Tag',[],'Required',[],'Optional',[]);
        
    end
    % //////////////////////////////////////////////////////////////
    properties (Hidden=true, SetAccess = protected, GetAccess=public)
        
        FitMaskName
        Compliance = struct();
        MapDim
        StatMaskDim
        ActiveMapIdx = 1
        MapLoadFormat
        MaskLoadFormat
        
        WarningHead = '-------------------------------- qMRLab Warning';
        ErrorHead   = '----------------------------------------- qMRLab Error';
        Tail = '\n-------------------------------------------------------|';
        
    end
    % //////////////////////////////////////////////////////////////
    methods
        
        function obj = AbstractStat()
            
            obj.StatVersion = qMRLabVer();
            
        end
                
        function obj = loadStatMask(obj,input)
            % This function assigns the StatMask property.
            % StatMask can be a labeled mask or a binary mask.
            %
            % loadStatMask method accepts following inputs:
            %
            % i)   variable from workspace (pass w/o single quotes)
            % ii)  a file name (*.mat, *.nii, *.nii.gz)
            % iii) a directory ('/../MaskFolder')
            % 
            % (i) and (ii) loads the target file containing a binary or a
            % labeled mask.
            %
            % (iii) loads the file (*.mat, *.nii, *.nii.gz) directly if it 
            % is the only only file respecting the format. 
            % If there are multiple files, (iii) assumes that the directory
            % contains a collection of binary masks, reads them all and merges
            % into a single labeled mask, where regions are labeled by the
            % respective file names. 
            % 
            % Warning for (iii): Please make sure that binary masks have no
            % overlapping regions, if multiple binary masks are going to be
            % read. 

            % Developers: 
            % getStatMask@AbstractStat call is different than calling it
            % directly. Note that this function is not hidden in the
            % superclass. This is why wrapping is neccesary if one would
            % like to keep its function but hide it from the user.
            % For other methods this is way more easier. For this one,
            % please use following snippet in the target subclass:
            %
            % IMPORTANT --- 
            % To hide/override this method in a subclass:
            % ---------------------------------------------------
            %{
            methods (Hidden)

            function obj = getStatMask(obj,input)

                W = evalin('caller','whos');

                if ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name]))
                  obj = loadStatMask@AbstractStat(obj,input);
                else
                  obj = loadStatMask@AbstractStat(obj,eval('input'));
                end
              end
            end
            %}
            % ---------------------------------------------------
            
            W = evalin('caller','whos');
            
            if ~isempty(inputname(2)) && ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name])) % Var from workspace
                
                obj.StatMask = input;
                [obj.StatMask,obj.StatLabels] = AbstractStat.maskAssignByType(obj.StatMask);
                obj.LabelIdx = cell2mat(obj.StatLabels);
                obj.StatMaskInfo = ['Workspace variable: ' input];
                obj.MaskLoadFormat = 'var';
                
            elseif exist(input,'file') == 2 % File
                
                obj.StatMask = AbstractStat.loadFile(input);
                [obj.StatMask,obj.StatLabels] = AbstractStat.maskAssignByType(obj.StatMask);
                obj.LabelIdx = cell2mat(obj.StatLabels);
                obj.StatMaskInfo = input;
                switch AbstractStat.getInpFormat(input)
                
                    case 'matlab'
                    obj.MaskLoadFormat = 'matlab';
                    case 'nifti'
                    obj.MaskLoadFormat = 'nifti';
                    
                end
                
            elseif exist(input,'file') == 7 % Folder
                
                % This folder should contain unified format.
                % If len>2 all inputs should be binary.
                
                obj.StatMaskInfo = input;
                obj = setMasksFromFolder(obj);
                if not(isempty(dir(fullfile(pwd, '*.mat'))))
                    obj.MaskLoadFormat = 'matlab';
                elseif not(isempty(dir(fullfile(pwd, '*.nii'))))
                    obj.MaskLoadFormat = 'nifti';
                elseif not(isempty(dir(fullfile(pwd, '*.nii.gz'))))
                    obj.MaskLoadFormat = 'nifti';
                end
            else
                
                error('qMRLab: Provided input is NOT i) a variable in workspace, ii) a file or iii) a folder.');
                
            end
            
            obj.StatMaskDim = length(squeeze(size(obj.StatMask)));
            
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
                obj = setMasksFromFolder(obj);
                
            else
                
                error('qMRLab: Provided input is NOT i) a variable in workspace, ii) a file or iii) a folder.');
                
            end
            
            
        end
        
        function obj = loadByFitResults(obj,filename,varargin)
            % This function assigns following fields w.r.t. a given
            % FitResults file created by qMRLab:
            %     i)  obj.Map
            %    ii)  obj.MapNames
            %
            % Assumptions:
            %    i)   FitResults should include Model and Version
            %   ii)   xnames field contains entries that matches to the
            %         names of the quantitative maps that are encapsulated
            %         by the FitResults.This is especially important if 
            %         output maps are conditional.
            %
            % Example Use:
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
            obj.MapLoadFormat = 'matlab';
            
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
            obj.ActiveMapIdx = 1;
            szz = size(obj.Map);
            
            if obj.NumMaps >1
                
                
                obj.MapDim = length(szz)-1;
                
            else
                
                obj.MapDim = length(szz);
                
            end
        end
        
        function obj = loadMap(obj,input)
            % This function assigns following fields w.r.t. a given
            % .mat ot a .nii file, containing a quantitative map:
            %     i)  obj.Map      (Just one, in this case)
            %    ii)  obj.MapNames (Just one, in this case)
            %
            %
            % Example Use:
            %
            % This function can be easily hidden from the users for classes
            % derived from this abstract base class:
            % obj = getStatMask@loadByFitResults(obj,filename,varargin);
            
            
            W = evalin('caller','whos');
            
            if ~isempty(inputname(2)) && ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name])) % Var from workspace
                
                obj.Map = input;
                obj.MapNames = {inputname(2)};
                obj.NumMaps = 1;
                obj = setActiveMap(obj,1);
                sz = size(obj.Map);
                obj.MapDim = length(sz);
                obj.MapLoadFormat = 'var';
                
            elseif exist(input,'file') == 2 % File
                
                obj.Map = AbstractStat.loadFile(input);
                obj.MapNames = {AbstractStat.strapFileNamePath(input)}; 
                obj.NumMaps = 1;
                obj = setActiveMap(obj,1);
                sz = size(obj.Map);
                obj.MapDim = length(sz);
                switch AbstractStat.getInpFormat(input)
                
                    case 'matlab'
                    obj.MapLoadFormat = 'matlab';
                    case 'nifti'
                    obj.MapLoadFormat = 'nifti';
                end
                
            elseif exist(input,'file') == 7 % Folder
                
                error('qMRLab: Provided input is NOT i) a variable in workspace or ii) a file.');
                
            else
                
                error('qMRLab: Provided input is NOT i) a variable in workspace or ii) a file.');
                
            end
            
            
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
        
        function obj = setActiveMap(obj,in)
            % Objects instantantiated from classes derived from AbstractStat
            % can have more than one quantitative maps in the obj.Map property.
            % For certain operations, one would like to specify which one to
            % include in a certain analysis.
            %
            % This function sets the ActiveMapIdx (Hidden) attribute w.r.t. the
            % argument "in" passed. In can be either numeric or char, to set
            % idx or to find corresponding idx from obj.MapNames then set it,
            % respectively.
            
            if ~isempty(obj.MapNames)
                ln = length(obj.MapNames);
            else
                error( [obj.ErrorHead...
                    '\n>>>>>> Cannot set ActiveMap to %d. No maps are loaded.'...
                    obj.Tail],in);
            end
            
            if isnumeric(in)
                
                if in>ln
                    
                    error( [obj.ErrorHead...
                        '\n>>>>>> Cannot set ActiveMap to %d. There are %d map(s) are available within this object.'...
                        obj.Tail],in,ln);
                else
                    
                    
                    obj.ActiveMapIdx = in;
                    
                end
                
            elseif ischar(in)
                
                [bool,idx] = ismember({in},obj.MapNames);
                
                if bool
                    obj.ActiveMapIdx = idx;
                else
                    error( [obj.ErrorHead...
                        '\n>>>>>> Cannot find %s in the loaded maps.'...
                        obj.Tail],in);
                end
                
                
            end
            
            
            
            
        end
        
        function showActiveMap(obj)
               
            if length(obj) >= 2
             
                error( [obj.ErrorHead...
                        '\n>>>>>> %s method is to be called by individuals objects in an ojbject array.'...
                        '\n>>>>>> Correct use: Correlation(1).showActiveMap'...
                        '\n>>>>>> Wrong use:   Correlation.showActiveMap'...
                        obj.Tail],'showActiveMap');
                    
            end
                
            disp(obj.MapNames(obj.ActiveMapIdx));
                
        end
        
        function obj = setStaticFigureOption(obj,in)

            if ~isequal(in,'osd') && ~isequal(in,'save') && ~isequal(in,'disable')
                
                error( [obj.ErrorHead...
                    '\n>>>>>> FigureOption must be one of the following'...
                    '\n>>>>>> ''osd''     : On screen display mode.'...
                    '\n>>>>>> ''save''    : Saves figure in Results.figure '...
                    '\n>>>>>> ''disable'' : Nothing will be displayed.'...
                    obj.Tail],'Correlation');
                
                
            end
            
            
            [obj(:).FigureOption] = deal({in});
            
            
        end
        
        function obj = setSignificanceLevel(obj,in)


          args = num2cell(in);
          [obj(:).SignificanceLevel] = deal(args{:});


        end

        
     end
    
    % //////////////////////////////////////////////////////////////
    
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
        
        function map = getActiveMap(obj)
            
            % This function is to extract a certain map from the map stack
            % contained in the obj.Map.
            
            if obj.MapDim == 2
                
                map = obj.Map(:,:,obj.ActiveMapIdx);
                
            elseif obj.MapDim == 3
                
                map = obj.Map(:,:,:,obj.ActiveMapIdx);
                
            end
            
        end

        function obj = setMasksFromFolder(obj,input)
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
            % External call: AbstractStat.setMasksFromFolder
            if nargin ==1
                path = obj.StatMaskInfo;
            elseif nargin ==2
                path = input;
            end
            
            matList  = dir(fullfile(path,'*.mat'));
            niiList1 = dir(fullfile(path,'*.nii.gz'));
            niiList2 = dir(fullfile(path,'*.nii'));
            
            if isempty(niiList1) && isempty(niiList2) && isempty(matList) % No acceptable format
                
                error('Directory does not contain any files with recognized formats (.mat, .nii.gz, .nii).');
                
            elseif (~isempty(niiList1) || ~isempty(niiList2)) && (isempty(matList)) % Nifti masks
                
                if ~isempty(niiList1) && ~isempty(niiList2)
                    
                    readList = {niiList1.name niiList1.name};
                    [obj.StatMask, obj.StatLabels, obj.LabelIdx] = AbstractStat.readUniFormat(readList);
                    
                elseif ~isempty(niiList1)
                    
                    readList = {niiList1.name};
                    [obj.StatMask, obj.StatLabels, obj.LabelIdx] = AbstractStat.readUniFormat(readList);
                    
                elseif ~isempty(niiList2)
                    
                    readList = {niiList2.name};
                    [obj.StatMask, obj.StatLabels, obj.LabelIdx] = AbstractStat.readUniFormat(readList);
                    
                else
                    
                    
                    
                end
                
            elseif (isempty(niiList1) && isempty(niiList2)) && (~isempty(matList)) % mat masks
                
                readList = {matList.name};
                [obj.StatMask, obj.StatLabels, obj.LabelIdx] = AbstractStat.readUniFormat(readList);
                
            else
                
                error('Mask folder contents shoud share the same format.');
                
            end
            
            
            
        end
        
    end

    % //////////////////////////////////////////////////////////////
    
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
                
            else
                
                fType = 'invalid';
                
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
        
        function [out, label, lblIdx] = readUniFormat(readlist)
            % Serves as a subfunction for setMasksFromFolder.
            % Combines multiple masks into one mask by reading a list of
            % files of the same format.
            % Size of the mask is adapted to the # of dimensions of the maps.
            % External call: AbstractStat.readUniFormat
            
            if length(readlist) == 1
                
                out = AbstractStat.loadFile(readlist{1});
                [out,label] = AbstractStat.maskAssignByType(out);
                lblIdx = cell2mat(label);
                               
            else
                
                tmp = AbstractStat.loadFile(readlist{1});
                sz = size(tmp);
                label = cell(length(readlist),1);
                
                if length(sz)>2
                    
                    out   = zeros(sz(1),sz(2),sz(3));
                    
                    
                elseif length(sz) == 2
                    
                    out = zeros(sz(1),sz(2));
                    
                end
                
                lblIdx = zeros(length(readlist),1);
                for ii=1:length(readlist)
                    
                    curMask = AbstractStat.loadFile(readlist{ii});
                    
                    % Critical assignment here!
                    out(curMask==1) = ii;
                    label{ii} = AbstractStat.strapFileName(readlist{ii});
                    
                    % Just to show users why.
                    
                    if nargout ==3
                       
                        lblIdx(ii) = ii;
                        
                    end
                    
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
        
        function out = strapFileNamePath(in)
            % This function  is to extract filename from the absolute path
            % pointing to a MATLAB or nifti file. 
            
            locsep = max(strfind(in,filesep));
            if isempty(locsep), locsep = 0; end
            
            switch AbstractStat.getInpFormat(in)
                
                
                case 'nifti'
                    
                    locpt = strfind(in, '.nii.gz');
                    
                    if isempty(locpt)
                     
                        locpt = strfind(in, '.nii');
                       
                    end
                    
                    
                    out = in((locsep+1):(locpt-1));
                    
                case 'matlab'
                
                     locpt = strfind(in, '.mat');
                     out = in((locsep+1):(locpt-1));
                
                otherwise
                    
                    error(['----------------------------------------- qMRLab Error'...
                        '\n>>>>>> %s file format is not recognized.'...
                        '\n>>>>>> Available formats: MATLAB (*.mat) & NIFTI (*.nii, *.nii.gz)'...
                        '\n--------------------------------------------'],in);
                    
            end
            
            
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
            
            NaNcontain = logical(any(isnan(vec)));
            
            if NaNcontain
                Mean = nanmean(vec);
                STD = nanstd(vec);
                NaNcontain = length(find(isnan(vec)));
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
