function SIIval = SII(E,N,Mtype)

% Implements  the ANSI S3.5-1997 standard: 
% "Methods for calculation of the Speech Intelligibility Index". 
%  
%   INPUT:    
%
%     'E' Speech Spectrum Level (Section 3.6 in the standard)
%         Level needs to be in dB SPL
%     'N' Noise Spectrum Level (Section 3.15 in the standard)
%         Level needs to be in dB SPL  
%     'M' Speech material (needed to specify band-importance function) 
%         A scalar having a value of either 1, 2, 3, 4, 5, 6. The Band-importance functions associated with each scalar are
%		                1:	various nonsense syllable tests where most English phonemes occur equally often (as specified in Table B.2)
%		                2:	CID-22 (as specified in Table B.2)
%		                3:	NU6 (as specified in Table B.2)
%		                3:	Diagnostic Rhyme test (as specified in Table B.2)
%		                5:	short passages of easy reading material (as specified in Table B.2)
%		                6:	SPIN (as specified in Table B.2)
%
%    OUTPUT:
%       Returns the SII value (0 to 1)
%
%     Note that only the one-third-octave band procedure is implemented.
%     Dimensions of 'E' and 'N' are 18x1, containing the speech and noise levels
%     at 1/3-octave frequencies (see line 78 for 1/3-octave center frequencies)
%
% EXAMPLE
% sp=[40 45 50 24 56 60 55 55 52 48 50 51 55 67 76 67 56 31];
% ns=[30 50 60 20 60 50 70 45 80 40 60 20 60 22 55 50 67 40];
% M= 5;
% sv = SII (sp,ns, M);
%
% (c)2012 Philipos C. Loizou


if length(E)~=18 | length(N)~=18
    error('The target and masker spectra vectors have incorrect dimension - needs to be 18.');
end
if Mtype>6 | Mtype<1
  error('Band-importance function type takes values between 1 and 6');
end

%================== DEFINE INPUT VARIABLES ==============================

G=zeros(1,18);  % insertion gains - needed if used in the context of amplification devices (hearing aids)
T=G;            % threshold levels in dB HL (for normal-hearing listeners, T=[0 0 ...0] )
VocalEffort = 'normal';  % or "raised", "loud" and "shout"

% Standard speech spectrum level for different vocal efforts (Table 3)
%
SpV=[32.41	33.81	35.29	30.77;
	34.48	33.92	37.76	36.65;
	34.75	38.98	41.55	42.5;
	33.98	38.57	43.78	46.51;
	34.59	39.11	43.3	47.4;
	34.27	40.15	44.85	49.24;
	32.06	38.78	45.55	51.21;
	28.3	36.37	44.05	51.44;
	25.01	33.86	42.16	51.31;
	23		31.89	40.53	49.63;
	20.15	28.58	37.7	47.65;
	17.32	25.32	34.39	44.32;
	13.18	22.35	30.98	40.8;
	11.55	20.15	28.21	38.13;
	9.33	16.78	25.41	34.41;
	5.31	11.47	18.35	28.24;
	2.59	7.67	13.87	23.45;
	1.13	5.07	11.39	20.72];

switch lower(VocalEffort)
	case 'normal', EV = SpV(:,1)';
	case 'raised', EV = SpV(:,2)';
	case 'loud',   EV = SpV(:,3)';
	case 'shout',  EV = SpV(:,4)';
	otherwise, error('Unknown level of vocal effort')
end;

% Define band center frequencies for 1/3rd octave procedure (Table 3)
f = [160 200 250 315 400 500 630 800 1000 1250 1600 2000, ...
     2500 3150 4000 5000 6300 8000];


% Define Internal Noise Spectrum Level (Table 3) 
X = [0.6 -1.7 -3.9 -6.1 -8.2 -9.7 -10.8 -11.9 -12.5 -13.5 -15.4 -17.7, ...
	-21.2 -24.2 -25.9 -23.6 -15.8 -7.1];


% ----------------- start processing ----------------------
%
% Equivalent Speech Spectrum Level (5.1.3, Eq. 17)	
E = E + G;

% Self-Speech Masking Spectrum (Sec 4.3.2.1, Eq. 5)
V = E - 24;

% 4.3.2.2	
B = max(V,N+G);
	
% Calculate Equivalent Masking Spectrum Level (Sec 4.3.2.5, Eq. 9)
%
C = 0.6.*(B+10*log10(f)-6.353) - 80;  % slope parameter Ci (4.3.2.3 Eq. 7)
Z(1) = B(1);

for i = 2:18
	Z(i) = 10*log10(10.^(0.1*N(i)) + ...
	sum(10.^(0.1*(B(1:(i-1))+3.32.*C(1:(i-1)).*log10(0.89*f(i)./f(1:(i-1)))))));
end;	


% Equivalent Internal Noise Spectrum Level (Sec 4.4 Eq. 10)
X = X + T;
	
% Compute disturbance Spectrum Level (4.5)
D = max(Z,X);

% Level Distortion Factor (Sec 4.6, Eq. 11)
%
L = 1 - (E - EV - 10)./160;
L = max(0,min(L,1)); 


% 4.7.1 Eq. 12
K = (E-D+15)/30;
K=max(0,min(K,1));

% Band Audibility Function (7.7.2 Eq. 13)
%
A = L.*K;

% Speech Intelligibility Index (4.8 Eq. 14)
%
SIIval = sum(BandImportance(Mtype).*A);

return;


%==================================================================

function BIF = BandImportance(type)
%
% Band importance functions, taken from Table B.2:
% type  = 
%		1:	Nonsense syllable tests where most English
%			phonemes occur equally often
%		2:	CID-22
%		3:	NU6 (monosyllables)
%		4:	Diagnostic Rhyme test (DRT)
%		5:	short passages of easy reading material
%		6:	SPIN (monosyllables)

if (nargin ~= 1) | (type>6) | (type<1)
	error('Incorrect argument to BandImportance');
end;

IFu   = [	0		0.0365	0.0168	0		0.0114	0
			0		0.0279	0.013	0.024	0.0153	0.0255
            0.0153  0.0405	0.0211	0.033	0.0179	0.0256
			0.0284	0.0500	0.0344	0.039	0.0558	0.036
			0.0363	0.0530	0.0517	0.0571	0.0898	0.0362
			0.0422	0.0518	0.0737	0.0691	0.0944	0.0514
			0.0509	0.0514	0.0658	0.0781	0.0709	0.0616
			0.0584	0.0575	0.0644	0.0751	0.066	0.077
			0.0667	0.0717	0.0664	0.0781	0.0628	0.0718
			0.0774	0.0873	0.0802	0.0811	0.0672	0.0718
			0.0893	0.0902	0.0987	0.0961	0.0747	0.1075
			0.1104	0.0938	0.1171	0.0901	0.0755	0.0921
			0.112	0.0928	0.0932	0.0781	0.082	0.1026
			0.0981	0.0678	0.0783	0.0691	0.0808	0.0922
			0.0867	0.0498	0.0562	0.048	0.0483	0.0719
			0.0728	0.0312	0.0337	0.033	0.0453	0.0461
			0.0551	0.0215	0.0177	0.027	0.0274	0.0306
			0		0.0253	0.0176	0.024	0.0145	0];

BIF = IFu(:,type)';
