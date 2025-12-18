function [signal_end] = unmapping(signal,cfg)

    signal_dem = signal(:);
    signal_end = qamdemod(signal_dem,cfg.Mod,'OutputType', 'bit','UnitAveragePower', true);
end