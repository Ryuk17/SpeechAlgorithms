function [SIG,BAK,OVL]= comp_fwseg_mars(cleanFile, enhancedFile);

% ----------------------------------------------------------------------
%      MARS Frequency-variant fwSNRseg objective speech quality measure
%
%   This function implements the frequency-variant fwSNRseg measure based
%   on MARS analysis (see Chap. 10, Sec. 10.5.4)
%
%
%   Usage:  [sig,bak,ovl]=comp_fwseg_mars(cleanFile.wav, enhancedFile.wav)
%           
%         cleanFile.wav - clean input file in .wav format
%         enhancedFile  - enhanced output file in .wav format
%         sig           - predicted rating [1-5] of speech distortion
%         bak           - predicted rating [1-5] of noise distortion
%         ovl           - predicted rating [1-5] of overall quality
%
%
%  Example call:  [s,b,o] =comp_fwseg_mars('sp04.wav','enhanced.wav')
%
%  
%  References:
%    [1] Chapter 10, Sec 10.5.4,
%    [2] Chapter 11
%
%   Authors: Yi Hu and Philipos C. Loizou 
%  (critical-band filtering routines were written by Bryan Pellom & John Hansen)
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
% ----------------------------------------------------------------------

if nargin~=2
    fprintf('USAGE: [sig,bak,ovl]=comp_fwseg_mars(cleanFile.wav, enhancedFile.wav)\n');
    fprintf('For more help, type: help comp_fwseg_mars\n\n');
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


SIG= sig_mars( wss_dist( 1), wss_dist( 2), wss_dist( 3), wss_dist( 4), ...
    wss_dist( 5), wss_dist( 6), wss_dist( 7), wss_dist( 8), ...
    wss_dist( 9), wss_dist( 10), wss_dist( 11), wss_dist( 12), ...
    wss_dist( 13), wss_dist( 14), wss_dist( 15), wss_dist( 16), ...
    wss_dist( 17), wss_dist( 18), wss_dist( 19), wss_dist( 20), ...
    wss_dist( 21), wss_dist( 22), wss_dist( 23), wss_dist( 24), ...
    wss_dist( 25));
SIG=max(1,SIG); SIG=min(5, SIG); % limit values to [1, 5]

BAK= bak_mars( wss_dist( 1), wss_dist( 2), wss_dist( 3), wss_dist( 4), ...
    wss_dist( 5), wss_dist( 6), wss_dist( 7), wss_dist( 8), ...
    wss_dist( 9), wss_dist( 10), wss_dist( 11), wss_dist( 12), ...
    wss_dist( 13), wss_dist( 14), wss_dist( 15), wss_dist( 16), ...
    wss_dist( 17), wss_dist( 18), wss_dist( 19), wss_dist( 20), ...
    wss_dist( 21), wss_dist( 22), wss_dist( 23), wss_dist( 24), ...
    wss_dist( 25));
BAK=max(1,BAK); BAK=min(5, BAK); % limit values to [1, 5]

OVL= ovl_mars( wss_dist( 1), wss_dist( 2), wss_dist( 3), wss_dist( 4), ...
    wss_dist( 5), wss_dist( 6), wss_dist( 7), wss_dist( 8), ...
    wss_dist( 9), wss_dist( 10), wss_dist( 11), wss_dist( 12), ...
    wss_dist( 13), wss_dist( 14), wss_dist( 15), wss_dist( 16), ...
    wss_dist( 17), wss_dist( 18), wss_dist( 19), wss_dist( 20), ...
    wss_dist( 21), wss_dist( 22), wss_dist( 23), wss_dist( 24), ...
    wss_dist( 25));
OVL=max(1,OVL); OVL=min(5, OVL); % limit values to [1, 5]


%-------------------------------------------------
function Y= bak_mars( FWSEG_VA, V5, V6, V7, V8, V9, V10, V11, V12, ...
    V13, V14, V15, V16, V17, V18, V19, V20, ...
    V21, V22, V23, V24, V25, V26, V27, V28)

BF1 = max(0, V21 - 0.282);
BF2 = max(0, FWSEG_VA + 9.094);
BF3 = max(0, - 9.094 - FWSEG_VA );
BF5 = max(0, 10.089 - V11 );
BF7 = max(0, 3.624 - V26 ) * BF3;
BF8 = max(0, V24 - 5.584) * BF5;
BF9 = max(0, 5.584 - V24 ) * BF5;
BF10 = max(0, V19 - 8.030) * BF1;
BF11 = max(0, 8.030 - V19 ) * BF1;
BF12 = max(0, V27 - 4.858) * BF1;
BF13 = max(0, 4.858 - V27 ) * BF1;
BF14 = max(0, FWSEG_VA + 7.282) * BF1;
BF15 = max(0, - 7.282 - FWSEG_VA ) * BF1;
BF17 = max(0, 9.458 - V16 ) * BF10;
BF18 = max(0, V27 - 10.431) * BF11;
BF19 = max(0, 10.431 - V27 ) * BF11;
BF21 = max(0, 11.059 - V22 ) * BF1;
BF22 = max(0, V26 - 8.675) * BF1;
BF23 = max(0, 8.675 - V26 ) * BF1;
BF25 = max(0, 11.195 - V6 ) * BF10;
BF26 = max(0, V8 - 7.138) * BF1;
BF27 = max(0, 7.138 - V8 ) * BF1;
BF29 = max(0, 9.006 - V10 ) * BF26;
BF30 = max(0, V14 - 8.210) * BF15;
BF35 = max(0, 7.026 - V19 ) * BF15;
BF36 = max(0, V11 - 3.424) * BF27;
BF39 = max(0, 5.418 - V17 ) * BF23;
BF40 = max(0, V28 - 6.813);
BF41 = max(0, 6.813 - V28 );
BF42 = max(0, V26 - 5.998) * BF14;
BF43 = max(0, 5.998 - V26 ) * BF14;
BF44 = max(0, V5 + 0.206) * BF41;
BF45 = max(0, - 0.206 - V5 ) * BF41;
BF46 = max(0, V22 - 7.901) * BF45;
BF49 = max(0, 7.496 - V8 ) * BF44;
BF51 = max(0, 7.904 - V11 ) * BF45;
BF52 = max(0, V26 - 10.938) * BF27;
BF54 = max(0, V9 - 4.507) * BF26;
BF56 = max(0, V28 - 0.549) * BF15;
BF57 = max(0, 0.549 - V28 ) * BF15;
BF58 = max(0, V25 - 3.252) * BF41;
BF59 = max(0, 3.252 - V25 ) * BF41;
BF60 = max(0, V23 - 7.650) * BF58;
BF61 = max(0, 7.650 - V23 ) * BF58;
BF62 = max(0, V25 - 9.931) * BF44;
BF63 = max(0, 9.931 - V25 ) * BF44;
BF64 = max(0, V25 - 4.923) * BF21;
BF65 = max(0, 4.923 - V25 ) * BF21;
BF67 = max(0, 3.746 - V28 ) * BF10;
BF68 = max(0, V11 - 5.346) * BF41;
BF69 = max(0, 5.346 - V11 ) * BF41;
BF70 = max(0, V12 - 9.026) * BF68;
BF71 = max(0, 9.026 - V12 ) * BF68;
BF73 = max(0, - 2.668 - V28 ) * BF21;
BF74 = max(0, V24 - 7.028) * BF41;
BF75 = max(0, 7.028 - V24 ) * BF41;
BF77 = max(0, - 0.224 - V6 ) * BF74;
BF78 = max(0, V5 - 3.884);
BF79 = max(0, 3.884 - V5 );
BF80 = max(0, V15 - 5.019) * BF78;
BF83 = max(0, - 1.880 - V28 ) * BF13;
BF84 = max(0, V7 - 3.067) * BF12;
BF85 = max(0, 3.067 - V7 ) * BF12;
BF87 = max(0, 5.353 - V6 );
BF88 = max(0, V13 - 3.405) * BF9;
BF89 = max(0, 3.405 - V13 ) * BF9;
BF91 = max(0, 5.599 - V13 ) * BF45;
BF92 = max(0, V15 - 9.821) * BF8;
BF94 = max(0, V14 + 2.594) * BF79;
BF97 = max(0, 8.635 - V23 ) * BF94;
BF99 = max(0, 1.332 - V24 ) * BF45;
BF100 = max(0, V7 - 0.209) * BF1;

Y = 2.751 + 0.135 * BF1 - 0.037 * BF2 + 0.328 * BF3 - 0.098 * BF5 ...
    + 0.988 * BF7 + 0.014 * BF8 - 0.034 * BF11 - 0.011 * BF12 ...
    - 0.013 * BF13 - 0.002 * BF17 + 0.014 * BF18 ...
    + 0.004 * BF19 - 0.007 * BF21 - 0.017 * BF22 ...
    - .895791E-03 * BF25 + 0.011 * BF26 - 0.009 * BF27 ...
    - 0.007 * BF29 + 0.052 * BF30 + 0.022 * BF35 ...
    - 0.002 * BF36 - 0.005 * BF39 - 0.059 * BF40 ...
    - 0.050 * BF41 + 0.001 * BF42 + .743730E-03 * BF43 ...
    + 0.011 * BF44 + 0.022 * BF45 + 0.009 * BF46 ...
    + 0.004 * BF49 - 0.005 * BF51 + 0.010 * BF52 ...
    - 0.001 * BF54 - 0.005 * BF56 - 0.015 * BF57 ...
    - 0.032 * BF59 + 0.009 * BF60 - 0.002 * BF61 ...
    - 0.009 * BF62 - 0.001 * BF63 + .819374E-03 * BF64 ...
    + 0.002 * BF65 + 0.003 * BF67 + 0.024 * BF69 ...
    - 0.011 * BF70 - 0.004 * BF71 + 0.013 * BF73 ...
    - 0.026 * BF74 + 0.005 * BF75 + 0.253 * BF77 ...
    - 0.065 * BF78 + 0.014 * BF80 - 0.010 * BF83 ...
    + 0.001 * BF84 + 0.018 * BF85 - 0.050 * BF87 ...
    - 0.002 * BF88 - 0.020 * BF89 + 0.003 * BF91 ...
    - 0.043 * BF92 + .707581E-03 * BF97 - 0.015 * BF99 ...
    - 0.005 * BF100;


function Y= sig_mars( FWSEG_VA, V5, V6, V7, V8, V9, V10, V11, V12, ...
    V13, V14, V15, V16, V17, V18, V19, V20, ...
    V21, V22, V23, V24, V25, V26, V27, V28)

BF1 = max(0, V7 - 9.535);
BF2 = max(0, 9.535 - V7 );
BF3 = max(0, V27 - 1.578);
BF5 = max(0, V6 - 5.422);
BF6 = max(0, 5.422 - V6 );
BF8 = max(0, 11.333 - V19 );
BF10 = max(0, - 6.774 - FWSEG_VA );
BF11 = max(0, V10 - 6.255) * BF8;
BF12 = max(0, 6.255 - V10 ) * BF8;
BF13 = max(0, V24 - 3.894);
BF15 = max(0, V5 - 3.884);
BF16 = max(0, 3.884 - V5 );
BF17 = max(0, V28 - 7.918);
BF18 = max(0, 7.918 - V28 );
BF19 = max(0, V13 - 6.077) * BF18;
BF20 = max(0, 6.077 - V13 ) * BF18;
BF22 = max(0, 6.614 - V20 ) * BF10;
BF23 = max(0, FWSEG_VA + 0.936) * BF8;
BF25 = max(0, V23 - 5.039);
BF26 = max(0, 5.039 - V23 );
BF28 = max(0, 9.007 - V20 ) * BF25;
BF29 = max(0, V25 - 7.582);
BF30 = max(0, 7.582 - V25 );
BF31 = max(0, V11 + 3.336) * BF16;
BF32 = max(0, V26 - 1.877);
BF35 = max(0, - 5.749 - FWSEG_VA ) * BF6;
BF36 = max(0, V7 - 4.451) * BF29;
BF37 = max(0, 4.451 - V7 ) * BF29;
BF38 = max(0, V14 - 10.158);
BF39 = max(0, 10.158 - V14 );
BF41 = max(0, 7.172 - V17 ) * BF39;
BF43 = max(0, 7.810 - V24 ) * BF26;
BF44 = max(0, V8 + 1.636) * BF3;
BF45 = max(0, FWSEG_VA - 10.068) * BF39;
BF47 = max(0, V23 - 4.721) * BF30;
BF48 = max(0, 4.721 - V23 ) * BF30;
BF50 = max(0, - 2.397 - V24 ) * BF16;
BF51 = max(0, V14 - 1.428) * BF17;
BF53 = max(0, V16 + 1.940) * BF18;
BF54 = max(0, V10 - 9.442) * BF18;
BF56 = max(0, V10 + 2.144) * BF16;
BF58 = max(0, 1.969 - V26 ) * BF2;
BF59 = max(0, V19 - 6.089) * BF16;
BF62 = max(0, 8.952 - V21 ) * BF15;
BF63 = max(0, V24 - 7.371) * BF3;
BF65 = max(0, V22 - 8.908) * BF6;
BF66 = max(0, 8.908 - V22 ) * BF6;
BF67 = max(0, V27 - 9.485) * BF30;
BF69 = max(0, V18 - 8.608) * BF10;
BF71 = max(0, V13 - 3.374) * BF25;
BF73 = max(0, V14 - 3.616) * BF13;
BF75 = max(0, V18 - 10.321) * BF32;
BF76 = max(0, 10.321 - V18 ) * BF32;
BF78 = max(0, 3.972 - V15 ) * BF26;
BF79 = max(0, V14 - 7.105) * BF26;
BF80 = max(0, 7.105 - V14 ) * BF26;

Y = 2.638 - 0.089 * BF1 + 0.083 * BF5 - 0.162 * BF6 - 0.037 * BF8 ...
    - 0.241 * BF10 + 0.018 * BF11 - 0.008 * BF12 ...
    + 0.059 * BF13 - 0.144 * BF17 - 0.116 * BF18 ...
    + 0.010 * BF19 - 0.012 * BF20 + 0.085 * BF22 ...
    + 0.011 * BF23 + 0.049 * BF25 - 0.159 * BF26 ...
    - 0.016 * BF28 - 0.138 * BF29 + 0.010 * BF31 ...
    + 0.016 * BF35 + 0.018 * BF36 + 0.246 * BF37 ...
    - 0.417 * BF38 + 0.052 * BF39 - 0.005 * BF41 ...
    + 0.021 * BF43 + 0.006 * BF44 - 0.047 * BF45 ...
    - 0.051 * BF47 - 0.014 * BF48 - 0.113 * BF50 ...
    + 0.019 * BF51 + 0.007 * BF53 + 0.017 * BF54 ...
    - 0.007 * BF56 - 0.098 * BF58 + 0.011 * BF59 ...
    - 0.016 * BF62 - 0.012 * BF63 + 0.113 * BF65 ...
    + 0.016 * BF66 + 0.040 * BF67 - 0.065 * BF69 ...
    - 0.018 * BF71 + 0.014 * BF73 - 0.009 * BF75 ...
    - 0.008 * BF76 - 0.032 * BF78 + 0.032 * BF79 ...
    + 0.011 * BF80;


function Y= ovl_mars( FWSEG_VA, V5, V6, V7, V8, V9, V10, V11, V12, ...
    V13, V14, V15, V16, V17, V18, V19, V20, ...
    V21, V22, V23, V24, V25, V26, V27, V28)

BF1 = max(0, V21 - 4.671);
BF3 = max(0, V6 - 5.396);
BF4 = max(0, 5.396 - V6 );
BF7 = max(0, V11 - 7.884);
BF8 = max(0, 7.884 - V11 );
BF9 = max(0, FWSEG_VA + 7.229) * BF1;
BF10 = max(0, - 7.229 - FWSEG_VA ) * BF1;
BF11 = max(0, V19 - 8.128) * BF1;
BF12 = max(0, 8.128 - V19 ) * BF1;
BF13 = max(0, V28 - 7.918);
BF14 = max(0, 7.918 - V28 );
BF15 = max(0, V5 + 2.888) * BF14;
BF16 = max(0, - 2.888 - V5 ) * BF14;
BF17 = max(0, V24 - 2.924) * BF8;
BF18 = max(0, 2.924 - V24 ) * BF8;
BF20 = max(0, 9.071 - V16 ) * BF15;
BF21 = max(0, V10 - 6.286) * BF14;
BF22 = max(0, 6.286 - V10 ) * BF14;
BF24 = max(0, V23 - 5.173);
BF25 = max(0, 5.173 - V23 );
BF26 = max(0, V26 - 8.987);
BF29 = max(0, 12.216 - V27 ) * BF3;
BF30 = max(0, V8 - 4.306) * BF16;
BF34 = max(0, V23 - 7.630) * BF21;
BF35 = max(0, 7.630 - V23 ) * BF21;
BF37 = max(0, 3.638 - V7 ) * BF1;
BF39 = max(0, 8.337 - V21 ) * BF17;
BF41 = max(0, 1.590 - V5 ) * BF11;
BF43 = max(0, 13.993 - V8 ) * BF11;
BF44 = max(0, V14 - 5.993) * BF25;
BF45 = max(0, 5.993 - V14 ) * BF25;
BF46 = max(0, V24 - 1.035);
BF47 = max(0, 1.035 - V24 );
BF49 = max(0, 8.915 - V23 ) * BF12;
BF51 = max(0, - 0.004 - FWSEG_VA );
BF52 = max(0, V27 - 6.520) * BF24;
BF53 = max(0, 6.520 - V27 ) * BF24;
BF54 = max(0, V7 - 11.484) * BF8;
BF55 = max(0, 11.484 - V7 ) * BF8;
BF57 = max(0, 5.742 - V17 ) * BF25;
BF58 = max(0, V12 - 6.949) * BF12;
BF59 = max(0, 6.949 - V12 ) * BF12;
BF60 = max(0, V25 - 9.203) * BF45;
BF63 = max(0, 1.887 - V13 ) * BF7;
BF65 = max(0, 9.498 - V26 ) * BF15;
BF66 = max(0, V5 - 6.566) * BF22;
BF71 = max(0, 13.239 - V19 ) * BF46;
BF72 = max(0, V19 - 9.925) * BF55;
BF77 = max(0, 3.430 - V22 ) * BF18;
BF78 = max(0, V27 - 6.513) * BF45;
BF79 = max(0, 6.513 - V27 ) * BF45;
BF81 = max(0, 12.511 - V18 );
BF82 = max(0, V11 - 6.777) * BF81;
BF83 = max(0, 6.777 - V11 ) * BF81;
BF85 = max(0, 3.433 - V5 ) * BF47;
BF87 = max(0, - 3.524 - FWSEG_VA ) * BF47;
BF88 = max(0, V27 - 11.604) * BF9;
BF91 = max(0, 8.845 - V26 ) * BF52;
BF92 = max(0, V14 - 5.931) * BF82;
BF93 = max(0, 5.931 - V14 ) * BF82;
BF94 = max(0, V21 - 7.245) * BF25;
BF95 = max(0, 7.245 - V21 ) * BF25;
BF96 = max(0, V14 - 5.323) * BF7;
BF98 = max(0, V10 - 6.248) * BF71;
BF100 = max(0, V18 - 0.602) * BF95;

Y = 2.936 + 0.047 * BF1 + 0.061 * BF3 - 0.084 * BF4 - 0.139 * BF8 ...
    - 0.064 * BF10 - 0.030 * BF12 - 0.103 * BF13 ...
    - 0.039 * BF14 + 0.020 * BF17 - 0.002 * BF20 ...
    - 0.005 * BF22 - 0.114 * BF25 - 0.090 * BF26 ...
    - 0.011 * BF29 + 0.010 * BF30 + 0.009 * BF34 ...
    + 0.002 * BF35 + 0.079 * BF37 - 0.006 * BF39 ...
    + 0.007 * BF41 - 0.003 * BF43 + 0.017 * BF44 ...
    + 0.076 * BF47 + 0.009 * BF49 + 0.016 * BF51 ...
    - 0.042 * BF53 - 0.079 * BF54 - 0.030 * BF57 ...
    - 0.018 * BF58 - 0.009 * BF59 - 0.119 * BF60 ...
    - 0.210 * BF63 - .456802E-03 * BF65 + 0.028 * BF66 ...
    + 0.020 * BF72 + 0.011 * BF77 + 0.005 * BF78 ...
    + 0.003 * BF79 - 0.049 * BF81 + 0.012 * BF83 ...
    - 0.030 * BF85 + 0.070 * BF87 + 0.008 * BF88 ...
    - 0.008 * BF91 + 0.010 * BF92 + 0.003 * BF93 ...
    + 0.022 * BF94 - 0.038 * BF96 + .933766E-03 * BF98 ...
    + 0.002 * BF100;



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
    % (3) Compute Filterbank Output Energies 
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

