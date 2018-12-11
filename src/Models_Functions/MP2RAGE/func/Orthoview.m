
function [ output_args ] = Orthoview( volume ,varargin)
%[ output_args ] = Orthoview( volume ,varargin)
%   varargin{1} is the position of the slices
%   varargin{2} is the range of the colorbar
%   varargin{3} is the type of image 'normal','mip',proj


dims=size(volume);
if nargin>=2
    if isempty(varargin{1})
        xyz=round(dims/2);
    else
        xyz=varargin{1};
    end;
    
else
    xyz=round(dims/2);
end
if nargin>=4
    if isempty(varargin{3})
        showim='normal';
    else
        showim=varargin{3};
    end;
    
else
    showim='normal';
end

if nargin>=3
    if isempty(varargin{2})
        if strcmp(showim,'normal')
            scale=[prctile(volume(:),2) prctile(volume(:),98)];
        end;
        if or(strcmp(showim,'mip'),strcmp(showim,'MIP'))
            
            scale=[0 max(volume(:))];
        end;
        if or(strcmp(showim,'proj'),strcmp(showim,'PROJ'))
            temp1=abs(sum(volume,1));
            temp2=abs(sum(volume,2));
            temp3=abs(sum(volume,3));
            maxi=max([max(temp1(:)), max(temp2(:)),max(temp3(:))]);
            scale=[0 maxi];
        end;
    else
        
        scale=varargin{2};
    end;
else
    
    scale=[prctile(volume(:),2) prctile(volume(:),98)];
end

% simulation=0;
mosaic=zeros([max(dims(2:3)) 2*dims(1)+dims(2)]);
temp1=zeros([size(mosaic,1),dims(2)]);
temp2=zeros([size(mosaic,1),dims(1)]);
temp3=zeros([size(mosaic,1),dims(1)]);
if strcmp(showim,'normal')
    temp1a=permute(volume(xyz(1),:,:),[3,2,1]);
    temp2a=permute(volume(:,xyz(2),:),[3,1,2]);
    temp3a=permute(volume(:,:,xyz(3)),[2,1,3]);
else
    if or(strcmp(showim,'mip'),strcmp(showim,'MIP'))
        temp1a=max(permute(volume(:,:,:),[3,2,1]),[],3);
        temp2a=max(permute(volume(:,:,:),[3,1,2]),[],3);
        temp3a=max(permute(volume(:,:,:),[2,1,3]),[],3);
    end;
    if or(strcmp(showim,'proj'),strcmp(showim,'PROJ'))
        temp1a=abs(sum(permute(volume(:,:,:),[3,2,1]),3));
        temp2a=abs(sum(permute(volume(:,:,:),[3,1,2]),3));
        temp3a=abs(sum(permute(volume(:,:,:),[2,1,3]),3));
    end;
    
end;


%     temp1a=permute(volume(xyz(1),:,:),[2,3,1]);
%     temp2a=permute(volume(:,xyz(2),:),[3,1,2]);
%     temp3a=permute(volume(:,:,xyz(3)),[1,2,3]);

%      keyboard
temp1(round((size(temp1,1)-size(temp1a,1))/2)+(1:size(temp1a,1)),:)=temp1a;
temp2(round((size(temp2,1)-size(temp2a,1))/2)+(1:size(temp2a,1)),:)=temp2a;
temp3(round((size(temp3,1)-size(temp3a,1))/2)+(1:size(temp3a,1)),:)=temp3a;
mosaic=cat(2,temp1,temp2,temp3);
%     subplot(111)
imagesc(flipdim(mosaic,1),scale);
axis equal tight off
colormap(gray)


end

