function [signal_end] = fft_process(signal,channel,cfg)

    % Remove CP
    L = length(channel)-1;
    %matrix_signal = reshape(signal(1:end-(L)),cfg.N_CP+cfg.N_sub,[]);
    matrix_signal = reshape(signal(1:end-L),cfg.N_CP+cfg.N_sub,[]);
    no_cp_signal = matrix_signal(cfg.N_CP+1:end,:);
    signal_end = fft(no_cp_signal,cfg.N_sub);
end