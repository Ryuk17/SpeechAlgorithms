function y = shiftcir(x,k)
% SHIFTCIR: SHIFT CIRcular.
% *******************************************************************@
% Inputs:
%    x, signal vector;
%    k, shift length;
% Outputs:
%    y, circularly shifted signal vector;
% Usage: 
%    y = shiftcir(x,k);
% Notes:
%    col vectors shifted up/down; row vectors shifted left/right;
%    k > 0 shifts up/left; k < 0 shifts down/right; 
% Functions: 
%    mod;
% Copyright (c) 1992-93 Carl Taswell. 
% All rights reserved. Created 5/8/92, last modified 6/6/93.
% *******************************************************************@
[r,c] = size(x); n = max(r,c); 
k = mod(k,n);  
if c==1
   y = [x(k+1:n);x(1:k)];  % up/down for col vector
else
   y = [x(k+1:n),x(1:k)];  % left/right for row vector
end   
