function wss_dist= comp_wss(cleanFile, enhancedFile);
% ----------------------------------------------------------------------
%
%     Weighted Spectral Slope (WSS) Objective Speech Quality Measure
%
%     This function implements the Weighted Spectral Slope (WSS)
%     distance measure originally proposed in [1].  The algorithm
%     works by first decomposing the speech signal into a set of
%     frequency bands (this is done for both the test and reference
%     frame).  The intensities within each critical band are 
%     measured.  Then, a weighted distances between the measured
%     slopes of the log-critical band spectra are computed.  
%     This measure is also described in Section 2.2.9 (pages 56-58)
%     of [2].
%
%     Whereas Klatt's original measure used 36 critical-band 
%     filters to estimate the smoothed short-time spectrum, this
%     implementation considers a bank of 25 filters spanning 
%     the 4 kHz bandwidth.  
%
%   Usage:  wss_dist=comp_wss(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         wss_dist      - computed spectral slope distance
%
%  Example call:  ws =comp_wss('sp04.wav','enhanced.wav')
%
%  References:
%
%     [1] D. H. Klatt, "Prediction of Perceived Phonetic Distance
%	    from Critical-Band Spectra: A First Step", Proc. IEEE
%	    ICASSP'82, Volume 2, pp. 1278-1281, May, 1982.
%
%     [2] S. R. Quackenbush, T. P. Barnwell, and M. A. Clements,
%	    Objective Measures of Speech Quality.  Prentice Hall
%	    Advanced Reference Series, Englewood Cliffs, NJ, 1988,
%	    ISBN: 0-13-629056-6.
%
%  Authors: Bryan L. Pellom and John H. L. Hansen (July 1998)
%  Modified by: Philipos C. Loizou  (Oct 2006)
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
%
% ----------------------------------------------------------------------
if nargin~=2
    fprintf('USAGE: WSS=comp_wss(cleanFile.wav, enhancedFile.wav)\n');
    fprintf('For more help, type: help comp_wss\n\n');
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

wss_dist_vec= wss( data1, data2,Srate1);
wss_dist_vec= sort( wss_dist_vec);
wss_dist= mean( wss_dist_vec( 1: round( length( wss_dist_vec)*alpha)));



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

winlength   = round(30*sample_rate/1000); 	   % window length in samples
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

