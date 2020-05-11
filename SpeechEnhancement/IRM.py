"""
@FileName: IRM.py
@Description: Implement IRM
@Author: Ryuk
@CreateDate: 2020/05/08
@LastEditTime: 2020/05/08
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import numpy as np
import librosa
from sklearn.preprocessing import StandardScaler
from keras.layers import *
from keras.models import Sequential


def generateDataset():
    mix, sr = librosa.load("./mix.wav", sr=8000)
    clean,sr = librosa.load("./clean.wav",  sr=8000)

    win_length = 256
    hop_length = 128
    nfft = 512

    mix_spectrum = librosa.stft(mix, win_length=win_length, hop_length=hop_length, n_fft=nfft)
    clean_spectrum = librosa.stft(clean, win_length=win_length, hop_length=hop_length, n_fft=nfft)

    mix_mag = np.abs(mix_spectrum).T
    clean_mag = np.abs(clean_spectrum).T

    # 调整输入为5帧
    frame_num = mix_mag.shape[0] - 4
    feature = np.zeros([frame_num, 257*5])
    k = 0
    for i in range(frame_num - 4):
        frame = mix_mag[k:k+5]
        feature[i] = np.reshape(frame, 257*5)
        k += 1

    snr = np.divide(clean_mag, mix_mag)
    mask = np.power(np.divide(snr, snr+1), 0.5)

    label = mask[2:-2]

    ss = StandardScaler()
    feature = ss.fit_transform(feature)
    return feature, label


def getModel():
    model = Sequential()
    model.add(Dense(2048, input_dim=1285))
    model.add(BatchNormalization())

    model.add(LeakyReLU(alpha=0.1))
    model.add(Dropout(0.1))

    model.add(Dense(2048))
    model.add(BatchNormalization())
    model.add(LeakyReLU(alpha=0.1))
    model.add(Dropout(0.1))

    model.add(Dense(2048))
    model.add(BatchNormalization())
    model.add(LeakyReLU(alpha=0.1))
    model.add(Dropout(0.1))

    model.add(Dense(257))
    model.add(BatchNormalization())
    model.add(Activation('sigmoid'))
    return model

def train(feature, label, model):
    model.compile(optimizer='adam',
                  loss='mse',
                  metrics=['mse'])
    model.fit(feature, label, batch_size=128, epochs=20, validation_split=0.1)
    model.save("./model.h5")

def main():
    feature, label = generateDataset()
    model = getModel()
    ss = StandardScaler()
    feature = ss.fit_transform(feature)
    train(feature, label, model)


if __name__ == "__main__":
    main()
