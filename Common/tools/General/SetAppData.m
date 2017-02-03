function SetAppData(varargin)
for k=1:nargin; setappdata(0, inputname(k), varargin{k}); end