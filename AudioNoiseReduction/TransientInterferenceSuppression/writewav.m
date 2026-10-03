function fidx=writewav(d,fs,filename,mode,nskip)
%WRITEWAV Creates .WAV format sound files FIDX=(D,FS,FILENAME,MODE,NSKIP)
%
%   The input arguments for WRITEWAV are as follows:
%
%       D           The sampled data to save
%       FS          The rate at which the data was sampled
%       FILENAME    A string containing the name of the .WAV file to create or
%                        alternatively the FIDX output from a previous writewav call
%       MODE        String containing any reasonable mixture of the following (*=default):
%
%  Precision: 'a'    for 8-bit A-law PCM
%             'u'    for 8-bit mu-law PCM
%            '16' *	for 16 bit PCM data
%             '8'    for 8 bit PCM data
%             ...    any number in the range 2 to 32 for PCM
%					
%    Scaling: 's' *  Auto scale to make data peak = +-1
%             'r'    Raw unscaled data (integer values)
%             'q'    Scaled to make 0dBm0 be unity mean square
%             'p'  	Scaled to make +-1 equal full scale
%     Offset: 'y' *	Correct for offset in <=8 bit PCM data
%             'z'    No offset correction
%   File I/O: 'f'    Do not close file on exit
%        NSKIP      Number of samples to skip before writing or -1[default] to continue from previous write
%                   Only valid if FIDX is specified for FILENAME 
%               
% Output Parameter:
%
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
%   Note: WRITEWAV will create an 16-bit PCM, auto-scaled wave file by default.
%   For stereo data, d(:,1) is the left channel and d(:,2) the right
%
%   See also READWAV

%	Copyright (C) Mike Brookes 1998
%
%      Last modified Tue May 12 16:11:10 1998
%
%   VOICEBOX home page: http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
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

if nargin<3 error('Usage: WRITEWAV(data,fs,filename,mode,nskip)'); end

info=zeros(1,9);
info(9)=fs;
if nargin<4 mode='s';
else mode = [mode(:).' 's'];
end
info(7)=16; info(8)=1; hi=32767; lo=-32768; pk=32767.5;
if nargin>3
   k=find((mode>='0') & (mode<='9'));
   if k info(7)=str2num(mode(k)); hi=pow2(0.5,info(7))-1; lo=-1-hi; pk=hi+0.5; end
   if any(mode=='a') info(8)=6; pk=4096; info(7)=8; end
   if any(mode=='u') info(8)=7; pk=8159; info(7)=8; end			% pk value wrong
end
k=find((mode>='p') & (mode<='s'));
sc=mode(k(1)); 
z=128*all(mode~='z');
info(6)=ceil(info(7)/8);


[n,nc]=size(d);
if n==1 n=nc; nc=1;
else d = d.';
end;
if nc>10 error('WRITEWAV: attempt to write a sound file with >10 channels'); end
nc=max(nc,1);
ncy=nc*info(6);
nyd=n*ncy;

if ischar(filename)
   nskip=0;
   ny=nyd;
   if isempty(findstr(filename,'.')) filename=[filename,'.wav']; end
   fid=fopen(filename,'wb+','l');
   if fid == -1 error(sprintf('Can''t open %s for output',filename)); end
   info(1)=fid;
   fwrite(fid,'RIFF','uchar');
   fwrite(fid,36+ny,'ulong');
   fwrite(fid,'WAVEfmt ','uchar');
   fwrite(fid,[16 0 info(8) nc],'ushort');
   fwrite(fid,[fs fs*ncy],'ulong');
   fwrite(fid,[ncy info(7)],'ushort');
   fwrite(fid,'data','uchar');
   fwrite(fid,ny,'ulong');
   info(3)=44;
   info(4)=n+nskip;
   info(2)=info(4);
else
   info=filename;
   fid=info(1);
   fseek(fid,0,1);
   if nargin<5 nskip=info(2); 
   elseif nskip<0 nskip=info(2);
   end
   info(2)=n+nskip;
   ny=nyd+nskip*ncy;
   if n & (info(2)>info(4))
      if ~info(4)
         fseek(fid,22,-1); fwrite(fid,nc,'ushort');
         fseek(fid,28,-1); fwrite(fid,fs*ncy,'ulong');
         fwrite(fid,ncy,'ushort');
      end
      fseek(fid,4,-1); fwrite(fid,36+ny,'ulong');
      fseek(fid,40,-1); fwrite(fid,ny,'ulong');
      info(4)=info(2);
   end
end
info(5)=nc;

if n
   st=fseek(fid,info(3)+nskip*nc*info(6),-1);
   if st error(sprintf('Cannot seek to %d in output file',info(3)+nskip*nc*info(6))); end
   if sc~='r'
      if sc=='s' pd=max(abs(d(:))); pd=pd+(pd==0);
      elseif sc=='p' pd=1;
      else 
         if info(8)==7
            pd=2.03761563;
         else
            pd=2.03033976;
         end
      end
      d=pk/pd*d;
   end
   
   if info(8)<6
      d=round(0.5*(lo+hi+abs(d-lo)-abs(d-hi)))*pow2(1,8*info(6)-info(7));
   else
      z=0;
      if info(8) < 7
         d=lin2pcma(d,213,1);
      else
         d=lin2pcmu(d,1);
      end
   end
   
   
   if info(6)<3
      if info(6)<2
         fwrite(fid,d+z,'uchar');
      else
         fwrite(fid,d,'short');
      end
   else
      if info(6)<4
         d=d(:)';
         d2=floor(d/65536);
         d=d-65536*d2;
         fwrite(fid,[rem(d,256); floor(d/256); d2],'uchar');
      else
         fwrite(fid,d,'long');
      end
   end
   if rem(ny,2) fwrite(fid,0,'uchar'); end
end
if all(mode~='f') fclose(fid); end
if nargout fidx=info; end