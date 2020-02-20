classdef progressBar < handle
% author : Alessandro Daducci 

properties
    width
    back, msg
    i, N
end


methods

    % ===========================
    % Initialize the progress bar
    % ===========================
	function obj = progressBar( N )
        obj.width = 25;
        obj.i     = 1;
        obj.N     = N;
        % display empty bar
        obj.msg = [ '   [' repmat(' ',1,obj.width) '] ' ];
        fprintf([obj.back, obj.msg]);
        obj.back = repmat('\b',1,length(obj.msg));
    end


    % ==========================================================
    % Update the counter by 1 and print the updated progress bar
    % ==========================================================
    function obj = update( obj )
        if ( obj.i < 1 || obj.i > obj.N )
            return
        end
        
        if ( mod( obj.i, obj.width ) == 0 || obj.i==obj.N )
            p = floor(obj.i/obj.N*obj.width);
            obj.msg = [ '   [' repmat('=',1,p) repmat(' ',1,obj.width-p) '] ' ];
            fprintf([obj.back, obj.msg]);
            obj.back = repmat('\b',1,length(obj.msg));
        end
        obj.i = obj.i + 1;
    end

    % ======================
    % Close the progress bar
    % ======================
    function close( obj )
        fprintf('\n');
        obj.i    = 0;
        obj.N    = 0;
        obj.msg  = '';
        obj.back = '';
    end

end

end

