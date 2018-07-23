function tryfunc(fun, varargin)
try 
    fun(varargin{:});
catch err
    qMR_reportBug(err)
end