"""
@FileName: baseline.py
@Description: Implement baseline for ESC
@Author: Ryuk
@CreateDate: 2020/08/02
@LastEditTime: 2020/08/02
@LastEditors: Please set LastEditors
@Version: v0.1
"""


import os
import librosa
import numpy as np
from tqdm import tqdm
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier
from sklearn.metrics import accuracy_score

RATE = 44100
FRAME = 512
NUM = 400

def compute_mfcc(wav):
    melspectrogram = librosa.feature.melspectrogram(wav, sr=RATE, hop_length=FRAME)
    logamplitude = librosa.core.amplitude_to_db(melspectrogram)
    mfcc = np.mean(librosa.feature.mfcc(S=logamplitude, n_mfcc=13),axis=1)
    return mfcc

def compute_spectral_contrast(wav):
    spectral_contrast = librosa.feature.spectral_contrast(wav, RATE, hop_length=512)
    spectral_contrast = np.mean(spectral_contrast, axis=1)
    return spectral_contrast

def compute_zcr(wav):
    zcr = []
    frames = librosa.util.frame(wav,hop_length=FRAME)
    frames = frames.T
    for i in range(len(frames)):
        zcr.append(np.mean(0.5 * np.abs(np.diff(np.sign(frames[i])))))

    zcr_mean = np.mean(zcr)
    zcr_std = np.std(zcr)
    return np.array([zcr_mean, zcr_std])


path = "D:\\Samples\\ESC-10\\"
folders = os.listdir(path)[:10]
print(folders)

feature = np.zeros([NUM, 22])
label = np.zeros(NUM)
count = 0
for i in tqdm(range(len(folders))):
    dirname = path + str(folders[i])
    wavefiles = os.listdir(dirname)

    for j in range(len(wavefiles)):
        wavname = dirname + "\\" + wavefiles[j]
        wav,RATE = librosa.load(wavname, RATE)
        mfcc = compute_mfcc(wav)
        sc = compute_spectral_contrast(wav)
        zcr = compute_zcr(wav)
        feature[count] = np.hstack([mfcc, sc, zcr])
        label[count] = i
        count += 1

# training
print("Start Training")
X_train,X_test, y_train, y_test = train_test_split(feature,label,test_size=0.3, random_state=2020)
clf = XGBClassifier(
    learning_rate=0.1,
    n_estimators=100,
    max_depth=6,
    min_child_weight = 1,
    gamma=0.,
    subsample=0.8,
    colsample_btree=0.8,
    objective='multi:softmax',
    scale_pos_weight=1,
    random_state=2020
)
clf.fit(X_train, y_train)

print("Start Testing")
y_pred = clf.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)
print("accuarcy: %.2f%%" % (accuracy * 100.0))
