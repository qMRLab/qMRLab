function [] = scd_schemefile_write(scheme,filename,SI)
% scd_schemefile_write(scheme,filename)
% units input are mT, um, ms
% units output are SI
% example: scd_schemefile_write(scheme,'exp.scheme')

if ~exist('SI','var') || isempty(SI)
    SI = false;
end

fid_scheme    = fopen([filename],'w');
fprintf(fid_scheme,'%s\n%s\n%s\n','#B-vector scheme. Contains gradient directions and b-values','#g_x  g_y  g_z  |G| DELTA delta TE','VERSION: STEJSKALTANNER');
for i=1:size(scheme,1)
    if SI
        fprintf(fid_scheme, '%f   %f   %f   %f   %f   %f   %f\n', scheme(i,[1:3]), scheme(i,4), scheme(i,5), scheme(i,6), scheme(i,7));
    else
        fprintf(fid_scheme, '%f   %f   %f   %f   %f   %f   %f\n', scheme(i,[1:3]), scheme(i,4)*1e3, scheme(i,5)*1e-3, scheme(i,6)*1e-3, scheme(i,7)*1e-3);
    end
end
fclose all;

end


