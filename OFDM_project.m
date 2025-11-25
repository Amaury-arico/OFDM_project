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
        @(x) mapping(x,cfg), ...
        @(x) ifft_process(x, cfg), ...
        @(h,delay) channel_def(cfg,h,delay), ...
        @(x,h) channel_conv(x,h),...
        @(x,EbN0) awgn_add(x,EbN0,cfg),...
        @(x,h) fft_process(x,h,cfg),...
        @(x,h) equalize_chan(x,h,cfg),...
        @(x) unmapping(x,cfg),...

  };

%% STEP 1 - Transmitter


% Generated bits for 32 OFDM symbols on 2048 sub-carriers
signal{1} = randi([0 1], cfg.Nbit, 1);
delay = 0;

% Run the blocks
for i = 1:2
    signal{i+1} = blocks{i}(signal{i});
end

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
channel = blocks{3}(h,delay);
signal{4} = blocks{4}(signal{3},channel);

% Receiver

BER_awgn = zeros(size(cfg.SNR));
BER_multipath = zeros(size(cfg.SNR));
BER_no_equalizer = zeros(size(cfg.SNR));
BER_exceeddelay = zeros(size(cfg.SNR));

for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{5} = blocks{5}(signal{4},EbN0);          % Additive noise
    signal{6} = blocks{6}(signal{5},channel);       % FFT
    signal{7} = blocks{7}(signal{6},channel);       % Equalizer - Zero Forcing
    signal{8} = blocks{8}(signal{7});               % Demapping
    
    BER_multipath(i) = mean(signal{1}~=signal{end});

end

for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{5} = blocks{5}(signal{4},EbN0);          % Additive noise
    signal{6} = blocks{6}(signal{5},channel);       % FFT
    signal{8} = blocks{8}(signal{6});               % Demapping
    
    BER_no_equalizer(i) = mean(signal{1}~=signal{end});

end

% INPUT CHANNEL
h=0;
delay = 0;
h(1)=1; %init channel
cfg.pathnb = 1;

if cfg.pathnb > 1
    for i = 2:cfg.pathnb
        %cfg.phase = unifrnd(-pi, pi);
        %cfg.ampl = rand(1);
        h(i)=cfg.ampl*exp(1j*cfg.phase);
        delay(i) = i*10;
    end
end

% Channel and Noise
channel = blocks{3}(h,delay);
signal{4} = blocks{4}(signal{3},channel);

for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{5} = blocks{5}(signal{4},EbN0);          % Additive noise - no multipath
    signal{6} = blocks{6}(signal{5},channel);       % FFT
    signal{8} = blocks{8}(signal{6});               % Demapping
    
    BER_awgn(i) = mean(signal{1}~=signal{end});

end

% INPUT CHANNEL
cfg.pathnb = 2;
h=0;
delay = 0;
h(1)=1; %init channel

if cfg.pathnb > 1
    for i = 2:cfg.pathnb
        %cfg.phase = unifrnd(-pi, pi);
        %cfg.ampl = rand(1);
        h(i)=cfg.ampl*exp(1j*cfg.phase);
        delay(i) = 600;
    end
end

% Channel and Noise
channel = blocks{3}(h,delay);
signal{4} = blocks{4}(signal{3},channel);

for i=1:size(cfg.SNR,2)

    EbN0 = cfg.SNR(i);
    signal{5} = blocks{5}(signal{4},EbN0);          % Additive noise
    signal{6} = blocks{6}(signal{5},channel);       % FFT
    signal{7} = blocks{7}(signal{6},channel);       % Equalizer - Zero Forcing
    signal{8} = blocks{8}(signal{7});               % Demapping
    
    BER_exceeddelay(i) = mean(signal{1}~=signal{end});

end

%% PLOT

l=200;
figure;
stairs((1:l),signal{1}(1:l),'r--');
hold on
stairs((1:l),signal{8}(1:l),'b');
ylim([-0.5 1.5]);
title('Start-End Signals comparison');

figure;
semilogy(cfg.SNR,BER_awgn,'bo-', 'LineWidth', 1.5);
hold on
semilogy(cfg.SNR,BER_no_equalizer,'rx-', 'LineWidth', 1.5);
semilogy(cfg.SNR,BER_multipath,'m*-', 'LineWidth', 1.5);
semilogy(cfg.SNR,BER_exceeddelay,'g^-', 'LineWidth', 1.5);
grid on
xlim([cfg.SNR(1) cfg.SNR(end)]);
legend('Noisy signal - LOS','Multipath - No EQ','Multipath - EQ', strcat('Multipath - EQ - CF = ',num2str(delay(end))));
title('Bit Error Rate evolution')


