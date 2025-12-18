function [symb_tx] = mapping_2(signal,cfg)
  
    % Mapping in QAM - frequency domain
    preamble_size = log2(cfg.Mod)*(cfg.N_sub)*cfg.N_pream;
    symb_tx = qammod(signal(preamble_size+1:end), cfg.Mod, 'InputType', 'bit', 'UnitAveragePower', true);
    
end