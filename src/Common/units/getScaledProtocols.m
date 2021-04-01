function [prot,OriginalProtEnabledOut] = getScaledProtocols(Model,direction,OriginalProtEnabled)
           % Beginning from v2.5.0 users can specify in which units they'd
           % like to pass protocol parameters. To ensure that the users are
           % interfacing with the parameters of the units they set, and
           % models receive parameters in the scale they require, we need
           % to scale them back and forth. This static method is
           % responsible for that. Prot sub-properties have two fields:
           %
           %    - .Format
           %       The name of the respective protocol parameter. For
           %       example, TI. When userUnitScaling is activated, these
           %       values attain the respective unit, if available. For 
           %       example, TI(s) or TI(ms) depending on the selection.
           %       User-modified Format tags are left unchanged throughout
           %       the session. To access the fields regardless of the unit
           %       specification, 'inOriginalUnits' drops the parantheses
           %       to get the respective value. 
           %    - .Mat
           %       The  value of the respective protocol parameter.
           %       Dynamically set to user-defined or original values during
           %       the Modelect construction or elsewhere, respectively.
           %
           % This function is wrapped by:
           %    -  setUserProtUnits
           %    -  setOriginalProtUnits
           % to provide easier function calls in the classdefs.
           %
           % Not a non-static member function to avoid endless recursion
           %      - This function is called during construction. 
           
            prot =  Model.Prot;
            if ~isempty(fieldnames(prot))
            
            try
                % See if it can fatch GUI data. If not, read 
                % from json
                reg = modelRegistry('get',Model.ModelName,'registryStruct',getappdata(0,'registryStruct'),...
                'unitDefsStruct',getappdata(0,'unitDefsStruct'), ...
                'usrPrefsStruct',getappdata(0,'usrPrefsStruct'));
            catch
                
                reg = modelRegistry('get',Model.ModelName);
                
            end

            protUnitMaps = reg.UnitBIDSMappings.Protocol;
        
            % This is the same with the fieldnames of protUnitMaps 
            protNames = fieldnames(Model.Prot);

            for ii=1:length(protNames)
                % Format fields in classnames omit unit from v2.5.0 onward
                % A format field is not necessarily 1x1, so we need to iterate over it
                curFormat = Model.Prot.(protNames{ii}).Format;
                % This is not cell in all the models, so ensure that 
                % it is casted to cell when it is initially not.
                if ~iscell(curFormat)
                    curFormat = cellstr(curFormat);
                    prot.(protNames{ii}).Format = curFormat;
                end
                % Format may include more than one fields
                for jj = 1:length(curFormat)

                switch direction
                % Whereas these values should change back and forth
                % depending on whether they are displayed in qMRLab GUI
                % during object construction, or whether they are about to
                % be fed into fitting/simulations. In the latter case, the
                % object must ensure that the original parameters are
                % passed. This is explicitly declared wherever applicable.
                case 'inUserUnits'
                    % Scale protocol parameters according to the user configs
                    % Only perform if the previous state is original.
                    if OriginalProtEnabled
                        
                        curFormat(jj) = getBareProtUnit(curFormat{jj},'fieldname');
                        prot.(protNames{ii}).Format(jj) = {[curFormat{jj} protUnitMaps.(protNames{ii}).(curFormat{jj}).Symbol]};
                        try
                            prot.(protNames{ii}).Mat(:,jj) = prot.(protNames{ii}).Mat(:,jj)./protUnitMaps.(protNames{ii}).(curFormat{jj}).ScaleFactor;
                        catch
                            if isvector(prot.(protNames{ii}).Mat)
                                prot.(protNames{ii}).Mat(jj) = prot.(protNames{ii}).Mat(jj)./protUnitMaps.(protNames{ii}).(curFormat{jj}).ScaleFactor;
                            else
                                prot.(protNames{ii}).Mat(jj,:) = prot.(protNames{ii}).Mat(jj,:)./protUnitMaps.(protNames{ii}).(curFormat{jj}).ScaleFactor;
                            end
                        end
                        % Negate to signal that original prot units are no
                        % longer enabled
                        OriginalProtEnabledOut = false;
                    else
                        % If there is a request to get Prot in user defined
                        % units, but the state indicates that it is already
                        % in the user units, then we'll do this assignment
                        % here. As we are circulating the same variable,
                        % this assignment is required (despite that it looks trivial). 
                        % Otherwise an exeption is thrown.
                        OriginalProtEnabledOut = false;
                    end
                    
                case 'inOriginalUnits'
                    % Scale protocol parameters back to the original units (for fitting etc)
                    if ~OriginalProtEnabled
                        prot.(protNames{ii}).Format(jj) = curFormat(jj);
                        % When user parameters are selected units are
                        % iserted in the Format Name. Here, we need to drop
                        % them to be able to access the original fields.
                        curFormat(jj) = getBareProtUnit(curFormat{jj},'fieldname');
                        try
                            prot.(protNames{ii}).Mat(:,jj) = prot.(protNames{ii}).Mat(:,jj).*protUnitMaps.(protNames{ii}).(curFormat{jj}).ScaleFactor;
                        catch
                            if isvector(prot.(protNames{ii}).Mat)
                                prot.(protNames{ii}).Mat(jj) = prot.(protNames{ii}).Mat(jj).*protUnitMaps.(protNames{ii}).(curFormat{jj}).ScaleFactor;
                            else
                                prot.(protNames{ii}).Mat(jj,:) = prot.(protNames{ii}).Mat(jj,:).*protUnitMaps.(protNames{ii}).(curFormat{jj}).ScaleFactor;
                            end
                        end
                        OriginalProtEnabledOut = true;
                    else
                        % If there is a request to get Prot in orig defined
                        % units, but the state indicates that it is already
                        % in the orig units, then we'll do this assignment
                        % here. As we are circulating the same variable,
                        % this assignment is required (despite that it looks trivial within the statement). 
                        % Otherwise an exeption is thrown.
                        OriginalProtEnabledOut = true;
                    end

                end
                end
            end
            
            else
                
                % Hits here when the model prot is empty 
                % such as mt_ratio, where this parameter 
                % is not important, yet still need to assign
                % as it is an output arg.
                OriginalProtEnabledOut = 1;
            
            end
        
end