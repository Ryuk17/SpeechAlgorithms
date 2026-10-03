% Test script for generate_wind_noise.m
%
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


clc;clear variables;

duration = 10;%seconds
simpar.fs = 16e3;%sampling frequency
simpar.L = duration*simpar.fs;
simpar.type = 'gusts'; %type of generated wind noise: constant -> 'const' or gusty -> 'gusts'

[n_sim] = generate_wind_noise(simpar);

figure;
spectrogram(n_sim,hanning(320),160,512,simpar.fs,'yaxis');