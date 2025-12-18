%% OFDM PROJECT - ELECH522

% Amaury Arico
% Bruface ULB-VUB
% MA2 IRELE - TELECOM
% 20251113

clear;
close all;
cfg = config_OFDM();


%% BLOCK

 blocks = { ...
        @(x) preamble_gen(x,cfg),...
        @(x) mapping_2(x,cfg), ...
        @(x) ifft_process(x, cfg), ...
        @(h,delay) channel_def(h,delay,cfg), ...
        @(x,h) channel_conv(x,h),...
        @(x,shift,CFO,error_mode) time_shift(x,shift,CFO,error_mode,cfg),...
        @(x,EbN0) awgn_add(x,EbN0,cfg),...
        @(x) time_CFO_acquisition(x,cfg),...
        @(x,time_corr, CFO_corr,channel) time_CFO_correction(x,time_corr, CFO_corr,channel,cfg),...
        @(x,h) fft_process(x,h,cfg),...
        @(preamble_tr,preamble_rx) channel_estimation(preamble_tr,preamble_rx,cfg),...
        @(x,h,mode) equalize_chan(x,h,mode,cfg),...
        @(x) unmapping_2(x,cfg),...
  };

%% STEP 1 - Transmitter

% ****Error 1 : No error    Error 2 : Time shift    Error 3 : CFO shift     Error 4 : CFO and Time shift***** 
error_mode = 2;             
shift = 40;                  % Time shift for symbols
CFO = 1e-6;               % 1e-6, 1000e-6
time_corr = 0;              % No time correction yet
Nframes = 50;

BER_time_error = zeros(size(cfg.SNR));
BER_no_error = zeros(size(cfg.SNR));
MSE_STO = zeros(size(cfg.SNR));
size_pream = log2(cfg.Mod)*cfg.N_pream*cfg.N_sub;

for z=1:size(cfg.SNR,2)
    errors = zeros(Nframes,1);
    for k = 1:Nframes

        % Generated bits for 32 OFDM symbols on 2048 sub-carriers
        signal{1} = randi([0 1], cfg.Nbit, 1);
        
        % Make 2 symbols of preamble identical ! - same bits for preamble
        signal{1} = [signal{1}(1:cfg.N_sub*log2(cfg.Mod));signal{1}(1:cfg.N_sub*log2(cfg.Mod));signal{1}(2*cfg.N_sub*log2(cfg.Mod)+1:end)];
        
        signal{2} = blocks{1}(signal{1});   % Preamble modulation
        signal{3} = blocks{2}(signal{1});   % QAM modulation
        signal{4} = [signal{2};signal{3}];  % Fusion preamble - data
        signal{5} = blocks{3}(signal{4});   % IFFT
        
        delay = 0;
        
        % INPUT CHANNEL
        h(1)=1; %init channel
        
        if cfg.pathnb > 1
            for i = 2:cfg.pathnb
                %cfg.phase = unifrnd(-pi, pi);
                %cfg.ampl = rand(1);
                h(i)=cfg.ampl*exp(1j*cfg.phase);
                delay(i) = i*10;
            end
        end
        
        % Channel and Noise
        channel = blocks{4}(h,delay);
        signal{6} = blocks{5}(signal{5},channel);       % Channel convolution
        
        % Channel estimate mode - 'time_est' - 'freq_est'
        channel_mode = 'freq_est';
        
        % Receiver
    
        EbN0 = cfg.SNR(z);
        signal{7} = blocks{6}(signal{6},shift,CFO,error_mode);          % Time shift
        signal{8} = blocks{7}(signal{7},EbN0);                          % Additive noise
        [time_corr, CFO_corr] = blocks{8}(signal{8});                   % Time shift and CFO shift finding
        disp(['SNR = ', num2str(EbN0)]);
        disp(['True STO = ', num2str(shift), ' | Estimated STO = ', num2str(time_corr)]);
        signal{9} = blocks{9}(signal{8},time_corr,CFO_corr,channel);    % Time correction
        signal{10} = blocks{10}(signal{9},channel);                     % FFT
        [h_temp,h_freq] = blocks{11}(signal{2},signal{10});             % channel estimation - preamble
        signal{11} = blocks{12}(signal{10},h_freq,channel_mode);        % Equalizer - Zero Forcing - Channel temporal est.
        signal{12} = blocks{13}(signal{11});                            % Demapping
        
        errors(k) = (time_corr - shift)^2;
    end
    MSE_STO(z) = mean(errors);
end

%% PLOT


figure;
semilogy(cfg.SNR,MSE_STO,'bo-', 'LineWidth', 1.5);
grid on
xlabel('SNR (dB)');
ylabel('MSE (dB)');
xlim([cfg.SNR(1) cfg.SNR(end)]);
title('MSE - STO estimation')
