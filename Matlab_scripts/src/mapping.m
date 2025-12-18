function [symb_tx] = mapping(signal,cfg)
  
    % Mapping in QAM - frequency domain
    disp(cfg.Mod);
    symb_tx = qammod(signal, cfg.Mod, 'InputType', 'bit', 'UnitAveragePower', true);
    
end