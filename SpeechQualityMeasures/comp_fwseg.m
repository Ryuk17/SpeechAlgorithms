function fwseg_dist= comp_fwseg(cleanFile, enhancedFile);

% ----------------------------------------------------------------------
%      Frequency weighted SNRseg Objective Speech Quality Measure
%
%   This function implements the frequency-weighted SNRseg measure [1]
%   using a different weighting function, the clean spectrum.
%
%   Usage:  fwSNRseg=comp_fwseg(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         fwSNRseg      - computed frequency weighted SNRseg in dB
% 
%         Note that large numbers of fwSNRseg are better.
%
%  Example call:  fwSNRseg =comp_fwseg('sp04.wav','enhanced.wav')
%
%  
%  References:
%   [1]  Tribolet, J., Noll, P., McDermott, B., and Crochiere, R. E. (1978).
%        A study of complexity and quality of speech waveform coders. Proc. 
%        IEEE Int. Conf. Acoust. , Speech, Signal Processing, 586-590.
%
%   Author: Philipos C. Loizou 
%  (critical-band filtering routines were written by Bryan Pellom & John Hansen)
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
% ----------------------------------------------------------------------

if nargin~=2
    fprintf('USAGE: fwSNRseg=comp_fwseg(cleanFile.wav, enhancedFile.wav)\n');
    fprintf('For more help, type: help comp_fwseg\n\n');
    return;
end


[data1, Srate1, Nbits1]= wavread(cleanFile);
[data2, Srate2, Nbits2]= wavread(enhancedFile);
if ( Srate1~= Srate2) | ( Nbits1~= Nbits2)
    error( 'The two files do not match!\n');
end

len= min( length( data1), length( data2));
data1= data1( 1: len)+eps;
data2= data2( 1: len)+eps;

wss_dist_vec= fwseg( data1, data2,Srate1);

fwseg_dist=mean(wss_dist_vec);


% ----------------------------------------------------------------------

function distortion = fwseg(clean_speech, processed_speech,sample_rate)


% ----------------------------------------------------------------------
% Check the length of the clean and processed speech.  Must be the same.
% ----------------------------------------------------------------------

clean_length      = length(clean_speech);
processed_length  = length(processed_speech);

if (clean_length ~= processed_length)
  disp('Error: Files  must have same length.');
  return
end



% ----------------------------------------------------------------------
% Global Variables
% ----------------------------------------------------------------------


winlength   = round(30*sample_rate/1000); 	   % window length in samples
skiprate    = floor(winlength/4);		   % window skip in samples
max_freq    = sample_rate/2;	   % maximum bandwidth
num_crit    = 25;		   % number of critical bands
USE_25=1;
n_fft       = 2^nextpow2(2*winlength);
n_fftby2    = n_fft/2;		   % FFT size/2
gamma=0.2;  % power exponent

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

W=[  % articulation index weights
0.003
0.003
0.003
0.007
0.010
0.016
0.016
0.017
0.017
0.022
0.027
0.028
0.030
0.032
0.034
0.035
0.037
0.036
0.036
0.033
0.030
0.029
0.027
0.026
0.026];

W=W';

if USE_25==0  % use 13 bands
    % ----- lump adjacent filters together ----------------
    k=2;
    cent_freq2(1)=cent_freq(1);
    bandwidth2(1)=bandwidth(1)+bandwidth(2);
    W2(1)=W(1);
    for i=2:13
        cent_freq2(i)=cent_freq2(i-1)+bandwidth2(i-1);
        bandwidth2(i)=bandwidth(k)+bandwidth(k+1);
        W2(i)=0.5*(W(k)+W(k+1));
        k=k+2;
    end

    sumW=sum(W2);
    bw_min      = bandwidth2 (1);	   % minimum critical bandwidth
else
    sumW=sum(W);
    bw_min=bandwidth(1);
end


% ----------------------------------------------------------------------
% Set up the critical band filters.  Note here that Gaussianly shaped
% filters are used.  Also, the sum of the filter weights are equivalent
% for each critical band filter.  Filter less than -30 dB and set to
% zero.
% ----------------------------------------------------------------------

min_factor = exp (-30.0 / (2.0 * 2.303));       % -30 dB point of filter
if USE_25==0
    
    num_crit=length(cent_freq2);

    for i = 1:num_crit
        f0 = (cent_freq2 (i) / max_freq) * (n_fftby2);
        all_f0(i) = floor(f0);
        bw = (bandwidth2 (i) / max_freq) * (n_fftby2);
        norm_factor = log(bw_min) - log(bandwidth2(i));
        j = 0:1:n_fftby2-1;
        crit_filter(i,:) = exp (-11 *(((j - floor(f0)) ./bw).^2) + norm_factor);
        crit_filter(i,:) = crit_filter(i,:).*(crit_filter(i,:) > min_factor);
    end

else
    for i = 1:num_crit
        f0 = (cent_freq (i) / max_freq) * (n_fftby2);
        all_f0(i) = floor(f0);
        bw = (bandwidth (i) / max_freq) * (n_fftby2);
        norm_factor = log(bw_min) - log(bandwidth(i));
        j = 0:1:n_fftby2-1;
        crit_filter(i,:) = exp (-11 *(((j - floor(f0)) ./bw).^2) + norm_factor);
        crit_filter(i,:) = crit_filter(i,:).*(crit_filter(i,:) > min_factor);
    end
end



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
   % (2) Compute the magnitude Spectrum of Clean and Processed
   % ----------------------------------------------------------

    
       clean_spec     = abs(fft(clean_frame,n_fft));
       processed_spec = abs(fft(processed_frame,n_fft)); 

    % normalize spectra to have area of one
    %
    clean_spec=clean_spec/sum(clean_spec(1:n_fftby2));
    processed_spec=processed_spec/sum(processed_spec(1:n_fftby2));

   % ----------------------------------------------------------
   % (3) Compute Filterbank Output Energies 
   % ----------------------------------------------------------
 
   clean_energy=zeros(1,num_crit);
   processed_energy=zeros(1,num_crit);
   error_energy=zeros(1,num_crit);
   W_freq=zeros(1,num_crit);
  
   for i = 1:num_crit
      clean_energy(i) = sum(clean_spec(1:n_fftby2) ...
                         	.*crit_filter(i,:)');
      processed_energy(i) = sum(processed_spec(1:n_fftby2) ...
          .*crit_filter(i,:)');
                  	
        error_energy(i)=max((clean_energy(i)-processed_energy(i))^2,eps);
        W_freq(i)=(clean_energy(i))^gamma;
       
   end
   SNRlog=10*log10((clean_energy.^2)./error_energy);
   
   
   
   fwSNR=sum(W_freq.*SNRlog)/sum(W_freq);
   
   distortion(frame_count)=min(max(fwSNR,-10),35);

   start = start + skiprate;
     
end



