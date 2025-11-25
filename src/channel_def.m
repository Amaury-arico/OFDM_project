function [h_channel] = channel_def(cfg,h,delay)
    
    % Delay addition
    h_channel = zeros(1, delay(end)+1);
    h_channel(delay+1) = h;

end