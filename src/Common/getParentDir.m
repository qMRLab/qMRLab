function parentDir = getParentDir(parentName)
%GETPARENTDIR Returns parent directory that matched the parent name input.
%   parentName: String. Parent or grandparent of the current folder.

curDir = split(pwd, '/');

maxParent = find(ismember(curDir, parentName));

try
    assert (maxParent ~= 0)
catch
   error('getParentDir: input parent folder name does not exist for this present working directory.') 
end

for ii = 1:maxParent
   
    
   if  strcmp(curDir{ii}, '')
       preDir = '/';
   else
       preDir = fullfile(preDir, curDir{ii});
   end
end

if exist(preDir, 'dir')
    parentDir = preDir;
else
    error('getParentDir: did not parse parent directory correctly, abort.') 
    parentDir = [];
end


end
