function [y,fs,wmode,fidx]=readwav(filename,mode,nmax,nskip)
%READWAV  Read a .WAV format sound file [Y,FS,WMODE,FIDX]=(FILENAME,MODE,NMAX,NSKIP)
%
% Input Parameters:
%
%	FILENAME gives the name of the file (with optional .WAV extension) or alternatively
%                 can be the FIDX output from a previous call to READWAV
%	MODE		specifies the following (*=default):
%
%    Scaling: 's'    Auto scale to make data peak = +-1
%             'r'    Raw unscaled data (integer values)
%             'q'    Scaled to make 0dBm0 be unity mean square
%             'p' *	Scaled to make +-1 equal full scale
%     Offset: 'y' *	Correct for offset in <=8 bit PCM data
%             'z'    No offset correction
%   File I/O: 'f'    Do not close file on exit
%
%	NMAX     maximum number of samples to read (or -1 for unlimited [default])
%	NSKIP    number of samples to skip from start of file
%               (or -1 to continue from previous read when FIDX is given instead of FILENAME [default])
%
% Output Parameters:
%
%	Y        data matrix of dimension (samples,channels)
%	FS       sample frequency in Hz
%	WMODE    mode string needed for WRITEWAV to recreate the data file
%	FIDX     Information row vector containing the element listed below.
%
%           (1)  file id
%				(2)  current position in file
%           (3)  dataoff	byte offset in file to start of data
%           (4)  nsamp	number of samples
%           (5)  nchan	number of channels
%           (6)  nbyte	bytes per data value
%           (7)  bits	number of bits of precision
%           (8)  code	Data format: 1=PCM, 2=ADPCM, 6=A-law, 7=Mu-law
%           (9)  fs	sample frequency
%
%   If no output parameters are specified, header information will be printed.
%
%   For stereo data, y(:,1) is the left channel and y(:,2) the right
%
%   See also WRITEWAV.

%	Copyright (C) Mike Brookes 1998
%
%      Last modified Tue Sep 26 13:41:35 2000
%
%   VOICEBOX is a MATLAB toolbox for speech processing. Home page is at
%   http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You can obtain a copy of the GNU General Public License from
%   ftp://prep.ai.mit.edu/pub/gnu/COPYING-2.0 or by writing to
%   Free Software Foundation, Inc.,675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<1 
    error('Usage: [y,fs,wmode,fidx]=READWAV(filename,mode,nmax,nskip)'); 
end

if nargin<2 
    mode='p';
else
    mode = [mode(:).' 'p'];
end
k=find((mode>='p') & (mode<='s'));
sc=mode(k(1)); 
z=128*all(mode~='z');


info=zeros(1,9);
if ischar(filename)
   fid=fopen(filename,'rb','l');
   if fid == -1
      fn=[filename,'.wav'];
      fid=fopen(fn,'rb','l'); 
      if fid ~= -1 
          filename=fn; 
      end
   end
   if fid == -1 
       error(['Can''t open ' filename ' for input']); 
   end
   info(1)=fid;
else
   info=filename;
   fid=info(1);
end

if ~info(3)
   fseek(fid,8,-1);						% read riff chunk
   header=fread(fid,4,'uchar');
   if header' ~= 'WAVE' fclose(fid); error(sprintf('File does not begin with a WAVE chunck')); end
   
   fmt=0;
   data=0;
   while ~data						% loop until FMT and DATA chuncks both found
      header=fread(fid,4,'char');
      len=fread(fid,1,'ulong');
      if header' == 'fmt '					% ******* found FMT chunk *********
         fmt=1;
         info(8)=fread(fid,1,'ushort');				% format: 1=PCM, 6=A-law, 7-Mu-law
         info(5)=fread(fid,1,'ushort');			%number of channels
         fs=fread(fid,1,'ulong');				% sample rate in Hz
         info(9)=fs;				% sample rate in Hz
         rate=fread(fid,1,'ulong');				% average bytes per second (ignore)
         align=fread(fid,1,'ushort');			% block alignment in bytes (ignore)
         info(7)=fread(fid,1,'ushort');				% bits per sample
         fseek(fid,len-16,0);				% skip to end of header
         if any([1 6 7]==info(8)) info(6)=ceil(info(7)/8);
         else info(6)=1; sc='r';
         end
      elseif header' == 'data'				% ******* found DATA chunk *********
         if ~fmt fclose(fid); error(sprintf('File %s does not contain a FMT chunck',filename)); end
         info(4) = fix(len/(info(6)*info(5)));
         info(3)=ftell(fid);
         data=1;
      else							% ******* found unwanted chunk *********
         fseek(fid,len,0);
      end
   end
else
   fs=info(9);
end


if nargin<4 nskip=info(2);
elseif nskip<0 nskip=info(2);
end

ksamples=info(4)-nskip;
if nargin>2
   if nmax>=0
      ksamples=min(nmax,ksamples);
   end
elseif ~nargout
   ksamples=min(5,ksamples);
end
if ksamples>0
   info(2)=nskip+ksamples;
   pk=(pow2(0.5,info(7))-0.5)*pow2(1,8*info(6)-info(7));		% full-scale range
   fseek(fid,info(3)+info(6)*info(5)*nskip,-1);
   nsamples=info(5)*ksamples;
   if info(6)<3
      if info(6)<2
         y=fread(fid,nsamples,'uchar');
         if info(8)==1 y=y-z;
         elseif info(8)==6
            y=pcma2lin(y,213,1); pk=4096;
         elseif info(8)==7
            y=pcmu2lin(y,1); pk=8159;
         end 
      else
         y=fread(fid,nsamples,'short');
      end
   else
      if info(6)<4
         y=fread(fid,3*nsamples,'uchar');
         y=reshape(y,3,nsamples);
         y=[1 256 65536]*y-pow2(fix(pow2(y(3,:),-7)),24);
      else
         y=fread(fid,nsamples,'long');
      end
   end
   if sc ~= 'r'
      if sc=='s' pd=max(abs(y)); pd=pk/(pd+(pd==0));
      elseif sc=='p' pd=1;
      else
         if info(8)==7
            pd=2.03761563;
         else
            pd=2.03033976;
         end
      end
      y=pd/pk*y;
   else
      if info(8)==1 y=y*pow2(1,info(7)-8*info(6)); end
   end
   
   if info(5)>1 y = reshape(y,info(5),ksamples).'; end
else
   y=[];
end

if all(mode~='f') fclose(fid); end

if nargout>2
   wmode=setstr([sc 'z'-z/128]);
   if info(8)==1
      wmode=[wmode num2str(info(7))];
   elseif info(8)==6
      wmode = [wmode 'a'];
   elseif info(8)==7
      wmode = [wmode 'u'];
   end
   fidx=info;
elseif ~nargout
   codes=' '*ones(9,6); codes(1+[1 2 6 7],:)=['PCM   ';'ADPCM ';'A-law ';'Mu-law'];
   fprintf(1,'\n%d Hz sample rate\n%d channel x %d samples = %.3g seconds\ndata type %d: %d bit %s\n',info([9 5 4]),info(4)/info(9), info([8 7]),codes(1+max(0,min(8,info(8))),:));
end
