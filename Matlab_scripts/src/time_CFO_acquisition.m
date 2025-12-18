function [time_corr,CFO_corr] = time_CFO_acquisition(signal,cfg)
    

    window = cfg.N_sub + cfg.N_CP;

    % Nbre of iteration for the window shift - shift over all the symbols
    len_loop = length(signal)-(2*window);

    auto_corr = zeros(len_loop,1);
    norm = zeros(len_loop,1);

    % Finding max correlation with window shift
    for i=0:len_loop-1
        pre_rx_1 = signal(window+1+i:2*window+i);
        pre_rx_2 = signal(1+i:window+i);
        auto_corr(i+1) = sum(conj(pre_rx_1).*(pre_rx_2));
        norm(i+1) = sum(abs(signal(1+i:2*window+i)).^2);
    end
    [~, index_max] = max(abs(auto_corr)./norm); 
    time_corr = index_max-1;

    R = auto_corr(index_max);

    %CFO_corr = atan(imag(R)/real(R))/(window*/cfg.symbolrate);
    CFO_corr = -angle(R)/((cfg.N_sub + cfg.N_CP)/cfg.BW);
    CFO_corr = CFO_corr/(2*pi());
end