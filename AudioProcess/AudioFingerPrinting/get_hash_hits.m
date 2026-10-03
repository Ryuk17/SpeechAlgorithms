function R = get_hash_hits(H)
% R = get_hash_hits(H)
%    Return values from song hash table for particular hashes
%    Each element of H is a <(20 bit) hash value>
%    Each row of R is a hit in format:
%    <song id> <start time index> <hash>
%    If H is a 2 column matrix, the first element is taken as a
%    time base which is subtracted from the start time index for
%    the retrieved hashes.
%    If H is a 3 column matrix, the first element is taken as a
%    songID and discarded.
% 2008-12-29 Dan Ellis dpwe@ee.columbia.edu

if size(H,2) == 3
  H = H(:,[2 3]);
end

if min(size(H))==1
  H = [zeros(length(H),1),H(:)];
end

global HashTable

Rsize = 100;
R = zeros(Rsize,3);
Rmax = 0;

for i = 1:length(H)
  hash = H(i,2);
  htime = double(H(i,1));
  htcol = HashTable(:,hash+1);
  nentries = max([0;find(htcol ~= 0)])/2;
  for j = 1:nentries
    song = htcol(2*j-1);
    time = double(htcol(2*j));
    Rmax = Rmax + 1;
    if Rmax > Rsize
      R = [R;zeros(Rsize,3)];
      Rsize = size(R,1);
    end
    dtime = time-htime;
    R(Rmax,:) = [double(song), dtime, double(hash)];
  end
end

R = R(1:Rmax,:);
