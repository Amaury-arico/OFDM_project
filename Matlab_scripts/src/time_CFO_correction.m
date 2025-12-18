function [signal_end] = time_CFO_correction(signal,time_corr, CFO_corr,channel,cfg)

    t = (0:length(signal)-1)'./cfg.BW;
    signal_CFO = signal.*exp(-1j*2*pi()*CFO_corr.*t);
    
    L = length(channel)-1;

    total_needed = cfg.block * (cfg.N_sub + cfg.N_CP) + L;

    time_corr = time_corr - 5;          % Margin

    if time_corr < 0
        time_corr = 0;
    end
    
    start_idx = 1 + time_corr;         % first valid sample
    end_idx   = start_idx + total_needed - 1;
    
    % If the signal is too short, pad zeros
    if length(signal_CFO) < end_idx
        signal_CFO = [signal_CFO; zeros(end_idx - length(signal_CFO), 1)];
    end
    
    % Extract synchronized portion
    signal_end = signal_CFO(start_idx:end_idx);

    %signal_end = signal(1:total_needed);
end