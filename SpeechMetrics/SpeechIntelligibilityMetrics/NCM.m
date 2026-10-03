function ncm_val= NCM( c_f, n_f)
% Input:
% c_f: clean speech filename
% n_f: noisy or processed speech filename

% Output: NCM value
%
% Code implements the NCM intelligibility measure as described in [1,pp.3392-3393]:
%
% [1]  Ma, J., Hu, Y. and Loizou, P. (2009). "Objective measures for
%      predicting speech intelligibility in noisy conditions based on new band-importance
%      functions", Journal of the Acoustical Society of America, 125(5), 3387-3405.
%
%  Author: Fei Chen and Philipos C. Loizou
%  Date: Aug 22, 2011
%
% =====================================================

W=0;      % flag used for selecting the weights used in Eq. 11
pw=3;     % power exponent - see Eq. 12


[x_c, F_SIGNAL, nbits]= wavread( c_f);
[x_n, Nfs, nbits] = wavread( n_f);

if F_SIGNAL ~=Nfs
    error('Files dont have same sampling frequency.');
end

if F_SIGNAL~=8000 & F_SIGNAL~=16000
    error('Sampling frequency needs to be either 8000 or 16000 Hz');
end

x= x_c;  % clean signal
y= x_n;  % noisy signal

 
F_ENVELOPE  =   32; % limits modulations to 0<f<16 Hz      
M_CHANNELS  =   20;

%   DEFINE BAND EDGES
BAND	  =	Get_Band(M_CHANNELS, F_SIGNAL);


%   Interpolate the ANSI weights in WEIGHT @ fcenter
[fcenter,WEIGHT]=get_ANSIs(BAND);

%   NORMALIZE LENGTHS
Lx          =   length(x);
Ly          =   length(y);


if      Lx > Ly, x  = x(1:Ly); end; 
if      Ly > Lx, y  = y(1:Lx); end


%   DESIGN BANDPASS FILTERS
for a = 1:M_CHANNELS,
    [B_bp A_bp]         =	butter( 4 , [BAND(a) BAND(a+1)]*(2/F_SIGNAL) );
    X_BANDS( : , a )    =	filter( B_bp , A_bp , x );
    Y_BANDS( : , a )    =	filter( B_bp , A_bp , y );

end

%   CALCULATE HILBERT ENVELOPES, and resample at F_ENVELOPE Hz
analytic_x	    =	hilbert( X_BANDS );
X               =	abs( analytic_x );
X               =   resample( X , F_ENVELOPE , F_SIGNAL );
analytic_y	    =	hilbert( Y_BANDS );
Y               =	abs( analytic_y );
Y               =   resample( Y , F_ENVELOPE , F_SIGNAL );

%% ---compute weights based on clean signal's rms envelopes-----
%

[Ldx, pp]=size(X);
p=pw;
wghts=zeros(M_CHANNELS,1);
    switch W
    
        case 0,
            wghts=WEIGHT'; %ANSI weights 
        case 1,
            for i=1:M_CHANNELS
                wp=norm(X(:,i),2)/sqrt(Ldx);   
                wghts(i)=wp^p;  % (Eq.12)*2,p=1.5 in the paper should take p=3 here 
            end;
        otherwise,
            fprintf('input error: Unknown W');
    end;


%%
% --- Calculate normalized covariance ---

for k= 1: M_CHANNELS    
    x_tmp= X( :, k);
    y_tmp= Y( :, k);
    
    
    lambda_x= norm( x_tmp- mean( x_tmp))^2;
    lambda_y= norm( y_tmp- mean( y_tmp))^2; 
    lambda_xy= sum( (x_tmp- mean( x_tmp)).* ...
        (y_tmp- mean( y_tmp))); 
    ro2( k)= (lambda_xy^ 2)/ (lambda_x* lambda_y);
    
    asnr( k)= 10* log10( (ro2( k)+ eps)/ (1- ro2( k)+ eps)); % Eq.9 in [1]
      
        
        if asnr( k)< -15
            asnr( k)= -15;
        elseif asnr( k)> 15
            asnr( k)= 15;
        end
        TI( k)= (asnr( k)+ 15)/ 30;     % Eq.10 in [1]
          
end

%% 
ncm_val= wghts'*TI(:)/sum(wghts); %Eq.11

return;

%% ------------------------------------------------------------------------------
%
function BAND = Get_Band(M,Fs);
%   This function sets the bandpass filter band edges.
% It assumes that the sampling frequency is 8000 Hz.
%

A                   =   165;
a                   =   2.1;
K                   =   1;
L                   =   35;
CF = 300; 
x_100     =   (L/a)*log10(CF/A + K);
CF = Fs/2-600; 
x_8000   =   (L/a)*log10(CF/A + K);
LX                  =   x_8000 - x_100;
x_step              =   LX / M;
x                   =   [x_100:x_step:x_8000];
if length(x) == M, x(M+1) = x_8000; end
BAND                =   A*(10.^(a*x/L) - K);

%% ------------------------------------------------------------------------
% to determine the AI weights @ sampling rate 'Fs' and splited bands 'BAND'
function [fcenter,ANSIs]=get_ANSIs(BAND)
fcenter=(BAND(1:end-1)+BAND(2:end))/2;

%% Data from Table B.1 in "ANSI (1997). S3.5–1997 Methods for Calculation of the Speech Intelligibility
%% Index. New York: American National Standards Institute."
f=[150 250 350 450 570 700 840 1000 1170 1370 1600 1850 2150 2500 2900 3400 4000 4800 5800 7000 8500];
BIF=[0.0192 0.0312 0.0926 0.1031 0.0735 0.0611 0.0495 0.0440 0.0440 0.0490 0.0486 0.0493 0.0490 0.0547 0.0555 0.0493 0.0359 0.0387 0.0256 0.0219 0.0043];

ANSIs= interp1(f,BIF,fcenter);