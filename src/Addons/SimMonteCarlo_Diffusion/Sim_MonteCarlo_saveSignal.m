function Sim_MonteCarlo_saveSignal(signal,signal_intra,signal_extra)
fname = uiputfile('*.mat');
if fname
    signal = permute(signal,[1 3 4 2]);
    signal_intra = permute(signal_intra,[2 3 4 1]);
    signal_extra = permute(signal_extra,[2 3 4 1]);

    save(fname,'signal','signal_intra','signal_extra')
end
