function scheme=scd_schemefile_create(bvecs_files, add_b0_beginning, DELTA, delta, Gmax, TE, acq_basename)
%     scheme=SCD_SCHEMEFILE_CREATE(bvecs_files, add_b0_beginning, DELTA, delta, Gmax, TE, acq_basename)
%   
%     bvecs_files=cell array of [bvec files OR bvecs matrices].
%
%     Example:
%       bvecs_mat = [ones(150,1), zeros(150,1), zeros(150,1)];
%       bvecs_mat_cell = {bvecs_mat, bvecs_mat};
%       add_b0_beginning = 0;
%       DELTA       = [20 35]*1e-3; % s
%       delta       = [8  8 ]*1e-3; % s
%       Gmax        = [380 380]*1e-3; % T/m
%       TE          = [69 70]*1e-3; %s
%       acq_basename= date;
%       scheme=SCD_SCHEMEFILE_CREATE(bvecs_mat_cell, add_b0_beginning, DELTA, delta,Gmax, TE, acq_basename);
%
%
%     Example 2:
%       bvecs_mat = [linspace(-1,1,150)', zeros(150,1), zeros(150,1)];
%       bvecs_mat_cell = {bvecs_mat, bvecs_mat};
%       add_b0_beginning = 0;
%       DELTA       = [20 35]*1e-3; % s
%       delta       = [8  8 ]*1e-3; % s
%       Gmax        = [380 380]*1e-3; % T/m
%       TE          = [69 70]*1e-3; %s
%       acq_basename= date;
%       scheme=SCD_SCHEMEFILE_CREATE(bvecs_mat_cell, add_b0_beginning, DELTA, delta,Gmax, TE, acq_basename);
%
%
%     Example 3:
%       bvecs_files = {'bvecs.txt', 'bvecs.txt'}; 
%       add_b0_beginning = 0;
%       DELTA       = [20 35]*1e-3; % s
%       delta       = [8  8 ]*1e-3; % s
%       Gmax        = [380 380]*1e-3; % T/m
%       TE          = [69 70]*1e-3; %s
%       acq_basename= date;
%       scheme=SCD_SCHEMEFILE_CREATE(bvecs_files, add_b0_beginning, DELTA, delta,Gmax, TE, acq_basename);
%
% SEE ALSO: scd_scheme_display

% bvecs_files=dir(bvecs_files);
% bvecs_files={bvecs_files.name};
% bvecs_files=sort_nat(bvecs_files);

fid_bvec_tot = fopen([acq_basename '_bvecs.txt'],'w');
fid_bvals_tot = fopen([acq_basename '_bvals.txt'],'w');
fid_scheme    = fopen([acq_basename '.scheme'],'w');
fprintf(fid_scheme,'%s\n%s\n%s\n','#B-vector scheme. Contains gradient directions and b-values','#g_x  g_y  g_z  |G| DELTA delta TE','VERSION: STEJSKALTANNER');


for i_seq=1:length(bvecs_files)
    for i_b0_beginning = 1:add_b0_beginning
        % write bvecs
        fprintf(fid_bvec_tot, '%f   %f   %f\n',0,0,0);
        % write bvals
        fprintf(fid_bvals_tot, '%f\n', 0);
        % write scheme
        fprintf(fid_scheme, '%f   %f   %f   %f   %f   %f   %f\n', 0,0,0, 0, DELTA(i_seq), delta(i_seq), TE(i_seq));
    end
    
    if isstr(bvecs_files{i_seq})
        bvec = txt2mat(bvecs_files{i_seq}); 
    elseif isnumeric(bvecs_files{i_seq})
        bvec=bvecs_files{i_seq};
    end
        
    if size(bvec,1)==3 && size(bvec,2)>3, bvec=bvec'; end
    
    for i_vec=1:size(bvec,1)
        bvec_norm = bvec(i_vec,:)/sqrt(sum(bvec(i_vec,:).^2)); bvec_norm(isnan(bvec_norm))=0;
        % write bvecs
        fprintf(fid_bvec_tot, '%f   %f   %f\n',bvec(i_vec,:));
        % write bvals
        fprintf(fid_bvals_tot, '%f\n', (Gmax(i_seq)*sqrt(sum(bvec(i_vec,:).^2,2))*delta(i_seq)*2*pi*42.58*1e3)^2*(DELTA(i_seq)-delta(i_seq)/3));
        % write scheme
        fprintf(fid_scheme, '%f   %f   %f   %f   %f   %f   %f\n', bvec_norm, Gmax(i_seq)*sqrt(sum(bvec(i_vec,:).^2)), DELTA(i_seq), delta(i_seq), TE(i_seq));
    end
end

fclose all;

scheme=scd_schemefile_read([acq_basename '.scheme']);
    

end