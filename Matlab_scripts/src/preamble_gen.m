function [QPSK_signal] = preamble_gen(bit_signal,cfg)
    
    size = log2(cfg.Mod)*cfg.N_pream*(cfg.N_sub);
    QPSK_signal = pskmod(bit_signal(1:size),cfg.Mod,'InputType', 'bit');


end