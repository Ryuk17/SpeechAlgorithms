"""
@FileName: Inference.py
@Description: Implement Inference
@Author: Ryuk
@CreateDate: 2020/05/08
@LastEditTime: 2020/05/08
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import librosa
from basic_functions import *
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from keras.models import load_model

def show(data, s):
    plt.figure(1)
    ax1 = plt.subplot(2, 1, 1)
    ax2 = plt.subplot(2, 1, 2)
    plt.sca(ax1)
    plt.plot(data)
    plt.sca(ax2)
    plt.plot(s)
    plt.show()


model = load_model("./model.h5")
data, fs = librosa.load("./test.wav", sr=8000)

win_length = 256
hop_length = 128
nfft = 512

spectrum = librosa.stft(data, win_length=win_length, hop_length=hop_length, n_fft=nfft)
magnitude = np.abs(spectrum).T
phase = np.angle(spectrum).T

frame_num = magnitude.shape[0] - 4
feature = np.zeros([frame_num, 257 * 5])
k = 0
for i in range(frame_num - 4):
    frame = magnitude[k:k + 5]
    feature[i] = np.reshape(frame, 257 * 5)
    k += 1

ss = StandardScaler()
feature = ss.fit_transform(feature)
mask = model.predict(feature)
mask[mask > 0.5] = 1
mask[mask <= 0.5] = 0

fig = plt.figure()
plt.imshow(mask, cmap='Greys', interpolation='none')
plt.show()
plt.close(fig)

magnitude = magnitude[2:-2]
en_magnitude = np.multiply(magnitude, mask)
phase = phase[2:-2]

en_spectrum = en_magnitude.T * np.exp(1.0j * phase.T)
frame = librosa.istft(en_spectrum, win_length=win_length, hop_length=hop_length)

show(data, frame)
librosa.output.write_wav("./output.wav",frame, sr=8000)