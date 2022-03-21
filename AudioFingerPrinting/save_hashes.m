function save_hashes(H)
% save_hashes(H)
%   Record the set of hashes that are rows of H in persistent
%   database.
%   Format of H rows are 3 columns:
%   <song id> <start time index> <hash>
% song ID is 32 bit
% time index is 32 bit
%   (32 ms basic resolution = 30/sec, so 600 sec song has time indices
%    up to 18,000 = 14 bits?)
% Hash is 20 bit = 1M slots
%
% 2008-12-24 Dan Ellis dpwe@ee.columbia.edu

% This version uses an in-memory global with one row per hash
% value, and a series of song ID / time ID entries per hash

global HashTable

if exist('HashTable','var') == 0 || length(HashTable) == 0
   clear_hashtable;
end

maxnentries = size(HashTable,1)/2;

nhash = size(H,1);

for i=1:nhash
  song = H(i,1);
  time = H(i,2);
  hash = H(i,3)+1;  % avoid hash == 0
  htcol = HashTable(:,hash);
  nentries = max([0;find(htcol ~= 0)])/2;
  if nentries < maxnentries
    HashTable(2*nentries+1,hash) = song;
    HashTable(2*nentries+2,hash) = time;
  end
end
