clear;

%transient estimation
[yIn,Fs]=audioread('sample/speech_transient.wav');
num_UC_frames=40;%number of uncausal frames
[~,tEst]=trans_estimating_omlsa_UC(yIn,num_UC_frames);
audiowrite('sample/transient_est.wav',tEst,Fs)
%speech enhancement
trans_reducing_omlsa('sample/speech_transient.wav','sample/enhanced.wav','sample/transient_est.wav');
%see the sound files of the estimated transient and the enhanced speech in
%the folder "sample"