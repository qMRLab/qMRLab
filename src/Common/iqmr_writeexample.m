%%
example = qMRusage(qMT_bSSFP,'fit'); 

% Duplicate %
prctpos=strfind(example,'%');
for ia = 1:length(prctpos)
    example=[example(1:((prctpos(ia)+ia-1)-1)) '%' example((prctpos(ia)+ia-1):end)];
end


fid = fopen('bSSFP_batch.m','w');
fprintf(fid,example);
fclose(fid);