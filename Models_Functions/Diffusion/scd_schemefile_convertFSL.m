function scd_schemefile_convertFSL(bvalfile, bvecfile)
% Example:
%   SCD_FSL2SCHEMEFILE('NODDI_protocol.bval','NODDI_protocol.bvec')

scheme = FSL2Protocol(bvalfile,bvecfile);
TE = 0; % ms
schememat = [scheme.grad_dirs scheme.G(:)*1e-3 scheme.delta(:)*1e3 scheme.smalldel(:)*1e3 TE];
scd_schemefile_write(schememat,'Protocol.txt')