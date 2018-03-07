%% Load From File
% P. Beliveau 
% December 2016
function File = LoadImage(FullFile)
    
    [pathstr,name,ext] = fileparts(FullFile) ;
    if strcmp(ext,'.mat');
        % load .mat file
        File = load(FullFile);
        %Header = 0
    elseif strcmp(ext,'.dcm');
        % load dicom file
        File = dicomread(FullFile); 
        %Header = dicominfo(FullFile);
    elseif strcmp(ext,'.nii') || strcmp(ext,'.gz') || strcmp(ext,'.img');
        % load .nii file
        % nii = load_nii(FullFile);
            % With brain image file from set 2, got error, so using 'load_untouch_nii.m' 
            %    Non-orthogonal rotation or shearing found inside the affine matrix
            %    in this NIfTI file. 
            %    Important: save back with same nifti header using: save_untouch_nii.m
        nii = load_untouch_nii(FullFile);
        File = nii.img;
        %Header = nii.hdr
    elseif strcmp(ext,'.tiff') || strcmp(ext,'.tif');
        TiffInfo = imfinfo(FullFile);
        NbIm = numel(TiffInfo);
        if NbIm == 1
            File = imread(FullFile);
        else
            for ImNo = 1:NbIm;
                File(:,:,ImNo) = imread(FullFile, ImNo);%, 'Info', info);            
            end
        end
    elseif strcmp(ext,'.raw');
        FF = fopen(FullFile);
        File = fread(FF, [320,320], 'uint16');
        fclose(FF);
        File = File';
        %Header = 0
    end
    File = 0;
end
