% Copyright 2009 The MathWorks, Inc.

classdef ParforProgMon < handle

    properties ( GetAccess = private, SetAccess = private )
        Port
        HostName
    end
    
    properties (Transient, GetAccess = private, SetAccess = private)
        JavaBit
    end
    
    methods ( Static )
        function o = loadobj( X )
        % Once we've been loaded, we need to reconstruct ourselves correctly as a
        % worker-side object.
            o = ParforProgMon( {X.HostName, X.Port} );
        end
    end
    
    methods
        function o = ParforProgMon( s, N, progressStepSize, width, height )
        % ParforProgMon Build a Parfor Progress Monitor
        % Use the syntax: ParforProgMon( 'Window Title', N, progressStepSize, width, height )
        % where N is the number of iterations in the PARFOR loop
        % progressStepSize indicates after how many iterations progress is shown
        % width indicates the width of the progress window
        % height indicates the width of the progress window
        
            if nargin == 1 && iscell( s )
                % "Private" constructor used on the workers
                o.JavaBit   = ParforProgressMonitor.createWorker( s{1}, s{2} );
                o.Port      = [];
            elseif nargin == 5
                % Normal construction
                o.JavaBit   = ParforProgressMonitor.createServer( s, N, progressStepSize, width, height );
                o.Port      = double( o.JavaBit.getPort() );
                % Get the client host name from pctconfig
                cfg         = pctconfig;
                o.HostName  = cfg.hostname;
            else
                error( 'Public constructor is: ParforProgressMonitor( ''Text'', N, progressStepSize, width, height )' );
            end
        end
        
        function X = saveobj( o )
        % Only keep the Port and HostName
            X.Port     = o.Port;
            X.HostName = o.HostName;
        end
        
        function increment( o )
        % Update the UI
            o.JavaBit.increment();
        end
        
        function delete( o )
        % Close the UI
            o.JavaBit.done();
        end
    end
end
