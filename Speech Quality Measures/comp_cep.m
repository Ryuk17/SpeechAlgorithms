function cep_mean= comp_cep(cleanFile, enhdFile);

% ----------------------------------------------------------------------
%          Cepstrum Distance Objective Speech Quality Measure
%
%   This function implements the cepstrum distance measure used
%   in [1]
%
%   Usage:  CEP=comp_cep(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         CEP           - computed cepstrum distance measure
% 
%         Note that the cepstrum measure is limited in the range [0, 10].
%
%  Example call:  CEP =comp_cep('sp04.wav','enhanced.wav')
%
%  
%  References:
%
%     [1]	Kitawaki, N., Nagabuchi, H., and Itoh, K. (1988). Objective quality
%           evaluation for low bit-rate speech coding systems. IEEE J. Select.
%           Areas in Comm., 6(2), 262-273.
%
%  Author: Philipos C. Loizou 
%  (LPC routines were written by Bryan Pellom & John Hansen)
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $

% ----------------------------------------------------------------------
if nargin~=2
    fprintf('USAGE: CEP=comp_cep(cleanFile.wav, enhancedFile.wav)\n');
    fprintf('For more help, type: help comp_cep\n\n');
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

IS_dist= cepstrum( data1, data2,Srate1);

IS_len= round( length( IS_dist)* alpha);
IS= sort( IS_dist);

cep_mean= mean( IS( 1: IS_len)); 




function distortion = cepstrum(clean_speech, processed_speech,sample_rate)


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

winlength   = round(30*sample_rate/1000); %240;		   % window length in samples
skiprate    = floor(winlength/4);		   % window skip in samples
if sample_rate<10000
   P           = 10;		   % LPC Analysis Order
else
    P=16;     % this could vary depending on sampling frequency.
end
C=10*sqrt(2)/log(10);
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

  C_clean=lpc2cep(A_clean);
  C_processed=lpc2cep(A_processed);
  
   % ----------------------------------------------------------
   % (3) Compute the cepstrum-distance measure
   % ----------------------------------------------------------

  
   distortion(frame_count) = min(10,C*norm(C_clean-C_processed,2)); 
   

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

%----------------------------------------------
function [cep]=lpc2cep(a)
%
% converts prediction to cepstrum coefficients
%
% Author: Philipos C. Loizou

M=length(a);
cep=zeros(1,M-1);

cep(1)=-a(2);

for k=2:M-1
    ix=1:k-1;
    vec1=cep(ix).*a(k-1+1:-1:2).*ix;
    cep(k)=-(a(k+1)+sum(vec1)/k);
    
end



 

    

