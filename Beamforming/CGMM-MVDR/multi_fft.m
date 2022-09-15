function [ frames, ffts ] = multi_fft( wav, frame_length, frame_shift, fft_len )
%MULTI_FFT is used to do fft of multi-channel data
%   wav: L*M matrix. L is length of signal and M is channel number
%   frames: M*T*F, M is channel numbers;
%                  T is frame numbers;
%                  F is fft bin numbers ;
%   ffts: M*T*(fft_len/2+1), the multi-channel fft matrix
[len, M ] = size(wav);

%% multi-channel fft

win = hamming(frame_length, 'periodic');

tmp = enframe(wav(:, 1),win, frame_shift);
T = size(tmp, 1);
frames = zeros([M,T, frame_length]);
ffts = zeros([M, T, fft_len/2+1]);


for i = 1:M
    frames(i, :, :)= enframe(wav(:, i),win, frame_shift);
    
    
end
tmp = fft(frames, fft_len, 3);
ffts = tmp(:, :, 1:fft_len/2+1);

end

