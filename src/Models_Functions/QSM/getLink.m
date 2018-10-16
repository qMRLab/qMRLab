function  link = getLink

  if ~isempty(getenv('ISTRAVIS')) && str2double(getenv('ISTRAVIS'))
    link = 'https://osf.io/549ke/download/';
  else
    link  = 'https://osf.io/9d8kz/download/';
  end

end
