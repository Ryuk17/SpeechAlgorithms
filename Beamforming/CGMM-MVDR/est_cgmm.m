function [ lambda_v, lambda_y, R_xn, R_n ] = est_cgmm( ffts )
%EST_CGMM is used to estimate the Complex GMM parameters 
%and generate the mask for nosie only and noisy t-f bins
%   ffts: M*L*(fft_len/2+1), the multi-channel fft matrix
%   lambda_v: the mask for noise only t-f bins
%   lambda_y: the mask for noisy t-f bins
%   Ry, Rv: the spacial covariance matrix of noisy and noise;;
%           M*M*F;

[M, T, F ] = size(ffts);

lambda_v = zeros(T, F);
lambda_y =zeros(T, F);
outer=outProdND(ffts); %M*M*T*F
Ry = squeeze(mean(outer, 3));
R_n = zeros([M, M, F]);
Rv = eye(M);
Rv = reshape(Rv, [size(Rv, 1), size(Rv, 2), 1]);
Rv = repmat(Rv, [1, 1, F]);
phi_y = ones(T, F);
phi_v = ones(T, F);


for iter=1:10
    for f=1:F
        Ry_f = Ry(:, :, f);
        Rv_f = Rv(:, :, f);
        if rcond(Ry_f) < 0.0001
            Ry_f = Ry_f + rand(M)*0.0001;
        end
        if rcond(Rv_f) < 0.0001
            Rv_f = Rv_f + rand(M)*0.0001;
        end
        invRy_f = inv(Ry_f);
        invRv_f = inv(Rv_f);
        y_tf = ffts(:, :, f);
        y_y_tf = outProdND(y_tf);
        sum_y = zeros(M);
        sum_v = zeros(M);
        acc_n = zeros(M);
        e= eye(M)*0.00000;
        for t = 1:T
            phi_y(t, f) = (1/M)*(trace(y_y_tf(:, :, t)*invRy_f));
            phi_v(t, f) = (1/M)*(trace(y_y_tf(:, :, t)*invRv_f));    
            kernel_y = y_tf(:, t)' * (1/phi_y(t, f))*invRy_f * y_tf(:, t);
            kernel_v = y_tf(:, t)' * (1/phi_v(t, f))*invRv_f * y_tf(:, t);
            p_y(t, f) = exp(-kernel_y)/(pi*det(phi_y(t, f)*Ry_f));
            p_v(t, f) = exp(-kernel_v)/(pi*det(phi_v(t, f)*Rv_f));
            lambda_y(t, f) = p_y(t, f) / (p_y(t, f)+p_v(t, f));
            lambda_v(t, f) = p_v(t, f) / (p_y(t, f)+p_v(t, f));
            sum_y = sum_y + lambda_y(t, f)/phi_y(t, f)*y_y_tf(:, :, t);
            sum_v = sum_v + lambda_v(t, f)/phi_v(t, f)*y_y_tf(:, :, t);
            acc_n = acc_n + lambda_v(t, f)*y_y_tf(:, :, t); %for eq(4)
        end
        R_n(:, :, f) = 1/sum(lambda_y(:, f)) * acc_n; %eq(4)
        
        tmp_Ry_f = 1/sum(lambda_y(:, f)) * sum_y;
        tmp_Rv_f = 1/sum(lambda_v(:, f)) * sum_v;
        
        [V1, D1] = eig(squeeze(tmp_Ry_f));
        [V2, D2] = eig(squeeze(tmp_Rv_f));

        entropy1 = -diag(V1, 0)'/sum(diag(V1, 0)) * log(diag(V1, 0)/sum(diag(V1, 0)));
        entropy2 = -diag(V2, 0)'/sum(diag(V2, 0)) * log(diag(V2, 0)/sum(diag(V2, 0)));
        if entropy1 > entropy2
            Ry(:, :, f) = tmp_Rv_f;
            Rv(:, :, f) = tmp_Ry_f;
        else
            Ry(:, :, f) = tmp_Ry_f;
            Rv(:, :, f) = tmp_Rv_f;
        end
    end
    
    Q = sum(sum(lambda_y .* log(p_y+0.001) + lambda_v .* log(p_v+0.001)))
    figure(1)
    imagesc(real([flipud(lambda_y');flipud(lambda_v')]));
end  
R_xn = Ry;

end

