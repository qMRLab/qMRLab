function  link = getLink_mp2rage

  if ~isempty(getenv('ISTRAVIS')) && str2double(getenv('ISTRAVIS'))
    link = 'https://osf.io/k3shf/download?version=1';
  else
    link  = 'https://osf.io/8x2c9/download?version=4';
  end

end
