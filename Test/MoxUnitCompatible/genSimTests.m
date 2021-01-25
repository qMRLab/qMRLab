function genSimTests()

% Read template line by line into cell array
fid = fopen('simTemp.qmr');
allScript = textscan(fid,'%s','Delimiter','\n');
fclose(fid);
allScript = allScript{1}; % This is a cell aray that contains template

MethodList = list_models;
disp('Copy below section and paste them into Travis config.')
disp('------------------------------------------------------')
for ii = 1:length(MethodList)
    
    Model = str2func(MethodList{ii}); Model = Model();
    if Model.voxelwise
        
        newScript = replaceJoker('*-modelName-*',MethodList{ii},allScript,1);
        
        writeName = ['SimTest_' MethodList{ii} '_test' '.m'];
        
        
        fileID = fopen(writeName,'w');
        formatSpec = '%s\n';
        [nrows,~] = size(newScript);
        for row = 1:nrows
            fprintf(fileID,formatSpec,newScript{row,:});
        end
        fclose(fileID);
        
        disp('- stage: Test');
        disp(['  script: travis_wait 30 octave --no-gui --eval "bootstrapTest;cd(' char(39) '/home/travis/build/neuropoly/qMRLab/Test/MoxUnitCompatible' char(39) ');res=moxunit_runtests(' char(39) writeName char(39) ');exit(~res);"']);
    end
    
    
    
    
end


end



function newScript = replaceJoker(thisJoker,replaceWith,inScript,type)

% thisJoker: Joker definition *- joker_def_here -*
% replaceWith: Cell Aray or cell to be repaced with thisJoker
% inScript : Input script (thisJoker will be replaced in inSCript)
% type: 1 or 2: In-line replacements or block replacements

IndexC = strfind(inScript, char({thisJoker}));
idx = find(not(cellfun('isempty', IndexC)));

if type == 1 % In-line replacements
    
    for i=1:length(idx)
        
        inScript(idx(i)) = strrep(inScript(idx(i)),{thisJoker},{replaceWith});
        
    end
    
    newScript = inScript;
    
elseif type ==2 % Code blocks
    
    lenNew = length(replaceWith);
    newScript = cell(length(inScript)+lenNew-1,1);
    try
        newScript(idx:(idx+lenNew-1)) = replaceWith;
    catch
        newScript(idx:(idx+lenNew-1)) = replaceWith';
    end
    newScript(1:(idx-1)) = inScript(1:(idx-1));
    newScript((idx+lenNew):(length(inScript)+lenNew-1)) = inScript((idx+1):end);
    
    
else
    
    
    
    
end

end