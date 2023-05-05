function Model = setUserProtUnits(Model)
   % Wrapper for getScaledProtocols static function to ensure that 
   % the Model.Prot has the user-defined units.
   %
   % Not a non-static member function to avoid endless recursion
   %      - This function is called during construction. 
  if Model.OriginalProtEnabled
   [Model.Prot,Model.OriginalProtEnabled] = getScaledProtocols(Model,'inUserUnits',Model.OriginalProtEnabled);
  else
     Model.OriginalProtEnabled = false;
  end
end