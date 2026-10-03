function win=biorwin(wins,dM,dN);
% biorbin : Find Biorthogonal analysis Window for STFT
% ***************************************************************@
% Inputs: 
%    wins,     synthesis window;
%    dM,			sampling step in Time;
%    dN,			sampling step in Frequency;
% Output: 
%    win,      analysis window;
% Usage:
%    win=biorwin(wins,dM,dN);
% Defaults:
%    noverlap=length(wins)/2;

% Copyright (c) 2000. Dr Israel Cohen. 
% All rights reserved. Created  5/12/00.
% ***************************************************************@

wins=wins(:);
L=length(wins);
N=L/dN;
win=zeros(L,1);
mu=zeros(2*dN-1,1);
mu(1)=1;
%mu(1)=1/N;
for k=1:dM
	H=zeros(2*dN-1,ceil(L/dM));
   for q=0:2*dN-2
      h=shiftcir(wins,q*N);
		H(q+1,:)=h(k:dM:L)';
   end
   win(k:dM:L)=pinv(H)*mu;
end

%win=win/max(win);