"""
@FileName: Test.py
@Description: Implement Test
@Author: Ryuk
@CreateDate: 2020/12/08
@LastEditTime: 2020/12/08
@LastEditors: Please set LastEditors
@Version: v0.1
"""

from Algorithm import *
import librosa
import soundfile as sf
import matplotlib.pyplot as plt


x, fs = librosa.load("./test.wav", sr=8000)
pitch_scale = 1.5
time_scale = 1
y = Processing(x, fs, pitch_scale, time_scale, cutoff_freq=500)
sf.write("./out.wav", y, fs)

fig=plt.figure()
ax=fig.add_subplot(2, 1, 1)
ax.plot(x)
ax=fig.add_subplot(2, 1, 2)
ax.plot(y)
plt.show()

