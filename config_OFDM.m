%% FUNCTION GATHERING INPUT

function cfg = config_OFDM()
    clc; close all;

    % setup the path
    project_root = fileparts(mfilename('fullpath')); % Get project root
    src_path = fullfile(project_root, 'src');
    if ~contains(path, src_path)
        addpath(genpath(src_path));
    end

    cfg = struct();

    %% OFDM TRANSMISSION AND RECEPTION - PART 1
    
    cfg.BW = 160e6;                   % Bandwidth of 160 MHz
    cfg.F_carrier = 5*10^9;              % Carrier at 5GHz
    cfg.N_sub = 2048;                    % Number of subcarriers (IFFT/FFT size)
    cfg.N_CP  = 256;                     % Cyclic prefix length
    cfg.N_pream = 2;
    cfg.N_data = 30;                     % Number of OFDM data symbols
    cfg.Mod    = 16;                     % QAM modulation order
    cfg.block = cfg.N_pream + cfg.N_data; % Total OFDM BLOCK
    cfg.Nbit = cfg.block * cfg.N_sub * log2(cfg.Mod); % Total Bits
    %cfg.symbolrate = cfg.BW/cfg.N_sub;
    cfg.symbolrate = cfg.BW;

    % Channel
    cfg.pathnb = 2;
    cfg.ampl = 0.3;
    cfg.phase = pi/4;

    % Noise
    cfg.SNR = -5:5:30;                   % Range of SNR values in dB  -- Eb/No

end