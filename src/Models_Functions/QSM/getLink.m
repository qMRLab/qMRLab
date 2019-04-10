function  link = getLink(modelName)
  
  TRAVIS = 0; 
  if ~isempty(getenv('ISTRAVIS')) && str2double(getenv('ISTRAVIS'))...
     && isempty(getenv('ISDOC')); TRAVIS = 1; end 

  switch modelName
    
  case 'qsm_sb'  
  
    if TRAVIS
      link = 'https://osf.io/549ke/download?version=4'; % Partial dataset
    else
      link  = 'https://osf.io/9d8kz/download?version=1'; % Full dataset
    end
  
  case 'charmed'  

    if TRAVIS
      link = 'https://osf.io/bdxa6/download?version=1'; % Octave output
    else
      link  = 'https://osf.io/u8n56/download?version=3'; % Matlab output
    end

  case 'qmt_bssfp'
    
    if TRAVIS
      link = 'https://osf.io/28nhj/download?version=1'; % Octave output
    else
      link  = 'https://osf.io/r64tk/download?version=2'; % Matlab output
    end    

  case 'qmt_sirfse'
    
    if TRAVIS
      link = 'https://osf.io/v2k7q/download?version=1'; % Octave output
    else
      link  = 'https://osf.io/fk2nd/download?version=2'; % Matlab output
    end    

  end

end
