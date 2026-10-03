function [y,tEst,phat_mat,lambda_d_mat,eta,Nframes,M,Mno]=trans_estimating_omlsa_UC(yIn,numUCframes)
% Transient estimatimg OM-LSA
% ***************************************************************@
% This code is based on the OM-LSA algorithm (I. Cohen, 2002)
%****************************************************************@
% Inputs and Outputs:
%    fin,  noisy input  file name (fin.wav)
%    fout, output file name (fout.wav)
%    ftrans, estimated transient file name (ftrans.wav)
%
% Copyright (c) 2012. David Dov, Ariel Hiszhorn
% All rights reserved. 
% ***************************************************************@

Fs=16000;
nfft=64;
tEst=zeros(size(yIn));

phat_mat=[];
lambda_d_mat=[];


% 1) Parameters of Short Time Fourier Analysis:
Fs_ref=16e3;		% 1.1) Reference Sampling frequency
M_ref=nfft;		% 1.2) Size of analysis window
Mo_ref=0.75*M_ref;	% 1.3) Number of overlapping samples in consecutive frames

% 2) Parameters of Noise Spectrum Estimate
w=1;			% 2.1)  Size of frequency smoothing window function=2*w+1
alpha_s_ref=0.85;	% 2.2)  Recursive averaging parameter for the smoothing operation
Nwin=2; 	% 2.3)  Resolution of local minima search
Vwin=5;
delta_s=1.67;		% 2.4)  Local minimum factor (1.67)
Bmin=1.66;              
delta_y=4.6;		% 2.4)  Local minimum factor
delta_yt=3;
alpha_d_ref=0.7;	% 2.7)  Recursive averaging parameter for the noise

% 3) Parameters of a Priori Probability for Signal-Absence Estimate
alpha_xi_ref=0.5;	% 3.1) Recursive averaging parameter
w_xi_local=1; 	% 3.2) Size of frequency local smoothing window function
w_xi_global=15; 	% 3.3) Size of frequency local smoothing window function
f_u=10e3; 		% 3.4) Upper frequency threshold for global decision
f_l=50; 		% 3.5) Lower frequency threshold for global decision
P_min=0.005; 		% 3.6) Lower bound constraint
xi_lu_dB=-5; 	% 3.7) Upper threshold for local decision
xi_ll_dB=-10; 	% 3.8) Lower threshold for local decision
xi_gu_dB=-5; 	% 3.9) Upper threshold for global decision
xi_gl_dB=-10; 	% 3.10) Lower threshold for global decision
xi_fu_dB=-5; 	% 3.11) Upper threshold for local decision
xi_fl_dB=-10; 	% 3.12) Lower threshold for local decision
xi_mu_dB=10; 	% 3.13) Upper threshold for xi_m
xi_ml_dB=0; 		% 3.14) Lower threshold for xi_m
q_max=0.998; 		% 3.15) Upper limit constraint

% 4) Parameters of "Decision-Directed" a Priori SNR Estimate
alpha_eta_ref=0.8;	% 4.1) Recursive averaging parameter
eta_min_dB=-30;	% 4.2) Lower limit constraint    our:was -18

% 5) Flags
broad_flag=1;               % broad band flag   % new version
tone_flag=1;                % pure tone flag   % new version
clicks_flag=1;          % clicks flag   % new version
nonstat='high';                %Non stationarity  % new version


% Read input data
%[y,Fs,NBITS]=wavread(fin);  % read input data
% [N,Fs,NBITS]=wavread(fin,0);  % read size of input data, Fs and NBITS
% N = N(1);
N=length(yIn);
% Adjust parameters according to the actual sampling frequency
if Fs~=Fs_ref
    M=2^round(log2(Fs/Fs_ref*M_ref));
    Mo=Mo_ref/M_ref*M;
    alpha_s=alpha_s_ref^(M_ref/M*Fs/Fs_ref);
    alpha_d=alpha_d_ref^(M_ref/M*Fs/Fs_ref);
    alpha_eta=alpha_eta_ref^(M_ref/M*Fs/Fs_ref);
    alpha_xi=alpha_xi_ref^(M_ref/M*Fs/Fs_ref);
else
    M=M_ref;
    Mo=Mo_ref;
    alpha_s=alpha_s_ref;
    alpha_d=alpha_d_ref;
    alpha_eta=alpha_eta_ref;
    alpha_xi=alpha_xi_ref;
end
alpha_d_long=0.99;
eta_min=10^(eta_min_dB/10);
G_f=eta_min^0.5;	   % Gain floor

% window function
win=hamming(M);
% find a normalization factor for the window
Mno=M-Mo;
win2=win.^2;
W0=win2(1:Mno);
for k=Mno:Mno:M-1
    swin2=lnshift(win2,k);
    W0=W0+swin2(1:Mno);
end
W0=mean(W0)^0.5;
win=win/W0;
Cwin=sum(win.^2)^0.5;
win=win/Cwin;

out=zeros(M,1);
Nframes=fix((N-Mo)/(M-Mo));   %  number of frames
b=hanning(2*w+1);
b=b/sum(b);     % normalize the window function
b_xi_local=hanning(2*w_xi_local+1);
b_xi_local=b_xi_local/sum(b_xi_local);  % normalize the window function
b_xi_global=hanning(2*w_xi_global+1);
b_xi_global=b_xi_global/sum(b_xi_global);   % normalize the window function
l_mod_lswitch=0;
M21=M/2+1;
k_u=round(f_u/Fs*M+1);  % Upper frequency bin for global decision
k_l=round(f_l/Fs*M+1);  % Lower frequency bin for global decision
k_u=min(k_u,M21);
k1_local=round(155/Fs*M+1);
k2_local=round(500/Fs*M+1);
k3_local=round(3500/Fs*M+1);
eta_2term=1; q=0; gamma=1; G=ones(M21,1); xi=0; eta=zeros(M21,1); xi_frame=0;
Ncount=round(Nframes/10);
waitHandle=waitbar(0,'Please wait...');
l_fnz=1;      % counter for the first frame which is non-zero    % new version omlsa3
fnz_flag=0;     % flag for the first frame which is non-zero    % new version omlsa3
zero_thres=1e-10;      % new version omlsa3
% zero_thres is a threshold for discriminating between zero and nonzero sample.
% You may choose zero_thres=0, but then the program  handles samples which are identically zero (and not “epsilon” values).

%% read y_frames for Smin_uc calculation
[y_frames]=read_file(yIn,M,Mno,Nframes);

%%
for l=1:Nframes
    
     if l==1
        %[y,Fs,wmode,fidx]=readwav(fin,'rf',M,0);    % open input file and read one frame of data
         y=yIn(1:nfft);
        
    else
        %[y0,Fs,wmode,fidx]=readwav(fidx,'rf',Mno);
        %y=[y(Mno+1:M,:) ; y0];      % update the frame of data
        y=yIn((l-1)*Mno+1:(l-1)*Mno+M);
    end

    if (~fnz_flag && abs(y(1))>zero_thres) ||  (fnz_flag && any(abs(y)>zero_thres))       % new version omlsa3
        fnz_flag=1;     % new version omlsa3

        % 1. Short Time Fourier Analysis
        Y=fft(win.*y);
        Ya2=abs(Y(1:M21)).^2;

        %         if l==1     % new version omlsa3
        if l==l_fnz     % new version omlsa3
            lambda_d=Ya2;
        end
        gamma=Ya2./max(lambda_d,1e-10);
        eta=alpha_eta*eta_2term+(1-alpha_eta)*max(gamma-1,0);
        eta=max(eta,eta_min);
        v=gamma.*eta./(1+eta);

        % 2.1. smooth over frequency
        Sf=conv(b,Ya2);  % smooth over frequency
        Sf=Sf(w+1:M21+w);
        %         if l==1     % new version omlsa3
        if l==l_fnz     % new version omlsa3
            Sy=Ya2;
            S=Sf;
            St=Sf;
            lambda_dav=Ya2;
        else
            S=alpha_s*S+(1-alpha_s)*Sf;     % smooth over time
        end
        %         if l<15     % new version omlsa3
        if l<14+l_fnz     % new version omlsa3
            Smin=S;
            SMact=S;
        else
            Smin=min(Smin,S);
            SMact=min(SMact,S);
        end
        
        % Local Minima Search
        I_f=(Ya2<delta_y*Bmin.*Smin & S<delta_s*Bmin.*Smin); % indicator (40)
        conv_I=conv(b,double(I_f));
        conv_I=conv_I(w+1:M21+w);
        Sft=St;
        idx=find(conv_I);
        if ~isempty(idx)
            if w
                conv_Y=conv(b,I_f.*Ya2);
                conv_Y=conv_Y(w+1:M21+w);
                Sft(idx)=conv_Y(idx)./conv_I(idx);
            else
                Sft(idx)=Ya2(idx);
            end
        end
        %         if l<15     % new version omlsa3
        if l<14+l_fnz     % new version omlsa3
            St=S;
%             Smint=St;
             Smint_C=St;
            SMactt=St;
        else
            St=alpha_s*St+(1-alpha_s)*Sft;
%               Smint=min(Smint,St);
            Smint_C=min(Smint_C,St);
            SMactt=min(SMactt,St);
        end
%% %%%%%%%%%%%%%% 
%          num_UC_frames=40;
        if l<Nframes-(numUCframes-1+l_fnz)
            Smint_UC=Smint_UC_calc(l,Vwin,l_fnz,y_frames,win,M21,b,w,S,alpha_s,delta_y,delta_s,Bmin,St,Nwin,numUCframes);
            Smint=max(Smint_C,Smint_UC) ;
        else
            Smint=Smint_C;
        end
%         Smint=Smint_C;
%% %%%%%%%%%%%%%%
 
        qhat=ones(M21,1);
        phat=zeros(M21,1);
        %     gamma_mint=Ya2./Bmin./max(Smint,1e-10);   % new version
        %     zetat=S./Bmin./max(Smint,1e-10);      % new version
        switch nonstat    % new version
            case   'low'  % new version
                gamma_mint=Ya2./Bmin./max(Smin,1e-10);   % new version
                zetat=S./Bmin./max(Smin,1e-10);      % new version
            otherwise  % new version
                gamma_mint=Ya2./Bmin./max(Smint,1e-10);   % new version
                zetat=S./Bmin./max(Smint,1e-10);      % new version
        end  % new version
        idx=find(gamma_mint>1 & gamma_mint<delta_yt & zetat<delta_s);
        qhat(idx)=(delta_yt-gamma_mint(idx))/(delta_yt-1);
        phat(idx)=1./(1+qhat(idx)./(1-qhat(idx)).*(1+eta(idx)).*exp(-v(idx)));
        idx=find(gamma_mint>=delta_yt | zetat>=delta_s);
        qhat(idx)=0;
        phat(idx)=1;
        alpha_dt=alpha_d+(1-alpha_d)*phat;
        lambda_dav=alpha_dt.*lambda_dav+(1-alpha_dt).*Ya2;
        %         if l<15     % new version omlsa3
        if l<14+l_fnz     % new version omlsa3
            lambda_dav_long=lambda_dav;
        else
            alpha_dt_long=alpha_d_long+(1-alpha_d_long)*phat;
            lambda_dav_long=alpha_dt_long.*lambda_dav_long+(1-alpha_dt_long).*Ya2;
        end
        l_mod_lswitch=l_mod_lswitch+1;
        if l_mod_lswitch==Vwin
            l_mod_lswitch=0;
            %             if l==Vwin    % new version omlsa3
            if l==Vwin-1+l_fnz    % new version omlsa3
                SW=repmat(S,1,Nwin);
                SWt=repmat(St,1,Nwin);
            else
                SW=[SW(:,2:Nwin) SMact];
                Smin=min(SW,[],2);
                SMact=S;
                SWt=[SWt(:,2:Nwin) SMactt];
                Smint_C=min(SWt,[],2);
                SMactt=St;
            end
        end
        % 2.4. Noise Spectrum Estimate
        %     lambda_d=1.4685*lambda_dav;  % new version
        switch nonstat    % new version
            case   'high'  % new version
                %lambda_d=2*lambda_dav;  % new version
                lambda_d=5*lambda_dav;
            otherwise  % new version
                lambda_d=1.4685*lambda_dav;  % new version
        end  % new version


        % 4. A Priori Probability for Signal-Absence Estimate
        xi=alpha_xi*xi+(1-alpha_xi)*eta;
        xi_local=conv(xi,b_xi_local);
        xi_local=xi_local(w_xi_local+1:M21+w_xi_local);
        xi_global=conv(xi,b_xi_global);
        xi_global=xi_global(w_xi_global+1:M21+w_xi_global);
        dxi_frame=xi_frame;
        xi_frame=mean(xi(k_l:k_u));
        dxi_frame=xi_frame-dxi_frame;
        if xi_local>0, xi_local_dB=10*log10(xi_local); else, xi_local_dB=-100; end
        if xi_global>0, xi_global_dB=10*log10(xi_global); else, xi_global_dB=-100; end
        if xi_frame>0, xi_frame_dB=10*log10(xi_frame); else, xi_frame_dB=-100; end

        P_local=ones(M21,1);
        idx=find(xi_local_dB<=xi_ll_dB);
        P_local(idx)=P_min;
        idx=find(xi_local_dB>xi_ll_dB & xi_local_dB<xi_lu_dB);
        P_local(idx)=P_min+(xi_local_dB(idx)-xi_ll_dB)/(xi_lu_dB-xi_ll_dB)*(1-P_min);

        P_global=ones(M21,1);
        idx=find(xi_global_dB<=xi_gl_dB);
        P_global(idx)=P_min;
        idx=find(xi_global_dB>xi_gl_dB & xi_global_dB<xi_gu_dB);
        P_global(idx)=P_min+(xi_global_dB(idx)-xi_gl_dB)/(xi_gu_dB-xi_gl_dB)*(1-P_min);

        m_P_local=mean(P_local(3:(k2_local+k3_local-3)));    % average probability of speech presence
        if m_P_local<0.25
            P_local(k2_local:k3_local)=P_min;    % reset P_local (frequency>500Hz) for low probability of speech presence
        end
        if tone_flag               % new version
            if (m_P_local<0.5) & (l>120)
                idx=find( lambda_dav_long(8:(M21-8)) > 2.5*(lambda_dav_long(10:(M21-6))+lambda_dav_long(6:(M21-10))) );
                P_local([idx+6;idx+7;idx+8])=P_min;   % remove interfering tonals
            end
        end              % new version

        if xi_frame_dB<=xi_fl_dB
            P_frame=P_min;
        elseif dxi_frame>=0
            xi_m_dB=min(max(xi_frame_dB,xi_ml_dB),xi_mu_dB);
            P_frame=1;
        elseif xi_frame_dB>=xi_m_dB+xi_fu_dB
            P_frame=1;
        elseif xi_frame_dB<=xi_m_dB+xi_fl_dB
            P_frame=P_min;
        else
            P_frame=P_min+(xi_frame_dB-xi_m_dB-xi_fl_dB)/(xi_fu_dB-xi_fl_dB)*(1-P_min);
        end

        %     q=1-P_global.*P_local*P_frame;   % new version
        if broad_flag   % new version
            q=1-P_global.*P_local*P_frame;   % new version
        else   % new version
            q=1-P_local*P_frame;   % new version
        end   % new version
        q=min(q,q_max);

        gamma=Ya2./max(lambda_d,1e-10);
        eta=alpha_eta*eta_2term+(1-alpha_eta)*max(gamma-1,0);
        eta=max(eta,eta_min);
        v=gamma.*eta./(1+eta);
        PH1=zeros(M21,1);
        idx=find(q<0.9);
        PH1(idx)=1./(1+q(idx)./(1-q(idx)).*(1+eta(idx)).*exp(-v(idx)));

        % 7. Spectral Gain
        GH1=ones(M21,1);
        idx=find(v>5);
        GH1(idx)=eta(idx)./(1+eta(idx));
        idx=find(v<=5 & v>0);
        GH1(idx)=eta(idx)./(1+eta(idx)).*exp(0.5*expint(v(idx)));

        %     Smint_global=[Smint [Smint(2:M21);Smint(M21)] [Smint(3:M21);Smint(M21-1:M21)] [Smint(4:M21);Smint(M21-2:M21)] [Smint(1);Smint(1:M21-1)] [Smint(1:2);Smint(1:M21-2)] [Smint(1:3);Smint(1:M21-3)]];   % new version
        %     Smint_global=min(Smint_global,[],2);   % new version
        %     lambda_d_global=1.5*Bmin*Smint_global;   % new version
        %    Sy=0.8*Sy+0.2*Ya2;    % new version
        %     GH0=G_f*(lambda_d_global./Sy).^0.5;    % new version
        if tone_flag   % new version
            lambda_d_global=lambda_d;   % new version
            lambda_d_global(4:M21-3)=min([lambda_d_global(4:M21-3),lambda_d_global(1:M21-6),lambda_d_global(7:M21)],[],2);   % new version
            Sy=0.8*Sy+0.2*Ya2;    % new version
            %             GH0=G_f*(lambda_d_global./Sy).^0.5;   % new version       % new version omlsa3
            GH0=G_f*(lambda_d_global./(Sy+1e-10)).^0.5;   % new version omlsa3
        else   % new version
            GH0=G_f;   % new version
        end   % new version
        G=GH1.^PH1.*GH0.^(1-PH1);
        eta_2term=GH1.^2.*gamma;


        %    X=[zeros(3,1); G(4:M21-1).*Y(4:M21-1); 0];
        X=[zeros(2,1); G(3:M21-1).*Y(3:M21-1); 0];
        X(M21+1:M)=conj(X(M21-1:-1:2)); %extend the anti-symmetric range of the spectum
        x=Cwin^2*win.*real(ifft(X));
        out=out+x;
    else        % new version omlsa3
        if ~fnz_flag        % new version omlsa3
            l_fnz=l_fnz+1;        % new version omlsa3
        end         % new version omlsa3
    end         % new version omlsa3
   
    
    tEst((l-1)*Mno+1:l*Mno)=out(1:Mno);
    
    
    out=[out(Mno+1:M); zeros(Mno,1)];   % update output frame
    if ~mod(l,Ncount)
        %disp([sprintf('%3.0f',100*l/Nframes) '%']);
        waitbar(l/Nframes);
    end  % dispaly percentage of the processing stage

phat_mat=[phat_mat; phat'];
lambda_d_mat=[lambda_d_mat;lambda_d'];
end
close(waitHandle)




