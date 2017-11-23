function [E,J]=SynthMeasIsoGPD(d, protocol)
% Computes signals and their derivatives for isotropic free diffusion with
% diffusivity d for the protocol.
%
% [E,J]=SynthMeasIsoGPD(d, protocol)
% returns the measurements E according to the model and the Jacobian J of the
% measurements with respect to the parameter d.
%
% d is the diffusivity.
%
% protocol is the object containing the acquisition protocol.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%

if(strcmp(protocol.pulseseq, 'PGSE') || strcmp(protocol.pulseseq, 'STEAM'))

    GAMMA = 2.675987E8;
    modQ = GAMMA*protocol.smalldel'.*protocol.G';
    modQ_Sq = modQ.^2;
    difftime = (protocol.delta'-protocol.smalldel'/3);

    E = exp(-difftime.*modQ_Sq*d);
    if(nargout>1)
        J = -difftime.*modQ_Sq.*E;
    end
elseif(strcmp(protocol.pulseseq, 'FullSTEAM'))

    GAMMA = 2.675987E8;

    FullG = protocol.grad_dirs.*repmat(protocol.G', [1 3]);
    GdGd = sum(FullG.*FullG,2)';
    GcGc = sum(protocol.cG.*protocol.cG,2)';
    GrGr = sum(protocol.rG.*protocol.rG,2)';
    GdGc = sum(FullG.*protocol.cG,2)';
    GdGr = sum(FullG.*protocol.rG,2)';
    GcGr = sum(protocol.cG.*protocol.rG,2)';

    tdd = protocol.gap1 + protocol.gap2 + protocol.TM + 2*protocol.sdelc + 2*protocol.smalldel/3 + 2*protocol.sdelr;
    tcc = protocol.TM + 2*protocol.sdelc/3 + 2*protocol.sdelr;
    trr = protocol.TM + 2*protocol.sdelr/3;
    tdc = protocol.TM + protocol.sdelc + 2*protocol.sdelr;
    tdr = protocol.TM + protocol.sdelr;
    tcr = protocol.TM + protocol.sdelr;

    gqt = GAMMA^2*(GdGd.*protocol.smalldel.^2.*tdd + ...
    GcGc.*protocol.sdelc.^2.*tcc + ...
    GrGr.*protocol.sdelr.^2.*trr + ...
    2*GdGc.*protocol.smalldel.*protocol.sdelc.*tdc + ...
    2*GdGr.*protocol.smalldel.*protocol.sdelr.*tdr + ...
    2*GcGr.*protocol.sdelc.*protocol.sdelr.*tcr);

    E=exp(-gqt'*d);

    if(nargout>1)
        J = -gqt.*E;
    end
elseif(strcmp(protocol.pulseseq, 'DSE'))
    bValue = GetB_ValuesDSE(protocol.G', protocol.delta1', protocol.delta2', protocol.delta3', protocol.t1', protocol.t2', protocol.t3');
    E = exp(-bValue*d);
    if(nargout>1)
        J = -bValue.*E;
    end
elseif(strcmp(protocol.pulseseq, 'OGSE'))
    bValue = GetB_Values(protocol)';
    E = exp(-bValue*d);
    if(nargout>1)
        J = -bValue.*E;
    end
else
    error('Not implemented for pulse sequence: %s', protocol.pulseseq);
end

