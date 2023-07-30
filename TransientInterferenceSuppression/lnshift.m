function y = lnshift(x,t)
% lnshift -- t circular left shift of 1-d signal
%  Usage
%    y = lnshift(x,t)
%  Inputs
%    x   1-d signal
%  Outputs
%    y   1-d signal 
%        y(i) = x(i+t) for i+t < n
%	 		y(i) = x(i+t-n) else

% Copyright (c) 2000. Dr Israel Cohen. 
% All rights reserved. Created  3/8/00.
% ***************************************************************@

szX=size(x);
if szX(1)>1
	n=szX(1);
   y=[x((1+t):n); x(1:t)];
else
	n=szX(2);
   y=[x((1+t):n) x(1:t)];
end

    
    
