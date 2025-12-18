function [signal_end] = time_shift(signal, shift, CFO, error_mode, cfg)
        
        % No error introduction
        if error_mode == 1
            signal_end = signal;

        % Time shift introduction
        elseif error_mode == 2
            signal_end = [zeros(shift,1);signal];

        % CFO introduction
        elseif error_mode == 3
            t = (0:length(signal)-1)'./cfg.BW;
            signal_end = signal.*exp(1j*2*pi()*CFO*cfg.F_carrier.*t);
        
        % CFO and Time shift introduction
        elseif error_mode == 4
            signal_time = [zeros(shift,1);signal];
            t = (0:length(signal_time)-1)'./cfg.BW;
            signal_end = signal_time.*exp(1j*2*pi()*CFO*cfg.F_carrier.*t);
        end
end