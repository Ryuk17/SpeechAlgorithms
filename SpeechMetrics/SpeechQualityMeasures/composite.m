function [Csig,Cbak,Covl]= composite(cleanFile, enhancedFile);
% ----------------------------------------------------------------------
%          Composite Objective Speech Quality Measure
%
%   This function implements the composite objective measure proposed in
%   [1]. 
%
%   Usage:  [sig,bak,ovl]=composite(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         sig           - predicted rating [1-5] of speech distortion
%         bak           - predicted rating [1-5] of noise distortion
%         ovl           - predicted rating [1-5] of overall quality
%
%       In addition to the above ratings (sig, bak, & ovl) it returns
%       the individual values of the LLR, SNRseg, WSS and PESQ measures.
%
%  Example call:  [sig,bak,ovl] =composite('sp04.wav','enhanced.wav')
%
%  
%  References:
%
%     [1]   Hu, Y. and Loizou, P. (2006). Evaluation of objective measures 
%           for speech enhancement. Proc. Interspeech, Pittsburg, PA. 
%        
%   Authors: Yi Hu and Philipos C. Loizou
%   (the LLR, SNRseg and WSS measures were based on Bryan Pellom and John
%     Hansen's implementations)
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $

% ----------------------------------------------------------------------

if nargin~=2
    fprintf('USAGE: [sig,bak,ovl]=composite(cleanFile.wav, enhancedFile.wav)\n');
    fprintf('For more help, type: help composite\n\n');
    return;
end

alpha= 0.95;

[data1, Srate1, Nbits1]= wavread(cleanFile);
[data2, Srate2, Nbits2]= wavread(enhancedFile);
if ( Srate1~= Srate2) | ( Nbits1~= Nbits2)
    error( 'The two files do not match!\n');
end

len= min( length( data1), length( data2));
data1= data1( 1: len)+eps;
data2= data2( 1: len)+eps;


% -- compute the WSS measure ---
%
wss_dist_vec= wss( data1, data2,Srate1);
wss_dist_vec= sort( wss_dist_vec);
wss_dist= mean( wss_dist_vec( 1: round( length( wss_dist_vec)*alpha)));

% --- compute the LLR measure ---------
%
LLR_dist= llr( data1, data2,Srate1);
LLRs= sort(LLR_dist);
LLR_len= round( length(LLR_dist)* alpha);
llr_mean= mean( LLRs( 1: LLR_len));

% --- compute the SNRseg ----------------
%
[snr_dist, segsnr_dist]= snr( data1, data2,Srate1);
snr_mean= snr_dist;
segSNR= mean( segsnr_dist);


% -- compute the pesq ----
%
% if     Srate1==8000,    mode='nb';
% elseif Srate1 == 16000, mode='wb';
% else,
%      error ('Sampling freq in PESQ needs to be 8 kHz or 16 kHz');
% end

     
 [pesq_mos_scores]= pesq(cleanFile, enhancedFile);
 
 if length(pesq_mos_scores)==2
     pesq_mos=pesq_mos_scores(1); % take the raw PESQ value instead of the
                                  % MOS-mapped value (this composite
                                  % measure was only validated with the raw
                                  % PESQ value)
 else
     pesq_mos=pesq_mos_scores;
 end
 
% --- now compute the composite measures ------------------
%
Csig = 3.093 - 1.029*llr_mean + 0.603*pesq_mos-0.009*wss_dist;
  Csig = max(1,Csig);  Csig=min(5, Csig); % limit values to [1, 5]
Cbak = 1.634 + 0.478 *pesq_mos - 0.007*wss_dist + 0.063*segSNR;
  Cbak = max(1, Cbak); Cbak=min(5,Cbak); % limit values to [1, 5]
Covl = 1.594 + 0.805*pesq_mos - 0.512*llr_mean - 0.007*wss_dist;
  Covl = max(1, Covl); Covl=min(5, Covl); % limit values to [1, 5]

fprintf('\n LLR=%f   SNRseg=%f   WSS=%f   PESQ=%f\n',llr_mean,segSNR,wss_dist,pesq_mos);

return; %=================================================================


function distortion = wss(clean_speech, processed_speech,sample_rate)


% ----------------------------------------------------------------------
% Check the length of the clean and processed speech.  Must be the same.
% ----------------------------------------------------------------------

clean_length      = length(clean_speech);
processed_length  = length(processed_speech);

if (clean_length ~= processed_length)
  disp('Error: Files  musthave same length.');
  return
end



% ----------------------------------------------------------------------
% Global Variables
% ----------------------------------------------------------------------

winlength   = round(30*sample_rate/1000); %240;		   % window length in samples
skiprate    = floor(winlength/4);		   % window skip in samples
max_freq    = sample_rate/2;	   % maximum bandwidth
num_crit    = 25;		   % number of critical bands

USE_FFT_SPECTRUM = 1;		   % defaults to 10th order LP spectrum
n_fft       = 2^nextpow2(2*winlength);
n_fftby2    = n_fft/2;		   % FFT size/2
Kmax        = 20;		   % value suggested by Klatt, pg 1280
Klocmax     = 1;		   % value suggested by Klatt, pg 1280		

% ----------------------------------------------------------------------
% Critical Band Filter Definitions (Center Frequency and Bandwidths in Hz)
% ----------------------------------------------------------------------

cent_freq(1)  = 50.0000;   bandwidth(1)  = 70.0000;
cent_freq(2)  = 120.000;   bandwidth(2)  = 70.0000;
cent_freq(3)  = 190.000;   bandwidth(3)  = 70.0000;
cent_freq(4)  = 260.000;   bandwidth(4)  = 70.0000;
cent_freq(5)  = 330.000;   bandwidth(5)  = 70.0000;
cent_freq(6)  = 400.000;   bandwidth(6)  = 70.0000;
cent_freq(7)  = 470.000;   bandwidth(7)  = 70.0000;
cent_freq(8)  = 540.000;   bandwidth(8)  = 77.3724;
cent_freq(9)  = 617.372;   bandwidth(9)  = 86.0056;
cent_freq(10) = 703.378;   bandwidth(10) = 95.3398;
cent_freq(11) = 798.717;   bandwidth(11) = 105.411;
cent_freq(12) = 904.128;   bandwidth(12) = 116.256;
cent_freq(13) = 1020.38;   bandwidth(13) = 127.914;
cent_freq(14) = 1148.30;   bandwidth(14) = 140.423;
cent_freq(15) = 1288.72;   bandwidth(15) = 153.823;
cent_freq(16) = 1442.54;   bandwidth(16) = 168.154;
cent_freq(17) = 1610.70;   bandwidth(17) = 183.457;
cent_freq(18) = 1794.16;   bandwidth(18) = 199.776;
cent_freq(19) = 1993.93;   bandwidth(19) = 217.153;
cent_freq(20) = 2211.08;   bandwidth(20) = 235.631;
cent_freq(21) = 2446.71;   bandwidth(21) = 255.255;
cent_freq(22) = 2701.97;   bandwidth(22) = 276.072;
cent_freq(23) = 2978.04;   bandwidth(23) = 298.126;
cent_freq(24) = 3276.17;   bandwidth(24) = 321.465;
cent_freq(25) = 3597.63;   bandwidth(25) = 346.136;

bw_min      = bandwidth (1);	   % minimum critical bandwidth

% ----------------------------------------------------------------------
% Set up the critical band filters.  Note here that Gaussianly shaped
% filters are used.  Also, the sum of the filter weights are equivalent
% for each critical band filter.  Filter less than -30 dB and set to
% zero.
% ----------------------------------------------------------------------

min_factor = exp (-30.0 / (2.0 * 2.303));       % -30 dB point of filter

for i = 1:num_crit
  f0 = (cent_freq (i) / max_freq) * (n_fftby2);
  all_f0(i) = floor(f0);
  bw = (bandwidth (i) / max_freq) * (n_fftby2);
  norm_factor = log(bw_min) - log(bandwidth(i));
  j = 0:1:n_fftby2-1;
  crit_filter(i,:) = exp (-11 *(((j - floor(f0)) ./bw).^2) + norm_factor);
  crit_filter(i,:) = crit_filter(i,:).*(crit_filter(i,:) > min_factor);
end   

% ----------------------------------------------------------------------
% For each frame of input speech, calculate the Weighted Spectral
% Slope Measure
% ----------------------------------------------------------------------

num_frames = clean_length/skiprate-(winlength/skiprate); % number of frames
start      = 1;					% starting sample
window     = 0.5*(1 - cos(2*pi*(1:winlength)'/(winlength+1)));

for frame_count = 1:num_frames

   % ----------------------------------------------------------
   % (1) Get the Frames for the test and reference speech. 
   %     Multiply by Hanning Window.
   % ----------------------------------------------------------

   clean_frame = clean_speech(start:start+winlength-1);
   processed_frame = processed_speech(start:start+winlength-1);
   clean_frame = clean_frame.*window;
   processed_frame = processed_frame.*window;

   % ----------------------------------------------------------
   % (2) Compute the Power Spectrum of Clean and Processed
   % ----------------------------------------------------------

    if (USE_FFT_SPECTRUM)
       clean_spec     = (abs(fft(clean_frame,n_fft)).^2);
       processed_spec = (abs(fft(processed_frame,n_fft)).^2);
    else
       a_vec = zeros(1,n_fft);
       a_vec(1:11) = lpc(clean_frame,10);
       clean_spec     = 1.0/(abs(fft(a_vec,n_fft)).^2)';

       a_vec = zeros(1,n_fft);
       a_vec(1:11) = lpc(processed_frame,10);
       processed_spec = 1.0/(abs(fft(a_vec,n_fft)).^2)';
    end

   % ----------------------------------------------------------
   % (3) Compute Filterbank Output Energies (in dB scale)
   % ----------------------------------------------------------
 
   for i = 1:num_crit
      clean_energy(i) = sum(clean_spec(1:n_fftby2) ...
		            .*crit_filter(i,:)');
      processed_energy(i) = sum(processed_spec(1:n_fftby2) ...
			        .*crit_filter(i,:)');
   end
   clean_energy = 10*log10(max(clean_energy,1E-10));
   processed_energy = 10*log10(max(processed_energy,1E-10));

   % ----------------------------------------------------------
   % (4) Compute Spectral Slope (dB[i+1]-dB[i]) 
   % ----------------------------------------------------------

   clean_slope     = clean_energy(2:num_crit) - ...
		     clean_energy(1:num_crit-1);
   processed_slope = processed_energy(2:num_crit) - ...
		     processed_energy(1:num_crit-1);

   % ----------------------------------------------------------
   % (5) Find the nearest peak locations in the spectra to 
   %     each critical band.  If the slope is negative, we 
   %     search to the left.  If positive, we search to the 
   %     right.
   % ----------------------------------------------------------

   for i = 1:num_crit-1

       % find the peaks in the clean speech signal
	
       if (clean_slope(i)>0) 		% search to the right
	  n = i;
          while ((n<num_crit) & (clean_slope(n) > 0))
	     n = n+1;
 	  end
	  clean_loc_peak(i) = clean_energy(n-1);
       else				% search to the left
          n = i;
	  while ((n>0) & (clean_slope(n) <= 0))
	     n = n-1;
 	  end
	  clean_loc_peak(i) = clean_energy(n+1);
       end

       % find the peaks in the processed speech signal

       if (processed_slope(i)>0) 	% search to the right
	  n = i;
          while ((n<num_crit) & (processed_slope(n) > 0))
	     n = n+1;
	  end
	  processed_loc_peak(i) = processed_energy(n-1);
       else				% search to the left
          n = i;
	  while ((n>0) & (processed_slope(n) <= 0))
	     n = n-1;
 	  end
	  processed_loc_peak(i) = processed_energy(n+1);
       end

   end

   % ----------------------------------------------------------
   %  (6) Compute the WSS Measure for this frame.  This 
   %      includes determination of the weighting function.
   % ----------------------------------------------------------

   dBMax_clean       = max(clean_energy);
   dBMax_processed   = max(processed_energy);

   % The weights are calculated by averaging individual
   % weighting factors from the clean and processed frame.
   % These weights W_clean and W_processed should range
   % from 0 to 1 and place more emphasis on spectral 
   % peaks and less emphasis on slope differences in spectral
   % valleys.  This procedure is described on page 1280 of
   % Klatt's 1982 ICASSP paper.

   Wmax_clean        = Kmax ./ (Kmax + dBMax_clean - ...
		 	    clean_energy(1:num_crit-1));
   Wlocmax_clean     = Klocmax ./ ( Klocmax + clean_loc_peak - ...
				clean_energy(1:num_crit-1));
   W_clean           = Wmax_clean .* Wlocmax_clean;

   Wmax_processed    = Kmax ./ (Kmax + dBMax_processed - ...
			        processed_energy(1:num_crit-1));
   Wlocmax_processed = Klocmax ./ ( Klocmax + processed_loc_peak - ...
			            processed_energy(1:num_crit-1));
   W_processed       = Wmax_processed .* Wlocmax_processed;
  
   W = (W_clean + W_processed)./2.0;
  
   distortion(frame_count) = sum(W.*(clean_slope(1:num_crit-1) - ...
		       processed_slope(1:num_crit-1)).^2);

   % this normalization is not part of Klatt's paper, but helps
   % to normalize the measure.  Here we scale the measure by the
   % sum of the weights.

   distortion(frame_count) = distortion(frame_count)/sum(W);
   
   start = start + skiprate;
     
end

%-----------------------------------------------
function distortion = llr(clean_speech, processed_speech,sample_rate)


% ----------------------------------------------------------------------
% Check the length of the clean and processed speech.  Must be the same.
% ----------------------------------------------------------------------

clean_length      = length(clean_speech);
processed_length  = length(processed_speech);

if (clean_length ~= processed_length)
  disp('Error: Both Speech Files must be same length.');
  return
end

% ----------------------------------------------------------------------
% Global Variables
% ----------------------------------------------------------------------

winlength   = round(30*sample_rate/1000); %  window length in samples
skiprate    = floor(winlength/4);		   % window skip in samples
if sample_rate<10000
   P           = 10;		   % LPC Analysis Order
else
    P=16;     % this could vary depending on sampling frequency.
end

% ----------------------------------------------------------------------
% For each frame of input speech, calculate the Log Likelihood Ratio 
% ----------------------------------------------------------------------

num_frames = clean_length/skiprate-(winlength/skiprate); % number of frames
start      = 1;					% starting sample
window     = 0.5*(1 - cos(2*pi*(1:winlength)'/(winlength+1)));

for frame_count = 1:num_frames

   % ----------------------------------------------------------
   % (1) Get the Frames for the test and reference speech. 
   %     Multiply by Hanning Window.
   % ----------------------------------------------------------

   clean_frame = clean_speech(start:start+winlength-1);
   processed_frame = processed_speech(start:start+winlength-1);
   clean_frame = clean_frame.*window;
   processed_frame = processed_frame.*window;

   % ----------------------------------------------------------
   % (2) Get the autocorrelation lags and LPC parameters used
   %     to compute the LLR measure.
   % ----------------------------------------------------------

   [R_clean, Ref_clean, A_clean] = ...
      lpcoeff(clean_frame, P);
   [R_processed, Ref_processed, A_processed] = ...
      lpcoeff(processed_frame, P);

   % ----------------------------------------------------------
   % (3) Compute the LLR measure
   % ----------------------------------------------------------

   numerator   = A_processed*toeplitz(R_clean)*A_processed';
   denominator = A_clean*toeplitz(R_clean)*A_clean';
   distortion(frame_count) = log(numerator/denominator); 
   start = start + skiprate;

end

%---------------------------------------------
function [acorr, refcoeff, lpparams] = lpcoeff(speech_frame, model_order)

   % ----------------------------------------------------------
   % (1) Compute Autocorrelation Lags
   % ----------------------------------------------------------

   winlength = max(size(speech_frame));
   for k=1:model_order+1
      R(k) = sum(speech_frame(1:winlength-k+1) ...
		     .*speech_frame(k:winlength));
   end

   % ----------------------------------------------------------
   % (2) Levinson-Durbin
   % ----------------------------------------------------------

   a = ones(1,model_order);
   E(1)=R(1);
   for i=1:model_order
      a_past(1:i-1) = a(1:i-1);
      sum_term = sum(a_past(1:i-1).*R(i:-1:2));
      rcoeff(i)=(R(i+1) - sum_term) / E(i);
      a(i)=rcoeff(i);
      a(1:i-1) = a_past(1:i-1) - rcoeff(i).*a_past(i-1:-1:1);
      E(i+1)=(1-rcoeff(i)*rcoeff(i))*E(i);
   end

   acorr    = R;
   refcoeff = rcoeff;
   lpparams = [1 -a];

   
   % ----------------------------------------------------------------------

function [overall_snr, segmental_snr] = snr(clean_speech, processed_speech,sample_rate)

% ----------------------------------------------------------------------
% Check the length of the clean and processed speech.  Must be the same.
% ----------------------------------------------------------------------

clean_length      = length(clean_speech);
processed_length  = length(processed_speech);

if (clean_length ~= processed_length)
  disp('Error: Both Speech Files must be same length.');
  return
end

% ----------------------------------------------------------------------
% Scale both clean speech and processed speech to have same dynamic
% range.  Also remove DC component from each signal
% ----------------------------------------------------------------------

%clean_speech     = clean_speech     - mean(clean_speech);
%processed_speech = processed_speech - mean(processed_speech);

%processed_speech = processed_speech.*(max(abs(clean_speech))/ max(abs(processed_speech)));

overall_snr = 10* log10( sum(clean_speech.^2)/sum((clean_speech-processed_speech).^2));

% ----------------------------------------------------------------------
% Global Variables
% ----------------------------------------------------------------------

winlength   = round(30*sample_rate/1000); %240;		   % window length in samples
skiprate    = floor(winlength/4);		   % window skip in samples
MIN_SNR     = -10;		   % minimum SNR in dB
MAX_SNR     =  35;		   % maximum SNR in dB

% ----------------------------------------------------------------------
% For each frame of input speech, calculate the Segmental SNR
% ----------------------------------------------------------------------

num_frames = clean_length/skiprate-(winlength/skiprate); % number of frames
start      = 1;					% starting sample
window     = 0.5*(1 - cos(2*pi*(1:winlength)'/(winlength+1)));

for frame_count = 1: num_frames

   % ----------------------------------------------------------
   % (1) Get the Frames for the test and reference speech. 
   %     Multiply by Hanning Window.
   % ----------------------------------------------------------

   clean_frame = clean_speech(start:start+winlength-1);
   processed_frame = processed_speech(start:start+winlength-1);
   clean_frame = clean_frame.*window;
   processed_frame = processed_frame.*window;

   % ----------------------------------------------------------
   % (2) Compute the Segmental SNR
   % ----------------------------------------------------------

   signal_energy = sum(clean_frame.^2);
   noise_energy  = sum((clean_frame-processed_frame).^2);
   segmental_snr(frame_count) = 10*log10(signal_energy/(noise_energy+eps)+eps);
   segmental_snr(frame_count) = max(segmental_snr(frame_count),MIN_SNR);
   segmental_snr(frame_count) = min(segmental_snr(frame_count),MAX_SNR);

   start = start + skiprate;

end



