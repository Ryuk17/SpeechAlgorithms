function [CSIIh,CSIIm,CSIIl]= CSII(cleanFile, enhancedFile)
%-------------------------------------------------------------
% 
% Reference:
% [1] Kates, I.M.(2005). "Coherence and speech intelligibility index,"J.Acoust. Soc. Am. 117(4),2224-2237
% Use weight as (19) in JASA paper in CSII_h,CSII_m,CSII_low
%
% Copyright (c) 2012 
% Authors: Fei Chen and Philipos Loizou
% ----------------------------------------------------------------------

if nargin~=2
    fprintf('USAGE: [CSh, CSm, CSl]=CSII(cleanFile.wav, enhancedFile.wav)\n');
   
    return;
end


[data1, Srate1, Nbits1]= wavread(cleanFile);
[data2, Srate2, Nbits2]= wavread(enhancedFile);
if ( Srate1~= Srate2) | ( Nbits1~= Nbits2)
    error( 'The three files do not match!\n');
end

len= min(min(length( data1)), length( data2));
data1= data1( 1: len)+eps;
data2= data2( 1: len)+eps;

[vec_CSIIh,vec_CSIIm,vec_CSIIl]= fwseg_noise(data1, data2,Srate1);

CSIIh=mean(vec_CSIIh);
CSIIm=mean(vec_CSIIm);
CSIIl=mean(vec_CSIIl);

%plot(wss_dist_vec_noisy)

% ----------------------------------------------------------------------

function [distortionh,distortionm,distortionl] = fwseg_noise(clean_speech, processed_speech,sample_rate)


% ----------------------------------------------------------------------
% Check the length of the noisy, the clean and processed speech.  Must be the same.
% ----------------------------------------------------------------------


clean_length      = length(clean_speech);
processed_length  = length(processed_speech);

if  clean_length ~= processed_length
  disp('Error: Files  must have same length.');
  return
end

rms_all=norm(clean_speech)/sqrt(processed_length); %norm(processed_speech)/sqrt(processed_length);

% ----------------------------------------------------------------------
% Global Variables
global W;
global pex;
% W=4;pex=0.5;
W=0;
% ----------------------------------------------------------------------

slice_dur=16;   % 16ms
slice_num=6;

% winlength   = round(slice_dur*slice_num*sample_rate/1000); 	   % window length in samples
% skiprate    = floor(winlength/slice_num);		   % window skip in samples

winlength   = round(30*sample_rate/1000); 	   % window length in samples
skiprate    = floor(winlength/4);		   % window skip in samples

max_freq    = sample_rate/2;	   % maximum bandwidth
num_crit    = 16;		   % number of critical bands
USE_25=1;
n_fft       = 2^nextpow2(2*winlength);
n_fftby2    = n_fft/2;		   % FFT size/2
gamma=pex;  % power exponent

% ----------------------------------------------------------------------
% Critical Band Filter Definitions (Center Frequency and Bandwidths in Hz)
% ----------------------------------------------------------------------
cent_freq(1)  = 150.0000;   bandwidth(1)  = 100.0000;
cent_freq(2)  = 250.000;    bandwidth(2)  = 100.0000;
cent_freq(3)  = 350.000;    bandwidth(3)  = 100.0000;
cent_freq(4)  = 450.000;    bandwidth(4)  = 110.0000;
cent_freq(5)  = 570.000;    bandwidth(5)  = 120.0000;
cent_freq(6)  = 700.000;    bandwidth(6)  = 140.0000;
cent_freq(7)  = 840.000;    bandwidth(7)  = 150.0000;
cent_freq(8)  = 1000.000;   bandwidth(8)  = 160.000;
cent_freq(9)  = 1170.000;   bandwidth(9)  = 190.000;
cent_freq(10) = 1370.000;   bandwidth(10) = 210.000;
cent_freq(11) = 1600.000;   bandwidth(11) = 240.000;
cent_freq(12) = 1850.000;   bandwidth(12) = 280.000;
cent_freq(13) = 2150.000;   bandwidth(13) = 320.000;
cent_freq(14) = 2500.000;   bandwidth(14) = 380.000;
cent_freq(15) = 2900.000;   bandwidth(15) = 450.000;
cent_freq(16) = 3400.000;   bandwidth(16) = 550.000;
Weight=[
    0.0192
    0.0312
    0.0926
    0.1031
    0.0735
    0.0611
    0.0495
    0.044
    0.044
    0.049
    0.0486
    0.0493
    0.049
    0.0547
    0.0555
    0.0493];
% ----------------------------------------------------------------------
% Set up the critical band filters.  Note here that Gaussianly shaped
% filters are used.  Also, the sum of the filter weights are equivalent
% for each critical band filter.  Filter less than -30 dB and set to
% zero.
% ----------------------------------------------------------------------

b = bandwidth;
q = cent_freq/1000;
p = 4*1000*q./b;        % Eq. (7)
%15.625=4000/256
for i = 1:num_crit
       j = 0:1:n_fftby2-1;   
       g(i,:)=abs(1-j*(sample_rate/n_fft)/(q(i)*1000));% Eq. (9)
       crit_filter(i,:) = (1+p(i)*g(i,:)).*exp(-p(i)*g(i,:));% Eq. (8)
end



num_frames = clean_length/skiprate-(winlength/skiprate); % number of frames
start      = 1;					% starting sample
window     = 0.5*(1 - cos(2*pi*(1:winlength)'/(winlength+1)));

%--------------------------------------------------------------
%cal r2_high,r2_middle,r2_low
num_high     = zeros(n_fftby2,1); % initialize to zero array
denx_high    = zeros(n_fftby2,1); 
deny_high    = zeros(n_fftby2,1);
num_middle   = zeros(n_fftby2,1); 
denx_middle  = zeros(n_fftby2,1); 
deny_middle  = zeros(n_fftby2,1);
num_low     = zeros(n_fftby2,1); 
denx_low    = zeros(n_fftby2,1); 
deny_low    = zeros(n_fftby2,1);

for frame_count = 1:num_frames

   % ----------------------------------------------------------
   % (1) Get the Frames for the test and reference speech. 
   %     Multiply by Hanning Window.
   % ----------------------------------------------------------

   clean_frame       = clean_speech(start:start+winlength-1);
   processed_frame   = processed_speech(start:start+winlength-1);
   rms_seg           = norm(clean_frame)/sqrt(winlength); %norm(processed_frame)/sqrt(winlength);
   rms_db(frame_count)=20*log10(rms_seg/rms_all);   
   clean_frame       = clean_frame.*window;
   processed_frame   = processed_frame.*window;
    
       clean_spec     = fft(clean_frame,n_fft);
       processed_spec = fft(processed_frame,n_fft); 
       
       if rms_db(frame_count)>=0
           num_high  = num_high + clean_spec(1:n_fftby2).*conj(processed_spec(1:n_fftby2));  % Eq 4 in Kates (1992)
           denx_high = denx_high + abs(clean_spec(1:n_fftby2)).^2;
           deny_high = deny_high + abs(processed_spec(1:n_fftby2)).^2;
       end;
       if (rms_db(frame_count)>=-10)&&(rms_db(frame_count)<0)
           num_middle = num_middle + clean_spec(1:n_fftby2).*conj(processed_spec(1:n_fftby2));  % Eq 4 in Kates (1992)
           denx_middle = denx_middle + abs(clean_spec(1:n_fftby2)).^2;
           deny_middle = deny_middle + abs(processed_spec(1:n_fftby2)).^2;
       end;
       if rms_db(frame_count)<-10
           num_low  = num_low + clean_spec(1:n_fftby2).*conj(processed_spec(1:n_fftby2));  % Eq 4 in Kates (1992)
           denx_low = denx_low + abs(clean_spec(1:n_fftby2)).^2;
           deny_low = deny_low + abs(processed_spec(1:n_fftby2)).^2;
       end;
   
     start = start + skiprate;
     
end

num2_high = abs(num_high).^2;
r2_high = num2_high./(denx_high.*deny_high);

num2_middle = abs(num_middle).^2;
r2_middle = num2_middle./(denx_middle.*deny_middle);

num2_low = abs(num_low).^2;
r2_low = num2_low./(denx_low.*deny_low);
%--------------------------------------------------------------
% cal distortion frame by frame
start      = 1;
high=1;middle=1;low=1;
distortionh(high)=0;
distortionm(middle)=0;
distortionl(low)=0;

for frame_count = 1:num_frames

   % ----------------------------------------------------------
   % (1) Get the Frames for the test and reference speech. 
   %     Multiply by Hanning Window.
   % ----------------------------------------------------------

   clean_frame       = clean_speech(start:start+winlength-1);
   processed_frame   = processed_speech(start:start+winlength-1);
   clean_frame       = clean_frame.*window;
   processed_frame   = processed_frame.*window;
   

   % ----------------------------------------------------------
   % (2) Compute the magnitude Spectrum of Clean and Processed
   % ----------------------------------------------------------

    
       clean_spec     = abs(fft(clean_frame,n_fft));
       processed_spec = abs(fft(processed_frame,n_fft)); 
        

   % ----------------------------------------------------------
   % (3) Compute Filterbank Output Energies 
   % ----------------------------------------------------------
   
   clean_energy     = zeros(1,num_crit);
   processed_energy = zeros(1,num_crit);
   W_freq           = zeros(1,num_crit);
  
   %-------------------------------------------------------------------
   %cal the weights
   for i = 1:num_crit

       clean_energy(i)     = sum(clean_spec(1:n_fftby2) ...
           .*crit_filter(i,:)');
       switch W
           case 0,
               W_freq(i)=Weight(i);
       end
   end
   %------------------------------------
   %cal the distortionh,distortionm,distortionl separately
       if rms_db(frame_count)>=0
           for i = 1:num_crit
               processed_energy(i) = sum(abs(processed_spec(1:n_fftby2)).^2.*r2_high...
                   .*crit_filter(i,:)');
               de_processed_energy(i) =sum(abs(processed_spec(1:n_fftby2)).^2.*(1-r2_high)...
                   .*crit_filter(i,:)');
           end

           SDR = processed_energy./de_processed_energy;% Eq 13 in Kates (2005)

           SDRlog=10*log10(SDR);

           SDRlog_lim = min(max(SDRlog,-15),15);  % limit between [-15, 15]

           Tjm  = (SDRlog_lim+15)/30;
           AI   =  max(0,sum(W_freq.*Tjm)/sum(W_freq));

           distortionh(high)=AI; high=high+1;
       end;
       
       if (rms_db(frame_count)>=-10)&&(rms_db(frame_count)<0)
           for i = 1:num_crit
               processed_energy(i) = sum(abs(processed_spec(1:n_fftby2)).^2.*r2_middle...
                   .*crit_filter(i,:)');
               de_processed_energy(i) =sum(abs(processed_spec(1:n_fftby2)).^2.*(1-r2_middle)...
                   .*crit_filter(i,:)');
           end

           SDR = processed_energy./de_processed_energy;% Eq 13 in Kates (2005)

           SDRlog=10*log10(SDR);

           SDRlog_lim = min(max(SDRlog,-15),15);  % limit between [-15, 15]

           Tjm  = (SDRlog_lim+15)/30;
           AI   =  max(0,sum(W_freq.*Tjm)/sum(W_freq));
           distortionm(middle)=AI; middle=middle+1;
       end;
       
       if (rms_db(frame_count)<-10)
           for i = 1:num_crit
               processed_energy(i) = sum(abs(processed_spec(1:n_fftby2)).^2.*r2_low...
                   .*crit_filter(i,:)');
               de_processed_energy(i) =sum(abs(processed_spec(1:n_fftby2)).^2.*(1-r2_low)...
                   .*crit_filter(i,:)');
           end

           SDR = processed_energy./de_processed_energy;% Eq 13 in Kates (2005)

           SDRlog=10*log10(SDR);

           SDRlog_lim = min(max(SDRlog,-15),15);  % limit between [-15, 15]

           Tjm  = (SDRlog_lim+15)/30;
           AI   =  max(0,sum(W_freq.*Tjm)/sum(W_freq));
           distortionl(low)=AI; low=low+1;
       end;
   
 start = start + skiprate;
     
end

high;
middle;
low;
