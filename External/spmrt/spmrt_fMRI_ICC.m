function spmrt_fMRI_ICC

% this function allows to compute intra-class correlation on fMRI maps
% it implement the ICC(3,1) as in Shrout & Fleiss (1979) Intraclass correlations:
% uses in assessing rater reliabilityPsychological Bulletin, 86, 420-428.
%
% user is requested to select images per session and a final map is
% returned - to read images, we call SPM function, i.e. SPM must be in the
% matlab path 
%
% --------------------------------------------------
% Cyril Pernet / Chris Gorgolewski v2 (02 July 2012)

%% get the images

% nb of sessions
nb_conditions = inputdlg('how many sessions to compute ICC on?','Sessions');
try
    nb_conditions = eval(cell2mat(nb_conditions));
catch me
    error('nb of condition invalid')
end

% loop to get images
for c=1:nb_conditions
    [P, sts]= spm_select(Inf,'.*\.img$',['Select Images session' num2str(c)']);
    if sts == 0 || isempty(P) == 1
        disp('no item selected')
        return
    end
    V{c} = spm_vol(P);
    spm_check_orientations(V{c});
    nbimages(c) = size(V{c},1);
end

if sum(nbimages(1) == nbimages) ~= c
    error(['different number of images between the diffewrent sessions n = ' num2str(nbimages)])
end
    
% get mask
[mask_name,sts] = spm_select(1,'.*\.img$','Select mask image');
if sts == 0
    return
else
    mask_data = spm_read_vols(spm_vol(mask_name));
end
dim = size(mask_data);
result = NaN(dim);

%% compute ICC

% ------------------------------------------------------------------------------------------
%
%                 (Between Subject Mean Square - Within Subject Mean Square) 
% the ICC(3,1) = ------------------------------------------------------------                 
%                 (Between Subject Mean Square + (df-1)* Within Subject Mean Square) 
%
% One Sample Repeated measure ANOVA Y = XB + E with X = [Factor / Subject]
%                                   gives the within subject mean square
%                                   and the effect of repeating measures
%                                   we find the between subject by
%                                   subtraction those 2 sum of squares from
%                                   the total SS (from the data)
% ------------------------------------------------------------------------------------------

nb_subjects = nbimages(1);
df  = nb_conditions -1;
dfe = (nb_subjects*nb_conditions)  - nb_subjects - df;
dfmodel = nb_subjects - df;

% create the design matrix for the different levels
% ------------------------------------------------

x = kron(eye(nb_conditions),ones(nb_subjects,1));  % effect
x0 = repmat(eye(nb_subjects),nb_conditions,1); % subject
X = [x x0];
figure('Name','Design matrix'); set(gcf,'Color','w'); imagesc(X);
colormap('gray');  title('ANOVA model','FontSize',16);xlabel('regressors');
ylabel('scaled model values'); drawnow;
go = questdlg('start the analysis?','design check','Yes','No','Yes');
if strcmp(go,'No')
    return
end

for z=1:dim(3)
    for y=1:dim(2)
        data_position = find(mask_data(:,y,z));
        
        if ~isempty(data_position)
            clear data
            for c=1:nb_conditions
                data(:,:,c) = spm_get_data(V{c},[data_position,repmat(y,size(data_position,1),1),repmat(z,size(data_position,1),1)]');
            end
            
            % data has dim nb_subject * nb_voxels * nb_conditions
            clear Y
            for n=1:size(data,2)
                tmp = data(:,n,:);
                Y(:,n) = tmp(:); % now Y had dim [nb subject*condition] * nb_voxels
            end
                
            % Compute the SS of the ANOVA
            % ----------------------------            
            % Sum Square Total
            SST   = diag((Y-repmat(mean(Y),size(Y,1),1))'*(Y-repmat(mean(Y),size(Y,1),1)));
            
            % Sum Square Subject (= within subject) 
            M     = X*pinv(X'*X)*X';
            R     = eye(size(Y,1)) - M;
            SSS   = diag(Y'*R*Y);
            MSS   = SSS / dfe;
            
            % Sum square effect ( = repeated measure)
            Betas = pinv(x)*Y;  % compute without cst/subjects
            yhat  = x*Betas;
            SSE    = diag((yhat-repmat(mean(yhat),size(yhat,1),1))'*(yhat-repmat(mean(yhat),size(yhat,1),1)));
            
            % Sum Square error ( = between subjects)
            SSError = SST - SSS - SSE;
            MSError = SSError / dfmodel;
            
            % ICC is
            result(data_position,y,z) = ((MSError-MSS) ./ (MSError + df*MSS));
        end
    end
end
 
%% save the result as an image

s = spm_vol(mask_name);
dir_path = uigetdir('select directory to save your ICC image','dir selection');
s.fname = [dir_path '/ICC.img'];
s.descrip = ['ICC computed within ' s.descrip];
spm_write_vol(s,result)
disp('ICC analysis done');

 
 
 
 
