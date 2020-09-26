function [SIG,BAK,OVL]= comp_fwseg_variant(cleanFile, enhancedFile);

% ----------------------------------------------------------------------
%      Frequency-variant fwSNRseg Objective Speech Quality Measure
%
%   This function implements the frequency-variant fwSNRseg measure [1]
%   (see also Chap. 10, Eq. 10.24)
%
%
%   Usage:  [sig,bak,ovl]=comp_fwseg_variant(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         sig           - predicted rating [1-5] of speech distortion
%         bak           - predicted rating [1-5] of noise distortion
%         ovl           - predicted rating [1-5] of overall quality
%
%
%  Example call:  [s,b,o] =comp_fwseg_variant('sp04.wav','enhanced.wav')
%
%  
%  References:
%     [1] S. R. Quackenbush, T. P. Barnwell, and M. A. Clements,
%	    Objective Measures of Speech Quality.  Prentice Hall
%	    Advanced Reference Series, Englewood Cliffs, NJ, 1988,
%	    ISBN: 0-13-629056-6.
%
%   Author: Philipos C. Loizou 
%  (critical-band filtering routines were written by Bryan Pellom & John Hansen)
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
% ----------------------------------------------------------------------

if nargin~=2
    fprintf('USAGE: [sig,bak,ovl]=comp_fwseg_variant(cleanFile.wav, enhancedFile.wav)\n');
    fprintf('For more help, type: help comp_fwseg_variant\n\n');
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

wss_dist_matrix= fwseg( data1, data2,Srate1);
wss_dist=mean(wss_dist_matrix);

% initialize  coefficients obtained from multiple linear
% regression analysis
%
b_sig=[0.021,-0.028,0.088,-0.031,0.048,-0.049,0.065,0.009,0.011,0.033,...
    -0.040,-0.002,0.041,-0.007,0.033,0.018,-0.007,0.044,-0.001,0.021,...
    -0.002,0.017,-0.03,0.073,0.043];
b_ovl=[-0.003,-0.026,0.066,-0.036,0.038,-0.023,0.037,0.022,0.014,0.009,...
    -0.03,0.004,0.044,-0.005,0.017,0.018,-0.001,0.051,0.009,0.011,...
    0.011,-0.002,-0.021,0.043,0.031];
b_bak=[-0.03,-0.022,0.03,-0.048,0.034,0.002,0.006,0.037,0.017,-0.016,-0.008,...
    0.019,0.024,-0.002,0.01,0.03,-0.018,0.046,0.022,0.005,0.03,-0.028,...
    -0.028,0.019,0.005];

SIG=0.567+sum(b_sig.*wss_dist);
SIG=max(1,SIG); SIG=min(5, SIG); % limit values to [1, 5]

BAK=1.013+sum(b_bak.*wss_dist);
BAK=max(1,BAK); BAK=min(5, BAK); % limit values to [1, 5]

OVL=0.446+sum(b_ovl.*wss_dist);
OVL=max(1,OVL); OVL=min(5, OVL); % limit values to [1, 5]


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

n_fft       = 2^nextpow2(2*winlength);
n_fftby2    = n_fft/2;		   % FFT size/2

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

num_frames = floor(clean_length/skiprate-(winlength/skiprate)); % number of frames
start      = 1;					% starting sample
window     = 0.5*(1 - cos(2*pi*(1:winlength)'/(winlength+1)));

distortion=zeros(num_frames,num_crit);
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
       
       % normalize so that spectra have unit area ----
        clean_spec=clean_spec/sum(clean_spec(1:n_fftby2));
        processed_spec=processed_spec/sum(processed_spec(1:n_fftby2));

   % ----------------------------------------------------------
   % (3) Compute Filterbank Output Energies (in dB scale)
   % ----------------------------------------------------------
 
   clean_energy=zeros(1,num_crit);
   processed_energy=zeros(1,num_crit);
   error_energy=zeros(1,num_crit);
   
   for i = 1:num_crit
      clean_energy(i) = sum(clean_spec(1:n_fftby2) ...
		            .*crit_filter(i,:)');
      processed_energy(i) = sum(processed_spec(1:n_fftby2) ...
			        .*crit_filter(i,:)');
      error_energy(i)=max((clean_energy(i)-processed_energy(i))^2,eps);
   end
   

   SNRlog=10*log10((clean_energy.^2)./error_energy);
   
   distortion(frame_count,:)=min(max(SNRlog,-10),35);
      
   start = start + skiprate;
     
end

