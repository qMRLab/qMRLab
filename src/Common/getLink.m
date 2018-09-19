function  link = getLink(mfilename)
  switch mfilename
  case 'qsm_sb'
    if ~isempty(getenv('ISTRAVIS')) && str2double(getenv('ISTRAVIS'))
      link = 'https://osf.io/549ke/download/';
    else
      link  = 'newlink';
    end
  end
