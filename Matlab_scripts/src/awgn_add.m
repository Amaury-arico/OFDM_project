function [signal_end] = awgn_add(signal,EbN0,cfg)

    power_baseband = mean(abs(signal).^2);
    power_passband = power_baseband/2;
    
    Energy_symbol = power_passband/cfg.symbolrate;
    Energy_bit = Energy_symbol / log2(cfg.Mod);

    No = Energy_bit/(10^(EbN0/10));

    noise_im = sqrt(No*cfg.symbolrate).*randn(size(signal,1),1);
    noise_real = sqrt(No*cfg.symbolrate).*randn(size(signal,1),1);

    noise = noise_real+1j*noise_im;

    signal_end = signal + noise;
    %signal_end = signal;

end