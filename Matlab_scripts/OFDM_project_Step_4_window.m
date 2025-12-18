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
        @(x,h,sym_tx,pilot_position,window,mode) pilot_phase_window_corr(x,h,sym_tx,pilot_position,window,mode,cfg),...
        @(x,h,mode) equalize_chan(x,h,mode,cfg),...
        @(x) unmapping_2(x,cfg),...
  };

%% STEP 1 - Transmitter

% ****Error 1 : No error    Error 2 : Time shift    Error 3 : CFO shift     Error 4 : CFO and Time shift***** 
error_mode = 4;             
shift = 5;                  % Time shift for symbols
CFO = 1e-6;                 % 1e-6, 1000e-6
time_corr = 0;              % No time correction yet
pilot_sym_position = [10,800];
window = 3;                 % Window on 3 OFDM Symbols

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

% Channel estimate mode
channel_mode = 'time_est';

% Receiver

BER_pilot = zeros(size(cfg.SNR));
BER_no_pilot = zeros(size(cfg.SNR));
BER_true = zeros(size(cfg.SNR));
NMSE_freq = zeros(size(cfg.SNR));
size_pream = log2(cfg.Mod)*cfg.N_pream*cfg.N_sub;

figure;
for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{7} = blocks{6}(signal{6},shift,CFO,error_mode);          % Time shift
    signal{8} = blocks{7}(signal{7},EbN0);                          % Additive noise
    [time_corr, CFO_corr] = blocks{8}(signal{8});                   % Time shift and CFO shift finding

    disp(['SNR = ', num2str(EbN0)]);
    disp(['True STO = ', num2str(shift), ' samples | Estimated STO = ', num2str(time_corr),' samples']);
    disp(['True CFO = ', num2str(CFO*cfg.F_carrier), ' Hz | Estimated CFO = ', num2str(CFO_corr),' Hz']);
    disp(['Residual CFO remaining : ', num2str(CFO*cfg.F_carrier-CFO_corr), ' Hz']);
    signal{9} = blocks{9}(signal{8},time_corr,CFO_corr,channel);    % Time and CFO correction
    signal{10} = blocks{10}(signal{9},channel);                     % FFT
    [h_temp,h_freq] = blocks{11}(signal{2},signal{10});             % channel estimation - preamble
    [signal{11},phase_corr,phase_average] = blocks{12}(signal{10},h_temp, signal{4},pilot_sym_position,window,channel_mode);% Pilot correction
    signal{12} = blocks{13}(signal{10},h_temp,channel_mode);        % Equalizer - Zero Forcing - Channel temporal est.
    signal{13} = blocks{14}(signal{12});                            % Demapping
    
    BER_pilot(i) = mean(signal{1}(size_pream+1:end)~=signal{end});
    % Normalized MSE calculation - Time impulse comparison
    %channel_MSE = [channel';zeros(cfg.N_sub-length(channel),1)]; % Pad the channel with zeros to fit Subcarriers elements
    %NMSE_time(i) = sum(abs(h_temp-channel_MSE).^2)/sum(abs(channel_MSE).^2);

    plot((1:length(phase_corr)),phase_corr,'LineWidth',0.8);
    hold on

end

grid on
xlabel('OFDM symbol number');
ylabel('Phase residual (Hz)');
xlim([1 30]);
legend('-5dB','0dB','5dB','10dB','15dB','20dB','25dB','30dB')
title('Phase residual evolution over OFDM symbol');

figure;
plot((1:length(phase_corr)),phase_corr,'LineWidth',0.8);
grid on
xlim([1 30]);
xlabel('OFDM symbol number');
ylabel('Phase residual (Hz)');
legend('30dB')
title(['Phase residual evolution over OFDM symbol with sliding window of ',num2str(window)]);


%% PLOT

 
figure;
semilogy(cfg.SNR,BER_pilot,'bo-', 'LineWidth', 1.5);
grid on
xlabel('SNR (dB)');
ylabel('BER');
xlim([cfg.SNR(1) 15]);
legend('BER-pilot');
title('Bit Error Rate evolution')

%% If CFO = 2pi*deltaf*Tsymb = pi -> Break of orthogonality ! all the FFT coefficients falls between 2 bins !
% with 2pi -> Spacing of 1 bin - weirdly orthogonality is preserved but
% shifted.  For CFO < pi -> samll ICI - constant phase shift.  For CFO >
% pi > 2pi -> large ICI - constant phase shift.

% T_symb = 2048/BW = 1.28*e-5 sec
% detlaf limits  = pi/(2*T_symb) = 122 KHz
% 2*pi*residual*T_symb -> much smaller than pi -> consider negligeable ICI.