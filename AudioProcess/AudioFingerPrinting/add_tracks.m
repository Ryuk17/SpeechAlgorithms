function [N,T] = add_tracks(D,SR,ID)
% [N,T] = add_tracks(D,SR,ID)
%    Add one or more tracks to the hashtable database.
%    <D, SR> define the waveform of the track, and ID is its
%    reference ID.
%    If D is a char array, load that wavefile.  Second arg is ID.
%    If D is a cell array, load each of those wavefiles; second arg
%    is vector of IDs.
%    N returns the total number of hashes added, T returns total
%    duration in secs of tracks added.
% 2008-12-29 Dan Ellis dpwe@ee.columbia.edu


[D,SR] = mp3read(D{1});
H = landmark2hash(find_landmarks(D,SR),ID);
save_hashes(H);
N = length(H);
T = length(D)/SR;
  disp(['added ',num2str(ID),' tracks (',num2str(T),' secs, ', ...
        num2str(N),' hashes, ',num2str(N/T),' hashes/sec)']);
		


