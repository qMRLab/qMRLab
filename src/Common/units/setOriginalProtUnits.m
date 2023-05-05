function Model = setOriginalProtUnits(Model)
   % Wrapper for getScaledProtocols static function to ensure that 
   % the Model.Prot has the original units. 
   %
   % Not a non-static member function to avoid endless recursion
   %      - This function is called during construction. 
  if ~Model.OriginalProtEnabled
   [Model.Prot,Model.OriginalProtEnabled] = getScaledProtocols(Model,'inOriginalUnits',Model.OriginalProtEnabled);
  else
      Model.OriginalProtEnabled = true;
  end

end