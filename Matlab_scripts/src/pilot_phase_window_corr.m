function [signal_end,freq_corr,phase_average] = pilot_phase_window_corr(signal,h, signal_tx, pilot_position, window, mode, cfg)


    if strcmp(mode, 'time_est')
           if size(h,1) == 1
           else
               h = h.';
           end
           H=fft(h,cfg.N_sub).';
    else
        H = h;
    end
    
    phase_corr_freq = zeros(cfg.block,1);
    phase_corr = zeros(cfg.block,1);
    H = H(pilot_position(1):pilot_position(2),1);

    for i = 1: cfg.block-1
        pilot_sequence = pilot_position(1)+i*cfg.N_sub : pilot_position(2)+i*cfg.N_sub;
        pilot_rx = signal(pilot_sequence);
        pilot_tx = signal_tx(pilot_sequence);
    
        if size(pilot_tx,1) == 1
            pilot_tx = pilot_tx.';
        end
        
        if size(pilot_rx,1) == 1
            pilot_rx = pilot_rx.';
        end
    
        auto_corr = sum(conj(pilot_rx).*(H.*pilot_tx));
        phase_corr(i) = -angle(auto_corr);
    
    end

    N = length(phase_corr_freq);
    half_step = floor(window/2);
    phase_corr_wind = zeros(N,1);
    phase_norm = zeros(N,1);
    freq_corr = zeros(N,1);

    for i = 1:N
        index_low = max(1,i-half_step);
        index_high = min(N,i+half_step);
        phase_corr_wind(i)=mean(phase_corr(index_low:index_high));
        phase_norm(i) = phase_corr_wind(i)/(i+2);
    end

    T = (cfg.N_CP + cfg.N_sub)/cfg.BW;
    freq_corr = phase_corr_wind./(2*pi*T);
    phase_average = mean(phase_norm)/(2*pi*T);

    for i = 1:N
        signal_end(:,i) = signal(:,i).*exp(-1j*phase_corr_wind(i));
    end
end