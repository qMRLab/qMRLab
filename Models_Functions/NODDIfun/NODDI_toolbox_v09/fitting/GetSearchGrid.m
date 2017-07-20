function grid = GetSearchGrid(model, material, fix, fixedvals)
% Returns a list of parameter combinations for the specified model
% for the GridSearch function to use in search for the combination
% that best fits a set of measurements.
%
% grid=GetSearchGrid(model, material, fix, fixedvals)
% returns a list of parameter combinations for the model that
% are realistic for a particular material type.
%
% model is a string specifying the model.
%
% material is a string specifying the type of material, which
% determines the range of each parameter in the grid.
% Options are:
% invivo
% invivopreterm
% invivowhitematter
% fixedwhitematter
%
% fix is a list of binary numbers specifying which
% model parameters have fixed values.  By default the
% list is all zeros so no parameters are fixed.
%
% fixedvals is an array the same size as fix that specifies
% the fixed values of any fixed parameters.  Entries in
% fixedvals in locations where fix has value zero are not
% used.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

if(nargin<3)
    fix=zeros(6);
    fixedvals = zeros(6);
end

if(strcmp(material, 'invivo'))
    fs = [0.0 0.25 0.5 0.75 1.0];
    dpars = [13.0 17.0 21.0]*1E-10;
    disos = [10.0 20.0 30.0 50.0]*1E-10;
    Rs=[0.5 1 2 4]*1E-6;
    irfracs=[0 0.1 0.2 0.3];
    fisos=[0.0 0.25 0.5 0.75 1.0];
    kappas = [0.5 1 2 4 8];
    fic = [0.3 0.5 0.7];
elseif(strcmp(material, 'exvivo'))
    fs = [0.0 0.25 0.5 0.75 1.0];
    dpars = [3.0 4.5 6.0 7.5]*1E-10;
    disos = [5.0 10.0 15.0]*1E-10;
    Rs=[1 2 4 8]*1E-6;
    irfracs=[0 0.1 0.2 0.3];
    fisos=[0.0 0.25 0.5 0.75 1.0];
    kappas = [0.5 1 2 4 8];
    fic = [0.3 0.5 0.7];
elseif(strcmp(material, 'invivopreterm'))
    fs = [0.0 0.1 0.2 0.3];
    dpars = [13.0 17.0 21.0]*1E-10;
    disos = [10.0 20.0 30.0 50.0]*1E-10;
    Rs=[1 2 4 8]*1E-6;
    irfracs=[0 0.1 0.2 0.3];
    fisos=[0.0 0.25 0.5 0.75 1.0];
    kappas = [0.5 1 2 4 8];
    fic = [0.3 0.5 0.7];
elseif(strcmp(material, 'invivowhitematter'))
    fs = [0.5 0.7 0.9];
    dpars = [10.0 13.0 15.0 17.0 19.0 21.0 23.0 25.0]*1E-10;
    disos = [10.0 20.0 30.0 50.0]*1E-10;
    Rs=[1 2 4 8]*1E-6;
    irfracs=[0 0.1 0.2 0.3];
    fisos=[0 0.2 0.4];
    kappas = [4 8 16 32 64 128];
    fic = [0.3 0.5 0.7];
elseif(strcmp(material, 'postmortemwhitematter'))
    fs = [0.5 0.7 0.9];
    dpars = [2.0 3.0 4.0 5.0 6.0]*1E-10;
    disos = [5.0 10.0 15.0]*1E-10;
    Rs=[1 2 4 8]*1E-6;
    irfracs=[0 0.1 0.2 0.3];
    fisos=[0 0.2 0.4];
    kappas = [4 8 16 32 64 128];
    fic = [0.3 0.5 0.7];
else
    error(['Unknown material: ', tissue]);
end

% Adjust for fixed parameters.  The first two parameters are the same for
% all models.
if(fix(1))
    fs = [fixedvals(1)];
end
if(fix(2))
    dpars = [fixedvals(2)];
end

if(strcmp(model, 'CylSingleRadTortGPD'))
    if(fix(3))
        Rs = [fixedvals(3)];
    end

    numCombs = length(Rs)*length(fs)*length(dpars);
    grid = zeros(3, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                pars = [fs(j) dpars(k) Rs(i)];
                grid(:,ind) = pars;
                ind = ind + 1;
            end
        end
    end
elseif(strcmp(model, 'CylSingleRadGPD'))
    if(fix(4))
        Rs = [fixedvals(4)];
    end

    numCombs = length(Rs)*length(fs)*length(dpars);
    grid = zeros(4, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                % Set dperp using the standard tortuosity model for
                % randomly placed cylinders unless fixed.
                dperp = dpars(k)*(1-fs(j));
                if(fix(3))
                    dperp = fixedvals(3);
                end
                pars = [fs(j) dpars(k) dperp Rs(i)];
                grid(:,ind) = pars;
                ind = ind + 1;
            end
        end
    end
elseif(strcmp(model, 'CylSingleRadTortIsoGPD'))
    if(fix(3))
        Rs = [fixedvals(3)];
    end
    if(fix(4))
        fisos = [fixedvals(4)];
    end

    numCombs = length(Rs)*length(fs)*length(dpars)*length(fisos);
    grid = zeros(4, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                for l=1:length(fisos)
                    pars = [fs(j) dpars(k) Rs(i) fisos(l)];
                    grid(:,ind) = pars;
                    ind = ind + 1;
                end
            end
        end
    end
elseif(strcmp(model, 'CylSingleRadIsoV_GPD') || strcmp(model, 'CylSingleRadIsoV_GPD_B0'))
    if(fix(4))
        Rs = [fixedvals(4)];
    end
    if(fix(5))
        fisos = [fixedvals(5)];
    end
    if(fix(6))
        disos = [fixedvals(6)];
    end

    numCombs = length(Rs)*length(fs)*length(dpars)*length(fisos)*length(disos);
    grid = zeros(6, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                for l=1:length(fisos)
                    for m=1:length(disos)
                        % Set dperp using the standard tortuosity model for
                        % randomly placed cylinders unless fixed.
                        dperp = dpars(k)*(1-fs(j));
                        if(fix(3))
                            dperp = fixedvals(3);
                        end
                        pars = [fs(j) dpars(k) dperp Rs(i) fisos(l) disos(m)];
                        grid(:,ind) = pars;
                        ind = ind + 1;
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'CylSingleRadTortIsoV_GPD') || strcmp(model, 'CylSingleRadTortIsoV_GPD_B0'))
    if(fix(3))
        Rs = [fixedvals(3)];
    end
    if(fix(4))
        fisos = [fixedvals(4)];
    end
    if(fix(5))
        disos = [fixedvals(5)];
    end

    numCombs = length(Rs)*length(fs)*length(dpars)*length(fisos)*length(disos);
    grid = zeros(5, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                for l=1:length(fisos)
                    for m=1:length(disos)
                        pars = [fs(j) dpars(k) Rs(i) fisos(l) disos(m)];
                        grid(:,ind) = pars;
                        ind = ind + 1;
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'CylSingleRadIsoDotGPD'))
    if(fix(4))
        Rs = [fixedvals(4)];
    end
    if(fix(5))
        irfracs = [fixedvals(5)];
    end
    numCombs = length(Rs)*length(fs)*length(dpars)*length(irfracs);
    grid = zeros(5, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                for l=1:length(irfracs)
                    dperp = dpars(k)*(1-fs(j));
                    pars = [fs(j) dpars(k) dperp Rs(i) irfracs(l)];
                    grid(:,ind) = pars;
                    ind = ind + 1;
                end
            end
        end
    end
elseif(strcmp(model, 'CylSingleRadIsoResTortIsoV_GPD') || strcmp(model, 'CylSingleRadIsoResTortIsoV_GPD_B0')...
        || strcmp(model, 'CylSingleRadIsoStickTortIsoV_GPD') || strcmp(model, 'CylSingleRadIsoStickTortIsoV_GPD_B0')...
        || strcmp(model, 'CylSingleRadIsoSphereTortIsoV_GPD') || strcmp(model, 'CylSingleRadIsoSphereTortIsoV_GPD_B0')...
        || strcmp(model, 'CylSingleRadIsoDotTortIsoV_GPD') || strcmp(model, 'CylSingleRadIsoDotTortIsoV_GPD_B0'))
    if(fix(3))
        Rs = [fixedvals(3)];
    end
    if(fix(4))
        irfracs = [fixedvals(4)];
    end
    if(fix(5))
        fisos = [fixedvals(5)];
    end
    if(fix(6))
        disos = [fixedvals(6)];
    end

    numCombs = length(Rs)*length(fs)*length(dpars)*length(fisos)*length(disos);
    grid = zeros(6, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                for l=1:length(fisos)
                    for m=1:length(disos)
                        for n=1:length(irfracs)
                            pars = [fs(j) dpars(k) Rs(i) irfracs(n) fisos(l) disos(m)];
                            grid(:,ind) = pars;
                            ind = ind + 1;
                        end
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'Stick'))
    numCombs = length(fs)*length(dpars);
    grid = zeros(3, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
            % Set dperp using the standard tortuosity model for
            % randomly placed cylinders unless fixed.
            dperp = dpars(j)*(1-fs(i));
            if(fix(3))
                dperp = fixedvals(3);
            end
            pars = [fs(i) dpars(j) dperp];
            grid(:,ind) = pars;
            ind = ind + 1;
        end
    end
elseif(strcmp(model, 'StickIsoV_B0'))
    if(fix(4))
        fisos = [fixedvals(4)];
    end
    if(fix(5))
        disos = [fixedvals(5)];
    end

    numCombs = length(fs)*length(dpars)*length(fisos)*length(disos);
    grid = zeros(5, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
            for k=1:length(fisos)
                for l=1:length(disos)
                    % Set dperp using the standard tortuosity model for
                    % randomly placed cylinders unless fixed
                    dperp = dpars(j)*(1-fs(i));
                    if(fix(3))
                        dperp = fixedvals(3);
                    end
                    pars = [fs(i) dpars(j) dperp fisos(k) disos(l)];
                    grid(:,ind) = pars;
                    ind = ind + 1;
                end
            end
        end
    end
elseif(strcmp(model, 'StickTortIsoV_B0'))
    if(fix(3))
        fisos = [fixedvals(3)];
    end
    if(fix(4))
        disos = [fixedvals(4)];
    end

    numCombs = length(fs)*length(dpars)*length(fisos)*length(disos);
    grid = zeros(4, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
            for k=1:length(fisos)
                for l=1:length(disos)
                    pars = [fs(i) dpars(j) fisos(k) disos(l)];
                    grid(:,ind) = pars;
                    ind = ind + 1;
                end
            end
        end
    end
elseif(strcmp(model, 'WatsonStick') || strcmp(model, 'WatsonSHStick'))
    numCombs = length(fs)*length(dpars)*length(kappas);
    grid = zeros(4, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
		  for k=1:length(kappas)
                % Set dperp using the standard tortuosity model for
                % randomly placed cylinders unless fixed.
                dperp = dpars(j)*(1-fs(i));
                if(fix(3))
                    dperp = fixedvals(3);
                end
                pars = [fs(i) dpars(j) dperp kappas(k)];
                grid(:,ind) = pars;
                ind = ind + 1;
            end
        end
    end
elseif(strcmp(model, 'WatsonSHStickIsoV_B0'))
    if(fix(4))
        kappas = [fixedvals(4)];
    end
    if(fix(5))
        fisos = [fixedvals(5)];
    end
    if(fix(6))
        disos = [fixedvals(6)];
    end

    numCombs = length(fs)*length(dpars)*length(fisos)*length(disos)*length(kappas);
    grid = zeros(6, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
            for k=1:length(fisos)
                for l=1:length(disos)
                    for m=1:length(kappas)
                      dperp = dpars(j)*(1-fs(i));
                      if(fix(3))
                          dperp = fixedvals(3);
                      end
                      pars = [fs(i) dpars(j) dperp kappas(m) fisos(k) disos(l)];
                      grid(:,ind) = pars;
                      ind = ind + 1;
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'WatsonSHStickIsoVIsoDot_B0'))
    if(fix(5))
        fisos = [fixedvals(5)];
    end
    if(fix(6))
        disos = [fixedvals(6)];
    end
    if(fix(7))
        irfracs = [fixedvals(7)];
    end

    numCombs = length(fs)*length(dpars)*length(fisos)*length(disos)*length(kappas)*length(irfracs);
    grid = zeros(7, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
            for k=1:length(fisos)
                for l=1:length(disos)
                    for m=1:length(kappas)
                        for n=1:length(irfracs)
                          dperp = dpars(j)*(1-fs(i));
                          if(fix(3))
                             dperp = fixedvals(3);
                          end
                          pars = [fs(i) dpars(j) dperp kappas(m) fisos(k) disos(l) irfracs(n)];
                          grid(:,ind) = pars;
                          ind = ind + 1;
                        end
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'WatsonStickTort') || strcmp(model, 'WatsonSHStickTort'))
    numCombs = length(fs)*length(dpars)*length(kappas);
    grid = zeros(3, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
		  for k=1:length(kappas)
                pars = [fs(i) dpars(j) kappas(k)];
                grid(:,ind) = pars;
                ind = ind + 1;
            end
        end
    end
elseif(strcmp(model, 'WatsonSHStickTortIsoV_B0'))
    if(fix(4))
        fisos = [fixedvals(4)];
    end
    if(fix(5))
        disos = [fixedvals(5)];
    end

    numCombs = length(fs)*length(dpars)*length(fisos)*length(disos)*length(kappas);
    grid = zeros(5, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
            for k=1:length(fisos)
                for l=1:length(disos)
                    for m=1:length(kappas)
                      pars = [fs(i) dpars(j) kappas(m) fisos(k) disos(l)];
                      grid(:,ind) = pars;
                      ind = ind + 1;
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'WatsonSHStickTortIsoVIsoDot_B0'))
    if(fix(4))
        fisos = [fixedvals(4)];
    end
    if(fix(5))
        disos = [fixedvals(5)];
    end
    if(fix(6))
        irfracs = [fixedvals(6)];
    end

    numCombs = length(fs)*length(dpars)*length(fisos)*length(disos)*length(kappas)*length(irfracs);
    grid = zeros(6, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
            for k=1:length(fisos)
                for l=1:length(disos)
                    for m=1:length(kappas)
                        for n=1:length(irfracs)
                          pars = [fs(i) dpars(j) kappas(m) fisos(k) disos(l) irfracs(n)];
                          grid(:,ind) = pars;
                          ind = ind + 1;
                        end
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'WatsonSHCylSingleRadTortIsoV_GPD') || strcmp(model, 'WatsonSHCylSingleRadTortIsoV_GPD_B0'))
    if(fix(3))
        Rs = [fixedvals(3)];
    end
    if(fix(5))
        fisos = [fixedvals(5)];
    end
    if(fix(6))
        disos = [fixedvals(6)];
    end

    numCombs = length(Rs)*length(fs)*length(dpars)*length(fisos)*length(disos)*length(kappas);
    grid = zeros(6, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                for l=1:length(fisos)
                    for m=1:length(disos)
                      for n=1:length(kappas)
                        pars = [fs(j) dpars(k) Rs(i) kappas(n) fisos(l) disos(m)];
                        grid(:,ind) = pars;
                        ind = ind + 1;
                      end
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'BinghamCylSingleRadTortIsoV_GPD_B0'))
    if(fix(3))
        Rs = [fixedvals(3)];
    end
    if(fix(7))
        fisos = [fixedvals(7)];
    end
    if(fix(8))
        disos = [fixedvals(8)];
    end

    numCombs = length(Rs)*length(fs)*length(dpars)*length(fisos)*length(disos)*length(kappas);
    grid = zeros(8, numCombs);
    ind = 1;
    for i=1:length(Rs)
        for j=1:length(fs)
            for k=1:length(dpars)
                for l=1:length(fisos)
                    for m=1:length(disos)
                        for n=1:length(kappas)
                            pars = [fs(j) dpars(k) Rs(i) kappas(n) 0 0 fisos(l) disos(m)];
                            grid(:,ind) = pars;
                            ind = ind + 1;
                        end
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'BinghamStickTortIsoV_B0'))
    if(fix(6))
        fisos = [fixedvals(6)];
    end
    if(fix(7))
        disos = [fixedvals(7)];
    end

    numCombs = length(fs)*length(dpars)*length(fisos)*length(disos)*length(kappas);
    grid = zeros(7, numCombs);
    ind = 1;
    for i=1:length(fs)
        for j=1:length(dpars)
            for k=1:length(fisos)
                for l=1:length(disos)
                    for m=1:length(kappas)
                        pars = [fs(i) dpars(j) kappas(m) 0 0 fisos(k) disos(l)];
                        grid(:,ind) = pars;
                        ind = ind + 1;
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'ExCrossingCylSingleRadGPD'))
    R1s = Rs;
    R2s = Rs;
    if(fix(4))
        R1s = [fixedvals(4)];
    end

    if(fix(5))
        R2s = [fixedvals(5)];
    end

    numCombs = length(R1s)*length(R2s)*length(fs)*length(dpars)*length(fic);
    grid = zeros(6, numCombs);
    ind = 1;
    for i=1:length(R1s)
        for j=1:length(R2s)
            for k=1:length(fs)
                for l=1:length(dpars)
                    for m=1:length(fic)
                        % Set dperp using the standard tortuosity model for
                        % randomly placed cylinders unless fixed.
                        dperp = dpars(l)*(1-fs(k));
                        if(fix(3))
                            dperp = fixedvals(3);
                        end                        
                        pars = [fs(k) dpars(l) dperp R1s(i) R2s(j) fic(m)];
                        grid(:,ind) = pars;
                        ind = ind + 1;
                    end
                end
            end
        end
    end
elseif(strcmp(model, 'ExCrossingCylSingleRadIsoDotTortIsoV_GPD_B0'))
    R1s = Rs;
    R2s = Rs;
    if(fix(3))
        R1s = [fixedvals(3)];
    end

    if(fix(4))
        R2s = [fixedvals(4)];
    end
    
    if(fix(6))
        irfracs = [fixedvals(6)];
    end
    
    if(fix(7))
        fisos = [fixedvals(7)];
    end
    
    if(fix(8))
        disos = [fixedvals(8)]; 
    end
    
    numCombs = length(R1s)*length(R2s)*length(fs)*length(dpars)*length(fic)*length(irfracs)*length(fisos)*length(disos);
    grid = zeros(8, numCombs);
    ind = 1;
    for i=1:length(R1s)
        for j=1:length(R2s)
            for k=1:length(fs)
                for l=1:length(dpars)
                    for m=1:length(fic)
								 for n=1:length(irfracs)
										for p=1:length(fisos)
											 for q=1:length(disos)
						  				  		  pars = [fs(k) dpars(l) R1s(i) R2s(j) fic(m) irfracs(n) fisos(p) disos(q)];
						  				  		  grid(:,ind) = pars;
						  				  		  ind = ind + 1;
									 		 end
										end
								 end
                    end
                end
            end
        end
    end
else
    error(['Starting combinations not implemented for model: ', model]);
end

