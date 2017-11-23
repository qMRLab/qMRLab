function [E J] = SynthMeas(model, xsc, protocol, fibredir, constants)
%
% function [E J] = SynthMeas(model, xsc, protocol, fibredir, constants)
%
% General method for generating synthetic data from a model.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

if(nargout == 1)
    if(strcmp(model, 'IsoGPD'))
        [E] = SynthMeasIsoGPD(xsc, protocol);
    elseif(strcmp(model, 'CylSingleRadGPD'))
        [E] = SynthMeasCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadGPD_B0'))
        [E] = SynthMeasCylSingleRadGPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoV_GPD'))
        [E] = SynthMeasCylSingleRadIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoV_GPD_B0'))
        [E] = SynthMeasCylSingleRadIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadTortGPD'))
        [E] = SynthMeasCylSingleRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadTortIsoGPD'))
        [E] = SynthMeasCylSingleRadTortIsoGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadTortIsoV_GPD'))
        [E] = SynthMeasCylSingleRadTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadTortIsoV_GPD_B0'))
        [E] = SynthMeasCylSingleRadTortIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoCylTortIsoV_GPD'))
        [E] = SynthMeasCylSingleRadIsoCylTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoStickTortIsoV_GPD'))
        [E] = SynthMeasCylSingleRadIsoStickTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoSphereTortIsoV_GPD'))
        [E] = SynthMeasCylSingleRadIsoSphereTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl, constants.roots_sph);
    elseif(strcmp(model, 'CylSingleRadIsoDotGPD'))
        [E] = SynthMeasCylSingleRadIsoDotGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoDotTortIsoV_GPD'))
        [E] = SynthMeasCylSingleRadIsoDotTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoDotTortIsoV_GPD_B0'))
        [E] = SynthMeasCylSingleRadIsoDotTortIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoDotTortIsoV_GPD_B0T1'))
        [E] = SynthMeasCylSingleRadIsoDotTortIsoV_GPD_B0T1(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoSphereTortIsoV_GPD'))
        [E] = SynthMeasCylSingleRadIsoSphereTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylGammaRadGPD'))
        [E] = SynthMeasCylGammaRadGPD_PGSE(xsc, protocol.grad_dirs, protocol.G', protocol.delta', protocol.smalldel', fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadTortGPD'))
        [E] = SynthMeasCylGammaRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadTortIsoGPD'))
        [E] = SynthMeasCylGammaRadTortIsoGPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadTortIsoV_GPD'))
        [E] = SynthMeasCylGammaRadTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadByVolGPD'))
        [E] = SynthMeasCylGammaRadByVolGPD_PGSE(xsc, protocol.grad_dirs, protocol.G', protocol.delta', protocol.smalldel', fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadByVolTortGPD'))
        [E] = SynthMeasCylGammaRadByVolTortGPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadByVolTortIsoGPD'))
        [E] = SynthMeasCylGammaRadByVolTortIsoGPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadByVolTortIsoV_GPD'))
        [E] = SynthMeasCylGammaRadByVolTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'SphereSingleRadGPD'))
        [E] = SynthMeasSphereSingleRadGPD(xsc, protocol, constants.roots_sph);
    elseif(strcmp(model, 'Stick'))
        [E] = SynthMeasStick(xsc, protocol, fibredir);
    elseif(strcmp(model, 'StickTort'))
        [E] = SynthMeasStickTort(xsc, protocol, fibredir);
    elseif(strcmp(model, 'StickIsoV_B0'))
        [E] = SynthMeasStickIsoV_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'StickTortIsoV_B0'))
        [E] = SynthMeasStickTortIsoV_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonCylSingleRadGPD'))
        [E] = SynthMeasWatsonCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonCylSingleRadTortGPD'))
        [E] = SynthMeasWatsonCylSingleRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonCylSingleRadTortIsoV_GPD'))
        [E] = SynthMeasWatsonCylSingleRadTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonCylSingleRadTortIsoV_GPD_B0'))
        [E] = SynthMeasWatsonCylSingleRadTortIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonStick'))
        [E] = SynthMeasWatsonStick(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonStickTort'))
        [E] = SynthMeasWatsonStickTort(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHCylSingleRadGPD'))
        [E] = SynthMeasWatsonSHCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonSHCylSingleRadTortGPD'))
        [E] = SynthMeasWatsonSHCylSingleRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonSHCylSingleRadTortIsoV_GPD'))
        [E] = SynthMeasWatsonSHCylSingleRadTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonSHCylSingleRadTortIsoV_GPD_B0'))
        [E] = SynthMeasWatsonSHCylSingleRadTortIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonSHStick'))
        [E] = SynthMeasWatsonSHStick(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickIsoV_B0'))
        [E] = SynthMeasWatsonSHStickIsoV_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickIsoVIsoDot_B0'))
        [E] = SynthMeasWatsonSHStickIsoVIsoDot_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickTort'))
        [E] = SynthMeasWatsonSHStickTort(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickTortIsoV_B0'))
        [E] = SynthMeasWatsonSHStickTortIsoV_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickTortIsoVIsoDot_B0'))
        [E] = SynthMeasWatsonSHStickTortIsoVIsoDot_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'BinghamCylSingleRadGPD'))
        [E] = SynthMeasBinghamCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'BinghamCylSingleRadTortGPD'))
        [E] = SynthMeasBinghamCylSingleRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'BinghamCylSingleRadTortIsoV_GPD'))
        [E] = SynthMeasBinghamCylSingleRadTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'BinghamCylSingleRadTortIsoV_GPD_B0'))
        [E] = SynthMeasBinghamCylSingleRadTortIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'BinghamStickTortIsoV_B0'))
        [E] = SynthMeasBinghamStickTortIsoV_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'ExCrossingCylSingleRadGPD'))
        [E] = SynthMeasExCrossingCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadGPD'))
        [E] = SynthMeasExCrossingCylSingleRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotGPD'))
        [E] = SynthMeasExCrossingCylSingleRadIsoDotGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotTortGPD'))
        [E] = SynthMeasExCrossingCylSingleRadIsoDotTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotTortIsoV_GPD'))
        [E] = SynthMeasExCrossingCylSingleRadIsoDotTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotTortIsoV_GPD_B0'))
        [E] = SynthMeasExCrossingCylSingleRadIsoDotTortIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    else
        error(['Undefined model: ', model]);
    end
else
    if(strcmp(model, 'IsoGPD'))
        [E J] = SynthMeasIsoGPD(xsc, protocol);
    elseif(strcmp(model, 'CylSingleRadGPD'))
        [E J] = SynthMeasCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoV_GPD'))
        [E J] = SynthMeasCylSingleRadIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadIsoV_GPD_B0'))
        [E J] = SynthMeasCylSingleRadIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadTortGPD'))
        [E J] = SynthMeasCylSingleRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadTortIsoGPD'))
        [E J] = SynthMeasCylSingleRadTortIsoGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadTortIsoV_GPD'))
        [E J] = SynthMeasCylSingleRadTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylSingleRadTortIsoV_GPD_B0'))
        [E J] = SynthMeasCylSingleRadTortIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'CylGammaRadGPD'))
        [E J] = SynthMeasCylGammaRadGPD_PGSE(xsc, protocol.grad_dirs, protocol.G', protocol.delta', protocol.smalldel', fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadTortGPD'))
        [E J] = SynthMeasCylGammaRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadTortIsoGPD'))
        [E J] = SynthMeasCylGammaRadTortIsoGPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadTortIsoV_GPD'))
        [E J] = SynthMeasCylGammaRadTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadByVolGPD'))
        [E J] = SynthMeasCylGammaRadByVolGPD_PGSE(xsc, protocol.grad_dirs, protocol.G', protocol.delta', protocol.smalldel', fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadByVolTortGPD'))
        [E J] = SynthMeasCylGammaRadByVolTortGPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadByVolTortIsoGPD'))
        [E J] = SynthMeasCylGammaRadByVolTortIsoGPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'CylGammaRadByVolTortIsoV_GPD'))
        [E J] = SynthMeasCylGammaRadByVolTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl, 0);
    elseif(strcmp(model, 'SphereSingleRadGPD'))
        [E J] = SynthMeasSphereSingleRadGPD(xsc, protocol, constants.roots_sph);
    elseif(strcmp(model, 'CylSingleRadGPD_B0'))
        [E J] = SynthMeasCylSingleRadGPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'Stick'))
        [E J] = SynthMeasStick(xsc, protocol, fibredir);
    elseif(strcmp(model, 'StickTort'))
        [E J] = SynthMeasStickTort(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonStick'))
        [E J] = SynthMeasWatsonStick(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonStickTort'))
        [E J] = SynthMeasWatsonStickTort(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStick'))
        [E J] = SynthMeasWatsonSHStick(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickIsoV_B0'))
        [E J] = SynthMeasWatsonSHStickIsoV_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickIsoVIsoDot_B0'))
        [E J] = SynthMeasWatsonSHStickIsoVIsoDot_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickTort'))
        [E J] = SynthMeasWatsonSHStickTort(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickTortIsoV_B0'))
        [E J] = SynthMeasWatsonSHStickTortIsoV_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonSHStickTortIsoVIsoDot_B0'))
        [E J] = SynthMeasWatsonSHStickTortIsoVIsoDot_B0(xsc, protocol, fibredir);
    elseif(strcmp(model, 'WatsonCylSingleRadGPD'))
        [E J] = SynthMeasWatsonCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonSHCylSingleRadGPD'))
        [E J] = SynthMeasWatsonSHCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonSHCylSingleRadTortGPD'))
        [E J] = SynthMeasWatsonSHCylSingleRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'WatsonSHCylSingleRadTortIsoV_GPD'))
        [E J] = SynthMeasWatsonSHCylSingleRadTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'BinghamCylSingleRadGPD'))
        [E J] = SynthMeasBinghamCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadGPD'))
        [E J] = SynthMeasExCrossingCylSingleRadGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadTortGPD'))
        [E J] = SynthMeasExCrossingCylSingleRadTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotGPD'))
        [E J] = SynthMeasExCrossingCylSingleRadIsoDotGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotTortGPD'))
        [E J] = SynthMeasExCrossingCylSingleRadIsoDotTortGPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotTortIsoV_GPD'))
        [E J] = SynthMeasExCrossingCylSingleRadIsoDotTortIsoV_GPD(xsc, protocol, fibredir, constants.roots_cyl);
    elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotTortIsoV_GPD_B0'))
        [E J] = SynthMeasExCrossingCylSingleRadIsoDotTortIsoV_GPD_B0(xsc, protocol, fibredir, constants.roots_cyl);
    else
        error(['Undefined model: ', model]);
    end
end

