function  link = getLink_t2

  if ~isempty(getenv('ISTRAVIS')) && str2double(getenv('ISTRAVIS'))
    link = 'https://osf.io/ns3wx/download?version=1';
  else
    link  = 'https://osf.io/kujp3/download?version=1';
  end

end
