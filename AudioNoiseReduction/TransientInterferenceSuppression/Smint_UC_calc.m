function [Smint_UC]=Smint_UC_calc(l,Vwin,l_fnz,y_frames,win,M21,b,w,S,alpha_s,delta_y,delta_s,Bmin,St,Nwin,num_UC_frames)
l_mod_lswitch=0;
for i=1:num_UC_frames-1+l_fnz
    % for i=Vwin-1+l_fnz:-1:1
    %%
    y=y_frames(:,l+i);
    Y=fft(win.*y);
    Ya2=abs(Y(1:M21)).^2;
    Sf=conv(b,Ya2);  % smooth over frequency
    Sf=Sf(w+1:M21+w);
    if i==l_fnz
        S=Sf;
        St=Sf;
    else
        S=alpha_s*S+(1-alpha_s)*Sf;     % smooth over time
    end
    
    if i<14+l_fnz     % new version omlsa3
        Smin=S;
        SMact=S; 
    else
        Smin=min(Smin,S);
        SMact=min(SMact,S);
    end

    %% Local Minima Search
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
    if i<14+l_fnz     % new version omlsa3
        St=S;
        %             Smint=St;
        Smint_UC=St;
        SMactt=St;
    else
        St=alpha_s*St+(1-alpha_s)*Sft;
        %               Smint=min(Smint,St);
        Smint_UC=min(Smint_UC,St);
        SMactt=min(SMactt,St);
    end
    
    l_mod_lswitch=l_mod_lswitch+1;
    if l_mod_lswitch==Vwin
        l_mod_lswitch=0;
        %             if l==Vwin    % new version omlsa3
        if i==Vwin-1+l_fnz    % new version omlsa3
            SW=repmat(S,1,Nwin);
            SWt=repmat(St,1,Nwin);
        else
            SW=[SW(:,2:Nwin) SMact];
            Smin=min(SW,[],2);
            SMact=S;
            SWt=[SWt(:,2:Nwin) SMactt];
            Smint_UC=min(SWt,[],2);
            SMactt=St;
        end
    end



end
