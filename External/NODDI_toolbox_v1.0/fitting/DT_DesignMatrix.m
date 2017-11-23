function X=DT_DesignMatrix(protocol)
% Computes the design matrix for DT fitting using linear least squares.
%
% function X=DT_DesignMatrix(protocol)
%
% protocol is the acquisition protocol.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%


GAMMA = 2.675987E8;

if(strcmp(protocol.pulseseq, 'PGSE') || strcmp(protocol.pulseseq, 'STEAM'))
    modQ = GAMMA*protocol.smalldel'.*protocol.G';
    q = repmat(modQ, [1,3]).*protocol.grad_dirs;
    diffTime = (protocol.delta' - protocol.smalldel'/3);

    % Compute the design matrix
    X = [ones(1, length(q)); -diffTime'.*q(:,1)'.*q(:,1)'; -2*diffTime'.*q(:,1)'.*q(:,2)'; -2*diffTime'.*q(:,1)'.*q(:,3)'; -diffTime'.*q(:,2)'.*q(:,2)'; -2*diffTime'.*q(:,2)'.*q(:,3)'; -diffTime'.*q(:,3)'.*q(:,3)']';

elseif(strcmp(protocol.pulseseq, 'OGSE'))
    q = protocol.grad_dirs;
    b = GetB_Values(protocol);

    % Compute the design matrix
    X = [ones(1, length(q)); -b.*q(:,1)'.*q(:,1)'; -2*b.*q(:,1)'.*q(:,2)'; -2*b.*q(:,1)'.*q(:,3)'; -b.*q(:,2)'.*q(:,2)'; -2*b.*q(:,2)'.*q(:,3)'; -b.*q(:,3)'.*q(:,3)']';

elseif(strcmp(protocol.pulseseq, 'DSE'))

    bValue = GetB_ValuesDSE(protocol.G, protocol.delta1, protocol.delta2, protocol.delta3, protocol.t1, protocol.t2, protocol.t3);
    
    % Compute the design matrix
    X = [ones(1, length(protocol.G)); -bValue.*protocol.grad_dirs(:,1)'.*protocol.grad_dirs(:,1)'; -2*bValue.*protocol.grad_dirs(:,1)'.*protocol.grad_dirs(:,2)'; -2*bValue.*protocol.grad_dirs(:,1)'.*protocol.grad_dirs(:,3)'; -bValue.*protocol.grad_dirs(:,2)'.*protocol.grad_dirs(:,2)'; -2*bValue.*protocol.grad_dirs(:,2)'.*protocol.grad_dirs(:,3)'; -bValue.*protocol.grad_dirs(:,3)'.*protocol.grad_dirs(:,3)']';

elseif(strcmp(protocol.pulseseq, 'FullSTEAM'))

    tdd = protocol.gap1 + protocol.gap2 + protocol.TM + 2*protocol.sdelc + 2*protocol.smalldel/3 + 2*protocol.sdelr;
    tcc = protocol.TM + 2*protocol.sdelc/3 + 2*protocol.sdelr;
    trr = protocol.TM + 2*protocol.sdelr/3;
    tdc = protocol.TM + protocol.sdelc + 2*protocol.sdelr;
    tdr = protocol.TM + protocol.sdelr;
    tcr = protocol.TM + protocol.sdelr;

    qdx = protocol.grad_dirs(:,1)'.*protocol.G.*protocol.smalldel;
    qdy = protocol.grad_dirs(:,2)'.*protocol.G.*protocol.smalldel;
    qdz = protocol.grad_dirs(:,3)'.*protocol.G.*protocol.smalldel;
    qcx = protocol.cG(:,1)'.*protocol.sdelc;
    qcy = protocol.cG(:,2)'.*protocol.sdelc;
    qcz = protocol.cG(:,3)'.*protocol.sdelc;
    qrx = protocol.rG(:,1)'.*protocol.sdelr;
    qry = protocol.rG(:,2)'.*protocol.sdelr;
    qrz = protocol.rG(:,3)'.*protocol.sdelr;

    Fxx = -GAMMA^2*(qdx.^2.*tdd + qcx.^2.*tcc + qrx.^2.*trr + 2*qdx.*qcx.*tdc + 2*qdx.*qrx.*tdr + 2*qcx.*qrx.*tcr);
    Fyy = -GAMMA^2*(qdy.^2.*tdd + qcy.^2.*tcc + qry.^2.*trr + 2*qdy.*qcy.*tdc + 2*qdy.*qry.*tdr + 2*qcy.*qry.*tcr);
    Fzz = -GAMMA^2*(qdz.^2.*tdd + qcz.^2.*tcc + qrz.^2.*trr + 2*qdz.*qcz.*tdc + 2*qdz.*qrz.*tdr + 2*qcz.*qrz.*tcr);
    Fxy = -GAMMA^2*(qdx.*qdy.*tdd + qcx.*qcy.*tcc + qrx.*qry.*trr + (qdx.*qcy+qdy.*qcx).*tdc + (qdx.*qry+qdy.*qrx).*tdr + (qcx.*qry+qcy.*qrx).*tcr)*2;
    Fxz = -GAMMA^2*(qdx.*qdz.*tdd + qcx.*qcz.*tcc + qrx.*qrz.*trr + (qdx.*qcz+qdz.*qcx).*tdc + (qdx.*qrz+qdz.*qrx).*tdr + (qcx.*qrz+qcz.*qrx).*tcr)*2;
    Fyz = -GAMMA^2*(qdy.*qdz.*tdd + qcy.*qcz.*tcc + qry.*qrz.*trr + (qdy.*qcz+qdz.*qcy).*tdc + (qdy.*qrz+qdz.*qry).*tdr + (qcy.*qrz+qcz.*qry).*tcr)*2;

    % Compute the design matrix
    X = [ones(1, length(protocol.G)); Fxx; Fxy; Fxz; Fyy; Fyz; Fzz]';
save /tmp/FS_X.mat X;

elseif(strcmp(protocol.pulseseq, 'GEN'))
    
    bValue = GENGetB_Values(protocol);
    % Compute the design matrix
    bValue=bValue';
    X = [ones(1, length(protocol.delta)); -bValue.*protocol.grad_dirs(:,1)'.*protocol.grad_dirs(:,1)'; -2*bValue.*protocol.grad_dirs(:,1)'.*protocol.grad_dirs(:,2)'; -2*bValue.*protocol.grad_dirs(:,1)'.*protocol.grad_dirs(:,3)'; -bValue.*protocol.grad_dirs(:,2)'.*protocol.grad_dirs(:,2)'; -2*bValue.*protocol.grad_dirs(:,2)'.*protocol.grad_dirs(:,3)'; -bValue.*protocol.grad_dirs(:,3)'.*protocol.grad_dirs(:,3)']';
    
else

    error('Not implemented for pulse sequence: %s', protocol.pulseseq);
end

