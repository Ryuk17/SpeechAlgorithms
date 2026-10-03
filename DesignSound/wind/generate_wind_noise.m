function [n] = generate_wind_noise(simpar)
%%
% Syntax:
%   [noise_sig] = generate_wind_noise(fs, L)
%
% Input arguments:
% simpar - paramater struct with following options
%   .fs:    sampling frequency 
%           (all parameters were derived for sampling of fs=16kHz, for other 
%           rates the signal is resampled using Matlabs resample function )
%   .L:     length of output signal in seconds
%   .type:  Type of wind noise: 'gusts' (default), 'constant'

% Related paper:
% C. Nelke, P. Vary: "Measurement, Analysis and Simulation of Wind Noise 
% Signals for Mobile Communication Devices", International Workshop on Acoustic 
% Signal Enhancement (IWAENC), September 2014
%
%--------------------------------------------------------------------------
% Copyright (c) 2014, Christoph Nelke
% Institute of Communication Systems and Data Processing
% RWTH Aachen University, Germany
% Contact information: nelke@ind.rwth-aachen.de
%
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%     * Neither the name of the RWTH Aachen University nor the names
%       of its contributors may be used to endorse or promote products derived
%       from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%--------------------------------------------------------------------------
% Version 1.0 - Version as described in paper
% Version 1.1 - ST energy defined by normal distr. process & combination of
% gains by modulation 
%--------------------------------------------------------------------------

fs = simpar.fs;
L = simpar.L*fs;

if isfield(simpar,'type')
    type = simpar.type;
else
    type = 'gusts';
end

%parameters extracted from wind noise recordings
var_excitation_noise = 0.005874;
mean_state2 = 0.005;
mean_state3 = 0.25;
lpc_coeff = [2.4804   -2.0032    0.5610   -0.0794    0.0392];
lpc_order = 5;
%switching factors for excitation signal
alpha1 = 0.15; %low wind
alpha2 = 0.5; %high wind

%load generate excitation signals
data = open('exc_signals.mat');
exc_pulses = data.exc_pulses;
nOfExcPulses = size(exc_pulses,1);
excite_sig_noise = randn(1,L)*sqrt(var_excitation_noise);

%load transition probabilities for Markov model
switch type
    case 'gusts'
        load('transition_prob_gusts.mat');
    case 'const'
        load('transition_prob_const.mat');
end

%compute cumulative transition probalities requiered for simulation
transitionMatrix_cum = transitionMatrix;
for k=1:size(transitionMatrix_cum,1)
    
    for l=2:size(transitionMatrix_cum,1)
        transitionMatrix_cum(k,l) = transitionMatrix_cum(k,l) + transitionMatrix_cum(k,l-1);
    end
end

% generate state sequence
state_act = 1; %no/low wind
states_syn = zeros(1,L);
for k=lpc_order+1:L
    x = rand(1,1);
    p = transitionMatrix_cum(state_act,:);
    if x<=p(1)  %no/low wind
        state_act = 1;
    elseif x>p(1) && x<=p(2)  %middle wind
        state_act = 2;
    else  %high wind
        state_act = 3;
    end
    states_syn(k) = state_act;
end

%generate gains for long term behaviour from state sequence
g_apl = zeros(1,L);
g_apl(states_syn==2) = mean_state2;
g_apl(states_syn==3) = mean_state3;

%generate gains for short term behaviour from random processes
g_apl_ST = (randn(1,length(g_apl)));

%smoothing of gains implemented by hann filters
win1 = hanning(10e3);
win1 = win1/sum(win1);
g_apl = fftfilt(win1,g_apl);
g_apl_LT = abs(g_apl);

win2 = hanning(fs*50e-3);
win2 = win2/sum(win2);
g_apl_ST = abs(fftfilt(win2,g_apl_ST));

%Combine LT and ST characteristic by modulation of gains
g_apl = g_apl_LT.*g_apl_ST;


hwb = waitbar(0,'Generating...');
n = zeros(1,L);
exc_L = 0;
idx_exc = 1;

states_syn(states_syn==0) = 1;

%generate wind noise signal
for k=lpc_order+1:L
    if ~mod(k,100)
        waitbar(k/L);
    end
    
    
    %update excitation pulse position
    if states_syn(k)~=1
        if idx_exc<exc_L
            idx_exc = idx_exc+1;
        else %end of current pulse -> load next pulse
            r_pulse = ceil(rand(1,1)*nOfExcPulses);
            exc_L = exc_pulses(r_pulse,end);
            exc_pulse_cur = exc_pulses(r_pulse,1:exc_L);
            idx_exc = 1;
        end
    end
    
    if states_syn(k)==1 %no wind
        exc_sig = excite_sig_noise(k)/2;
    elseif states_syn(k)==2 %low wind -> noise excitiation
        exc_sig = alpha1*exc_pulse_cur(idx_exc) + (1-alpha1)*excite_sig_noise(k);            
                
    else %middle/high wind -> turbulent pulse excitiation                       
        exc_sig = alpha2*exc_pulse_cur(idx_exc) + (1-alpha2)*excite_sig_noise(k);
    end
    
    n(k) = (g_apl(k)*exc_sig + n(k-1:-1:k-lpc_order) + g_apl_LT(k)*excite_sig_noise(k)*var_excitation_noise)*lpc_coeff.';
end

close(hwb)

%resample if necessary 
if fs~=16e3
    n = resample(n,fs,16e3);
end
%scale output
n = n/max(abs(n))*0.95;