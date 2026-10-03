Usage: 
  NCM (cleanFileName.wav,NoisySpeechFilename.wav')

Example:
 >> NCM('S_03_01.wav','S_03_01_babble_sn0_klt.wav')

ans =

    0.4162

Reference:
[1]  Ma, J., Hu, Y. and Loizou, P. (2009). "Objective measures for
      predicting speech intelligibility in noisy conditions based on new band-importance
     functions", Journal of the Acoustical Society of America, 125(5), 3387-3405.

=================================================
CSII measure usage:
>> [CSh, CSm, CSl]=CSII('S_03_01.wav', 'S_03_01_babble_sn0_klt.wav')

CSh =

    0.5556


CSm =

    0.2480


CSl =

    0.0457

=============================================================
 SII Measure usage:

 sp=[40 45 50 24 56 60 55 55 52 48 50 51 55 67 76 67 56 31]; % values in dB SPL
 ns=[30 50 60 20 60 50 70 45 80 40 60 20 60 22 55 50 67 40]; % values in dB SPL
 M= 5;
 sv = SII (sp,ns, M)

sv =

    0.2357