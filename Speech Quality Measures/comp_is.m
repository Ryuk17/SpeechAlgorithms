function is_mean= comp_is(cleanFile, enhdFile);
% ----------------------------------------------------------------------
%          Itakura-Saito (IS) Objective Speech Quality Measure
%
%   This function implements the Itakura-Saito distance measure
%   defined on page 50 of [1] (see Equation 2.26).  See also
%   Equation 12 (page 1480) of [2].
%
%   Usage:  IS=comp_is(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         IS            - computed Itakura Saito measure
% 
%         Note that the IS measure is limited in the range [0, 100].
%
%  Example call:  IS =comp_is('sp04.wav','enhanced.wav')
%
%  
%  References:
%
%     [1] S. R. Quackenbush, T. P. Barnwell, and M. A. Clements,
%	    Objective Measures of Speech Quality.  Prentice Hall
%	    Advanced Reference Series, Englewood Cliffs, NJ, 1988,
%	    ISBN: 0-13-629056-6.
%
%     [2] B.-H. Juang, "On Using the Itakura-Saito Measures for
%           Speech Coder Performance Evaluation", AT&T Bell
%  	    Laboratories Technical Journal, Vol. 63, No. 8,
%	    October 1984, pp. 1477-1498.
%
%  Authors: Bryan L. Pellom and John H. L. Hansen (July 1998)
%  Modified by: Philipos C. Loizou  (Oct 2006) - limited IS to be in [0,100]
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $

% ----------------------------------------------------------------------

if nargin~=2
    fprintf('USAGE: IS=comp_is(cleanFile.wav, enhancedFile.wav)\n');
    fprintf('For more help, type: help comp_is\n\n');
    return;
end

alpha=0.95;

[data1, Srate1, Nbits1]= wavread(cleanFile);
[data2, Srate2, Nbits2]= wavread(enhdFile);
if ( Srate1~= Srate2) | ( Nbits1~= Nbits2)
    error( 'The two files do not match!\n');
end
    
len= min( length( data1), length( data2));
data1= data1( 1: len)+eps;
data2= data2( 1: len)+eps;


IS_dist= is( data1, data2,Srate1);

IS_len= round( length( IS_dist)* alpha);
IS= sort( IS_dist);

is_mean= mean( IS( 1: IS_len));



function distortion = is(clean_speech, processed_speech,sample_rate)


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

% ----------------------------------------------------------------------
% Global Variables
% ----------------------------------------------------------------------

%sample_rate = 8000;		   % default sample rate
winlength   = round(30*sample_rate/1000); %240;		   % window length in samples
skiprate    = floor(winlength/4);		   % window skip in samples
if sample_rate<10000
   P           = 10;		   % LPC Analysis Order
else
    P=16;     % this could vary depending on sampling frequency.
end
% ----------------------------------------------------------------------
% For each frame of input speech, calculate the Itakura-Saito Measure
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
   %     to compute the IS measure.
   % ----------------------------------------------------------

   [R_clean, Ref_clean, A_clean] = ...
      lpcoeff(clean_frame, P);
   [R_processed, Ref_processed, A_processed] = ...
      lpcoeff(processed_frame, P);

  
   % ----------------------------------------------------------
   % (3) Compute the IS measure
   % ----------------------------------------------------------

   numerator      = A_processed*toeplitz(R_clean)*A_processed';
   denominator    = max(A_clean*toeplitz(R_clean)*A_clean',eps);
   gain_clean     = max(R_clean*A_clean',eps);	      % this is gain
   gain_processed = max(R_processed*A_processed',eps); % squared (sigma^2)

   
     ISvalue=(gain_clean/gain_processed)*(numerator/denominator) + ...
      log(gain_processed/gain_clean)-1; 

  distortion(frame_count) = min(ISvalue,100);
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



