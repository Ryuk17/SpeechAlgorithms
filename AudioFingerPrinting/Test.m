Path = '.\sample\';                   
File = dir(fullfile(Path,'*.mp3'));  
FileNames = {File.name}'; 

Length_Names = size(FileNames,1); 

mp3 = []
SR = 44100;
for k = 1 : Length_Names
    mp3Name = strcat(Path, FileNames(k));
	mp3  = [mp3, mp3Name];
	add_tracks(mp3Name, SR, k);
end

[dt,srt] = mp3read('.\Test.mp3');
R = match_query(dt,srt);
R(1,:)


