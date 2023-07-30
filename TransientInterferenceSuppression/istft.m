function x=istft(Y,nfft,dM,dN,wintype)
% istft : Inverse Short Time Fourier Transform
% ***************************************************************@
% Inputs: 
%    Y,     	stft of x;
%    nfft,  	window length;
%    dM,			sampling step in Time;
%    dN,			sampling step in Frequency;
%    wintype,	window type;
% Inputs: 
%    x,     	signal;
% Usage:
%    x=istft(Y,nfft,dM,dN,wintype);
% Defaults:
%    wintype='Hanning';
%    dN = 1;
%    dM = 0.5*nfft;
%    nfft=2*(size(Y,1)-1);

% Copyright (c) 2000. Dr Israel Cohen. 
% All rights reserved. Created  17/12/00.
% ***************************************************************@

if nargin == 1
	nfft = 2*(size(Y,1)-1);
end
if nargin < 3
   dM = 0.5*nfft;
   dN = 1;
end
if nargin < 5
	wintype = 'Hanning';
end

if exist(wintype)
   win=eval([lower(wintype),sprintf('(%g)',nfft)]);
else
   error(['Undefined window type: ',wintype])
end

%extend the anti-symmetric range of the spectum
N=nfft/dN;
N2=N/2;
Y(N2+2:N,:)=conj(Y(N2:-1:2,:));  
Y=real(ifft(Y));
Y=Y((1:N)'*ones(1,dN),:);

% Apply the synthesis window
ncol=size(Y,2);
Y = win(:,ones(1,ncol)).*Y;

% Overlapp & add
x=zeros((ncol-1)*dM+nfft,1);
idx=(1:nfft)';
start=0;
for l=1:ncol
   x(start+idx)=x(start+idx)+Y(:,l);
   start=start+dM;
end
