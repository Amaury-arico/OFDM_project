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
        @(x,cfg) preamble_gen(x,cfg),...
        @(x,cfg) mapping_2(x,cfg), ...
        @(x,cfg) ifft_process(x, cfg), ...
        @(h,delay,cfg) channel_def(h,delay,cfg), ...
        @(x,h) channel_conv(x,h),...
        @(x,shift,CFO,error_mode,cfg) time_shift(x,shift,CFO,error_mode,cfg),...
        @(x,EbN0,cfg) awgn_add(x,EbN0,cfg),...
        @(x,cfg) time_CFO_acquisition(x,cfg),...
        @(x,time_corr, CFO_corr,channel,cfg) time_CFO_correction(x,time_corr, CFO_corr,channel,cfg),...
        @(x,h,cfg) fft_process(x,h,cfg),...
        @(preamble_tr,preamble_rx,cfg) channel_estimation(preamble_tr,preamble_rx,cfg),...
        @(x,h,mode,cfg) equalize_chan(x,h,mode,cfg),...
        @(x,cfg) unmapping_2(x,cfg),...
  };

%% STEP 1 - Transmitter

% ****Error 1 : No error    Error 2 : Time shift    Error 3 : CFO shift     Error 4 : CFO and Time shift***** 
error_mode = 3;             
shift = 0;                  % Time shift for symbols
CFO = 4e-8;                 % 1e-6, 1000e-6
time_corr = 0;              % No time correction yet

% Channel estimate mode
channel_mode = 'time_est';

% Receiver

BER_2048 = zeros(size(cfg.SNR));
BER_1024 = zeros(size(cfg.SNR));
BER_512 = zeros(size(cfg.SNR));

cfg.N_sub = 2048;
%cfg.N_CP = round((256/2048)*cfg.N_sub);
cfg.Nbit = cfg.block * cfg.N_sub * log2(cfg.Mod);
size_pream = log2(cfg.Mod)*cfg.N_pream*cfg.N_sub;

% Generated bits for 32 OFDM symbols on 2048 sub-carriers
signal{1} = randi([0 1], cfg.Nbit, 1);

% Make 2 symbols of preamble identical ! - same bits for preamble
signal{1} = [signal{1}(1:cfg.N_sub*log2(cfg.Mod));signal{1}(1:cfg.N_sub*log2(cfg.Mod));signal{1}(2*cfg.N_sub*log2(cfg.Mod)+1:end)];

signal{2} = blocks{1}(signal{1},cfg);   % Preamble modulation
signal{3} = blocks{2}(signal{1},cfg);   % QAM modulation
signal{4} = [signal{2};signal{3}];  % Fusion preamble - data
signal{5} = blocks{3}(signal{4},cfg);   % IFFT

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
channel = blocks{4}(h,delay,cfg);
signal{6} = blocks{5}(signal{5},channel);       % Channel convolution


for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{7} = blocks{6}(signal{6},shift,CFO,error_mode,cfg);          % Time shift
    signal{8} = blocks{7}(signal{7},EbN0,cfg);                          % Additive noise
    [time_corr, CFO_corr] = blocks{8}(signal{8},cfg);                   % Time shift and CFO shift finding
    % disp(['SNR = ', num2str(EbN0)]);
    % disp(['True STO = ', num2str(shift), ' | Estimated STO = ', num2str(time_corr)]);
    % disp(['True CFO = ', num2str(CFO*cfg.F_carrier), ' | Estimated CFO = ', num2str(CFO_corr)]);
    %signal{9} = blocks{9}(signal{8},time_corr,CFO_corr,channel,cfg);    % Time correction
    signal{10} = blocks{10}(signal{8},channel,cfg);                     % FFT
    [h_temp,h_freq] = blocks{11}(signal{2},signal{10},cfg);             % channel estimation - preamble
    signal{11} = blocks{12}(signal{10},channel,channel_mode,cfg);        % Equalizer - Zero Forcing - Channel temporal est.
    signal{12} = blocks{13}(signal{11},cfg);                            % Demapping

    BER_2048(i) = mean(signal{1}(size_pream+1:end)~=signal{end});
    % Normalized MSE calculation - Time impulse comparison
    %channel_MSE = [channel';zeros(cfg.N_sub-length(channel),1)]; % Pad the channel with zeros to fit Subcarriers elements
    %NMSE_time(i) = sum(abs(h_temp-channel_MSE).^2)/sum(abs(channel_MSE).^2);

end
disp('2048 symb done !');

cfg.N_sub = 1024;
%cfg.N_CP = round((256/2048)*cfg.N_sub);
cfg.Nbit = cfg.block * cfg.N_sub * log2(cfg.Mod);
size_pream = log2(cfg.Mod)*cfg.N_pream*cfg.N_sub;

% Generated bits for 32 OFDM symbols on 2048 sub-carriers
signal{1} = randi([0 1], cfg.Nbit, 1);

% Make 2 symbols of preamble identical ! - same bits for preamble
signal{1} = [signal{1}(1:cfg.N_sub*log2(cfg.Mod));signal{1}(1:cfg.N_sub*log2(cfg.Mod));signal{1}(2*cfg.N_sub*log2(cfg.Mod)+1:end)];

signal{2} = blocks{1}(signal{1},cfg);   % Preamble modulation
signal{3} = blocks{2}(signal{1},cfg);   % QAM modulation
signal{4} = [signal{2};signal{3}];  % Fusion preamble - data
signal{5} = blocks{3}(signal{4},cfg);   % IFFT

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
channel = blocks{4}(h,delay,cfg);
signal{6} = blocks{5}(signal{5},channel);       % Channel convolution
for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{7} = blocks{6}(signal{6},shift,CFO,error_mode,cfg);          % Time shift
    signal{8} = blocks{7}(signal{7},EbN0,cfg);                          % Additive noise
    [time_corr, CFO_corr] = blocks{8}(signal{8},cfg);                   % Time shift and CFO shift finding
    % disp(['SNR = ', num2str(EbN0)]);
    % disp(['True STO = ', num2str(shift), ' | Estimated STO = ', num2str(time_corr)]);
    % disp(['True CFO = ', num2str(CFO*cfg.F_carrier), ' | Estimated CFO = ', num2str(CFO_corr)]);
    %signal{9} = blocks{9}(signal{8},time_corr,CFO_corr,channel,cfg);    % Time correction
    signal{10} = blocks{10}(signal{8},channel,cfg);                     % FFT
    [h_temp,h_freq] = blocks{11}(signal{2},signal{10},cfg);             % channel estimation - preamble
    signal{11} = blocks{12}(signal{10},channel,channel_mode,cfg);        % Equalizer - Zero Forcing - Channel temporal est.
    signal{12} = blocks{13}(signal{11},cfg);                            % Demapping

    BER_1024(i) = mean(signal{1}(size_pream+1:end)~=signal{end});
    % Normalized MSE calculation - Time impulse comparison
    %channel_MSE = [channel';zeros(cfg.N_sub-length(channel),1)]; % Pad the channel with zeros to fit Subcarriers elements
    %NMSE_time(i) = sum(abs(h_temp-channel_MSE).^2)/sum(abs(channel_MSE).^2);

end
disp('1024 symb done !');

cfg.N_sub = 512;
%cfg.N_CP = round((256/2048)*cfg.N_sub);
cfg.Nbit = cfg.block * cfg.N_sub * log2(cfg.Mod);
size_pream = log2(cfg.Mod)*cfg.N_pream*cfg.N_sub;

% Generated bits for 32 OFDM symbols on 2048 sub-carriers
signal{1} = randi([0 1], cfg.Nbit, 1);

% Make 2 symbols of preamble identical ! - same bits for preamble
signal{1} = [signal{1}(1:cfg.N_sub*log2(cfg.Mod));signal{1}(1:cfg.N_sub*log2(cfg.Mod));signal{1}(2*cfg.N_sub*log2(cfg.Mod)+1:end)];

signal{2} = blocks{1}(signal{1},cfg);   % Preamble modulation
signal{3} = blocks{2}(signal{1},cfg);   % QAM modulation
signal{4} = [signal{2};signal{3}];  % Fusion preamble - data
signal{5} = blocks{3}(signal{4},cfg);   % IFFT

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
channel = blocks{4}(h,delay,cfg);
signal{6} = blocks{5}(signal{5},channel);       % Channel convolution

for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{7} = blocks{6}(signal{6},shift,CFO,error_mode,cfg);          % Time shift
    signal{8} = blocks{7}(signal{7},EbN0,cfg);                          % Additive noise
    [time_corr, CFO_corr] = blocks{8}(signal{8},cfg);                   % Time shift and CFO shift finding
    % disp(['SNR = ', num2str(EbN0)]);
    % disp(['True STO = ', num2str(shift), ' | Estimated STO = ', num2str(time_corr)]);
    % disp(['True CFO = ', num2str(CFO*cfg.F_carrier), ' | Estimated CFO = ', num2str(CFO_corr)]);
    %signal{9} = blocks{9}(signal{8},time_corr,CFO_corr,channel,cfg);    % Time correction
    signal{10} = blocks{10}(signal{8},channel,cfg);                     % FFT
    [h_temp,h_freq] = blocks{11}(signal{2},signal{10},cfg);             % channel estimation - preamble
    signal{11} = blocks{12}(signal{10},channel,channel_mode,cfg);        % Equalizer - Zero Forcing - Channel temporal est.
    signal{12} = blocks{13}(signal{11},cfg);                            % Demapping
    
    BER_512(i) = mean(signal{1}(size_pream+1:end)~=signal{end});
    % Normalized MSE calculation - Time impulse comparison
    %channel_MSE = [channel';zeros(cfg.N_sub-length(channel),1)]; % Pad the channel with zeros to fit Subcarriers elements
    %NMSE_time(i) = sum(abs(h_temp-channel_MSE).^2)/sum(abs(channel_MSE).^2);

end
disp('512 symb done !');

%% PLOT

 
figure;
%semilogy(cfg.SNR,BER_4096,'bo-', 'LineWidth', 1.5);
%hold on
semilogy(cfg.SNR,BER_2048,'rx-', 'LineWidth', 1.5);
hold on
semilogy(cfg.SNR,BER_1024,'m+-', 'LineWidth', 1.5);
semilogy(cfg.SNR,BER_512,'co-', 'LineWidth', 1.5);
grid on
xlabel('SNR (dB)');
ylabel('BER');
xlim([cfg.SNR(1) cfg.SNR(end)]);
legend('2048 symb','1024 symb', '512 symb');
title('Bit Error Rate evolution')


% Reason for worse performance with 400 Nsub -> High noise level - each sub
% carrier contains larger bandwidth (much sensitive to frequency
% selectivity - bandwith not flat anymore)