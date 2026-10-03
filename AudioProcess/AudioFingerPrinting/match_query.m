function [R,L] = match_query(D,SR)
% [R,L] = match_query(D,SR)
%     Match landmarks from an audio query against the database.
%     Rows of R are potential maxes, in format
%      songID  modalDTcount modalDT
%     i.e. there were <modalDTcount> occurrences of hashes 
%     that occurred in the query and reference with a difference of 
%     <modalDT> frames.
%     L returns the actual landmarks that this implies.
% 2008-12-29 Dan Ellis dpwe@ee.columbia.edu

%Rt = get_hash_hits(landmark2hash(find_landmarks(D,SR)));
Lq = find_landmarks(D,SR);
%Lq = fuzzify_landmarks(Lq);
% Augment with landmarks calculated half-a-window advanced too
landmarks_hopt = 0.032;
%Lq = [Lq;find_landmarks(D(round(landmarks_hopt/4*SR):end),SR)];
Lq = [Lq;find_landmarks(D(round(landmarks_hopt/2*SR):end),SR)];
%Lq = [Lq;find_landmarks(D(round(3*landmarks_hopt/4*SR):end),SR)];
% add in quarter-hop offsets too for even better recall

Hq = landmark2hash(Lq);
Rt = get_hash_hits(Hq);
nr = size(Rt,1);

if nr > 0

  % Find all the unique tracks referenced
  [utrks,xx] = unique(sort(Rt(:,1)));
  utrkcounts = diff(xx,nr);

  nutrks = length(utrks);

  R = zeros(nutrks,3);

  for i = 1:nutrks
    tkR = Rt(Rt(:,1)==utrks(i),:);
    % Find the most popular time offset
    [dts,xx] = unique(sort(tkR(:,2)),'first');
    dtcounts = 1+diff([xx',size(tkR,1)]);
    [vv,xx] = max(dtcounts);
    R(i,:) = [utrks(i),vv,dts(xx)];
  end

  % Sort by descending match count
  [vv,xx] = sort(R(:,2),'descend');
  R = R(xx,:);

  % Extract the actual landmarks
  H = Rt((Rt(:,1)==R(1,1)) & (Rt(:,2)==R(1,3)),:);
  % Restore the original times
  for i = 1:size(H,1)
    hix = find(Hq(:,3)==H(i,3));
    hix = hix(1);  % if more than one...
    H(i,2) = H(i,2)+Hq(hix,2);
    L(i,:) = hash2landmark(H(i,:));
  end


  % Return no more than 10 hits, and only down to half the #hits in
  % most popular
  if size(R,1) > 10
    R = R(1:10,:);
  end
  maxhits = R(1,2);
  nuffhits = R(:,2)>(maxhits/2);
  %R = R(nuffhits,:);

else
  R = [];
  disp('*** NO HITS FOUND ***');
end
