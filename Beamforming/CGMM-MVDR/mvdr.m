%% Author Sining Sun (NWPU)
% snsun@nwpu-aslp.org

function  enspec  = mvdr( ffts, Rn, d )
%MVDR is used to do MVDR beamforming;
%   ffts: M*T*F multi-channel spectrum 
%   Rn: M*M*F covariance matrix. 
%       M is channels number, 
%       F is frequency bin number
%   d: M*F steering vector
%   enspec: Tenhanced spectrum after MVDR
%   

[M, T, F]  = size(ffts); %fft bins number
w = zeros(M, F);         %mvdr beamforming weight 
enspec = zeros(T, F);    %beamforming outputs
e = 0.0001*eye(M);       %avoid the matrix singular
for f= 1:F

    if (rcond(squeeze(Rn(:, :, f))) < 0.001)
        invRv = inv(e+squeeze(Rn(:, :, f)));
    else
        invRv = inv(squeeze(Rn(:, :, f)));
    end
    w(:, f) = invRv * d(:, f) / (d(:, f)' * invRv *d(:, f));
    enspec(:, f) = (w(:, f)' * squeeze(ffts(:, :, f))).';
end
end

