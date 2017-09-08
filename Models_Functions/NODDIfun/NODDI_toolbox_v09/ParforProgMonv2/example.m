% ParforProgMon - M object to make ParforProgressMonitor objects easier to
% use. Create one of these on the client outside your PARFOR loop with a
% name for the window. Pass it in to the PARFOR loop, and have the workers
% call "increment" at the end of each iteration. This sends notification
% back to the client which then updates the UI.

% ParforProgMon Build a Parfor Progress Monitor
% Use the syntax: ParforProgMon( 'Window Title', N, progressStepSize, width, height )
% where N is the number of iterations in the PARFOR loop
% progressStepSize indicates after how many iterations progress is shown
% width indicates the width of the progress window
% height indicates the width of the progress window

tic
N = 500000;
progressStepSize = 100;
ppm = ParforProgMon('Example: ', N, progressStepSize, 300, 80);

parfor ii=1:N
    rand(100,100);
    if mod(ii,progressStepSize)==0
        ppm.increment();
    end
end

ppm.delete()
toc