function addnoise_asl(cleanfile, noisefile, outfile, snr) 
% ----------------------------------------------------------------------
%   This function adds noise to a file at a specified SNR level. It uses
%   the active speech level to compute the speech energy. The
%   active speech level is computed as per ITU-T P.56 standard [1].
%
%   Usage:  addnoise_asl(cleanFile.wav, noiseFile.wav, noisyFile.wav, SNR)
%           
%         cleanFile.wav  - clean input file in .wav format
%         noiseFile.wav  - file containing the noise signal in .wav format
%         noisyFile.wav  - resulting noisy file
%         SNR            - desired SNR in dB
%
%   Note that if the variable IRS below (line 38) is set to 1, then it applies the IRS
%   filter to bandlimit the signal to 300 Hz - 3.2 kHz. The default IRS
%   value is 0, ie, no IRS filtering is applied.
%
%  Example call:
%       addnoise_asl('sp04.wav','white_noise.wav','sp04_white_5db.wav',5);
%
%  
%  References:
%   [1] ITU-T (1993). Objective measurement of active speech level. ITU-T 
%       Recommendation P. 56
%
%   Author: Yi Hu and Philipos C. Loizou 
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
% ----------------------------------------------------------------------

if nargin ~=4
    fprintf('USAGE: addnoise_asl(cleanFile.wav, noiseFile.wav, noisyFile.wav, SNR) \n');
    fprintf('For more help, type: help addnoise_asl\n\n');
    return;
end

IRS=0;  % if 1 apply IRS filter simulating telephone handset bandwidth (300 Hz -3.2 kHz)

% wavread gives floating point column data
[clean, srate, nbits]= wavread(cleanfile); 
% filter clean speech with irs filter
if IRS==1, clean= apply_IRS( clean, srate, nbits); end;

[Px, asl, c0]= asl_P56 ( clean, srate, nbits); 
% Px is the active speech level ms energy, asl is the active factor, and c0
% is the active speech level threshold. 


x=clean;
x_len= length( x); % length of speech signal

[noise, srate1, nbits1]= wavread( noisefile);
if (srate1~= srate)| (nbits1~= nbits)
    error( 'the formats of the two files dont match!');
end
noise_len= length( noise);
if (noise_len<= x_len)
    error( 'the noise length has to be greater than speech length!');
end

rand_start_limit= noise_len- x_len+ 1; 
% the start of the noise segment can vary between [1 rand_start_limit]
rand_start= round( (rand_start_limit- 1)* rand( 1)+ 1); 
% random start of the noise segment 
noise_segment= noise( rand_start: rand_start+ x_len- 1);

if IRS==1, noise_segment= apply_IRS( noise_segment, srate, nbits); end;

% this is the randomly selected noise segment that will be added to the
% clean speech x
Pn= noise_segment'* noise_segment/ x_len;
% we need to scale the noise segment samples to obtain the desired snr= 10*
% log10( Px/ (sf^2 * Pn))
sf= sqrt( Px/Pn/ (10^ (snr/ 10))); % scale factor for noise segment data
noise_segment= noise_segment * sf; 

noisy = x+ noise_segment;  

if ( (max( noisy)>= 1) | (min( noisy)< -1))
    error( 'Overflow occurred!\n');
end;


wavwrite( noisy, srate, nbits, outfile);

fprintf( 1, '\n NOTE: For comparison, the SNR based on long-term RMS level is %4.2f dB.\n\n', 10*log10((x'*x)/ ...
     (noise_segment'*noise_segment)));


%------------------------------------------------------------------------
function data_filtered= apply_IRS( data, Fs, nbits);

n= length( data);

% now find the next power of 2 which is greater or equal to n
pow_of_2= 2^ (ceil( log2( n)));

align_filter_dB= [0, -200; 50, -40; 100, -20; 125, -12; 160, -6; 200, 0;...    
    250, 4; 300, 6; 350, 8; 400, 10; 500, 11; 600, 12; 700, 12; 800, 12;...
    1000, 12; 1300, 12; 1600, 12; 2000, 12; 2500, 12; 3000, 12; 3250, 12;...
    3500, 4; 4000, -200; 5000, -200; 6300, -200; 8000, -200]; 

[number_of_points, trivial]= size( align_filter_dB);
overallGainFilter= interp1( align_filter_dB( :, 1), align_filter_dB( :, 2), ...
    1000);

x= zeros( 1, pow_of_2);
x( 1: n)= data;

x_fft= fft( x, pow_of_2);

freq_resolution= Fs/ pow_of_2;

factorDb( 1: pow_of_2/2+ 1)= interp1( align_filter_dB( :, 1), ...
    align_filter_dB( :, 2), (0: pow_of_2/2)* freq_resolution)- ...
    overallGainFilter;
factor= 10.^ (factorDb/ 20);

factor= [factor, fliplr( factor( 2: pow_of_2/2))];
x_fft= x_fft.* factor;

y= ifft( x_fft, pow_of_2);

data_filtered= y( 1: n)';



function [asl_ms, asl, c0]= asl_P56 ( x, fs, nbits)
% this implements ITU P.56 method B. 
% 'speechfile' is the speech file to calculate active speech level for,
% 'asl' is the active speech level (between 0 and 1),
% 'asl_rms' is the active speech level mean square energy.

% x is the column vector of floating point speech data

x= x(:); % make sure x is column vector
T= 0.03; % time constant of smoothing, in seconds
H= 0.2; % hangover time in seconds
M= 15.9; 
% margin in dB of the difference between threshold and active speech level
thres_no= nbits- 1; % number of thresholds, for 16 bit, it's 15

I= ceil( fs* H); % hangover in samples
g= exp( -1/( fs* T)); % smoothing factor in envelop detection
c( 1: thres_no)= 2.^ (-15: thres_no- 16); 
% vector with thresholds from one quantizing level up to half the maximum
% code, at a step of 2, in the case of 16bit samples, from 2^-15 to 0.5; 
a( 1: thres_no)= 0; % activity counter for each level threshold
hang( 1: thres_no)= I; % hangover counter for each level threshold

sq= x'* x; % long-term level square energy of x
x_len= length( x); % length of x

% use a 2nd order IIR filter to detect the envelope q
x_abs= abs( x); 
p= filter( 1-g, [1 -g], x_abs); 
q= filter( 1-g, [1 -g], p);

for k= 1: x_len
    for j= 1: thres_no
        if (q(k)>= c(j))
            a(j)= a(j)+ 1;
            hang(j)= 0;
        elseif (hang(j)< I)
            a(j)= a(j)+ 1;
            hang(j)= hang(j)+ 1;
        else
            break;
        end
    end
end

asl= 0; 
asl_rms= 0; 
if (a(1)== 0)
    return;
else
    AdB1= 10* log10( sq/ a(1)+ eps);
end

CdB1= 20* log10( c(1)+ eps);
if (AdB1- CdB1< M)
    return;
end

AdB(1)= AdB1; 
CdB(1)= CdB1;
Delta(1)= AdB1- CdB1;

for j= 2: thres_no
    AdB(j)= 10* log10( sq/ (a(j)+ eps)+ eps);
    CdB(j)= 20* log10( c(j)+ eps);
end

for j= 2: thres_no    
    if (a(j) ~= 0)       
        Delta(j)= AdB(j)- CdB(j);        
        if (Delta(j)<= M) 
            % interpolate to find the asl
            [asl_ms_log, cl0]= bin_interp( AdB(j), ...
                AdB(j-1), CdB(j), CdB(j-1), M, 0.5);
            asl_ms= 10^ (asl_ms_log/ 10);
            asl= (sq/ x_len)/ asl_ms;  
            c0= 10^( cl0/ 20);            
            break;
        end        
    end
end




function [asl_ms_log, cc]= bin_interp(upcount, lwcount, ...
    upthr, lwthr, Margin, tol)

if (tol < 0)
    tol = -tol;
end

% Check if extreme counts are not already the true active value
iterno = 1;
if (abs(upcount - upthr - Margin) < tol)
    asl_ms_log= upcount;
    cc= upthr;
    return;
end
if (abs(lwcount - lwthr - Margin) < tol)
    asl_ms_log= lwcount;
    cc= lwthr;
    return;
end

% Initialize first middle for given (initial) bounds 
midcount = (upcount + lwcount) / 2.0;
midthr = (upthr + lwthr) / 2.0;

% Repeats loop until `diff' falls inside the tolerance (-tol<=diff<=tol)
while ( 1) 
    
    diff= midcount- midthr- Margin;
    if (abs(diff)<= tol)
        break;
    end
    
    % if tolerance is not met up to 20 iteractions, then relax the
    % tolerance by 10%
    
    iterno= iterno+ 1; 
    
    if (iterno>20) 
      tol = tol* 1.1; 
    end

    if (diff> tol)   % then new bounds are ...     
        midcount = (upcount + midcount) / 2.0; 
        % upper and middle activities 
        midthr = (upthr + midthr) / 2.0;	  
        % ... and thresholds     
    elseif (diff< -tol)	% then new bounds are ... 
        midcount = (midcount + lwcount) / 2.0; 
        % middle and lower activities 
        midthr = (midthr + lwthr) / 2.0;   
        % ... and thresholds 
    end    
    
end
%   Since the tolerance has been satisfied, midcount is selected 
%   as the interpolated value with a tol [dB] tolerance.

asl_ms_log= midcount;
cc= midthr;




