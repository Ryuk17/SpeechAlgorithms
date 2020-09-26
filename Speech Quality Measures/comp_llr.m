function llr_mean= comp_llr(cleanFile, enhancedFile);

% ----------------------------------------------------------------------
%
%      Log Likelihood Ratio (LLR) Objective Speech Quality Measure
%
%
%     This function implements the Log Likelihood Ratio Measure
%     defined on page 48 of [1] (see Equation 2.18).
%
%   Usage:  llr=comp_llr(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         llr           - computed likelihood ratio
%
%         Note that the LLR measure is limited in the range [0, 2].
%
%  Example call:  llr =comp_llr('sp04.wav','enhanced.wav')
%
%
%  References:
%
%     [1] S. R. Quackenbush, T. P. Barnwell, and M. A. Clements,
%	    Objective Measures of Speech Quality.  Prentice Hall
%	    Advanced Reference Series, Englewood Cliffs, NJ, 1988,
%	    ISBN: 0-13-629056-6.
%
%  Authors: Bryan L. Pellom and John H. L. Hansen (July 1998)
%  Modified by: Philipos C. Loizou  (Oct 2006) - limited LLR to be in [0,2]
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
% ----------------------------------------------------------------------

if nargin~=2
    fprintf('USAGE: LLR=comp_llr(cleanFile.wav, enhancedFile.wav)\n');
    fprintf('For more help, type: help comp_llr\n\n');
    return;
end

alpha=0.95;
[data1, Srate1, Nbits1]= wavread(cleanFile);
[data2, Srate2, Nbits2]= wavread(enhancedFile);
if ( Srate1~= Srate2) | ( Nbits1~= Nbits2)
    error( 'The two files do not match!\n');
end
    
len= min( length( data1), length( data2));
data1= data1( 1: len)+eps;
data2= data2( 1: len)+eps;

IS_dist= llr( data1, data2,Srate1);

IS_len= round( length( IS_dist)* alpha);
IS= sort( IS_dist);

llr_mean= mean( IS( 1: IS_len));



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

winlength   = round(30*sample_rate/1000); %240;		   % window length in samples
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
   distortion(frame_count) = min(2,log(numerator/denominator));
   start = start + skiprate;

end


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



