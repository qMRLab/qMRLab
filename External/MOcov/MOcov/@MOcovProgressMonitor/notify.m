function notify(obj, varargin)
    s=get_notify_str(obj,varargin{:});
    fprintf('%s',s);