function imtool3D_nii_crop(filename)
nii = nii_tool('load',filename);
tool = imtool3D_3planes(nii.img);
for ii=1:3
tool(ii).setAspectRatio(nii.hdr.pixdim(2:4));
end
RECTS = imtool3D_3planes_rect(tool);

waitfor(tool(ii).getHandles.fig);

pos = RECTS(1).getPosition();
cut_from_L = floor(pos(2)-pos(4)/2);
cut_from_R = floor(pos(2)+pos(4)/2);
cut_from_P = floor(pos(1)-pos(3)/2);
cut_from_A = floor(pos(1)+pos(3)/2);
pos = RECTS(2).getPosition();
cut_from_I = floor(pos(1)-pos(3)/2);
cut_from_S = floor(pos(1)+pos(3)/2);

nii.img = nii.img( cut_from_L+1 : cut_from_R, ...
			   cut_from_P+1 : cut_from_A, ...
			   cut_from_I+1 : cut_from_S, ...
			   :,:,:,:,:);
     

b = nii.hdr.quatern_b;
c = nii.hdr.quatern_c;
d = nii.hdr.quatern_d;

if 1.0-(b*b+c*c+d*d) < 0
   if abs(1.0-(b*b+c*c+d*d)) < 1e-5
       a = 0;
   else
       error('Incorrect quaternion values in this NIFTI data.');
   end
else
   a = sqrt(1.0-(b*b+c*c+d*d));
end

R = [a*a+b*b-c*c-d*d     2*b*c-2*a*d        2*b*d+2*a*c
   2*b*c+2*a*d         a*a+c*c-b*b-d*d    2*c*d-2*a*b
   2*b*d-2*a*c         2*c*d+2*a*b        a*a+d*d-c*c-b*b];

qmod = R*[cut_from_L*nii.hdr.pixdim(2);cut_from_P*nii.hdr.pixdim(3);cut_from_I*nii.hdr.pixdim(4)*nii.hdr.pixdim(1)];
nii.hdr.qoffset_x = nii.hdr.qoffset_x + qmod(1);
nii.hdr.qoffset_y = nii.hdr.qoffset_y + qmod(2);
nii.hdr.qoffset_z = nii.hdr.qoffset_z + qmod(3);

nii.hdr.srow_x(4) = nii.hdr.srow_x(4) + ...
                    nii.hdr.srow_x(1)*cut_from_L + ...
                    nii.hdr.srow_x(2)*cut_from_P + ...
                    nii.hdr.srow_x(3)*cut_from_I;
nii.hdr.srow_y(4) = nii.hdr.srow_y(4) + ...
                    nii.hdr.srow_y(1)*cut_from_L + ...
                    nii.hdr.srow_y(2)*cut_from_P + ...
                    nii.hdr.srow_y(3)*cut_from_I;
nii.hdr.srow_z(4) = nii.hdr.srow_z(4) + ...
                    nii.hdr.srow_z(1)*cut_from_L + ...
                    nii.hdr.srow_z(2)*cut_from_P + ...
                    nii.hdr.srow_z(3)*cut_from_I;
nii_tool('save',nii,[strrep(strrep(filename,'.nii.gz',''),'.nii','') '_crop.nii'])
