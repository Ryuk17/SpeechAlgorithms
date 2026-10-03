%% Test scripts 
%% Author Sining Sun (NWPU)
% snsun@nwpu-aslp.org
clc
clear

%% Load the test multi-channel test data
I = 6; %channels number
for i = 1:I
    wav_all(:, i) = audioread(['test_wav/test3/20G_20GO010I_STR.CH' int2str(i) '.wav']);
end
wav= wav_all(:, [1, 3, 4, 5, 6]); % we do not use ch2 because of bad quality
M=5
% You just neet to give your wav and M and repalace them here.
%% enframe and do fft
frame_length = 400;
frame_shift = 160;
fft_len = 512;
[frames, ffts] = multi_fft(wav, frame_length, frame_shift, fft_len);

%% Estimate the TF-SPP and spacial covariance matrix for noisy speech and noise 
[lambda_v, lambda_y, Ry, Rv] = est_cgmm(ffts);

Rx = Ry -Rv;         %trade off. Rx may be not positive definite

[M, T, F]  = size(ffts); %fft bins number
d = zeros(M, F);         %steering vectors
w = d;                   %mvdr beamforming weight 
output = zeros(T, F);    %beamforming outputs

%% Get steering vectors d using eigvalue composition 
for f= 1:F
    [V, ~, ~] = svd(Rx(:,:,f));
    d(:, f) = V(:, 1);
end
%% Do MVDR beamforming
output = mvdr(ffts, Rv, d);

%% Reconstruct time domain signal using overlap and add;
output = [output, fliplr(conj(output(:, 2:end-1)))];
rec_frames = real(ifft(output, fft_len, 2));
rec_frames = rec_frames(:,1:frame_length);
sig = overlapadd(rec_frames, hamming(frame_length, 'periodic'), frame_shift);

audiowrite('output.wav', sig./max(abs(sig)), 16000);
