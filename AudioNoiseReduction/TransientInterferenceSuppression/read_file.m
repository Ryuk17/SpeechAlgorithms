function [y_frames]=read_file(yIn,M,Mno,Nframes)
% for l=1:Nframes 
% for l=1:Nframes-(M-Mno)/Mno

for l=1:Nframes    
        y_frames(:,l)=yIn((l-1)*Mno+1:(l-1)*Mno+M);    
end