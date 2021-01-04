"""
@FileName: Algorithm.py
@Description: Implement Algorithm
@Author: Ryuk
@CreateDate: 2020/12/07
@LastEditTime: 2020/12/07
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import numpy as np
from scipy import signal

def Processing(x, fs, pitch_scale, time_scale, cutoff_freq=500):
    # normalize
    x = x - np.mean(x)
    x = x / np.max(np.abs(x))

    #x = LowPassFilter(x, fs, cutoff_freq)
    pitch = PitchEstimator(x, fs)
    output = PitchMark(x, pitch, fs, pitch_scale, time_scale)
    return output

def LowPassFilter(x, fs, cutoff_freq):
    if cutoff_freq == 0:
        return x
    else:
        factor = np.exp(-1 / (fs / cutoff_freq))
        y = signal.filtfilt([1 - factor], [1, -factor], x)
        return y


def PitchEstimator(x, fs):
    frame_length = round(fs * 0.03)
    frame_shift = round(fs * 0.01)
    length = len(x)
    frame_num = int(np.floor((length - frame_length)/ frame_shift)) + 2
    frame_pitch = np.zeros(frame_num + 2)

    frame_range = np.arange(0, frame_length)
    for count in range(1, frame_num):
        frame = x[frame_range]
        frame_pitch[count] = PitchDetection(frame, fs)
        frame_range += frame_shift

    frame_pitch = signal.medfilt(frame_pitch, 5)

    pitch = np.zeros(length)
    for i in range(length):
        index = int(np.floor((i + 1) / frame_shift))
        pitch[i] = frame_pitch[index]
    return pitch

def CenterClipping(x, clip_rate):
    max_amplitude = np.max(np.abs(x))
    clip_level = max_amplitude * clip_rate
    positive_index = np.where(x > clip_level)
    negative_index = np.where(x < -clip_level)
    clipped_data = np.zeros(len(x))
    clipped_data[positive_index] = x[positive_index] - clip_level
    clipped_data[negative_index] = x[negative_index] + clip_level
    return clipped_data

def AutoCorrelation(x, lags):
    N = len(x)
    auto_corr = np.correlate(x, x, mode = 'full')
    assert N >= lags - 1
    auto_corr = auto_corr[N - lags - 1 : N + lags]
    auto_corr = auto_corr / np.max(auto_corr)
    return auto_corr

def IsPeak(index, low, high, x):
    if index == low or index == high:
        return False
    if x[index] < x[index-1] or x[index] < x[index+1]:
        return False
    return True

def PitchDetection(x, fs):
    min_lag = round(fs / 500)
    max_lag = round(fs / 70)
    x = CenterClipping(x, 0.3)

    auto_corr = AutoCorrelation(x, max_lag)
    auto_corr = auto_corr[max_lag: 2 * max_lag]

    search_range = auto_corr[min_lag - 1:max_lag]
    max_corr = np.max(search_range)
    max_corr_index = np.argmax(search_range)
    max_corr_index = max_corr_index + min_lag - 1

    min_corr = np.min(auto_corr[:max_corr_index+1])

    if max_corr > 0.35 and min_corr < 0 and IsPeak(max_corr_index, min_lag, max_lag, auto_corr):
        pitch = fs / (max_corr_index + 1)
    else:
        pitch = 0

    return pitch

def VAD(pitch):
    unvoiced = []
    voiced = []
    ustart, ustop, vstart, vstop = 0, 0, 0, 0
    ustart = 0
    ustop = np.nonzero(pitch)[0][0]
    unvoiced.append([ustart, ustop - 1])
    vstart =  ustop
    flag = 1
    for i in range(ustop, len(pitch)):
        if pitch[i] == 0 and flag == 1:
            # voiced -> unvoiced
            vstop = i - 1
            voiced.append([vstart, vstop])
            ustart = vstop + 1
            flag = 0

        if pitch[i] != 0 and flag == 0:
            # unvoiced -> voiced
            ustop = i - 1
            unvoiced.append([ustart, ustop])
            vstart = ustop + 1
            flag = 1
    unvoiced.append([ustart, len(pitch)])
    return np.array(unvoiced), np.array(voiced)

def FindPeakCandidates(x, MaxCandidateNumber, Offset):
    length = len(x)
    x1 = np.roll(x, 1)
    x2 = np.roll(x, -1)
    PeakIndices = []
    for i in range(len(x)):
        if x[i] >= x1[i] and x[i] >= x2[i]:
            PeakIndices.append(i)
    SortedIndices = np.argsort(-x[PeakIndices])
    y = np.sort(-x[PeakIndices])

    MinDur = round(length / 7)
    l = len(SortedIndices)
    i = 0

    while i < l - 1:
        j = i + 1
        while j < l:
            if abs(PeakIndices[SortedIndices[i]] - PeakIndices[SortedIndices[j]]) < MinDur:
                SortedIndices = np.delete(SortedIndices, j)
                l = l - 1
            else:
                j = j + 1
        i += 1

    PeakCandidates = np.zeros(MaxCandidateNumber)
    prange = np.arange(0, min(MaxCandidateNumber, len(SortedIndices)))
    PeakIndices = np.array(PeakIndices)
    PeakCandidates[prange] = PeakIndices[SortedIndices[prange]] + Offset

    imin = np.argmin(x)
    imax = np.argmax(x)
    PeakCandidates = np.hstack([PeakCandidates, np.array([-Offset, imin, imax, 0, length - 1] + Offset)])
    return PeakCandidates.astype(np.int)

def IncreaseMarking(x, p, fs, m):
    leftDuration = int(round(fs / p[0]))
    i = leftDuration
    length = len(x)

    ca = []
    LeftThr = 0
    if i < length:
        while i < length:
            leftHalf = np.floor(leftDuration * 0.3)
            Range = np.arange(int(max(i - leftHalf, LeftThr)), int(min(i + leftHalf + 1, length)))

            Offset = Range[0]
            c = FindPeakCandidates(x[Range], m, Offset)

            ca.append(c)
            i = c[0]
            leftDuration = round(fs / p[i])

            i += leftDuration
        return np.array(ca)
    else:
        return []

def Pitch2Duration(p, fs):
    d = p
    for i in range(len(p)):
        if p[i] != 0:
            d[i] = fs / p[i]
    return d

def StateProb(h, min, max):
    if min == max:
        return 1
    else:
        return (h - min) / (max - min) + 10e-10

def TransitionProb(i, k, d):
    beta = 0.7
    gamma = 0.6
    dur = (d[i] + d[k]) / 2
    tc = 1 / (1 - beta * abs(dur - abs(k - i)))
    tc = tc.astype(np.complex)
    tc = np.power(tc, gamma)
    return tc

def VoicedSegmentMarking(x, p, fs):
    MaxCandidateNumber = 3
    i = np.argmax(x)
    length = len(x)
    flag = 0

    first = np.zeros(MaxCandidateNumber + 5)
    first[: MaxCandidateNumber + 5] = i
    first[1: MaxCandidateNumber + 1] = 0

    RightCandidates = IncreaseMarking(x[i:length], p[i:length], fs, MaxCandidateNumber)
    LeftCandidates = IncreaseMarking(np.flipud(x[:i+1]), np.flipud(p[: i+1]), fs, MaxCandidateNumber)

    if len(RightCandidates) == 0 and len(LeftCandidates) == 0:
        Candidates = first
        flag = 1
    elif len(RightCandidates) == 0 and len(LeftCandidates) != 0:
        LeftCandidates = np.flipud(i + 1 - LeftCandidates)
        LeftCandidates[np.where(LeftCandidates == i + 1)] = 0
        Candidates = np.vstack([LeftCandidates, first])
    elif len(RightCandidates) != 0 and len(LeftCandidates) == 0:
        RightCandidates = i + 1 + RightCandidates
        RightCandidates[np.where(RightCandidates == i + 1)] = 0
        Candidates = np.vstack([first, RightCandidates])
    else:
        LeftCandidates = np.flipud(i + 1 - LeftCandidates)
        LeftCandidates[np.where(LeftCandidates == i + 1)] = 0
        RightCandidates = i + 1 + RightCandidates
        RightCandidates[np.where(RightCandidates == i + 1)] = 0
        Candidates = np.vstack([LeftCandidates, first, RightCandidates])

    Candidates = Candidates - 1
    Candidates[Candidates < 0] = 0


    d = Pitch2Duration(p, fs)

    cost = np.zeros(length, dtype=np.complex)
    trace = np.zeros(length)
    if flag == 1:
        length = 1
        Candidates = np.array(Candidates, dtype=np.int).reshape(1, len(Candidates))
    else:
        length = len(Candidates[:, 1])
        Candidates = np.array(Candidates, dtype=np.int)


    imin = Candidates[0, MaxCandidateNumber + 2]
    imax = Candidates[0, MaxCandidateNumber + 3]

    search = [_ for _ in Candidates[0:,0: MaxCandidateNumber][0] if _ != 0]
    for curr in search:
        if curr != 0:
            cost[curr] = np.log(StateProb(x[curr], x[imin], x[imax]))
            trace[curr] = 0

    for k in range(1, length):
        imin = Candidates[k, MaxCandidateNumber + 1]
        imax = Candidates[k, MaxCandidateNumber + 2]

        search = [_ for _ in Candidates[k :,0: MaxCandidateNumber][0] if _ != 0]
        for curr in search:
            if trace[curr] != 0:
                break

            MaxProb = -10e-9
            search = [_ for _ in Candidates[k-1 :,0: MaxCandidateNumber][0] if _ != 0]
            for prev in search:
                if prev != 0:
                    Prob = np.log(TransitionProb(prev, curr, d)) + cost[prev]
                    if Prob > MaxProb:
                        MaxProb = Prob
                        trace[curr] = prev
            cost[curr] = MaxProb + np.log(StateProb(x[curr], x[imin], x[imax]))

    Marks = np.zeros(length)
    last = [_ for _ in Candidates[length-1, 0:MaxCandidateNumber] if _ != 0]
    index = np.argmax(cost[last])
    curr = int(last[index])
    prev = int(trace[curr])
    length = length - 1
    while prev != 0:
        Marks[length] = curr
        length = length - 1
        curr = prev
        prev = int(trace[curr])
    Marks[length] = curr
    return Marks, Candidates

def UnvoicedMod(input, fs, alpha):
    d = round(0.01 * fs)
    input_len = len(input)
    ta = []
    for i in range(0, input_len, d):
        ta.append(i)

    output_len = np.ceil(alpha * len(input)).astype(np.int)
    output = np.zeros(output_len)
    ts = []
    for i in range(0, output_len, d):
        ts.append(i)

    ta_prime = np.round(np.array(ts) / alpha)

    for i in range(len(ts) - 1):
        for j in range(len(ta) - 1):
            if ta[j] <= ta_prime[i] <= ta[j+1]:
                output[ts[i]:ts[i+1]+1] = input[ta[j]:ta[j+1]+1]

    output = output[ts[0]:ts[-1]+1]
    return output

def nextpow2(x):
    if x == 0:
        return 0
    else:
        return np.ceil(np.log2(x)).astype(np.int)

def selectCorrectPos(i, anaPm):
    if i == 0:
        return 1
    elif i >= len(anaPm) - 1:
       return len(anaPm) - 2
    else:
        return i

def addTogether(y, x, t, maxLen):
    length = len(x)
    max = t + length
    range = np.arange(t, max)

    if max > maxLen:
        maxLen = max

    length = len(y)
    if length < max:
        y = np.hstack((y, np.zeros(max - length)))
    y[range] = y[range] + x
    return maxLen, y

def psola(input, fs, anaPm, pitch_scale, time_scale):
    length = len(anaPm)
    pitchPeriod = np.zeros(len(input))
    anaPm = anaPm.astype(np.int)
    for i in range(1, length):
        pitchPeriod[anaPm[i - 1]: anaPm[i]] = anaPm[i] - anaPm[i - 1]

    pitchPeriod[0: anaPm[0]] = pitchPeriod[anaPm[0]]
    pitchPeriod[anaPm[length - 1]: len(input)+1] = pitchPeriod[anaPm[length - 1] - 1]

    synPm = []
    synPm.append(anaPm[0])
    count = 0
    index = synPm[count]
    length = len(input)
    while index < length:
        LHS = 0
        RHS = 1

        while (LHS < RHS) and (index < length):
            index = index + 1
            LHS = time_scale * (index - synPm[count]) ** 2
            RHS = sum(pitchPeriod[synPm[count]:index+1]) / pitch_scale

        if LHS > RHS:
            count = count + 1
            synPm.append(index)
            index = synPm[count] + 1

    input = input.T
    wave = []
    dft = []
    for i in range(1, len(anaPm) - 1):
        left = anaPm[i - 1]
        right = anaPm[i + 1]
        frame = input[left: right+1] * np.hanning(right - left + 1)
        wave.append(frame)
        N = len(frame)
        M = 2 ** nextpow2(2 * N - 1)
        dft.append(np.fft.fft(frame, M))



    outPm = np.round(np.array(synPm) * time_scale).astype(np.int)
    output = np.zeros(outPm[count])

    maxLen = 0
    minLen = len(output)

    first = 0
    for j in range(1, len(synPm) - 1):
        for i in range(first, len(anaPm) - 2):
            if anaPm[i] <= synPm[j] < anaPm[i + 1]:
                first = i
                k = selectCorrectPos(i, anaPm)
                gamma = (synPm[j] - anaPm[k]) / (anaPm[k + 1] - anaPm[k])
                wave1 = wave[k - 1]
                wave2 = wave[k]
                maxLen, newUnitWave = addTogether((1 - gamma) * wave1, gamma * wave2, 0, maxLen)

                maxLen, output = addTogether(output, newUnitWave, outPm[j - 1], maxLen)

                if outPm[j - 1] < minLen:
                    minLen = outPm[j - 1]
    output = output[minLen:outPm[count]]
    return output

def PitchMark(x, pitch, fs, pitch_scale, time_scale):
    unvoiced, voiced = VAD(pitch)
    pm = []
    ca = []
    first = 0
    waveOut = []
    for i in range(len(voiced[:,1])):
        voiced_range = np.arange(voiced[i, 0], voiced[i, 1] + 1)
        data = x[voiced_range]
        marks, cans = VoicedSegmentMarking(data, pitch[voiced_range], fs)
        pm.append(marks + voiced_range[0])
        ca.append(cans + voiced_range[0])

        waveOut.extend(UnvoicedMod(x[first:int(marks[0] + voiced_range[0] + 1)], fs, time_scale))
        first = int(marks[-1] + voiced_range[0] + 2)
        waveOut.extend(psola(data, fs, marks, pitch_scale, time_scale))
    return waveOut















