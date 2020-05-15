"""
@FileName: analysis.py
@Description: Implement analysis
@Author: Ryuk
@CreateDate: 2020/05/15
@LastEditTime: 2020/05/15
@LastEditors: Please set LastEditors
@Version: v0.1
"""

from utils import *
import matplotlib.pyplot as plt
import librosa

vad = extractLabel("./data/vad/sample001.txt")
feature = extractFeature("./data/wav/sample001.wav")
wav, sr = librosa.load("./data/wav/sample001.wav", sr=8000)

time = np.arange(0, len(wav)) * (1.0 / sr)
frame_num = np.arange(0, len(feature))

fig = plt.figure(figsize=(10, 16))
# wavform
ax = fig.add_subplot(5, 1, 1)
ax.plot(time, wav,'b')
plt.ylabel("Waveform")
plt.tight_layout()
# zcr
ax = fig.add_subplot(5, 1, 2)
ax.plot(frame_num,feature[:,0], 'b')
plt.ylabel("Short-Time ZCR")
plt.tight_layout()
# energy
ax = fig.add_subplot(5, 1, 3)
ax.plot(frame_num,feature[:,1], 'b')
plt.ylabel("Short-Time Energy")
plt.tight_layout()
# skew
ax = fig.add_subplot(5, 1, 4)
ax.plot(frame_num, feature[:,2], 'b')
plt.ylabel("Spectrum Skew")
plt.tight_layout()
#  kurtosi
ax = fig.add_subplot(5, 1, 5)
ax.plot(frame_num, feature[:,3], 'b')
plt.ylabel("Spectrum Kurtosi")
plt.tight_layout()
plt.show()
