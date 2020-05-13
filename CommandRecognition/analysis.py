"""
@FileName: analysis.py
@Description: Implement analysis
@Author: Ryuk
@CreateDate: 2020/05/13
@LastEditTime: 2020/05/13
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import numpy as np
import librosa
import matplotlib.pyplot as plt

yes, sr = librosa.load("./data/yes/00f0204f_nohash_0.wav", sr=16000)
no, sr = librosa.load("./data/yes/0a9f9af7_nohash_0.wav", sr=16000)

yes_mfcc = librosa.feature.mfcc(yes, sr)
no_mfcc = librosa.feature.mfcc(no, sr)

yes_time = np.arange(0, len(yes)) * (1.0 / sr)
no_time = np.arange(0, len(no)) * (1.0 / sr)

fig = plt.figure()
ax = fig.add_subplot(2, 2, 1)
ax.plot(yes_time,yes,'b')
plt.ylabel("Yes")
ax = fig.add_subplot(2, 2, 2)
cmap = "binary"
ax.imshow(yes_mfcc[::-1], cmap=cmap)
ax = fig.add_subplot(2, 2, 3)
ax.plot(no_time,no,'r')
plt.ylabel("No")
ax = fig.add_subplot(2, 2, 4)
ax.imshow(no_mfcc[::-1], cmap=cmap)
plt.show()