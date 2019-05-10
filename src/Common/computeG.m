function G = computeG(delta,T2r,lineshape,onres)
% computeG : Compute lineshape value
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------


switch lineshape
    case 'Gaussian'
        G = gaussianLineshape(delta, T2r);
    case 'Lorentzian'
        G = lorentzianLineshape(delta, T2r);
    case 'SuperLorentzian'
        if (~exist('onres','var') || isempty(onres))
            onres = 1;   % by default, extrapolate near resonance
        end
        G = superlorentzianLineshape(delta, T2r, onres);
    otherwise
        error('Please use Gaussian, Lorentzian or SuperLorentzian as argument for lineshape');
end

end