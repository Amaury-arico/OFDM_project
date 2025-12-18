function [signal_end] = equalize_chan(signal,h,mode,cfg)

   if strcmp(mode, 'time_est')
       if size(h,1) == 1
       else
           h = h.';
       end
       H=fft(h,cfg.N_sub).';
       signal_end = signal./H;
   else
       signal_end = signal./h;
   end
    
end