function [signal_end,phase_corr_freq] = pilot_phase_corr(signal,h, signal_tx, pilot_position,mode, cfg)


if strcmp(mode, 'time_est')
       if size(h,1) == 1
       else
           h = h.';
       end
       H=fft(h,cfg.N_sub).';
else
    H = h;
end

offset = pilot_position;
pilot_sequence = offset*cfg.N_sub+1 : offset*cfg.N_sub+cfg.N_sub;
pilot_rx = signal(pilot_sequence);
pilot_tx = signal_tx(pilot_sequence);

if size(pilot_tx,1) == 1
    pilot_tx = pilot_tx.';
end

if size(pilot_rx,1) == 1
    pilot_rx = pilot_rx.';
end

auto_corr = sum(conj(pilot_rx).*(H.*pilot_tx));
phase_corr = -angle(auto_corr);

T = (cfg.N_CP + cfg.N_sub)/cfg.BW;
phase_corr_freq = phase_corr/(2*pi*offset*T);

%disp(['Phase correction for pilot - OFDM symbol n° : ',num2str(offset),' is : ', num2str(phase_corr),' rad']);
disp(['Phase correction for pilot - OFDM symbol n° : ',num2str(offset),' is : ', num2str(phase_corr_freq),' Hz']);

signal_end = signal.*exp(-1j*phase_corr);
end