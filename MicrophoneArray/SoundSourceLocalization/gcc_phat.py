"""
@FileName: SoundSourceLocalization.py
@Description: Implement SoundSourceLocalization
@Author: Ryuk
@CreateDate: 2020/09/01
@LastEditTime: 2020/09/06
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import numpy as np
import librosa
from tqdm import tqdm
import matplotlib.pyplot as plt


def gcc_phat(ref, sig, sr):
    n_point = 2 * ref.shape[0] - 1
    X = np.fft.fft(ref, n_point)
    Y = np.fft.fft(sig, n_point)
    XY = X * np.conj(Y)

    c = XY / (abs(X) * abs(Y) + 10e-6)
    c = np.real(np.fft.ifft(c))
    end = len(c)
    center_point = end // 2
	
	#fft shift
    c = np.hstack((c[center_point + 1:], c[:center_point + 1]))
    lag = np.argmax(abs(c)) - len(ref) + 1
    tau = lag / sr
    return tau


SOUND_SPEED = 340.0
MIC_DISTANCE = 0.15
sample_rate = 48000
MAX_TDOA = MIC_DISTANCE / float(SOUND_SPEED)

org_ref, sr = librosa.load("./samples/ref.wav", sr=sample_rate)
org_sig, sr = librosa.load("./samples/sig.wav", sr=sample_rate)


ref = librosa.util.frame(org_ref, 1024, 256).T
sig = librosa.util.frame(org_sig, 1024, 256).T
fai = []
for i in tqdm(range(len(ref))):
    tau = gcc_phat(ref[i], sig[i], sample_rate)
    theta = np.arcsin(tau / MAX_TDOA) * 180 / np.pi
    fai.append(theta)


plt.subplot(211)
plt.ylabel('DOA ')
plt.xlabel('Frame index')
plt.title('DOA')
plt.plot(fai)
plt.subplot(212)
plt.ylabel('Amplitude')
plt.xlabel('Frame index')
plt.title('Waveform')
plt.plot(org_ref)
plt.tight_layout()
plt.show()