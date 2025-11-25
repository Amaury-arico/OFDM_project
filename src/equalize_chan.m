function [signal_end] = equalize_chan(signal,h,cfg)
    
   H=fft(h,cfg.N_sub).';
   signal_end = signal./H;
    
end