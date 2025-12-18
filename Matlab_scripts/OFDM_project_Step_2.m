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
        @(x,EbN0) awgn_add(x,EbN0,cfg),...
        @(x,h) fft_process(x,h,cfg),...
        @(preamble_tr,preamble_rx) channel_estimation(preamble_tr,preamble_rx,cfg),...
        @(x,h,mode) equalize_chan(x,h,mode,cfg),...
        @(x) unmapping_2(x,cfg),...
  };

%% STEP 1 - Transmitter


% Generated bits for 32 OFDM symbols on 2048 sub-carriers
signal{1} = randi([0 1], cfg.Nbit, 1);
signal{2} = blocks{1}(signal{1});
signal{3} = blocks{2}(signal{1});
signal{4} = [signal{2};signal{3}];
signal{5} = blocks{3}(signal{4});

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
signal{6} = blocks{5}(signal{5},channel);

% Channel estimate mode
channel_mode = 'time_est';

% Receiver

BER_h_temp = zeros(size(cfg.SNR));
BER_h_freq = zeros(size(cfg.SNR));
NMSE_time = zeros(size(cfg.SNR));
NMSE_freq = zeros(size(cfg.SNR));
size_pream = log2(cfg.Mod)*cfg.N_pream*cfg.N_sub;

for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{7} = blocks{6}(signal{6},EbN0);                  % Additive noise
    signal{8} = blocks{7}(signal{7},channel);               % FFT
    [h_temp,h_freq] = blocks{8}(signal{2},signal{8});       % channel estimation - preamble
    signal{9} = blocks{9}(signal{8},h_temp,channel_mode);                % Equalizer - Zero Forcing - Channel temporal est.
    signal{10} = blocks{10}(signal{9});                     % Demapping
    
    BER_h_temp(i) = mean(signal{1}(size_pream+1:end)~=signal{end});
    % Normalized MSE calculation - Time impulse comparison
    channel_MSE = [channel';zeros(cfg.N_sub-length(channel),1)]; % Pad the channel with zeros to fit Subcarriers elements
    NMSE_time(i) = sum(abs(h_temp-channel_MSE).^2)/sum(abs(channel_MSE).^2);
    MSE_time(i) = sum(abs(h_temp-channel_MSE).^2);

end

% Channel estimate mode
channel_mode = 'freq_est';

for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{7} = blocks{6}(signal{6},EbN0);                  % Additive noise
    signal{8} = blocks{7}(signal{7},channel);               % FFT
    [h_temp,h_freq] = blocks{8}(signal{2},signal{8});       % channel estimation - preamble
    signal{9} = blocks{9}(signal{8},h_freq,channel_mode);                % Equalizer - Zero Forcing - Channel temporal est.
    signal{10} = blocks{10}(signal{9});                     % Demapping
    
    BER_h_freq(i) = mean(signal{1}(size_pream+1:end)~=signal{end});
    % Normalized MSE calculation - Time impulse comparison
    H_true = fft(channel',cfg.N_sub);
    NMSE_freq(i) = sum(abs(h_freq-H_true).^2)/sum(abs(H_true).^2);
    MSE_freq(i) = sum(abs(h_freq-H_true).^2);

end

% Channel estimate mode
channel_mode = 'time_est';

for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{7} = blocks{6}(signal{6},EbN0);                  % Additive noise
    signal{8} = blocks{7}(signal{7},channel);               % FFT
    [h_temp,h_freq] = blocks{8}(signal{2},signal{8});       % channel estimation - preamble
    signal{9} = blocks{9}(signal{8},channel,channel_mode);  % Equalizer - Zero Forcing - Channel temporal est.
    signal{10} = blocks{10}(signal{9});                     % Demapping
    
    BER_true(i) = mean(signal{1}(size_pream+1:end)~=signal{end});

end


%% PLOT

% l=200;
% figure;
% stairs((1:l),signal{1}(1:l),'r--');
% hold on
% stairs((1:l),signal{8}(1:l),'b');
% ylim([-0.5 1.5]);
% title('Start-End Signals comparison');
% 
figure;
subplot(1,2,1)
semilogy(cfg.SNR,BER_h_freq,'bo-', 'LineWidth', 1.5);
hold on
semilogy(cfg.SNR,BER_h_temp,'rx-', 'LineWidth', 1.5);
semilogy(cfg.SNR,BER_true,'m*-', 'LineWidth', 1.5);
grid on
xlabel('SNR (dB)');
ylabel('BER');
xlim([cfg.SNR(1) cfg.SNR(end)]);
legend('Estimated Channel in Freq', 'Estimated Channel in Temp');
title('Bit Error Rate evolution')


subplot(1,2,2)
plot(cfg.SNR,NMSE_freq,'bo-', 'LineWidth', 1.5);
hold on
plot(cfg.SNR,NMSE_time,'rx-', 'LineWidth', 1.5);
grid on
xlabel('SNR (dB)');
ylabel('NMSE (%)');
xlim([cfg.SNR(1) cfg.SNR(end)]);
legend('Estimated Channel in Freq', 'Estimated Channel in Temp');
title('Normalized MSE - Channel estimation')


figure;
semilogy(cfg.SNR,MSE_freq,'bo-', 'LineWidth', 1.5);
hold on
semilogy(cfg.SNR,MSE_time,'rx-', 'LineWidth', 1.5);
grid on
xlabel('SNR (dB)');
ylabel('MSE (dB)');
xlim([cfg.SNR(1) cfg.SNR(end)]);
legend('Estimated Channel in Freq', 'Estimated Channel in Temp');
title('Normalized MSE - Channel estimation')