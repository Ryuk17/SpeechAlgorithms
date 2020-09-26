function [snr_mean, segsnr_mean]= comp_SNR(cleanFile, enhdFile);
%
%   Segmental Signal-to-Noise Ratio Objective Speech Quality Measure
%
%     This function implements the segmental signal-to-noise ratio
%     as defined in [1, p. 45] (see Equation 2.12).
%
%   Usage:  [SNRovl, SNRseg]=comp_snr(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         SNRovl        - overall SNR (dB)
%         SNRseg        - segmental SNR (dB)
%
%     This function returns 2 parameters.  The first item is the
%     overall SNR for the two speech signals.  The second value
%     is the segmental signal-to-noise ratio (1 seg-snr per 
%     frame of input).  The segmental SNR is clamped to range 
%     between 35dB and -10dB (see suggestions in [2]).
%
%   Example call:  [SNRovl,SNRseg]=comp_SNR('sp04.wav','enhanced.wav')
%
%  References:
%
%     [1] S. R. Quackenbush, T. P. Barnwell, and M. A. Clements,
%	    Objective Measures of Speech Quality.  Prentice Hall
%	    Advanced Reference Series, Englewood Cliffs, NJ, 1988,
%	    ISBN: 0-13-629056-6.
%
%     [2] P. E. Papamichalis, Practical Approaches to Speech 
%	    Coding, Prentice-Hall, Englewood Cliffs, NJ, 1987.
%	    ISBN: 0-13-689019-9. (see pages 179-181).
%
%  Authors: Bryan L. Pellom and John H. L. Hansen (July 1998)
%  Modified by: Philipos C. Loizou  (Oct 2006)
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
%-------------------------------------------------------------------------

if nargin ~=2
    fprintf('USAGE: [snr_mean, segsnr_mean]= comp_SNR(cleanFile, enhdFile) \n');
    return;
end   

[data1, Srate1, Nbits1]= wavread(cleanFile);
[data2, Srate2, Nbits2]= wavread(enhdFile);
if (( Srate1~= Srate2) | ( Nbits1~= Nbits2))
    error( 'The two files do not match!\n');
end
  
len= min( length( data1), length( data2));
data1= data1( 1: len);
data2= data2( 1: len);

[snr_dist, segsnr_dist]= snr( data1, data2,Srate1);

snr_mean= snr_dist;
segsnr_mean= mean( segsnr_dist);


% =========================================================================
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


winlength   = round(30*sample_rate/1000); %240;		   % window length in samples for 30-msecs
skiprate    = floor(winlength/4); %60;		   % window skip in samples
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

