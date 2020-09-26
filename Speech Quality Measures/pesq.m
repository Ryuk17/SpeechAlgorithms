function [ scores ] = pesq( ref_wav, deg_wav )

% ----------------------------------------------------------------------
%            PESQ objective speech quality measure
%            (narrowband and wideband implementations)
%
%   This function implements the PESQ measure based on the ITU standards
%   P.862 [1] and P.862.1 [2] for narrowband speech and P.862.2 for 
%   wideband speech [3].
%
%
%   Usage:  scores = pesq( cleanFile, enhancedFile )
%           
%         cleanFile     - clean input file in .wav format sampled at 
%                         sampling frequency Fs=8 kHz or Fs=16 kHz
%                         for narrowband or wideband assessment,
%                         respectively.
%
%         enhancedFile  - enhanced output file in .wav format sampled
%                         at same sampling frequency as the cleanFile
%
%         scores        - For narrowband speech, two scores are returned,
%                         one for the raw PESQ value [1] (first value) and 
%                         one for the MOS-mapped score value [2] (second value).
%                         For wideband speech, only the MOS-mapped value
%                         is returned [3].
%
%  Example call:  scores = pesq('sp04.wav', 'enhanced.wav')
%
%  
%  References:
%
%   [1] ITU (2000). Perceptual evaluation of speech quality (PESQ), and 
%       objective method for end-to-end speech quality assessment of 
%       narrowband telephone networks and speech codecs. ITU-T
%       Recommendation P.862 
%
%   [2] ITU (2003).  Mapping function for transforming P.862 raw result 
%       scores to MOS-LQO, ITU-T Recommendation P. 862.1 
%
%   [3] ITU (2007). Wideband extension to Recommendation P.862 for the
%       assessment of wideband telephone networks and speech codecs. ITU-T
%       Recommendation P.862.2
%
%
%   Authors: Yi Hu, Kamil Wojcicki and Philipos C. Loizou 
%
%
% Copyright (c) 2006, 2012 by Philipos C. Loizou
% $Revision: 2.0 $  $Date: 5/14/2012 $
% ----------------------------------------------------------------------

    if nargin ==0, fprintf('Usage: pesq( ref_wav, deg_wav )\n');
                   fprintf('       ref_wav = reference input filename\n');
                   fprintf('       deg_wav = degraded output filename\n\n');
                   fprintf('For more help, type: help pesq\n\n'); 
                   return;
    elseif nargin > 2, error('%s.m: Incorrect number of input arguments.\nFor usage help type: help %s',mfilename,mfilename);
    end

    if ~isstr( ref_wav ), error( '%s.m: First input argumnet has to be a reference wav filename as string.\nFor usage help type: help %s',mfilename,mfilename); end;
    if ~isstr( deg_wav ), error( '%s.m: Second input argumnet has to be a processed wav filename as string.\nFor usage help type: help %s',mfilename,mfilename); end;

    if ~exist( ref_wav, 'file' ), error( '%s.m: Reference wav file: %s not found.',mfilename,ref_wav); end;
    if ~exist( deg_wav, 'file' ), error( '%s.m: Processed wav file: %s not found.',mfilename,deg_wav); end;

    [ ref_data, ref_sampling_rate ] = wavread( ref_wav ); 
    [ deg_data, deg_sampling_rate ] = wavread( deg_wav );

    if ref_sampling_rate ~= deg_sampling_rate, error( '%s.m: Sampling rate mismatch.\nThe sampling rate of the reference wav file (%i Hz) has to match sampling rate of the degraded wav file (%i Hz).',mfilename,ref_sampling_rate,deg_sampling_rate);
    else, sampling_rate = ref_sampling_rate; end;

    if sampling_rate==8E3, mode='narrowband'; 
    elseif sampling_rate==16E3, mode='wideband';
    else, error( '%s.m: Unsupported sampling rate (%i Hz).\nOnly sampling rates of 8000 Hz (for narrowband assessment)\nand 16000 Hz (for wideband assessment) are supported.',mfilename,sampling_rate); 
    end

    clearvars -global Downsample DATAPADDING_MSECS SEARCHBUFFER Fs WHOLE_SIGNAL Align_Nfft Window

    global Downsample DATAPADDING_MSECS SEARCHBUFFER Fs WHOLE_SIGNAL
    global Align_Nfft Window 
    
    setup_global( sampling_rate );
    TWOPI= 6.28318530717959;
    for count = 0: Align_Nfft- 1
        Window(1+ count) = 0.5 * (1.0 - cos((TWOPI * count) / Align_Nfft));
    end         
    
    ref_data= ref_data(:).';
    ref_data= ref_data* 32768;
    ref_Nsamples= length( ref_data)+ 2* SEARCHBUFFER* Downsample;
    ref_data= [zeros( 1, SEARCHBUFFER* Downsample), ref_data, ...
        zeros( 1, DATAPADDING_MSECS* (Fs/ 1000)+ SEARCHBUFFER* Downsample)];
    
    deg_data= deg_data(:).';
    deg_data= deg_data* 32768;
    deg_Nsamples= length( deg_data)+ 2* SEARCHBUFFER* Downsample;
    deg_data= [zeros( 1, SEARCHBUFFER* Downsample), deg_data, ...
        zeros( 1, DATAPADDING_MSECS* (Fs/ 1000)+ SEARCHBUFFER* Downsample)];
    
    maxNsamples= max( ref_Nsamples, deg_Nsamples);
    
    ref_data= fix_power_level( ref_data, ref_Nsamples, maxNsamples);
    deg_data= fix_power_level( deg_data, deg_Nsamples, maxNsamples);
 

% KKW ---------

    switch lower( mode )

        case { [], '', 'nb', '+nb', 'narrowband', '+narrowband' }
   
            standard_IRS_filter_dB= [0, -200; 50, -40; 100, -20; 125, -12; 160, -6; 200, 0;...    
                250, 4; 300, 6; 350, 8; 400, 10; 500, 11; 600, 12; 700, 12; 800, 12;...
                1000, 12; 1300, 12; 1600, 12; 2000, 12; 2500, 12; 3000, 12; 3250, 12;...
                3500, 4; 4000, -200; 5000, -200; 6300, -200; 8000, -200]; 
    
            ref_data= apply_filter( ref_data, ref_Nsamples, standard_IRS_filter_dB);
            deg_data= apply_filter( deg_data, deg_Nsamples, standard_IRS_filter_dB);

        case { 'wb', '+wb', 'wideband', '+wideband' }
            ref_data = apply_filters_WB( ref_data, ref_Nsamples );
            deg_data = apply_filters_WB( deg_data, deg_Nsamples );
    
        otherwise
            error( sprintf('Mode: "%s" is unsupported.', mode) ); 

    end

% -------------


    % 
    % fid= fopen( 'log_mat_ref.txt', 'wt');
    % fprintf( fid, '%f\n', ref_data);
    % fclose( fid);
    % 
    % fid= fopen( 'log_mat_deg.txt', 'wt');
    % fprintf( fid, '%f\n', deg_data);
    % fclose( fid);
    
    % % to save time, read from data file ========
    % fid= fopen( 'log_mat_ref.txt', 'rt');
    % ref_data= fscanf( fid, '%f\n');
    % ref_data= ref_data';
    % fclose( fid);
    % ref_Nsamples= length( ref_data)- DATAPADDING_MSECS* (Fs/ 1000);
    % 
    % fid= fopen( 'log_mat_deg.txt', 'rt');
    % deg_data= fscanf( fid, '%f\n');
    % deg_data= deg_data';
    % fclose( fid);
    % deg_Nsamples= length( deg_data)- DATAPADDING_MSECS* (Fs/ 1000);
    % % the above part will be commented after debugging ========
    
    % for later use in psychoacoustical model
    model_ref= ref_data;
    model_deg= deg_data;
    
    [ref_data, deg_data]= input_filter( ref_data, ref_Nsamples, deg_data, ...
        deg_Nsamples);
    
    % fid= fopen( 'log_mat_ref_tovad.txt', 'wt');
    % fprintf( fid, '%f\n', ref_data);
    % fclose( fid);
    % 
    % fid= fopen( 'log_mat_deg_tovad.txt', 'wt');
    % fprintf( fid, '%f\n', deg_data);
    % fclose( fid);
    
    [ref_VAD, ref_logVAD]= apply_VAD( ref_data, ref_Nsamples);
    [deg_VAD, deg_logVAD]= apply_VAD( deg_data, deg_Nsamples);
    
    % subplot( 2, 2, 1); plot( ref_VAD); title( 'ref\_VAD');
    % subplot( 2, 2, 2); plot( ref_logVAD); title( 'ref\_logVAD');
    % 
    % subplot( 2, 2, 3); plot( deg_VAD); title( 'deg\_VAD');
    % subplot( 2, 2, 4); plot( deg_logVAD); title( 'deg\_logVAD');
    % 
    % fid= fopen( 'mat_ref_vad.txt', 'wt');
    % fprintf( fid, '%f\n', ref_VAD);
    % fclose( fid);
    % 
    % fid= fopen( 'mat_ref_logvad.txt', 'wt');
    % fprintf( fid, '%f\n', ref_logVAD);
    % fclose( fid);
    % 
    % fid= fopen( 'mat_deg_vad.txt', 'wt');
    % fprintf( fid, '%f\n', deg_VAD);
    % fclose( fid);
    % 
    % fid= fopen( 'mat_deg_logvad.txt', 'wt');
    % fprintf( fid, '%f\n', deg_logVAD);
    % fclose( fid);
    % 
    
    crude_align (ref_logVAD, ref_Nsamples, deg_logVAD, deg_Nsamples,...
        WHOLE_SIGNAL);
    
    utterance_locate (ref_data, ref_Nsamples, ref_VAD, ref_logVAD,...
        deg_data, deg_Nsamples, deg_VAD, deg_logVAD);
    
    ref_data= model_ref;
    deg_data= model_deg;
    
    % make ref_data and deg_data equal length
    if (ref_Nsamples< deg_Nsamples)
        newlen= deg_Nsamples+ DATAPADDING_MSECS* (Fs/ 1000);
        ref_data( newlen)= 0;
    elseif (ref_Nsamples> deg_Nsamples)
        newlen= ref_Nsamples+ DATAPADDING_MSECS* (Fs/ 1000);
        deg_data( newlen)= 0;
    end
    
    pesq_mos= pesq_psychoacoustic_model (ref_data, ref_Nsamples, deg_data, ...
        deg_Nsamples );


% KKW ---------

    switch lower( mode )

        case { [], '', 'nb', '+nb', 'narrowband', '+narrowband' }
            % NB: P.862.1->P.800.1 (PESQ_MOS->MOS_LQO)
            mos_lqo = 0.999 + ( 4.999-0.999 ) ./ ( 1+exp(-1.4945*pesq_mos+4.6607) );
            scores = [ pesq_mos, mos_lqo ]; 

        case { 'wb', '+wb', 'wideband', '+wideband' }
            % WB: P.862.2->P.800.1 (PESQ_MOS->MOS_LQO)
            mos_lqo = 0.999 + ( 4.999-0.999 ) ./ ( 1+exp(-1.3669*pesq_mos+3.8224) );
            scores = [ mos_lqo ];

        otherwise
            error( sprintf('Mode: "%s" is unsupported.', mode) ); 

    end

% -------------

    
    %fprintf( '\tPrediction PESQ_MOS = %4.3f\n', pesq_mos );

    clearvars -global Downsample DATAPADDING_MSECS SEARCHBUFFER Fs WHOLE_SIGNAL Align_Nfft Window


function align_filtered= apply_filter( data, data_Nsamples, align_filter_dB)
    
    global Downsample DATAPADDING_MSECS SEARCHBUFFER Fs
    
    align_filtered= data;
    n= data_Nsamples- 2* SEARCHBUFFER* Downsample+ DATAPADDING_MSECS* (Fs/ 1000);
    % now find the next power of 2 which is greater or equal to n
    pow_of_2= 2^ (ceil( log2( n)));
    
    [number_of_points, trivial]= size( align_filter_dB);
    overallGainFilter= interp1( align_filter_dB( :, 1), align_filter_dB( :, 2), ...
        1000);
    
    x= zeros( 1, pow_of_2);
    x( 1: n)= data( SEARCHBUFFER* Downsample+ 1: SEARCHBUFFER* Downsample+ n);
    
    x_fft= fft( x, pow_of_2);
    
    freq_resolution= Fs/ pow_of_2;
    
    factorDb( 1: pow_of_2/2+ 1)= interp1( align_filter_dB( :, 1), ...
        align_filter_dB( :, 2), (0: pow_of_2/2)* freq_resolution)- ...
        overallGainFilter;
    factor= 10.^ (factorDb/ 20);
    
    factor= [factor, fliplr( factor( 2: pow_of_2/2))];
    x_fft= x_fft.* factor;
    
    y= ifft( x_fft, pow_of_2);
    
    align_filtered( SEARCHBUFFER* Downsample+ 1: SEARCHBUFFER* Downsample+ n)...
        = y( 1: n);
    
    % fid= fopen( 'log_mat.txt', 'wt');
    % fprintf( fid, '%f\n', y( 1: n));
    % fclose( fid);
    


function mod_data= apply_filters( data, Nsamples)
    %IIRFilt( InIIR_Hsos, InIIR_Nsos, data, data_Nsamples);
    
    global InIIR_Hsos InIIR_Nsos DATAPADDING_MSECS Fs
    % data_Nsamples= Nsamples+ DATAPADDING_MSECS* (Fs/ 1000);
    
    % now we construct the second order section matrix
    sosMatrix= zeros( InIIR_Nsos, 6);
    sosMatrix( :, 4)= 1; %set a(1) to 1
    % each row of sosMatrix holds [b(1*3) a(1*3)] for each section
    sosMatrix( :, 1: 3)= InIIR_Hsos( :, 1: 3);
    sosMatrix( :, 5: 6)= InIIR_Hsos( :, 4: 5);
    %sosMatrix
    
    % now we construct second order section direct form II filter
    iirdf2= dfilt.df2sos( sosMatrix);
    
    mod_data= filter( iirdf2, data);


% KKW ---------

function mod_data= apply_filters_WB( data, Nsamples)
    
    global WB_InIIR_Hsos WB_InIIR_Nsos DATAPADDING_MSECS Fs
    
    % now we construct the second order section matrix
    sosMatrix= zeros( WB_InIIR_Nsos, 6);
    sosMatrix( :, 4)= 1; %set a(1) to 1

    % each row of sosMatrix holds [b(1*3) a(1*3)] for each section
    sosMatrix( :, 1: 3)= WB_InIIR_Hsos( :, 1: 3);
    sosMatrix( :, 5: 6)= WB_InIIR_Hsos( :, 4: 5);
    %sosMatrix
    
    % now we construct second order section direct form II filter
    iirdf2= dfilt.df2sos( sosMatrix);
    
    mod_data= filter( iirdf2, data);

% -------------


function [VAD, logVAD]= apply_VAD( data, Nsamples)
    
    global Downsample MINSPEECHLGTH JOINSPEECHLGTH
    
    Nwindows= floor( Nsamples/ Downsample);
    %number of 4ms window
    
    VAD= zeros( 1, Nwindows);
    for count= 1: Nwindows
        VAD( count)= sum( data( (count-1)* Downsample+ 1: ...
            count* Downsample).^ 2)/ Downsample;   
    end
    %VAD is the power of each 4ms window 
    
    LevelThresh = sum( VAD)/ Nwindows;
    %LevelThresh is set to mean value of VAD
    
    LevelMin= max( VAD);
    if( LevelMin > 0 )
        LevelMin= LevelMin* 1.0e-4;
    else
        LevelMin = 1.0;
    end
    %fprintf( 1, 'LevelMin is %f\n', LevelMin);
    
    VAD( find( VAD< LevelMin))= LevelMin;
    
    for iteration= 1: 12    
        LevelNoise= 0;
        len= 0;
        StDNoise= 0;    
    
        VAD_lessthan_LevelThresh= VAD( find( VAD<= LevelThresh));
        len= length( VAD_lessthan_LevelThresh);
        LevelNoise= sum( VAD_lessthan_LevelThresh);
        if (len> 0)
            LevelNoise= LevelNoise/ len;
            StDNoise= sqrt( sum( ...
            (VAD_lessthan_LevelThresh- LevelNoise).^ 2)/ len);
        end
        LevelThresh= 1.001* (LevelNoise+ 2* StDNoise);  
    end
    %fprintf( 1, 'LevelThresh is %f\n', LevelThresh);
    
    LevelNoise= 0;
    LevelSig= 0;
    len= 0;
    VAD_greaterthan_LevelThresh= VAD( find( VAD> LevelThresh));
    len= length( VAD_greaterthan_LevelThresh);
    LevelSig= sum( VAD_greaterthan_LevelThresh);
    
    VAD_lessorequal_LevelThresh= VAD( find( VAD<= LevelThresh));
    LevelNoise= sum( VAD_lessorequal_LevelThresh);
    
    if (len> 0)
        LevelSig= LevelSig/ len;
    else
        LevelThresh= -1;
    end
    %fprintf( 1, 'LevelSig is %f\n', LevelSig);
    
    if (len< Nwindows)
        LevelNoise= LevelNoise/( Nwindows- len);
    else
        LevelNoise= 1;
    end
    %fprintf( 1, 'LevelNoise is %f\n', LevelNoise);
    
    VAD( find( VAD<= LevelThresh))= -VAD( find( VAD<= LevelThresh));
    VAD(1)= -LevelMin;
    VAD(Nwindows)= -LevelMin;
    
    start= 0;
    finish= 0;
    for count= 2: Nwindows
        if( (VAD(count) > 0.0) && (VAD(count-1) <= 0.0) )
            start = count;
        end
        if( (VAD(count) <= 0.0) && (VAD(count-1) > 0.0) )
            finish = count;
            if( (finish - start)<= MINSPEECHLGTH )
                VAD( start: finish- 1)= -VAD( start: finish- 1);
            end
        end
    end
    %to make sure finish- start is more than 4
    
    if( LevelSig >= (LevelNoise* 1000) )
        for count= 2: Nwindows
            if( (VAD(count)> 0) && (VAD(count-1)<= 0) )
                start= count;
            end
            if( (VAD(count)<= 0) && (VAD(count-1)> 0) )
                finish = count;
                g = sum( VAD( start: finish- 1));
                if( g< 3.0* LevelThresh* (finish - start) )
                    VAD( start: finish- 1)= -VAD( start: finish- 1);
                end
            end
        end
    end
    
    start = 0;
    finish = 0;
    for count= 2: Nwindows
        if( (VAD(count) > 0.0) && (VAD(count-1) <= 0.0) )
            start = count;
            if( (finish > 0) && ((start - finish) <= JOINSPEECHLGTH) )
                VAD( finish: start- 1)= LevelMin;
            end        
        end
        if( (VAD(count) <= 0.0) && (VAD(count-1) > 0.0) )
            finish = count;
        end
    end
    
    start= 0;
    for count= 2: Nwindows
        if( (VAD(count)> 0) && (VAD(count-1)<= 0) )
            start= count;
        end
    end
    if( start== 0 )
        VAD= abs(VAD);
        VAD(1) = -LevelMin;
        VAD(Nwindows) = -LevelMin;
    end
    
    count = 4;
    while( count< (Nwindows-1) )
        if( (VAD(count)> 0) && (VAD(count-2) <= 0) )
            VAD(count-2)= VAD(count)* 0.1;
            VAD(count-1)= VAD(count)* 0.3;
            count= count+ 1;
        end
        if( (VAD(count)<= 0) && (VAD(count-1)> 0) )
            VAD(count)= VAD(count-1)* 0.3;
            VAD(count+ 1)= VAD(count-1)* 0.1;
            count= count+ 3;
        end
        count= count+ 1;
    end
    
    VAD( find( VAD< 0))= 0;
    
    % fid= fopen( 'mat_vad.txt', 'wt');
    % fprintf( fid, '%f\n', VAD);
    % fclose( fid);
    
    if( LevelThresh<= 0 )
        LevelThresh= LevelMin;
    end
    
    logVAD( find( VAD<= LevelThresh))= 0;
    VAD_greaterthan_LevelThresh= find( VAD> LevelThresh);
    logVAD( VAD_greaterthan_LevelThresh)= log( VAD( ...
        VAD_greaterthan_LevelThresh)/ LevelThresh);
    


function crude_align( ref_logVAD, ref_Nsamples, deg_logVAD, ...
        deg_Nsamples, Utt_id)
    
    global Downsample 
    global Nutterances Largest_uttsize Nsurf_samples Crude_DelayEst
    global Crude_DelayConf UttSearch_Start UttSearch_End Utt_DelayEst
    global Utt_Delay Utt_DelayConf Utt_Start Utt_End
    global MAXNUTTERANCES WHOLE_SIGNAL
    global pesq_mos subj_mos cond_nr 
    
    if (Utt_id== WHOLE_SIGNAL )
        nr = floor( ref_Nsamples/ Downsample);
        nd = floor( deg_Nsamples/ Downsample);
        startr= 1;
        startd= 1;
    elseif Utt_id== MAXNUTTERANCES
        startr= UttSearch_Start(MAXNUTTERANCES);
        startd= startr+ Utt_DelayEst(MAXNUTTERANCES)/ Downsample;
        if ( startd< 0 )
            startr= 1- Utt_DelayEst(MAXNUTTERANCES)/ Downsample;
            startd= 1;
        end
    
        nr= UttSearch_End(MAXNUTTERANCES)- startr;
        nd= nr;
    
        if( startd+ nd> floor( deg_Nsamples/ Downsample) )
            nd= floor( deg_Nsamples/ Downsample)- startd;
        end
    %     fprintf( 'nr,nd is %d,%d\n', nr, nd);
    
    else
        startr= UttSearch_Start(Utt_id);
        startd= startr+ Crude_DelayEst/ Downsample; 
    
        if ( startd< 0 )       
            startr= 1- Crude_DelayEst/ Downsample;
            startd= 1;
        end
    
        nr= UttSearch_End(Utt_id)- startr;
        nd = nr;
        if( startd+ nd> floor( deg_Nsamples/ Downsample)+ 1)
            nd = floor( deg_Nsamples/ Downsample)- startd+ 1;
        end
    end

    startr = max(1,startr); % <- KKW
    startd = max(1,startd); % <- KKW
    
    max_Y= 0.0;
    I_max_Y= nr;
    if( (nr> 1) && (nd> 1) )
        Y= FFTNXCorr( ref_logVAD, startr, nr, deg_logVAD, startd, nd);
        [max_Y, I_max_Y]= max( Y);
        if (max_Y<= 0)
            max_Y= 0;
            I_max_Y= nr;
        end
    end
    
    % fprintf( 'max_Y, I_max_Y is %f, %d\n', max_Y, I_max_Y);
    
    if( Utt_id== WHOLE_SIGNAL )
        Crude_DelayEst= (I_max_Y- nr)* Downsample;
        Crude_DelayConf= 0.0;
    %     fprintf( 1, 'I_max_Y, nr, Crude_DelayEst is %f, %f, %f\n', ...
    %         I_max_Y, nr, Crude_DelayEst);
    elseif( Utt_id == MAXNUTTERANCES )
        Utt_Delay(MAXNUTTERANCES)= (I_max_Y- nr)* Downsample+ ...
            Utt_DelayEst(MAXNUTTERANCES);    
    %     fprintf( 'startr, startd, nr, nd, I_max, Utt_Delay[%d] is %d, %d, %d, %d, %d, %d\n', ...
    %           MAXNUTTERANCES, startr, startd, nr, nd, ...
    %             I_max_Y, Utt_Delay(MAXNUTTERANCES) );
    else
    %     fprintf( 'I_max_Y, nr is %d, %d\n', I_max_Y, nr);
        Utt_DelayEst(Utt_id)= (I_max_Y- nr)* Downsample+ ... 
            Crude_DelayEst;    
    end
    


function mod_data= DC_block( data, Nsamples)
    
    global Downsample DATAPADDING_MSECS SEARCHBUFFER
    
    ofs= SEARCHBUFFER* Downsample;
    mod_data= data;
    
    %compute dc component, it is a little weird
    facc= sum( data( ofs+ 1: Nsamples- ofs))/ Nsamples; 
    mod_data( ofs+ 1: Nsamples- ofs)= data( ofs+ 1: Nsamples- ofs)- facc;
    
    mod_data( ofs+ 1: ofs+ Downsample)= mod_data( ofs+ 1: ofs+ Downsample).* ...
        ( 0.5+ (0: Downsample- 1))/ Downsample;
    
    mod_data( Nsamples- ofs: -1: Nsamples- ofs-Downsample+ 1)= ...
        mod_data( Nsamples- ofs: -1: Nsamples- ofs-Downsample+ 1).* ...
        ( 0.5+ (0: Downsample- 1))/ Downsample;
    


function Y= FFTNXCorr( ref_VAD, startr, nr, deg_VAD, startd, nd)
    % this function has other simple implementations, current implementation is
    % consistent with the C version
    
    % % one way to do this (in time domain) =====
    % % fprintf( 1, 'startr, nr is %d, %d\n', startr, nr);
    % x1= ref_VAD( startr: startr+ nr- 1);
    % x2= deg_VAD( startd: startd+ nd- 1);
    % x1= fliplr( x1);
    % Y= conv( x2, x1);
    % % done =====
    
    % the other way to do this (in freq domain)===
    Nx= 2^ (ceil( log2( max( nr, nd))));
    x1= zeros( 1, 2* Nx);
    x2= zeros( 1, 2* Nx);
    startd=max(1,startd); %<<< PL: Added to avoid index 0
    startr=max(1,startr);
    
    x1( 1: nr)= fliplr( ref_VAD( startr: startr+ nr- 1));
    x2( 1: nd)= deg_VAD( startd: startd+ nd- 1);
    
    if (nr== 491) && false
        fid= fopen( 'mat_debug.txt', 'wt');
        fprintf( fid, '%f\n', x1);
        fclose( fid);
    end
    
    x1_fft= fft( x1, 2* Nx);
    x2_fft= fft( x2, 2* Nx);
    
    tmp1= ifft( x1_fft.* x2_fft, 2* Nx);
    
    Ny= nr+ nd- 1;
    Y= tmp1( 1: Ny);
    % done ===========
    


function mod_data= fix_power_level( data, data_Nsamples, maxNsamples)
    % this function is used for level normalization, i.e., to fix the power
    % level of data to a preset number, and return it to mod_data. 
    
    global Downsample DATAPADDING_MSECS SEARCHBUFFER Fs
    global TARGET_AVG_POWER 
    TARGET_AVG_POWER= 1e7;
    
    align_filter_dB= [0,-500; 50, -500; 100, -500; 125, -500; 160, -500; 200, -500;
        250, -500; 300, -500; 350,  0; 400,  0; 500,  0; 600,  0; 630,  0;
        800,  0; 1000, 0; 1250, 0; 1600, 0; 2000, 0; 2500, 0; 3000, 0;
        3250, 0; 3500, -500; 4000, -500; 5000, -500; 6300, -500; 8000, -500];    
    
    align_filtered= apply_filter( data, data_Nsamples, align_filter_dB);
    power_above_300Hz = pow_of (align_filtered, SEARCHBUFFER* Downsample+ 1, ...
        data_Nsamples- SEARCHBUFFER* Downsample+ DATAPADDING_MSECS* (Fs/ 1000), ...
        maxNsamples- 2* SEARCHBUFFER* Downsample+ DATAPADDING_MSECS* (Fs/ 1000));
    
    global_scale= sqrt( TARGET_AVG_POWER/ power_above_300Hz);
    % fprintf( 1, '\tglobal_scale is %f\n', global_scale);
    mod_data= data* global_scale;


function id_searchwindows( ref_VAD, ref_Nsamples, deg_VAD, deg_Nsamples);
    
    global MINUTTLENGTH Downsample MINUTTLENGTH SEARCHBUFFER
    global Crude_DelayEst Nutterances UttSearch_Start UttSearch_End
    
    Utt_num = 1;
    speech_flag = 0;
    
    VAD_length= floor( ref_Nsamples/ Downsample);
    del_deg_start= MINUTTLENGTH- Crude_DelayEst/ Downsample;
    del_deg_end= floor((deg_Nsamples- Crude_DelayEst)/ Downsample)-...
        MINUTTLENGTH;
    
    for count= 1: VAD_length
        VAD_value= ref_VAD(count);
        if( (VAD_value> 0) && (speech_flag== 0) ) 
            speech_flag= 1;
            this_start= count;
            UttSearch_Start(Utt_num)= count- SEARCHBUFFER;
    %         if( UttSearch_Start(Utt_num)< 0 )
    %             UttSearch_Start(Utt_num)= 0;
    %         end
            if( UttSearch_Start(Utt_num)< 1 )
                UttSearch_Start(Utt_num)= 1;
            end
        end
    
        if( ((VAD_value== 0) || (count == (VAD_length-1))) && ...
                (speech_flag == 1) ) 
            speech_flag = 0;
            UttSearch_End(Utt_num) = count + SEARCHBUFFER;
    %         if( UttSearch_End(Utt_num) > VAD_length - 1 )
    %             UttSearch_End(Utt_num) = VAD_length -1;
    %         end
            if( UttSearch_End(Utt_num) > VAD_length  )
                UttSearch_End(Utt_num) = VAD_length;
            end
    
            if( ((count - this_start) >= MINUTTLENGTH) &&...
                    (this_start < del_deg_end) &&...
                    (count > del_deg_start) )
                Utt_num= Utt_num + 1;            
            end
        end
    end
    Utt_num= Utt_num- 1;
    Nutterances = Utt_num;
    
    % fprintf( 1, 'Nutterances is %d\n', Nutterances);
    
    % fid= fopen( 'mat_utt.txt', 'wt');
    % fprintf( fid, '%d\n', UttSearch_Start( 1: Nutterances));
    % fprintf( fid, '\n');
    % fprintf( fid, '%d\n', UttSearch_End( 1: Nutterances));
    % fclose(fid);
    


function id_utterances( ref_Nsamples, ref_VAD, deg_Nsamples)
    
    global Largest_uttsize MINUTTLENGTH MINUTTLENGTH Crude_DelayEst
    global Downsample SEARCHBUFFER Nutterances Utt_Start
    global Utt_End Utt_Delay
    
    Utt_num = 1;
    speech_flag = 0;
    VAD_length = floor( ref_Nsamples / Downsample);
    % fprintf( 1, 'VAD_length is %d\n', VAD_length);
    
    del_deg_start = MINUTTLENGTH - Crude_DelayEst / Downsample;
    del_deg_end = floor((deg_Nsamples- Crude_DelayEst)/ Downsample) ...
        - MINUTTLENGTH;
    
    for count = 1: VAD_length 
        VAD_value = ref_VAD(count);
        if( (VAD_value > 0.0) && (speech_flag == 0) ) 
            speech_flag = 1;
            this_start = count;
            Utt_Start (Utt_num) = count;
        end
    
        if( ((VAD_value == 0) || (count == VAD_length)) && ...
                (speech_flag == 1) ) 
            speech_flag = 0;
            Utt_End (Utt_num) = count;
    
            if( ((count - this_start) >= MINUTTLENGTH) && ...
                    (this_start < del_deg_end) && ... 
                    (count > del_deg_start) )
                Utt_num = Utt_num + 1;   
            end
        end
    end
    
    Utt_Start(1) = SEARCHBUFFER+ 1;
    Nutterances=max(1,Nutterances);  %<<< PL: Added to avoid index 0
    Utt_End(Nutterances) = VAD_length - SEARCHBUFFER+ 1;
    
    for Utt_num = 2: Nutterances
        this_start = Utt_Start(Utt_num)- 1;
        last_end = Utt_End(Utt_num - 1)- 1;
        count = floor( (this_start + last_end) / 2);
        Utt_Start(Utt_num) = count+ 1;
        Utt_End(Utt_num - 1) = count+ 1;
    end
    
    this_start = (Utt_Start(1)- 1) * Downsample + Utt_Delay(1);
    if( this_start < (SEARCHBUFFER * Downsample) )
        count = SEARCHBUFFER + floor( ...
            (Downsample - 1 - Utt_Delay(1)) / Downsample);
        Utt_Start(1) = count+ 1;
    end
    
    last_end = (Utt_End(Nutterances)- 1) * Downsample + 1 + ...
        Utt_Delay(Nutterances);
    % fprintf( 'Utt_End(%d) is %d\n', Nutterances, Utt_End(Nutterances));
    % fprintf( 'last_end is %d\n', last_end);
    % fprintf( 'Utt_Delay(%d) is %d\n', Nutterances, Utt_Delay(Nutterances));
    if( last_end > (deg_Nsamples - SEARCHBUFFER * Downsample+ 1) )
        count = floor( (deg_Nsamples - Utt_Delay(Nutterances)) / Downsample) ...
            - SEARCHBUFFER;
        Utt_End(Nutterances) = count+ 1;
    end
    
    for Utt_num = 2: Nutterances
        this_start = (Utt_Start(Utt_num)- 1) * Downsample + Utt_Delay(Utt_num);
        last_end = (Utt_End(Utt_num - 1)- 1) * Downsample + Utt_Delay(Utt_num - 1);
        if( this_start < last_end )
            count = floor( (this_start + last_end) / 2);
            this_start = floor( (Downsample- 1+ count- Utt_Delay(Utt_num))...
                / Downsample);
            last_end = floor( (count - Utt_Delay(Utt_num - 1))...
                / Downsample);
            Utt_Start(Utt_num) = this_start+ 1;
            Utt_End(Utt_num- 1) = last_end+ 1;
        end
    end
    
    Largest_uttsize= max( Utt_End- Utt_Start);    
    


function [mod_ref_data, mod_deg_data]= input_filter( ref_data, ref_Nsamples, ...
        deg_data, deg_Nsamples)
    
    mod_ref_data= DC_block( ref_data, ref_Nsamples);
    mod_deg_data= DC_block( deg_data, deg_Nsamples);
    
    mod_ref_data= apply_filters( mod_ref_data, ref_Nsamples);
    mod_deg_data= apply_filters( mod_deg_data, deg_Nsamples);
    


function pesq_mos= pesq_psychoacoustic_model (ref_data, ref_Nsamples, deg_data, ...
        deg_Nsamples )
    
    global CALIBRATE Nfmax Nb Sl Sp
    global nr_of_hz_bands_per_bark_band centre_of_band_bark
    global width_of_band_hz centre_of_band_hz width_of_band_bark
    global pow_dens_correction_factor abs_thresh_power
    global Downsample SEARCHBUFFER DATAPADDING_MSECS Fs Nutterances
    global Utt_Start Utt_End Utt_Delay NUMBER_OF_PSQM_FRAMES_PER_SYLLABE 
    global Fs Plot_Frame
    
    % Plot_Frame= 75; % this is the frame whose spectrum will be plotted
    Plot_Frame= -1; 
    
    FALSE= 0;
    TRUE= 1;
    NUMBER_OF_PSQM_FRAMES_PER_SYLLABE= 20;
    
    maxNsamples = max (ref_Nsamples, deg_Nsamples);
    Nf = Downsample * 8;
    MAX_NUMBER_OF_BAD_INTERVALS = 1000;
    
    start_frame_of_bad_interval= zeros( 1, MAX_NUMBER_OF_BAD_INTERVALS);
    stop_frame_of_bad_interval= zeros( 1, MAX_NUMBER_OF_BAD_INTERVALS);
    start_sample_of_bad_interval= zeros( 1, MAX_NUMBER_OF_BAD_INTERVALS);
    stop_sample_of_bad_interval= zeros( 1, MAX_NUMBER_OF_BAD_INTERVALS);
    number_of_samples_in_bad_interval= zeros( 1, MAX_NUMBER_OF_BAD_INTERVALS);
    delay_in_samples_in_bad_interval= zeros( 1, MAX_NUMBER_OF_BAD_INTERVALS);
    number_of_bad_intervals= 0;
    there_is_a_bad_frame= FALSE;
    
    Whanning= hann( Nf, 'periodic');
    Whanning= Whanning';
    
    D_POW_F = 2;
    D_POW_S = 6;
    D_POW_T = 2;
    A_POW_F = 1;
    A_POW_S = 6;
    A_POW_T = 2;
    D_WEIGHT= 0.1;
    A_WEIGHT= 0.0309;
    
    CRITERIUM_FOR_SILENCE_OF_5_SAMPLES = 500;
    samples_to_skip_at_start = 0;
    sum_of_5_samples= 0;
    while ((sum_of_5_samples< CRITERIUM_FOR_SILENCE_OF_5_SAMPLES) ...
            && (samples_to_skip_at_start < maxNsamples / 2))
        sum_of_5_samples= sum( abs( ref_data( samples_to_skip_at_start...
            + SEARCHBUFFER * Downsample + 1: samples_to_skip_at_start...
            + SEARCHBUFFER * Downsample + 5)));
    
        if (sum_of_5_samples< CRITERIUM_FOR_SILENCE_OF_5_SAMPLES)
            samples_to_skip_at_start = samples_to_skip_at_start+ 1;
        end
    end
    % fprintf( 'samples_to_skip_at_start is %d\n', samples_to_skip_at_start);
    
    samples_to_skip_at_end = 0;
    sum_of_5_samples= 0;
    while ((sum_of_5_samples< CRITERIUM_FOR_SILENCE_OF_5_SAMPLES) ...
            && (samples_to_skip_at_end < maxNsamples / 2))
        sum_of_5_samples= sum( abs( ref_data( maxNsamples - ...
            SEARCHBUFFER* Downsample + DATAPADDING_MSECS* (Fs/ 1000) ...
            - samples_to_skip_at_end - 4: maxNsamples - ...
            SEARCHBUFFER* Downsample + DATAPADDING_MSECS* (Fs/ 1000) ...
            - samples_to_skip_at_end)));
        if (sum_of_5_samples< CRITERIUM_FOR_SILENCE_OF_5_SAMPLES)
            samples_to_skip_at_end = samples_to_skip_at_end+ 1;
        end
    end
    % fprintf( 'samples_to_skip_at_end is %d\n', samples_to_skip_at_end);
    
    start_frame = floor( samples_to_skip_at_start/ (Nf/ 2));
    stop_frame = floor( (maxNsamples- 2* SEARCHBUFFER* Downsample ...
        + DATAPADDING_MSECS* (Fs/ 1000)- samples_to_skip_at_end) ...
        / (Nf/ 2))- 1;
    % number of frames in speech data plus DATAPADDING_MSECS
    % fprintf( 'start/end frame is %d/%d\n', start_frame, stop_frame);
    
    D_disturbance= zeros( stop_frame+ 1, Nb);
    DA_disturbance= zeros( stop_frame+ 1, Nb);
    
    power_ref = pow_of (ref_data, SEARCHBUFFER* Downsample, ...
        maxNsamples- SEARCHBUFFER* Downsample+ DATAPADDING_MSECS* (Fs/ 1000),...
        maxNsamples- 2* SEARCHBUFFER* Downsample+ DATAPADDING_MSECS* (Fs/ 1000));
    power_deg = pow_of (deg_data, SEARCHBUFFER * Downsample, ...
        maxNsamples- SEARCHBUFFER* Downsample+ DATAPADDING_MSECS* (Fs/ 1000),...
        maxNsamples- 2* SEARCHBUFFER* Downsample+ DATAPADDING_MSECS* (Fs/ 1000));
    % fprintf( 'ref/deg power is %f/%f\n', power_ref, power_deg);
    
    hz_spectrum_ref             = zeros( 1, Nf/ 2);
    hz_spectrum_deg             = zeros( 1, Nf/ 2);
    frame_is_bad                = zeros( 1, stop_frame + 1);
    smeared_frame_is_bad        = zeros( 1, stop_frame + 1);
    silent                      = zeros( 1, stop_frame + 1);
    
    pitch_pow_dens_ref          = zeros( stop_frame + 1, Nb);
    pitch_pow_dens_deg          = zeros( stop_frame + 1, Nb);
    
    frame_was_skipped           = zeros( 1, stop_frame + 1);
    frame_disturbance           = zeros( 1, stop_frame + 1);
    frame_disturbance_asym_add  = zeros( 1, stop_frame + 1);
    
    avg_pitch_pow_dens_ref      = zeros( 1, Nb);
    avg_pitch_pow_dens_deg      = zeros( 1, Nb);
    loudness_dens_ref           = zeros( 1, Nb);
    loudness_dens_deg           = zeros( 1, Nb);
    deadzone                    = zeros( 1, Nb);
    disturbance_dens            = zeros( 1, Nb);
    disturbance_dens_asym_add   = zeros( 1, Nb);
    
    time_weight                 = zeros( 1, stop_frame + 1);
    total_power_ref             = zeros( 1, stop_frame + 1);
    
    % fid= fopen( 'tmp_mat.txt', 'wt');
    
    for frame = 0: stop_frame
        start_sample_ref = 1+ SEARCHBUFFER * Downsample + frame* (Nf/ 2);
        hz_spectrum_ref= short_term_fft (Nf, ref_data, Whanning, ...
            start_sample_ref);
    
        utt = Nutterances;
        while ((utt >= 1) && ((Utt_Start(utt)- 1)* Downsample+ 1 ...
                > start_sample_ref))
            utt= utt - 1;
        end
    
        if (utt >= 1)
            delay = Utt_Delay(utt);
        else
            delay = Utt_Delay(1);
        end
    
        start_sample_deg = start_sample_ref + delay;
    
        if ((start_sample_deg > 0) && (start_sample_deg + Nf- 1 < ...
                maxNsamples+ DATAPADDING_MSECS* (Fs/ 1000)))
            hz_spectrum_deg= short_term_fft (Nf, deg_data, Whanning, ...
                start_sample_deg);
        else
            hz_spectrum_deg( 1: Nf/ 2)= 0;
        end
    
        pitch_pow_dens_ref( frame+ 1, :)= freq_warping (...
            hz_spectrum_ref, Nb, frame);
        %peak = maximum_of (pitch_pow_dens_ref, 0, Nb);
        pitch_pow_dens_deg( frame+ 1, :)= freq_warping (...
            hz_spectrum_deg, Nb, frame);
    
        total_audible_pow_ref = total_audible (frame, pitch_pow_dens_ref, 1E2);
        total_audible_pow_deg = total_audible (frame, pitch_pow_dens_deg, 1E2);
        silent(frame+ 1) = (total_audible_pow_ref < 1E7);
    
    %     fprintf( fid, 'total_audible_pow_ref[%d] is %f\n', frame, ...
    %         total_audible_pow_ref);
    
        if (frame== Plot_Frame)
            figure;
            freq_resolution= Fs/ Nf;
            axis_freq= ( 0: Nf/2- 1)* freq_resolution;
            subplot( 1, 2, 1);        
            plot( axis_freq, 10* log10( hz_spectrum_ref+ eps));
            axis( [0 Fs/2 -10 120]); %xlabel( 'Hz'); ylabel( 'Db');        
            title( 'reference signal power spectrum');
            subplot( 1, 2, 2);
            plot( axis_freq, 10* log10( hz_spectrum_deg+ eps));
            axis( [0 Fs/2 -10 120]); %xlabel( 'Hz'); ylabel( 'Db');
            title( 'degraded signal power spectrum');
    
            figure;
            subplot( 1, 2, 1);
            plot( centre_of_band_hz, 10* log10( eps+ ...
                pitch_pow_dens_ref( frame+ 1, :)));
            axis( [0 Fs/2 0 95]); %xlabel( 'Hz'); ylabel( 'Db');  
            title( 'reference signal bark spectrum');        
            subplot( 1, 2, 2);
            plot( centre_of_band_hz, 10* log10( eps+ ...
                pitch_pow_dens_deg( frame+ 1, :)));
            axis( [0 Fs/2 0 95]); %xlabel( 'Hz'); ylabel( 'Db');        
            title( 'degraded signal bark spectrum');
    
        end        
    end
    % fclose( fid);
    
    avg_pitch_pow_dens_ref= time_avg_audible_of (stop_frame + 1, ...
        silent, pitch_pow_dens_ref, floor((maxNsamples- 2* SEARCHBUFFER* ...
        Downsample+ DATAPADDING_MSECS* (Fs/ 1000))/ (Nf / 2))- 1);
    avg_pitch_pow_dens_deg= time_avg_audible_of (stop_frame + 1, ...
        silent, pitch_pow_dens_deg, floor((maxNsamples- 2* SEARCHBUFFER* ...
        Downsample+ DATAPADDING_MSECS* (Fs/ 1000))/ (Nf/ 2))- 1);
    
    % fid= fopen( 'tmp_mat.txt', 'wt');
    % fprintf( fid, '%f\n', avg_pitch_pow_dens_deg);
    % fclose( fid);
    
    if (CALIBRATE== 0)
        pitch_pow_dens_ref= freq_resp_compensation (stop_frame + 1, ...
            pitch_pow_dens_ref, avg_pitch_pow_dens_ref, ...
            avg_pitch_pow_dens_deg, 1000);
        if (Plot_Frame>= 0) % plot pitch_pow_dens_ref
            figure;
            subplot( 1, 2, 1);
            plot( centre_of_band_hz, 10* log10( eps+ ...
                pitch_pow_dens_ref( Plot_Frame+ 1, :)));
            axis( [0 Fs/2 0 95]); %xlabel( 'Hz'); ylabel( 'Db');   
            title( 'reference signal bark spectrum with frequency compensation');
            subplot( 1, 2, 2);
            plot( centre_of_band_hz, 10* log10( eps+ ...
                pitch_pow_dens_deg( Plot_Frame+ 1, :)));
            axis( [0 Fs/2 0 95]); %xlabel( 'Hz'); ylabel( 'Db');
            title( 'degraded signal bark spectrum');
        end
    
    end
    % tmp1= pitch_pow_dens_ref';
    
    MAX_SCALE = 5.0;
    MIN_SCALE = 3e-4;
    oldScale = 1;
    THRESHOLD_BAD_FRAMES = 30;
    for frame = 0: stop_frame
    
        total_audible_pow_ref = total_audible (frame, pitch_pow_dens_ref, 1);
        total_audible_pow_deg = total_audible (frame, pitch_pow_dens_deg, 1);        
        total_power_ref (1+ frame) = total_audible_pow_ref;
    
        scale = (total_audible_pow_ref + 5e3)/ (total_audible_pow_deg + 5e3);    
        if (frame > 0) 
            scale = 0.2 * oldScale + 0.8 * scale;
        end
        oldScale = scale;
    
        if (scale > MAX_SCALE) 
            scale = MAX_SCALE;
        elseif (scale < MIN_SCALE) 
            scale = MIN_SCALE;            
        end
    
        pitch_pow_dens_deg( 1+ frame, :) = ...
            pitch_pow_dens_deg( 1+ frame, :) * scale;
    
        if (frame== Plot_Frame)
            figure;
            subplot( 1, 2, 1);
            plot( centre_of_band_hz, 10* log10( eps+ ...
                pitch_pow_dens_ref( Plot_Frame+ 1, :)));
            axis( [0 Fs/2 0 95]); %xlabel( 'Hz'); ylabel( 'Db');        
            subplot( 1, 2, 2);
            plot( centre_of_band_hz, 10* log10( eps+ ...
                pitch_pow_dens_deg( Plot_Frame+ 1, :)));
            axis( [0 Fs/2 0 95]); %xlabel( 'Hz'); ylabel( 'Db');
        end
    
        loudness_dens_ref = intensity_warping_of (frame, pitch_pow_dens_ref);
        loudness_dens_deg = intensity_warping_of (frame, pitch_pow_dens_deg);         
        disturbance_dens = loudness_dens_deg - loudness_dens_ref;
    
        if (frame== Plot_Frame)
            figure;
            subplot( 1, 2, 1);
            plot( centre_of_band_hz, 10* log10( eps+ ...
                loudness_dens_ref));
            axis( [0 Fs/2 0 15]); %xlabel( 'Hz'); ylabel( 'Db'); 
            title( 'reference signal loudness density');
            subplot( 1, 2, 2);
            plot( centre_of_band_hz, 10* log10( eps+ ...
                loudness_dens_deg));
            axis( [0 Fs/2 0 15]); %xlabel( 'Hz'); ylabel( 'Db');
            title( 'degraded signal loudness density');        
        end
    
        for band =1: Nb
            deadzone (band) = 0.25* min (loudness_dens_deg (band), ...
                loudness_dens_ref (band));    
        end
    
        for band = 1: Nb
            d = disturbance_dens (band);
            m = deadzone (band);
    
            if (d > m) 
                disturbance_dens (band) = disturbance_dens (band)- m;
    %             disturbance_dens (band) = d- m;
            else
                if (d < -m) 
                    disturbance_dens (band) = disturbance_dens (band)+ m;
    %                 disturbance_dens (band) = d+ m;
                else
                    disturbance_dens (band) = 0;
                end
            end
        end
    
        if (frame== Plot_Frame)
            figure;
            subplot( 1, 2, 1);
            plot( centre_of_band_hz, disturbance_dens);
            axis( [0 Fs/2 -1 50]); %xlabel( 'Hz'); ylabel( 'Db');                
            title( 'disturbance');        
        end
        D_disturbance( frame+ 1, :)= disturbance_dens;
    
        frame_disturbance (1+ frame) = pseudo_Lp (disturbance_dens, D_POW_F);    
        if (frame_disturbance (1+ frame) > THRESHOLD_BAD_FRAMES) 
            there_is_a_bad_frame = TRUE;
        end
    
        disturbance_dens= multiply_with_asymmetry_factor (...
            disturbance_dens, frame, pitch_pow_dens_ref, pitch_pow_dens_deg);
    
        if (frame== Plot_Frame)        
            subplot( 1, 2, 2);
            plot( centre_of_band_hz, disturbance_dens);
            axis( [0 Fs/2 -1 50]); %xlabel( 'Hz'); ylabel( 'Db');
            title( 'disturbance after asymmetry processing');
        end
        DA_disturbance( frame+ 1, :)= disturbance_dens;
    
        frame_disturbance_asym_add (1+ frame) = ...
            pseudo_Lp (disturbance_dens, A_POW_F);    
    end
    % fid= fopen( 'tmp_mat.txt', 'wt');
    % fprintf( fid, '%f\n', frame_disturbance);
    % fclose( fid);
    
    frame_was_skipped (1: 1+ stop_frame) = FALSE;
    
    for utt = 2: Nutterances
        frame1 = floor (((Utt_Start(utt)- 1- SEARCHBUFFER )* Downsample+ 1+ ...
            Utt_Delay(utt))/ (Nf/ 2));
        j = floor( floor(((Utt_End(utt-1)- 1- SEARCHBUFFER)* Downsample+ 1+ ...
            Utt_Delay(utt-1)))/(Nf/ 2));
        delay_jump = Utt_Delay(utt) - Utt_Delay(utt-1);
    
        if (frame1 > j) 
            frame1 = j;    
        end
        if (frame1 < 0) 
            frame1 = 0;
        end
    %     fprintf( 'frame1, j, delay_jump is %d, %d, %d\n', frame1, ...
    %         j, delay_jump);
    
        if (delay_jump < -(Nf/ 2)) 
            frame2 = floor (((Utt_Start(utt)- 1- SEARCHBUFFER)* Downsample+ 1 ...
                + max (0, abs (delay_jump)))/ (Nf/ 2)) + 1; 
    
            for frame = frame1: frame2
                if (frame < stop_frame) 
                    frame_was_skipped (1+ frame) = TRUE;
                    frame_disturbance (1+ frame) = 0;
                    frame_disturbance_asym_add (1+ frame) = 0;
                end
            end
        end
    end
    
    nn = DATAPADDING_MSECS* (Fs/ 1000) + maxNsamples;
    tweaked_deg = zeros( 1, nn);
    % fprintf( 'nn is %d\n', nn);
    
    for i= SEARCHBUFFER* Downsample+ 1: nn- SEARCHBUFFER* Downsample
        utt = Nutterances;
    
        while ((utt >= 1) && ((Utt_Start (utt)- 1)* Downsample> i)) 
            utt = utt- 1;
        end
        if (utt >= 1) 
            delay = Utt_Delay (utt);        
        else
            delay = Utt_Delay (1);
        end
    
        j = i + delay;
        if (j < SEARCHBUFFER * Downsample+ 1) 
            j = SEARCHBUFFER * Downsample+ 1;
        end
        if (j > nn - SEARCHBUFFER * Downsample) 
            j = nn - SEARCHBUFFER * Downsample;
        end
        tweaked_deg (i) = deg_data (j);
    end
    
    if (there_is_a_bad_frame) 
    
        for frame = 0: stop_frame
            frame_is_bad (1+ frame) = (frame_disturbance (1+ frame)...
                > THRESHOLD_BAD_FRAMES);       
            smeared_frame_is_bad (1+ frame) = FALSE;
        end
        frame_is_bad (1) = FALSE;
        SMEAR_RANGE = 2;
    
        for frame = SMEAR_RANGE: stop_frame- 1- SMEAR_RANGE
            max_itself_and_left = frame_is_bad (1+ frame);
            max_itself_and_right = frame_is_bad (1+ frame);
    
            for i = -SMEAR_RANGE: 0
                if (max_itself_and_left < frame_is_bad (1+ frame+ i)) 
                    max_itself_and_left = frame_is_bad (1+ frame+ i);
                end
            end
    
            for i = 0: SMEAR_RANGE
                if (max_itself_and_right < frame_is_bad (1+ frame + i)) 
                    max_itself_and_right = frame_is_bad (1+ frame + i);
                end
            end
    
            mini = max_itself_and_left;
            if (mini > max_itself_and_right) 
                mini = max_itself_and_right;
            end
    
            smeared_frame_is_bad (1+ frame) = mini;
        end
    
        MINIMUM_NUMBER_OF_BAD_FRAMES_IN_BAD_INTERVAL = 5;
        number_of_bad_intervals = 0;    
        frame = 0; 
        while (frame <= stop_frame) 
            while ((frame <= stop_frame) && (~smeared_frame_is_bad (1+ frame)))
                frame= frame+ 1;
            end
    
            if (frame <= stop_frame) 
                start_frame_of_bad_interval(1+ number_of_bad_intervals)= ...
                    1+ frame;
    
                while ((frame <= stop_frame) && (...
                        smeared_frame_is_bad (1+ frame))) 
                    frame= frame+ 1; 
                end
    
                if (frame <= stop_frame)
                    stop_frame_of_bad_interval(1+ number_of_bad_intervals)= ...
                        1+ frame; 
                    if (stop_frame_of_bad_interval(1+ number_of_bad_intervals)- ...
                            start_frame_of_bad_interval(1+ number_of_bad_intervals)...
                            >= MINIMUM_NUMBER_OF_BAD_FRAMES_IN_BAD_INTERVAL) 
                        number_of_bad_intervals= number_of_bad_intervals+ 1;
                    end
                end
            end
        end
    
        for bad_interval = 0: number_of_bad_intervals - 1
            start_sample_of_bad_interval(1+ bad_interval) = ...
                (start_frame_of_bad_interval(1+ bad_interval)- 1) * (Nf/ 2) ...
                + SEARCHBUFFER * Downsample+ 1;
            stop_sample_of_bad_interval(1+ bad_interval) = ...
                (stop_frame_of_bad_interval(1+ bad_interval)- 1) * (Nf/ 2) ...
                + Nf + SEARCHBUFFER* Downsample;
            if (stop_frame_of_bad_interval(1+ bad_interval) > stop_frame+ 1) 
                stop_frame_of_bad_interval(1+ bad_interval) = stop_frame+ 1; 
            end
    
            number_of_samples_in_bad_interval(1+ bad_interval) = ...
                stop_sample_of_bad_interval(1+ bad_interval) - ...
                start_sample_of_bad_interval(1+ bad_interval)+ 1;
        end        
    %     fprintf( 'number of bad intervals %d\n', number_of_bad_intervals);
    %     fprintf( '%d %d\n', number_of_samples_in_bad_interval(1), ...
    %         number_of_samples_in_bad_interval(2));
    %     fprintf( '%d %d\n', start_sample_of_bad_interval(1), ...
    %         start_sample_of_bad_interval(2));
    
        SEARCH_RANGE_IN_TRANSFORM_LENGTH = 4;    
        search_range_in_samples= SEARCH_RANGE_IN_TRANSFORM_LENGTH * Nf;
    
        for bad_interval= 0: number_of_bad_intervals- 1
            ref = zeros (1, 2 * search_range_in_samples + ...
                number_of_samples_in_bad_interval (1+ bad_interval));
            deg = zeros (1, 2 * search_range_in_samples + ...
                number_of_samples_in_bad_interval (1+ bad_interval));
    
            ref(1: search_range_in_samples) = 0;
    
            ref (search_range_in_samples+ 1: search_range_in_samples+ ...
                    number_of_samples_in_bad_interval (1+ bad_interval)) = ...
                    ref_data (start_sample_of_bad_interval( 1+ bad_interval) + 1: ...
                    start_sample_of_bad_interval( 1+ bad_interval) + ...
                    number_of_samples_in_bad_interval (1+ bad_interval));
    
            ref (search_range_in_samples + ...
                    number_of_samples_in_bad_interval (1+ bad_interval) + 1: ...
                    search_range_in_samples + ...
                    number_of_samples_in_bad_interval (1+ bad_interval) + ...
                    search_range_in_samples) = 0;
    
            for i = 0: 2 * search_range_in_samples + ...
                    number_of_samples_in_bad_interval (1+ bad_interval) - 1
                j = start_sample_of_bad_interval (1+ bad_interval) - ...
                    search_range_in_samples + i;
                nn = maxNsamples - SEARCHBUFFER * Downsample + ...
                    DATAPADDING_MSECS  * (Fs / 1000);
                if (j <= SEARCHBUFFER * Downsample) 
                    j = SEARCHBUFFER * Downsample+ 1;
                end
                if (j > nn) 
                    j = nn;
                end
                deg (1+ i) = tweaked_deg (j);
            end
    
            [delay_in_samples, best_correlation]= compute_delay ...
                (1, 2 * search_range_in_samples + ...
                number_of_samples_in_bad_interval (1+ bad_interval), ...
                search_range_in_samples, ref, deg);
            delay_in_samples_in_bad_interval (1+ bad_interval) =  ...
                delay_in_samples;
    %         fprintf( 'delay_in_samples, best_correlation is \n\t%d, %f\n', ...
    %             delay_in_samples, best_correlation);
    %         
            if (best_correlation < 0.5) 
                delay_in_samples_in_bad_interval  (1+ bad_interval) = 0;
            end
        end
    
        if (number_of_bad_intervals > 0) 
            doubly_tweaked_deg = tweaked_deg( 1: maxNsamples + ...
                DATAPADDING_MSECS  * (Fs / 1000));
            for bad_interval= 0: number_of_bad_intervals- 1
                delay = delay_in_samples_in_bad_interval (1+ bad_interval);
    
                for i = start_sample_of_bad_interval (1+ bad_interval): ...
                        stop_sample_of_bad_interval (1+ bad_interval)
                    j = i + delay;
                    if (j < 1) 
                        j = 1;
                    end
                    if (j > maxNsamples) 
                        j = maxNsamples;
                    end
                    h = tweaked_deg (j);
                    doubly_tweaked_deg (i) = h;
                end
            end
    
            untweaked_deg = deg_data;
            deg_data = doubly_tweaked_deg;
    
            for bad_interval= 0: number_of_bad_intervals- 1
                for frame = start_frame_of_bad_interval (1+ bad_interval): ...
                        stop_frame_of_bad_interval (1+ bad_interval)- 1
                    frame= frame- 1;
                    start_sample_ref = SEARCHBUFFER * Downsample + ...
                        frame * Nf / 2+ 1;
                    start_sample_deg = start_sample_ref;
                    hz_spectrum_deg= short_term_fft (Nf, deg_data, ...
                        Whanning, start_sample_deg);    
                    pitch_pow_dens_deg( 1+ frame, :)= freq_warping (...
                        hz_spectrum_deg, Nb, frame);
                end
    
                oldScale = 1;
                for frame = start_frame_of_bad_interval (1+ bad_interval): ...
                        stop_frame_of_bad_interval (1+ bad_interval)- 1
                    frame= frame- 1;    
                    % see implementation for detail why 1 needed to be
                    % subtracted
                    total_audible_pow_ref = total_audible (frame, ...
                        pitch_pow_dens_ref, 1);
                    total_audible_pow_deg = total_audible (frame, ...
                        pitch_pow_dens_deg, 1);        
                    scale = (total_audible_pow_ref + 5e3) / ...
                        (total_audible_pow_deg + 5e3);
                    if (frame > 0) 
                        scale = 0.2 * oldScale + 0.8*scale;
                    end
                    oldScale = scale;
                    if (scale > MAX_SCALE) 
                        scale = MAX_SCALE;
                    end
                    if (scale < MIN_SCALE) 
                        scale = MIN_SCALE;   
                    end
    
                    pitch_pow_dens_deg (1+ frame, :) = ...
                        pitch_pow_dens_deg (1+ frame, :)* scale;
                    loudness_dens_ref= intensity_warping_of (frame, ...
                        pitch_pow_dens_ref); 
                    loudness_dens_deg= intensity_warping_of (frame, ...
                        pitch_pow_dens_deg); 
                    disturbance_dens = loudness_dens_deg - loudness_dens_ref;
    
                    for band = 1: Nb
                        deadzone(band) = min (loudness_dens_deg(band), ...
                            loudness_dens_ref(band));    
                        deadzone(band) = deadzone(band)* 0.25;
                    end
    
                    for band = 1: Nb
                        d = disturbance_dens (band);
                        m = deadzone (band);
    
                        if (d > m) 
                            disturbance_dens (band) = ...
                                disturbance_dens (band)- m;
                        else
                            if (d < -m) 
                                disturbance_dens (band) = ...
                                    disturbance_dens (band)+ m;
                            else
                                disturbance_dens (band) = 0;
                            end
                        end
                    end
    
                    frame_disturbance( 1+ frame) = min (...
                        frame_disturbance( 1+ frame), pseudo_Lp(...
                        disturbance_dens, D_POW_F));
                    disturbance_dens= multiply_with_asymmetry_factor ...
                        (disturbance_dens, frame, pitch_pow_dens_ref, ...
                        pitch_pow_dens_deg);
                    frame_disturbance_asym_add(1+ frame) = min (...
                        frame_disturbance_asym_add(1+ frame), ...
                        pseudo_Lp (disturbance_dens, A_POW_F));    
                end
            end
            deg_data = untweaked_deg;
        end
    end     
    
    for frame = 0: stop_frame
        h = 1;
        if (stop_frame + 1 > 1000) 
            n = floor( (maxNsamples - 2 * SEARCHBUFFER * Downsample)...
                / (Nf / 2)) - 1;
            timeWeightFactor = (n - 1000) / 5500;
            if (timeWeightFactor > 0.5) 
                timeWeightFactor = 0.5;
            end
            h = (1.0 - timeWeightFactor) + timeWeightFactor * frame / n;
        end
    
        time_weight (1 +frame) = h;
    end
    
    % fid= fopen( 'tmp_mat1.txt', 'at');
    % fprintf( '\n');
    for frame = 0: stop_frame
        h = ((total_power_ref (1+ frame) + 1e5) / 1e7)^ 0.04; 
    %     if (frame== 118)
    %         fprintf( '%f\n', h);    
    %         fprintf( '%f\n', frame_disturbance( 1+ frame));
    %     end
        frame_disturbance( 1+ frame) = frame_disturbance( 1+ frame)/ h;
    
    %     if (frame== 118)
    %         fprintf( '%f\n', frame_disturbance( 1+ frame));
    %     end
    %         
        frame_disturbance_asym_add( 1+ frame) = ...
            frame_disturbance_asym_add( 1+ frame)/ h;
        if (frame_disturbance( 1+ frame) > 45) 
            frame_disturbance( 1+ frame) = 45;  
        end
        if (frame_disturbance_asym_add( 1+ frame)> 45) 
            frame_disturbance_asym_add( 1+ frame) = 45;
        end
    end
    % fclose ( fid);
    
    d_indicator = Lpq_weight (start_frame, stop_frame, ...
        D_POW_S, D_POW_T, frame_disturbance, time_weight);
    a_indicator = Lpq_weight (start_frame, stop_frame, ...
        A_POW_S, A_POW_T, frame_disturbance_asym_add, time_weight);       
    
    pesq_mos = 4.5 - D_WEIGHT * d_indicator - A_WEIGHT * a_indicator; 
    
    if (Plot_Frame> 0)
        figure;
        subplot( 1, 2, 1);
        mesh( 0: stop_frame, centre_of_band_hz, D_disturbance');
        title( 'disturbance');
        subplot( 1, 2, 2);
        mesh( 0: stop_frame, centre_of_band_hz, DA_disturbance');
        title( 'disturbance after asymmetry processing');
    end
    
    % fid= fopen( 'tmp_mat.txt', 'wt');
    % fprintf( fid, 'time_weight\n');
    % fprintf( fid, '%f\n', time_weight);
    % fprintf( fid, 'frame_disturbance:\n');
    % fprintf( fid, '%f\n', frame_disturbance);
    % fprintf( fid, 'frame_disturbance_asym_add\n');
    % fprintf( fid, '%f\n', frame_disturbance_asym_add);
    % fclose( fid);
    


function result_time= Lpq_weight(start_frame, stop_frame, ...
            power_syllable, power_time, frame_disturbance, time_weight)
    
    global NUMBER_OF_PSQM_FRAMES_PER_SYLLABE
    
    % fid= fopen( 'tmp_mat1.txt', 'at');
    % fprintf( 'result_time:\n');
    
    result_time= 0;
    total_time_weight_time = 0;
    % fprintf( 'start/end frame: %d/%d\n', start_frame, stop_frame);
    for start_frame_of_syllable = start_frame: ...
            NUMBER_OF_PSQM_FRAMES_PER_SYLLABE/2: stop_frame
        result_syllable = 0;
        count_syllable = 0;
    
        for frame = start_frame_of_syllable: ...
                start_frame_of_syllable + NUMBER_OF_PSQM_FRAMES_PER_SYLLABE- 1
            if (frame <= stop_frame) 
                h = frame_disturbance(1+ frame);
    %             if (start_frame_of_syllable== 101)
    %                 fprintf( fid, '%f\n', h);
    %             end
                result_syllable = result_syllable+ (h^ power_syllable);
            end
            count_syllable = count_syllable+ 1;
        end
    
        result_syllable = result_syllable/ count_syllable;
        result_syllable = result_syllable^ (1/power_syllable);     
    
        result_time= result_time+ (time_weight (...
            1+ start_frame_of_syllable - start_frame) * ...
            result_syllable)^ power_time; 
        total_time_weight_time = total_time_weight_time+ ...
            time_weight (1+ start_frame_of_syllable - start_frame)^ power_time;
    
    %     fprintf( fid, '%f\n', result_time);
    end
    % fclose (fid);
    
    % fprintf( 'total_time_weight_time is %f\n', total_time_weight_time);
    result_time = result_time/ total_time_weight_time;
    result_time= result_time^ (1/ power_time);
    % fprintf( 'result_time is %f\n\n', result_time);
    


function [best_delay, max_correlation] = compute_delay (...
        start_sample, stop_sample, search_range, ...
        time_series1, time_series2) 
    
    n = stop_sample - start_sample+ 1;   
    power_of_2 = 2^ (ceil( log2( 2 * n)));
    
    power1 = pow_of (time_series1, start_sample, stop_sample, n)* ...
        n/ power_of_2;
    power2 = pow_of (time_series2, start_sample, stop_sample, n)* ...
        n/ power_of_2;
    normalization = sqrt (power1 * power2);
    % fprintf( 'normalization is %f\n', normalization);
    
    if ((power1 <= 1e-6) || (power2 <= 1e-6)) 
        max_correlation = 0;
        best_delay= 0;
    end
    
    x1( 1: power_of_2)= 0;
    x2( 1: power_of_2)= 0;
    y( 1: power_of_2)= 0;
    
    x1( 1: n)= abs( time_series1( start_sample: ...
        stop_sample));
    x2( 1: n)= abs( time_series2( start_sample: ...
        stop_sample));
    
    x1_fft= fft( x1, power_of_2)/ power_of_2;
    x2_fft= fft( x2, power_of_2);
    x1_fft_conj= conj( x1_fft);
    y= ifft( x1_fft_conj.* x2_fft, power_of_2);
    
    best_delay = 0;
    max_correlation = 0;
    
    % these loop can be rewritten
    for i = -search_range: -1
        h = abs (y (1+ i + power_of_2)) / normalization;
        if (h > max_correlation) 
            max_correlation = h;
            best_delay= i;
        end
    end
    for i = 0: search_range- 1
        h = abs (y (1+i)) / normalization;
        if (h > max_correlation) 
            max_correlation = h;
            best_delay= i;
        end
    end
    best_delay= best_delay- 1;
    


function mod_disturbance_dens= multiply_with_asymmetry_factor (...
        disturbance_dens, frame, pitch_pow_dens_ref, pitch_pow_dens_deg) 
    
    global Nb
    for i = 1: Nb
        ratio = (pitch_pow_dens_deg(1+ frame, i) + 50)...
            / (pitch_pow_dens_ref (1+ frame, i) + 50);
        h = ratio^ 1.2;    
        if (h > 12) 
            h = 12;
        elseif (h < 3) 
            h = 0.0;
        end
        mod_disturbance_dens (i) = disturbance_dens (i) * h;
    end
    


function loudness_dens = intensity_warping_of (...
        frame, pitch_pow_dens)
    
    global abs_thresh_power Sl Nb centre_of_band_bark
    ZWICKER_POWER= 0.23;
    for band = 1: Nb
        threshold = abs_thresh_power (band);
        input = pitch_pow_dens (1+ frame, band);
    
        if (centre_of_band_bark (band) < 4) 
            h =  6 / (centre_of_band_bark (band) + 2);
        else
            h = 1;
        end
    
        if (h > 2) 
            h = 2;
        end
        h = h^ 0.15;
        modified_zwicker_power = ZWICKER_POWER * h;
        if (input > threshold) 
            loudness_dens (band) = ((threshold / 0.5)^ modified_zwicker_power)...
                * ((0.5 + 0.5 * input / threshold)^ modified_zwicker_power- 1);
        else
            loudness_dens (band) = 0;
        end
    
        loudness_dens (band) = loudness_dens (band)* Sl;
    end
    


function result= pseudo_Lp (x, p)
    
    global Nb width_of_band_bark
    totalWeight = 0;
    result = 0;
    for band = 2: Nb
        h = abs (x (band));
        w = width_of_band_bark (band);
        prod = h * w;
    
        result = result+ prod^ p;
        totalWeight = totalWeight+ w;
    end
    result = (result/ totalWeight)^ (1/p);
    result = result* totalWeight;
    


function mod_pitch_pow_dens_ref= freq_resp_compensation (number_of_frames, ...
        pitch_pow_dens_ref, avg_pitch_pow_dens_ref, ...
        avg_pitch_pow_dens_deg, constant)
    
    global Nb
    
    for band = 1: Nb
        x = (avg_pitch_pow_dens_deg (band) + constant) / ...
            (avg_pitch_pow_dens_ref (band) + constant);
        if (x > 100.0) 
            x = 100.0;
        elseif (x < 0.01) 
            x = 0.01;
        end
    
        for frame = 1: number_of_frames
            mod_pitch_pow_dens_ref(frame, band) = ...
                pitch_pow_dens_ref(frame, band) * x;
        end
    end
    


function avg_pitch_pow_dens= time_avg_audible_of(number_of_frames, ...
        silent, pitch_pow_dens, total_number_of_frames) 
    
    global Nb abs_thresh_power
    
    for band = 1: Nb
        result = 0;
        for frame = 1: number_of_frames
            if (~silent (frame)) 
                h = pitch_pow_dens (frame, band);
                if (h > 100 * abs_thresh_power (band)) 
                    result = result + h;
                end
            end
    
            avg_pitch_pow_dens (band) = result/ total_number_of_frames;
        end
    end  
    


function hz_spectrum= short_term_fft (Nf, data, Whanning, start_sample)
    
    x1= data( start_sample: start_sample+ Nf-1).* Whanning;
    x1_fft= fft( x1);
    hz_spectrum= abs( x1_fft( 1: Nf/ 2)).^ 2;
    hz_spectrum( 1)= 0;
    


function pitch_pow_dens= freq_warping( hz_spectrum, Nb, frame)
    
    global nr_of_hz_bands_per_bark_band pow_dens_correction_factor
    global Sp
    
    hz_band = 1;
    for bark_band = 1: Nb
        n = nr_of_hz_bands_per_bark_band (bark_band);    
        sum = 0;
        for i = 1: n
            sum = sum+ hz_spectrum( hz_band);
            hz_band= hz_band+ 1;
        end
        sum = sum* pow_dens_correction_factor (bark_band);
        sum = sum* Sp;
        pitch_pow_dens (bark_band) = sum;
    
    end
    


function total_audible_pow = total_audible (frame, ...
        pitch_pow_dens, factor)
    
    global Nb abs_thresh_power
    
    total_audible_pow = 0;
    for band= 2: Nb
        h = pitch_pow_dens (frame+ 1,band);
        threshold = factor * abs_thresh_power (band);
        if (h > threshold) 
            total_audible_pow = total_audible_pow+ h;
        end
    end
    


function pesq_testbench( testfiles, result)
    % used to calculate pesq score for noisy and enhanced speech 
    
    fid= fopen( testfiles, 'rt');
    fid1= fopen( result, 'wt');
    tline= fgetl( fid);
    srate= str2num( tline);
    % the first element is the sampling rate
    
    while 1
        tline = fgetl(fid);
        if ~ischar(tline)
            break;
        end
        if tline== '$'
            % beginning of new set of clean/noisy/enhanced speech files
            clean= fgetl( fid); % get clean file
            noisy= fgetl( fid); % get noisy file
            fprintf( 1, 'pesq_measure( %d, %s, %s)\n', srate, clean, noisy);
            noisy_pesq= pesq_measure( srate, clean, noisy);
            fprintf( fid1, '\nnew set of clean/noisy/enhanced speech files:\n');
            fprintf( fid1, '(%d, %s, %s)\t %4.3f\n', srate, ...
                clean, noisy, noisy_pesq);
        elseif tline== '#'
            % end of testfile
            break;
        else        
            enhanced= tline;
            fprintf( 1, 'pesq_measure( %d, %s, %s)\n', srate, clean, enhanced);
            enhanced_pesq= pesq_measure( srate, clean, enhanced);
            fprintf( fid1, '(%d, %s, %s)\t %4.3f\n', srate, ...
                clean, enhanced, enhanced_pesq);
        end
    
    end
    
    fclose( fid);
    fclose( fid1);
    


function power= pow_of( data, start_point, end_point, divisor)
    
    power= sum( data( start_point: end_point).^ 2)/ divisor; 
    


function setup_global( sampling_rate);
    
    global Downsample InIIR_Hsos InIIR_Nsos Align_Nfft
    global DATAPADDING_MSECS SEARCHBUFFER Fs MINSPEECHLGTH JOINSPEECHLGTH
    
    global Nutterances Largest_uttsize Nsurf_samples Crude_DelayEst
    global Crude_DelayConf UttSearch_Start UttSearch_End Utt_DelayEst
    global Utt_Delay Utt_DelayConf Utt_Start Utt_End
    global MAXNUTTERANCES WHOLE_SIGNAL
    global pesq_mos subj_mos cond_nr MINUTTLENGTH
    global CALIBRATE Nfmax Nb Sl Sp 
    global nr_of_hz_bands_per_bark_band centre_of_band_bark 
    global width_of_band_hz centre_of_band_hz width_of_band_bark 
    global pow_dens_correction_factor abs_thresh_power
    
    CALIBRATE= 0;
    Nfmax= 512;
    
    MAXNUTTERANCES= 50;
    MINUTTLENGTH= 50;
    WHOLE_SIGNAL= -1;
    UttSearch_Star= zeros( 1, MAXNUTTERANCES);
    UttSearch_End= zeros( 1, MAXNUTTERANCES);
    Utt_DelayEst= zeros( 1, MAXNUTTERANCES);
    Utt_Delay= zeros( 1, MAXNUTTERANCES);
    Utt_DelayConf= zeros( 1, MAXNUTTERANCES);
    Utt_Start= zeros( 1, MAXNUTTERANCES);
    Utt_End= zeros( 1, MAXNUTTERANCES);
    
    DATAPADDING_MSECS= 320;
    SEARCHBUFFER= 75;
    MINSPEECHLGTH= 4;
    JOINSPEECHLGTH= 50;


% KKW ---------

    global WB_InIIR_Nsos WB_InIIR_Hsos

    switch sampling_rate 
    
        case 8E3
            WB_InIIR_Nsos = 1;
            WB_InIIR_Hsos = [ 2.6657628,  -5.3315255,  2.6657628,  -1.8890331,  0.89487434 ];

        case 16E3
            WB_InIIR_Nsos = 1;
            WB_InIIR_Hsos = [ 2.740826,  -5.4816519,   2.740826,  -1.9444777,  0.94597794 ];

        otherwise
            error('Unsupported sampling rate.');

    end

% -------------

    
    Sp_16k = 6.910853e-006;
    Sl_16k = 1.866055e-001;
    fs_16k= 16000;
    Downsample_16k = 64;
    Align_Nfft_16k = 1024;
    InIIR_Nsos_16k = 12;
    InIIR_Hsos_16k = [
       0.325631521,        -0.086782860,  -0.238848661,  -1.079416490,  0.434583902;
       0.403961804,        -0.556985881,  0.153024077,   -0.415115835,  0.696590244;
       4.736162769,        3.287251046,   1.753289019,   -1.859599046,  0.876284034;
       0.365373469,        0.000000000,   0.000000000,   -0.634626531,  0.000000000;
       0.884811506,        0.000000000,   0.000000000,   -0.256725271,  0.141536777;
       0.723593055,        -1.447186099,  0.723593044,   -1.129587469,  0.657232737;
       1.644910855,        -1.817280902,  1.249658063,   -1.778403899,  0.801724355;
       0.633692689,        -0.284644314,  -0.319789663,  0.000000000,   0.000000000;
       1.032763031,        0.268428979,   0.602913323,   0.000000000,   0.000000000;
       1.001616361,        -0.823749013,  0.439731942,   -0.885778255,  0.000000000;
       0.752472096,        -0.375388990,  0.188977609,   -0.077258216,  0.247230734;
       1.023700575,        0.001661628,   0.521284240,   -0.183867259,  0.354324187
       ];
    
    Sp_8k = 2.764344e-5;
    Sl_8k = 1.866055e-1;
    fs_8k= 8000;
    Downsample_8k = 32;
    Align_Nfft_8k = 512;
    InIIR_Nsos_8k = 8;
    InIIR_Hsos_8k = [
        0.885535424,       -0.885535424,  0.000000000,   -0.771070709,  0.000000000;
        0.895092588,       1.292907193,   0.449260174,   1.268869037,   0.442025372;
        4.049527940,       -7.865190042,  3.815662102,   -1.746859852,  0.786305963;
        0.500002353,       -0.500002353,  0.000000000,   0.000000000,   0.000000000;
        0.565002834,       -0.241585934,  -0.306009671,  0.259688659,   0.249979657;
        2.115237288,       0.919935084,   1.141240051,   -1.587313419,  0.665935315;
        0.912224584,       -0.224397719,  -0.641121413,  -0.246029464,  -0.556720590;
        0.444617727,       -0.307589321,  0.141638062,   -0.996391149,  0.502251622
        ];
    
    nr_of_hz_bands_per_bark_band_8k = [
        1,    1,    1,    1,    1,     1,    1,    1,    2,    1, ...
        1,    1,    1,    1,    2,     1,    1,    2,    2,    2, ...
        2,    2,    2,    2,    2,     3,    3,    3,    3,    4, ...
        3,    4,    5,    4,    5,     6,    6,    7,    8,    9, ...
        9,    11
        ];
    
    centre_of_band_bark_8k = [
        0.078672,   0.316341,   0.636559,   0.961246,   1.290450, ...
        1.624217,   1.962597,   2.305636,   2.653383,   3.005889, ...
        3.363201,   3.725371,   4.092449,   4.464486,   4.841533, ...
        5.223642,   5.610866,   6.003256,   6.400869,   6.803755, ...
        7.211971,   7.625571,   8.044611,   8.469146,   8.899232, ...
        9.334927,   9.776288,   10.223374,  10.676242,  11.134952,...
        11.599563,  12.070135,  12.546731,  13.029408,  13.518232,...
        14.013264,  14.514566,  15.022202,  15.536238,  16.056736,...
        16.583761,  17.117382
        ];
    
    centre_of_band_hz_8k = [
        7.867213,    31.634144,   63.655895,   96.124611,   129.044968,...
        162.421738,  196.259659,  230.563568,  265.338348,  300.588867,...     
        336.320129,  372.537140,  409.244934,  446.448578,  484.568604,...     
        526.600586,  570.303833,  619.423340,  672.121643,  728.525696,...     
        785.675964,  846.835693,  909.691650,  977.063293,  1049.861694,...     
        1129.635986, 1217.257568, 1312.109497, 1412.501465, 1517.999390,...   
        1628.894165, 1746.194336, 1871.568848, 2008.776123, 2158.979248,...     
        2326.743164, 2513.787109, 2722.488770, 2952.586670, 3205.835449,... 
        3492.679932, 3820.219238
        ];
    
    width_of_band_bark_8k = [
        0.157344,     0.317994,     0.322441,     0.326934,     0.331474, ...    
        0.336061,     0.340697,     0.345381,     0.350114,     0.354897, ...    
        0.359729,     0.364611,     0.369544,     0.374529,     0.379565, ...    
        0.384653,     0.389794,     0.394989,     0.400236,     0.405538, ...    
        0.410894,     0.416306,     0.421773,     0.427297,     0.432877, ...    
        0.438514,     0.444209,     0.449962,     0.455774,     0.461645, ...    
        0.467577,     0.473569,     0.479621,     0.485736,     0.491912, ...    
        0.498151,     0.504454,     0.510819,     0.517250,     0.523745, ...    
        0.530308,     0.536934
        ];
    
    width_of_band_hz_8k = [
        15.734426,  31.799433,  32.244064,   32.693359,   33.147385, ...    
        33.606140,  34.069702,  34.538116,   35.011429,   35.489655, ...    
        35.972870,  36.461121,  36.954407,   37.452911,   40.269653, ...    
        42.311859,  45.992554,  51.348511,   55.040527,   56.775208, ...    
        58.699402,  62.445862,  64.820923,   69.195374,   76.745667, ...   
        84.016235,  90.825684,  97.931152,   103.348877,  107.801880, ...    
        113.552246, 121.490601, 130.420410,  143.431763,  158.486816,  ...   
        176.872803, 198.314697, 219.549561,  240.600098,  268.702393,  ...   
        306.060059, 349.937012
        ];
    
    pow_dens_correction_factor_8k = [
        100.000000,  99.999992,   100.000000,  100.000008,   100.000008,... 
        100.000015,  99.999992,   99.999969,   50.000027,    100.000000,...     
        99.999969,   100.000015,  99.999947,   100.000061,   53.047077, ...    
        110.000046,  117.991989,  65.000000,   68.760147,    69.999931, ...    
        71.428818,   75.000038,   76.843384,   80.968781,    88.646126, ...    
        63.864388,   68.155350,   72.547775,   75.584831,    58.379192,...     
        80.950836,   64.135651,   54.384785,   73.821884,    64.437073, ...    
        59.176456,   65.521278,   61.399822,   58.144047,    57.004543,...     
        64.126297,   59.248363
        ];
    
    abs_thresh_power_8k = [
        51286152,     2454709.500,  70794.593750,  ...
        4897.788574,  1174.897705,  389.045166,  ...
        104.712860,   45.708820,    17.782795,   ...
        9.772372,     4.897789,     3.090296,     ...
        1.905461,     1.258925,     0.977237,     ...
        0.724436,     0.562341,     0.457088,     ...
        0.389045,     0.331131,     0.295121,     ...
        0.269153,     0.257040,     0.251189,     ...
        0.251189,     0.251189,     0.251189,     ...
        0.263027,     0.288403,     0.309030,     ...
        0.338844,     0.371535,     0.398107,     ...
        0.436516,     0.467735,     0.489779,     ...
        0.501187,     0.501187,     0.512861,     ...
        0.524807,     0.524807,     0.524807
        ];
    
    nr_of_hz_bands_per_bark_band_16k = [
        1,    1,    1,    1,    1,   1,    1,    1,    2,    1,    ...
        1,    1,    1,    1,    2,   1,    1,    2,    2,    2,    ...
        2,    2,    2,    2,    2,   3,    3,    3,    3,    4,    ...
        3,    4,    5,    4,    5,   6,    6,    7,    8,    9,    ...
        9,    12,   12,   15,   16,  18,   21,   25,   20
        ];
    
    centre_of_band_bark_16k = [
        0.078672,   0.316341,   0.636559,    0.961246,     1.290450, ...
        1.624217,   1.962597,   2.305636,    2.653383,     3.005889, ...
        3.363201,   3.725371,   4.092449,    4.464486,     4.841533, ...
        5.223642,   5.610866,   6.003256,    6.400869,     6.803755, ...
        7.211971,   7.625571,   8.044611,    8.469146,     8.899232, ...
        9.334927,   9.776288,   10.223374,   10.676242,    11.134952, ...
        11.599563,  12.070135,  12.546731,   13.029408,    13.518232, ...
        14.013264,  14.514566,  15.022202,   15.536238,    16.056736, ...
        16.583761,  17.117382,  17.657663,   18.204674,    18.758478, ...
        19.319147,  19.886751,  20.461355,   21.043034
        ];
    
    centre_of_band_hz_16k = [
        7.867213,     31.634144,    63.655895,    96.124611,   129.044968,...
        162.421738,   196.259659,   230.563568,   265.338348,  300.588867,...
        336.320129,   372.537140,   409.244934,   446.448578,  484.568604,...
        526.600586,   570.303833,   619.423340,   672.121643,  728.525696,...
        785.675964,   846.835693,   909.691650,   977.063293,  1049.861694,...
        1129.635986,  1217.257568,  1312.109497,  1412.501465, 1517.999390,...
        1628.894165,  1746.194336,  1871.568848,  2008.776123, 2158.979248,...
        2326.743164,  2513.787109,  2722.488770,  2952.586670, 3205.835449,...
        3492.679932,  3820.219238,  4193.938477,  4619.846191, 5100.437012,...
        5636.199219,  6234.313477,  6946.734863,  7796.473633
        ];
    
    width_of_band_bark_16k = [
        0.157344,     0.317994,     0.322441,     0.326934,     0.331474,...
        0.336061,     0.340697,     0.345381,     0.350114,     0.354897,...
        0.359729,     0.364611,     0.369544,     0.374529,     0.379565,...
        0.384653,     0.389794,     0.394989,     0.400236,     0.405538,...
        0.410894,     0.416306,     0.421773,     0.427297,     0.432877,...
        0.438514,     0.444209,     0.449962,     0.455774,     0.461645,...
        0.467577,     0.473569,     0.479621,     0.485736,     0.491912,...
        0.498151,     0.504454,     0.510819,     0.517250,     0.523745,...
        0.530308,     0.536934,     0.543629,     0.550390,     0.557220,...
        0.564119,     0.571085,     0.578125,     0.585232
        ];
    
    width_of_band_hz_16k = [
        15.734426,     31.799433,     32.244064,     32.693359,     ...
        33.147385,     33.606140,     34.069702,     34.538116,   ...
        35.011429,     35.489655,     35.972870,     36.461121,    ... 
        36.954407,     37.452911,     40.269653,     42.311859,   ...
        45.992554,     51.348511,     55.040527,     56.775208,    ...
        58.699402,     62.445862,     64.820923,     69.195374,   ...
        76.745667,     84.016235,     90.825684,     97.931152,   ...
        103.348877,    107.801880,    113.552246,    121.490601,  ...
        130.420410,    143.431763,    158.486816,    176.872803,  ...
        198.314697,    219.549561,    240.600098,    268.702393,  ...
        306.060059,    349.937012,    398.686279,    454.713867,  ...
        506.841797,    564.863770,    637.261230,    794.717285,  ...
        931.068359
        ];
    
    pow_dens_correction_factor_16k = [
        100.000000,     99.999992,     100.000000,    100.000008,...
        100.000008,     100.000015,    99.999992,     99.999969,  ...
        50.000027,      100.000000,    99.999969,     100.000015, ...
        99.999947,      100.000061,    53.047077,     110.000046, ...
        117.991989,     65.000000,     68.760147,     69.999931, ...
        71.428818,      75.000038,     76.843384,     80.968781, ...
        88.646126,      63.864388,     68.155350,     72.547775, ...
        75.584831,      58.379192,     80.950836,     64.135651, ...
        54.384785,      73.821884,     64.437073,     59.176456,     ...
        65.521278,      61.399822,     58.144047,     57.004543,     ...
        64.126297,      54.311001,     61.114979,     55.077751,     ...
        56.849335,      55.628868,     53.137054,     54.985844,    ...
        79.546974
        ];
    
    abs_thresh_power_16k = [
        51286152.00,  2454709.500,  70794.593750,  ...
        4897.788574,  1174.897705,  389.045166,     ...
        104.712860,   45.708820,    17.782795,    ...
        9.772372,     4.897789,     3.090296,   ...
        1.905461,     1.258925,     0.977237,     ...
        0.724436,     0.562341,     0.457088,     ...
        0.389045,     0.331131,     0.295121,     ...
        0.269153,     0.257040,     0.251189,    ...
        0.251189,     0.251189,     0.251189,    ...
        0.263027,     0.288403,     0.309030,     ...
        0.338844,     0.371535,     0.398107,    ...
        0.436516,     0.467735,     0.489779,    ...
        0.501187,     0.501187,     0.512861,    ...
        0.524807,     0.524807,     0.524807,    ...
        0.512861,     0.478630,     0.426580,    ...
        0.371535,     0.363078,     0.416869,    ...
        0.537032
        ];
    
    if (sampling_rate== fs_16k)
        Downsample = Downsample_16k;
        InIIR_Hsos = InIIR_Hsos_16k;
        InIIR_Nsos = InIIR_Nsos_16k;
        Align_Nfft = Align_Nfft_16k;
        Fs= fs_16k;
    
        Nb = 49;
        Sl = Sl_16k;
        Sp = Sp_16k;
        nr_of_hz_bands_per_bark_band = nr_of_hz_bands_per_bark_band_16k;
        centre_of_band_bark = centre_of_band_bark_16k;
        centre_of_band_hz = centre_of_band_hz_16k;
        width_of_band_bark = width_of_band_bark_16k;
        width_of_band_hz = width_of_band_hz_16k;
        pow_dens_correction_factor = pow_dens_correction_factor_16k;
        abs_thresh_power = abs_thresh_power_16k;
    
        return;
    end
    
    if (sampling_rate== fs_8k)
        Downsample = Downsample_8k;
        InIIR_Hsos = InIIR_Hsos_8k;
        InIIR_Nsos = InIIR_Nsos_8k;
        Align_Nfft = Align_Nfft_8k;
        Fs= fs_8k;
    
        Nb = 42;
        Sl = Sl_8k;
        Sp = Sp_8k;
        nr_of_hz_bands_per_bark_band = nr_of_hz_bands_per_bark_band_8k;
        centre_of_band_bark = centre_of_band_bark_8k;
        centre_of_band_hz = centre_of_band_hz_8k;
        width_of_band_bark = width_of_band_bark_8k;
        width_of_band_hz = width_of_band_hz_8k;
        pow_dens_correction_factor = pow_dens_correction_factor_8k;
        abs_thresh_power = abs_thresh_power_8k;
        return;
    end
    


function split_align( ref_data, ref_Nsamples, ref_VAD, ref_logVAD, ...
        deg_data, deg_Nsamples, deg_VAD, deg_logVAD, ...
        Utt_Start_l, Utt_SpeechStart, Utt_SpeechEnd, Utt_End_l, ...
        Utt_DelayEst_l, Utt_DelayConf_l)
    
    global MAXNUTTERANCES Align_Nfft Downsample Window    
    global Utt_DelayEst Utt_Delay UttSearch_Start UttSearch_End 
    global Best_ED1 Best_D1 Best_DC1 Best_ED2 Best_D2 Best_DC2 Best_BP
    
    Utt_BPs= zeros( 1, 41);
    Utt_ED1= zeros( 1, 41);
    Utt_ED2= zeros( 1, 41);
    Utt_D1= zeros( 1, 41);
    Utt_D2= zeros( 1, 41);
    Utt_DC1= zeros( 1, 41);
    Utt_DC2= zeros( 1, 41);
    
    Utt_Len = Utt_SpeechEnd - Utt_SpeechStart;
    Utt_Test = MAXNUTTERANCES;
    Best_DC1 = 0.0;
    Best_DC2 = 0.0;
    kernel = Align_Nfft / 64;
    Delta = Align_Nfft / (4 * Downsample);
    Step = floor( ((0.801 * Utt_Len + 40 * Delta - 1)/(40 * Delta)));
    Step = Step* Delta;
    % fprintf( 'Step is %f\n', Step);
    
    Pad = floor( Utt_Len / 10);
    if( Pad < 75 ) 
        Pad = 75;
    end
    
    Utt_BPs(1) = Utt_SpeechStart + Pad;
    N_BPs = 1;
    while( 1)
        N_BPs= N_BPs+ 1;
        Utt_BPs(N_BPs)= Utt_BPs(N_BPs- 1)+ Step;
        if (~((Utt_BPs(N_BPs) <= (Utt_SpeechEnd- Pad)) && (N_BPs <= 40) ))
            break;
        end
    end
    
    if( N_BPs <= 1 ) 
        return;
    end
    
    % fprintf( 'Utt_DelayEst_l, Utt_Start_l, N_BPs is %d,%d,%d\n', ...
    %     Utt_DelayEst_l, Utt_Start_l, N_BPs);
    for bp = 1: N_BPs- 1
        Utt_DelayEst(Utt_Test) = Utt_DelayEst_l;
        UttSearch_Start(Utt_Test) = Utt_Start_l;
        UttSearch_End(Utt_Test) = Utt_BPs(bp);
    %     fprintf( 'bp,Utt_BPs(%d) is %d,%d\n', bp,bp,Utt_BPs(bp)); 
    
        crude_align( ref_logVAD, ref_Nsamples, deg_logVAD, ...
            deg_Nsamples, MAXNUTTERANCES);
        Utt_ED1(bp) = Utt_Delay(Utt_Test);
    
        Utt_DelayEst(Utt_Test) = Utt_DelayEst_l;
        UttSearch_Start(Utt_Test) = Utt_BPs(bp);
        UttSearch_End(Utt_Test) = Utt_End_l;
    
        crude_align( ref_logVAD, ref_Nsamples, deg_logVAD, ...
            deg_Nsamples, MAXNUTTERANCES);
        Utt_ED2(bp) = Utt_Delay(Utt_Test);
    end
    
    % stream = fopen( 'matmat.txt', 'wt' ); 
    % for count= 1: N_BPs- 1 
    %     fprintf( stream, '%d\n', Utt_ED2(count));
    % end
    % fclose( stream );
    
    Utt_DC1(1: N_BPs-1) = -2.0;
    % stream= fopen( 'what_mmm.txt', 'at');
    while( 1 )
        bp = 1;
        while( (bp <= N_BPs- 1) && (Utt_DC1(bp) > -2.0) )
            bp = bp+ 1;
        end
        if( bp >= N_BPs )
            break;
        end
    
        estdelay = Utt_ED1(bp);
    %     fprintf( 'bp,estdelay is %d,%d\n', bp, estdelay);
        H(1: Align_Nfft)= 0;
        Hsum = 0.0;
    
        startr = (Utt_Start_l- 1) * Downsample+ 1;
        startd = startr + estdelay;
    %     fprintf( 'startr/startd is %d/%d\n', startr, startd);
    
        if ( startd < 0 )
            startr = -estdelay+ 1;
            startd = 1;
        end

        startr = max(1,startr); % <- KKW
        startd = max(1,startd); % <- KKW
    
        while( ((startd + Align_Nfft) <= 1+ deg_Nsamples) &&...
                ((startr + Align_Nfft) <= (1+ (Utt_BPs(bp)- 1) * Downsample)) )

            X1= ref_data(startr: startr+ Align_Nfft- 1).* Window;
            X2= deg_data(startd: startd+ Align_Nfft- 1).* Window;
    
            X1_fft= fft( X1, Align_Nfft );
            X1_fft_conj= conj( X1_fft);
            X2_fft= fft( X2, Align_Nfft );
            X1= ifft( X1_fft_conj.* X2_fft, Align_Nfft);
    
            X1= abs( X1);
            v_max= max( X1)* 0.99;        
            n_max = (v_max^ 0.125 )/ kernel;
    %         fprintf( stream, '%f %f\n', v_max, n_max);
    
            for count = 0: Align_Nfft- 1
                if( X1(count+ 1) > v_max )
                    Hsum = Hsum+ n_max * kernel;
                    for k = 1-kernel: kernel- 1
                        H(1+ rem( count+ k+ Align_Nfft, Align_Nfft))= ...
                            H(1+ rem(count+ k+ Align_Nfft, Align_Nfft))+ ...
                            n_max* (kernel- abs(k));
                    end
                end
            end
    
            startr = startr+ (Align_Nfft / 4);
            startd = startd+ (Align_Nfft / 4);
        end
    
        [v_max, I_max] = max( H);
        if( I_max- 1 >= (Align_Nfft/2) )
            I_max = I_max- Align_Nfft;
        end
    
        Utt_D1(bp) = estdelay + I_max- 1;
        if( Hsum > 0.0 )
    %         if (Utt_Len== 236)
    %             fprintf( 'v_max, Hsum is %f, %f\n', v_max, Hsum);
    %         end
            Utt_DC1(bp) = v_max / Hsum;
        else
            Utt_DC1(bp) = 0.0;
        end
    
    %     fprintf( 'bp/startr/startd is %d/%d/%d\n', bp, startr, startd);
        while( bp < (N_BPs - 1) )
            bp = bp + 1;
    
            if( (Utt_ED1(bp) == estdelay) && (Utt_DC1(bp) <= -2.0) )
    %             loopno= 0;
                while(((startd+ Align_Nfft)<= 1+ deg_Nsamples) && ...
                        ((startr+ Align_Nfft)<= ...
                        ((Utt_BPs(bp)- 1)* Downsample+ 1) ))
                    X1= ref_data( startr: startr+ Align_Nfft- 1).* ...
                        Window;
    % %                 if (Utt_Len== 321)
    %                     fid= fopen( 'what_mat.txt', 'at');
    %                     fprintf( fid, '%f\n', Window);
    %                     fclose( fid);
    % %                     fprintf( '\n');
    % %                 end
                    X2= deg_data( startd: startd+ Align_Nfft- 1).* ...
                        Window;
                    X1_fft= fft( X1, Align_Nfft );
                    X1_fft_conj= conj( X1_fft);
                    X2_fft= fft( X2, Align_Nfft );
                    X1= ifft( X1_fft_conj.* X2_fft, Align_Nfft);
    
                    X1= abs( X1);
                    v_max = 0.99* max( X1);
                    n_max = (v_max^ 0.125)/ kernel;
    %                 fprintf( 'v_max n_max is %f %f\n', v_max, n_max);
    
                    for count = 0: Align_Nfft- 1
                        if( X1(count+ 1) > v_max )
                            Hsum = Hsum+ n_max * kernel;
                            for k = 1-kernel: kernel-1
                                H(1+ rem( count+ k+ Align_Nfft, Align_Nfft))= ...
                                    H(1+ rem(count+ k+ Align_Nfft, Align_Nfft))+ ...
                                    n_max* (kernel- abs(k));
                            end
                        end
                    end
    
                    startr = startr+ (Align_Nfft / 4);
                    startd = startd+ (Align_Nfft / 4);
    
    %                 loopno= loopno+ 1;
                end
    %             fprintf( 'loopno is %d\n', loopno);
    
                [v_max, I_max] = max( H);
    %             fprintf( 'I_max is %d ', I_max);
                if( I_max- 1 >= (Align_Nfft/2) )
                    I_max = I_max- Align_Nfft;
                end
    
                Utt_D1(bp) = estdelay + I_max- 1;
                if( Hsum > 0.0 )
    %                 fprintf( 'v_max Hsum is %f %f\n', v_max, Hsum);
                    Utt_DC1(bp) = v_max / Hsum;
                else
                    Utt_DC1(bp) = 0.0;
                end
            end
        end
    end
    % fclose( stream);
    
    for bp= 1: N_BPs- 1
        if( Utt_DC1(bp) > Utt_DelayConf_l )
            Utt_DC2(bp) = -2.0;
        else
            Utt_DC2(bp) = 0.0;
        end
    end
    
    while( 1 )
        bp = N_BPs- 1;
        while( (bp >= 1) && (Utt_DC2(bp) > -2.0) )
            bp = bp- 1; 
        end
        if( bp < 1 )
            break;
        end 
    
        estdelay = Utt_ED2(bp);
        H( 1: Align_Nfft)= 0;
        Hsum = 0.0;
    
        startr = (Utt_End_l- 1)* Downsample+ 1- Align_Nfft;
        startd = startr + estdelay;
    
    %     fprintf( '***NEW startr is %d\n', startr);
    
    %     fprintf( 'startr/d, deg_Nsamples is %d/%d, %d\n', startr,startd, ...
    %         deg_Nsamples);
    %     fprintf( 'deg_data has %d elements\n', numel( deg_data));
    
        if ( (startd + Align_Nfft) > deg_Nsamples+ 1 )
            startd = deg_Nsamples - Align_Nfft+ 1;
            startr = startd - estdelay;
        end
    
        while( (startd>= 1) && (startr>= (Utt_BPs(bp)- 1)* Downsample+ 1) )
            X1= ref_data( startr: startr+ Align_Nfft- 1).* Window;
            X2= deg_data( startd: startd+ Align_Nfft- 1).* Window;
    
            X1_fft= fft( X1, Align_Nfft);
            X1_fft_conj= conj( X1_fft);
            X2_fft= fft( X2, Align_Nfft);
    
            X1= ifft( X1_fft_conj.* X2_fft, Align_Nfft );
            X1= abs( X1);
    
            v_max = max( X1)* 0.99;
            n_max = ( v_max^ 0.125 )/ kernel;
    
            for count = 0: Align_Nfft- 1
                if( X1(count+ 1) > v_max )
                    Hsum = Hsum+ n_max * kernel;
                    for k = 1-kernel: kernel- 1
                        H(1+ rem(count+ k+ Align_Nfft, Align_Nfft))= ...
                            H(1+ rem(count+ k+ Align_Nfft, Align_Nfft))+ ...
                            n_max* (kernel- abs(k));
                    end
                end
            end
    
            startr = startr- (Align_Nfft / 4);
            startd = startd- (Align_Nfft / 4);
        end
    
        [v_max, I_max] = max( H);
        if( I_max- 1 >= (Align_Nfft/2) )
            I_max = I_max- Align_Nfft;
        end
    
        Utt_D2(bp) = estdelay + I_max- 1;
        if( Hsum > 0.0 )
            Utt_DC2(bp) = v_max / Hsum;
        else
            Utt_DC2(bp) = 0.0;
        end
    
        while( bp > 1 )
            bp = bp - 1;
            if( (Utt_ED2(bp) == estdelay) && (Utt_DC2(bp) <= -2.0) )
                while( (startd >= 1) && (startr >= (Utt_BPs(bp)- 1) * Downsample+ 1)) 
                     X1= ref_data( startr: startr+ Align_Nfft- 1).* Window;
                     X2= deg_data( startd: startd+ Align_Nfft- 1).* Window;
                     X1_fft_conj= conj( fft( X1, Align_Nfft));
                     X2_fft= fft( X2, Align_Nfft);
                     X1= ifft( X1_fft_conj.* X2_fft, Align_Nfft);
    
                     X1= abs( X1);
                     v_max = max( X1)* 0.99;
                     n_max = (v_max^ 0.125)/ kernel;
    
                     for count = 0: Align_Nfft- 1
                         if( X1(count+ 1) > v_max )
                             Hsum = Hsum+ n_max * kernel;
                             for k = 1-kernel: kernel- 1
                                 H(1+ rem( count+ k+ Align_Nfft, Align_Nfft))= ...
                                     H(1+ rem(count+ k+ Align_Nfft, Align_Nfft))+ ...
                                     n_max* (kernel- abs(k));
                             end
                         end
                     end
    
                     startr = startr- (Align_Nfft / 4);
                     startd = startd- (Align_Nfft / 4);
                end
    
                [v_max, I_max] = max( H);
                if( I_max- 1 >= (Align_Nfft/2) )
                    I_max = I_max- Align_Nfft;
                end
    
                Utt_D2(bp) = estdelay + I_max- 1;
                if( Hsum > 0.0 )
                    Utt_DC2(bp) = v_max / Hsum;
                else
                    Utt_DC2(bp) = 0.0;
                end
            end
        end
    end
    
    % fid= fopen( 'uttinfo_mat.txt', 'wt');
    % fprintf( fid, '%f\n', Utt_D2);
    % fprintf( fid, '\n');
    % fprintf( fid, '%f\n', Utt_DC2);
    % fclose( fid);
    
    % fprintf( 'Utt_Len, N_BPs is %d, %d\n', Utt_Len, N_BPs);
    for bp = 1: N_BPs- 1
        if( (abs(Utt_D2(bp) - Utt_D1(bp)) >= Downsample) && ...
                ((Utt_DC1(bp)+ Utt_DC2(bp))> (Best_DC1 + Best_DC2)) &&...
                (Utt_DC1(bp) > Utt_DelayConf_l) && ...
                (Utt_DC2(bp) > Utt_DelayConf_l) )
            Best_ED1 = Utt_ED1(bp);
            Best_D1 = Utt_D1(bp);
            Best_DC1 = Utt_DC1(bp);
            Best_ED2 = Utt_ED2(bp);
            Best_D2 = Utt_D2(bp);
            Best_DC2 = Utt_DC2(bp);
            Best_BP = Utt_BPs(bp);
    %         fprintf( 'in loop...');
        end
    end
    
    % if (Utt_Len== 236)
    %     fid= fopen( 'matmat.txt', 'wt');
    %     fprintf( fid, 'N_BPs is %d\n', N_BPs);
    %     fprintf( fid, 'Utt_DelayConf is %f\n', Utt_DelayConf_l);
    %     fprintf( fid, 'ED2\t ED1\t D2\t D1\t DC2\t DC1\t BPs\n');
    %     for bp= 1: N_BPs- 1
    %         fprintf( fid, '%d\t %d\t %d\t %d\t %f\t %f\t %d\n', Utt_ED2( bp), ...
    %             Utt_ED1( bp), Utt_D2(bp), Utt_D1(bp), Utt_DC2(bp),...
    %             Utt_DC1( bp), Utt_BPs( bp));
    %     end
    %     fclose( fid);
    % end
    


function time_align(ref_data, ref_Nsamples, deg_data, deg_Nsamples, Utt_id)
    
    global Utt_DelayEst Utt_Delay Utt_DelayConf UttSearch_Start UttSearch_End 
    global Align_Nfft Downsample Window
    
    estdelay = Utt_DelayEst(Utt_id);
    
    H = zeros( 1, Align_Nfft);
    X1= zeros( 1, Align_Nfft);
    X2= zeros( 1, Align_Nfft);
    
    startr = (UttSearch_Start(Utt_id)- 1)* Downsample+ 1;
    startd = startr + estdelay;
    if ( startd < 0 )
        startr = 1 -estdelay;
        startd = 1;
    end
    
    while( ((startd + Align_Nfft) <= deg_Nsamples) && ((startr + Align_Nfft) <= ((UttSearch_End(Utt_id)- 1) * Downsample)) )

        X1 = ref_data( startr: startr+ Align_Nfft- 1) .* Window;
        X2 = deg_data( startd: startd+ Align_Nfft- 1) .* Window;
    
        % find cross-correlation between X1 and X2
        X1_fft= fft( X1, Align_Nfft );
        X1_fft_conj= conj( X1_fft);
        X2_fft= fft( X2, Align_Nfft );    
        X1= ifft( X1_fft_conj.* X2_fft, Align_Nfft );        
    
        X1= abs( X1);     
        v_max = max( X1)* 0.99;
    
        X1_greater_vmax= find( X1 > v_max );
        H( X1_greater_vmax )= H( X1_greater_vmax )+ v_max^ 0.125;
    
        startr = startr+ Align_Nfft/ 4;
        startd = startd+ Align_Nfft/ 4;
    
    end
    
    X1= H;
    X2= 0;
    Hsum = sum( H);
    
    X2(1) = 1.0;
    kernel = Align_Nfft / 64;
    
    for count= 2: kernel
        X2( count)= 1- (count- 1)/ kernel;
        X2( Align_Nfft- count+ 2)= 1- (count- 1)/ kernel;
    end
    
    X1_fft= fft( X1, Align_Nfft );
    X2_fft= fft( X2, Align_Nfft );
    
    X1= ifft( X1_fft.* X2_fft, Align_Nfft );
    
    if (Hsum> 0)
        H= abs( X1)/ Hsum;
    else
        H= 0;
    end
    
    [v_max, I_max] = max( H);
    if( I_max- 1 >= (Align_Nfft/2) )
        I_max = I_max- Align_Nfft;
    end
    
    Utt_Delay(Utt_id) = estdelay + I_max- 1;
    Utt_DelayConf(Utt_id) = v_max; % confidence
    


function utterance_locate (ref_data, ref_Nsamples, ref_VAD, ref_logVAD,...
        deg_data, deg_Nsamples, deg_VAD, deg_logVAD);
    
    global Nutterances Utt_Delay Utt_DelayConf Utt_Start Utt_End Utt_DelayEst
    
    id_searchwindows( ref_VAD, ref_Nsamples, deg_VAD, deg_Nsamples);
    
    for Utt_id= 1: Nutterances
        %fprintf( 1, 'Utt_id is %d\n', Utt_id);
        crude_align( ref_logVAD, ref_Nsamples, deg_logVAD, deg_Nsamples, Utt_id);
        time_align(ref_data, ref_Nsamples, ...
            deg_data, deg_Nsamples, Utt_id);
    end
    
    id_utterances( ref_Nsamples, ref_VAD, deg_Nsamples);
    % fid= fopen( 'mat_utt_info.txt', 'wt');
    % fprintf( fid, 'Utt_DelayEst: \n');
    % fprintf( fid, '%d\n', Utt_DelayEst( 1: Nutterances));
    % fprintf( fid, 'Utt_Delay:\n');
    % fprintf( fid, '%d\n', Utt_Delay(1: Nutterances));
    % fprintf( fid, 'Utt_Delay confidence:\n');
    % fprintf( fid, '%f\n', Utt_DelayConf(1: Nutterances));
    % fprintf( fid, 'Utt_Start: \n');
    % fprintf( fid, '%d\n', Utt_Start( 1: Nutterances));
    % fprintf( fid, 'Utt_End: \n');
    % fprintf( fid, '%d\n', Utt_End(1: Nutterances));
    % fclose( fid);
    
    utterance_split( ref_data, ref_Nsamples, ref_VAD, ref_logVAD, ...
        deg_data, deg_Nsamples, deg_VAD, deg_logVAD); 
    


function utterance_split( ref_data, ref_Nsamples, ref_VAD, ref_logVAD, ...
        deg_data, deg_Nsamples, deg_VAD, deg_logVAD)
    
    global Nutterances MAXNUTTERANCES Downsample SEARCHBUFFER
    global Utt_DelayEst Utt_Delay Utt_DelayConf UttSearch_Start
    global Utt_Start Utt_End Largest_uttsize UttSearch_End
    global Best_ED1 Best_D1 Best_DC1 Best_ED2 Best_D2 Best_DC2 Best_BP
    
    Utt_id = 1;
    while( (Utt_id <= Nutterances) && (Nutterances <= MAXNUTTERANCES) )
        Utt_DelayEst_l = Utt_DelayEst(Utt_id);
        Utt_Delay_l = Utt_Delay(Utt_id);
        Utt_DelayConf_l = Utt_DelayConf(Utt_id);
        Utt_Start_l = Utt_Start(Utt_id);
        Utt_End_l = Utt_End(Utt_id);
    
        Utt_SpeechStart = Utt_Start_l;
        Utt_SpeechStart = max([1 Utt_SpeechStart]); % <- KKW
         %fprintf( 'SpeechStart is %d\n', Utt_SpeechStart);
        while( (Utt_SpeechStart < Utt_End_l) && ...
                (ref_VAD(Utt_SpeechStart)<= 0.0) )
            Utt_SpeechStart = Utt_SpeechStart + 1;
        end %find the SpeechStart for each utterance
        Utt_SpeechEnd = Utt_End_l;
    %     fprintf( 'SpeechEnd is %d\n', Utt_SpeechEnd);
        while( (Utt_SpeechEnd > Utt_Start_l) && ...
                (ref_VAD(Utt_SpeechEnd) <= 0))
            Utt_SpeechEnd = Utt_SpeechEnd- 1;
        end
        Utt_SpeechEnd = Utt_SpeechEnd+ 1;    
        %find SpeechEnd for each utterance
        Utt_Len = Utt_SpeechEnd - Utt_SpeechStart;
    
    %     fprintf( 'Utt_Len is %d\n', Utt_Len);
    
        if( Utt_Len >= 200 )
            split_align( ref_data, ref_Nsamples, ref_VAD, ref_logVAD, ...
                deg_data, deg_Nsamples, deg_VAD, deg_logVAD, ...
                Utt_Start_l, Utt_SpeechStart, Utt_SpeechEnd, Utt_End_l, ...
                Utt_DelayEst_l, Utt_DelayConf_l);
    %         fprintf( '\nBest_ED1, Best_D1, Best_DC1 is %d, %d, %f\n',...
    %               Best_ED1, Best_D1, Best_DC1);
    %         fprintf( 'Best_ED2, Best_D2, Best_DC2 is %d, %d, %f\n',...
    %               Best_ED2, Best_D2, Best_DC2);
    %         fprintf( 'Best_BP is %d\n', Best_BP);
    
            if( (Best_DC1 > Utt_DelayConf_l) && (Best_DC2 > Utt_DelayConf_l) )
                for step = Nutterances: -1: Utt_id+ 1
                    Utt_DelayEst(step+ 1) = Utt_DelayEst(step);
                    Utt_Delay(step+ 1) = Utt_Delay(step);
                    Utt_DelayConf(step+ 1) = Utt_DelayConf(step);
                    Utt_Start(step+ 1) = Utt_Start(step);
                    Utt_End(step+ 1) = Utt_End(step);
                    UttSearch_Start(step+ 1) = Utt_Start( step);
                    UttSearch_End(step+ 1) = Utt_End( step);
                end
    
                Nutterances = Nutterances+ 1;
    
                Utt_DelayEst(Utt_id) = Best_ED1;
                Utt_Delay(Utt_id) = Best_D1;
                Utt_DelayConf(Utt_id) = Best_DC1;
    
                Utt_DelayEst(Utt_id +1) = Best_ED2;
                Utt_Delay(Utt_id +1) = Best_D2;
                Utt_DelayConf(Utt_id +1) = Best_DC2;
    
                UttSearch_Start(Utt_id +1) = UttSearch_Start(Utt_id);
                UttSearch_End(Utt_id +1) = UttSearch_End( Utt_id);
                if( Best_D2 < Best_D1 )
                    Utt_Start(Utt_id) = Utt_Start_l;
                    Utt_End(Utt_id) = Best_BP;
                    Utt_Start(Utt_id +1) = Best_BP;
                    Utt_End(Utt_id +1) = Utt_End_l;
                else
                    Utt_Start( Utt_id) = Utt_Start_l;
                    Utt_End( Utt_id) = Best_BP + ...
                        floor( (Best_D2- Best_D1)/ (2 * Downsample));
                    Utt_Start( Utt_id +1) = Best_BP - ...
                        floor( (Best_D2- Best_D1)/ (2 * Downsample));
                    Utt_End( Utt_id +1) = Utt_End_l;
                end
    
                if( (Utt_Start(Utt_id)- SEARCHBUFFER- 1)* Downsample+ 1+ ...
                        Best_D1 < 0 )
                    Utt_Start(Utt_id) = SEARCHBUFFER+ 1+  ...
                        floor( (Downsample - 1 - Best_D1) / Downsample);
                end
    
                if( ((Utt_End( Utt_id +1)- 1)* Downsample+ 1 + Best_D2) >...
                        (deg_Nsamples - SEARCHBUFFER * Downsample) )
                    Utt_End( Utt_id +1) = floor( (deg_Nsamples - Best_D2)...
                        / Downsample)- SEARCHBUFFER+ 1;
                end
            else
                Utt_id= Utt_id+ 1;
            end
        else
            Utt_id = Utt_id+ 1;
        end
    end
    
    Largest_uttsize = max( Utt_End- Utt_Start);
    
    % fid= fopen( 'uttinfo_mat.txt', 'wt');
    % fprintf( fid, 'Number of Utterances is:\n');
    % fprintf( fid, '%d\n', Nutterances);
    % fprintf( fid, 'Utterance Delay Estimation:\n');
    % fprintf( fid, '%d\n', Utt_DelayEst( 1: Nutterances) );
    % fprintf( fid, 'Utterance Delay:\n');
    % fprintf( fid, '%d\n', Utt_Delay( 1: Nutterances));
    % fprintf( fid, 'Utterance Delay Confidence:\n');
    % fprintf( fid, '%f\n', Utt_DelayConf( 1: Nutterances));
    % fprintf( fid, 'Utterance Start:\n');
    % fprintf( fid, '%d\n', Utt_Start( 1: Nutterances));
    % fprintf( fid, 'Utterance End:\n');
    % fprintf( fid, '%d\n', Utt_End( 1: Nutterances));
    % fprintf( fid, 'Largest utterance length:\n');
    % fprintf( fid, '%d\n', Largest_uttsize);
    % fclose( fid);
    

% EOF
