function [signal_end] = ifft_process(signal,cfg)
   
    % Reshape stream of bits to parallel matrix for frequency domain signal
    % shape

    freq_signal = reshape(signal, cfg.N_sub,[]);
    time_signal = ifft(freq_signal, cfg.N_sub);

    % Add cyclic prefix
    full_signal = [time_signal(end-cfg.N_CP+1:end,:);time_signal];

    signal_end = full_signal(:);
    
end