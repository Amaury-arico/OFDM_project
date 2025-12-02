function [signal_end] = unmapping_2(signal,cfg)

    signal_dem = signal(:);
    signal_dem = signal_dem(2*cfg.N_sub+1:end);

    signal_end = qamdemod(signal_dem,cfg.Mod,'OutputType', 'bit','UnitAveragePower', true);
end