function [h_est_temp, h_est_freq] = channel_estimation(preamble_tr, preamble_rx,cfg)
    
    size_vec = (cfg.N_sub);
    sym_0 = size_vec;

    % Take 2nd symbol
    pre_tr = preamble_tr(sym_0+1:sym_0 + size_vec);
    pre_tr = pre_tr(:);

    pre_rx = preamble_rx(sym_0+1:sym_0 + size_vec);
    pre_rx = pre_rx(:);
    
    % Calculate diagonal matrice of transmitted symbol
    lambda = diag(pre_tr);
    lambda_h = diag(conj(pre_tr));

    % Channel estimation
    % Frequency estimate
    
    h_est_freq = lambda_h*pre_rx;
    %h_est_freq = pre_rx./pre_tr;

    % Time estimate
    F_q = zeros(cfg.N_sub,cfg.N_sub);
    for q = 0 : size_vec-1
        for n = 0 : size_vec-1
            F_q(q+1,n+1) = exp(-1j*2*pi()*q*n/(cfg.N_sub));
        end
    end
    F_q = F_q(:,1:cfg.N_CP);
    h_est_temp = 1/(cfg.N_sub)*F_q'*lambda_h*pre_rx;
    h_est_temp  = [h_est_temp ; zeros(cfg.N_sub-cfg.N_CP,1)];

end