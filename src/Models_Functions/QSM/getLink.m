function  link = getLink

  if ~isempty(getenv('ISTRAVIS')) && str2double(getenv('ISTRAVIS'))
    link = 'https://osf.io/549ke/download?version=4';
  else
    link  = 'https://osf.io/9d8kz/download?version=1';
  end

end
