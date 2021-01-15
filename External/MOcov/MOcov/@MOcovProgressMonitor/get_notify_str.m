function s=get_notify_str(obj,varargin)
    n=numel(varargin);

    verbosity=obj.verbosity;
    idx=min(n, verbosity);

    if idx==0
        s='';
        return
    end

    msg=varargin{idx};
    if numel(msg)==1 && obj.char_counter<obj.max_chars
        obj.char_counter=obj.char_counter+1;
        pat='%s';
    else
        obj.char_counter=0;
        pat='%s\n';
    end

    s=sprintf(pat, msg);

