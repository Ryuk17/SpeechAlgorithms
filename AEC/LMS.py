"""
@FileName: LMS.py
@Description: Implement LMS AEC
@Author: Ryuk
@CreateDate: 2020/07/01
@LastEditTime: 2020/07/04
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import librosa
import numpy as np
from tqdm import tqdm
import matplotlib.pyplot as plt


far, sr = librosa.load("./far.wav", sr=16000)
near, sr = librosa.load("./near.wav", sr=16000)

L = 128                 # 滤波器抽头系数
N = len(far)            # 迭代长度
T = 0.92                # 双端检测阈值
lambda_DTD=0.95         # DTD更新系数
DTDbegin=20000          # DTD 开始检测时间

w = np.zeros(L)
xin = np.zeros(L)

# DTD相关参数
varMIC = np.zeros(N)
r_em = np.zeros(N)

x = far
d = near

mu = 0.014
y = np.zeros(N)
e = np.zeros(N)
threshold = np.zeros(N)
decision_statistic = np.zeros(N)
powerD = np.zeros(N)
powerE = np.zeros(N)
ERLE = np.zeros(N)

for i in tqdm(range(N)):
    for j in range(L - 1, 0, -1):
        xin[j] = xin[j - 1]

    # LMS
    xin[0] = x[i]

    y[i] = np.dot(w, xin)
    error = d[i] - y[i]
    e[i] = error
    wtemp = w + np.multiply(2 * mu * error, xin)

    # DTD
    threshold[i] = T
    if i < DTDbegin:
        w = wtemp
    else:
        r_em[i] = lambda_DTD * (r_em[i - 1]) + (1 - lambda_DTD) * e[i] * d[i]
        varMIC[i] = np.sqrt(lambda_DTD * (varMIC[i - 1] ** 2) + (1 - lambda_DTD) * d[i] * d[i])
        decision_statistic[i] = 1 - (r_em[i] / varMIC[i]) ** 2

    if decision_statistic[i] > threshold[i]:
        w = wtemp

    # ERLE
    powerD[i] = np.abs(d[i]) ** 2 # Power of Microphone signal
    powerE[i] = np.abs(e[i]) ** 2 # power of Error signal
    ERLE[i]=10 * np.log10(np.mean(powerD[i:i+L])/np.mean(powerE[i:i+L]))

# 画图
time = np.arange(0, len(far)) * (1.0 / sr)
fig = plt.figure(figsize=(10, 16))

# near
ax = fig.add_subplot(6, 1, 1)
ax.plot(time, near,'b')
plt.ylabel("Near")
plt.tight_layout()

# far
ax = fig.add_subplot(6, 1, 2)
ax.plot(time, far, 'b')
plt.ylabel("Far")
plt.tight_layout()

# output
ax = fig.add_subplot(6, 1, 3)
ax.plot(time, y, 'b')
plt.ylabel("Output")
plt.tight_layout()

# error
ax = fig.add_subplot(6, 1, 4)
ax.plot(time, e, 'b')
plt.ylabel("Error")
plt.tight_layout()

# Decision_statistic
ax = fig.add_subplot(6, 1, 5)
ax.plot(time, decision_statistic, 'b')
plt.axhline(y=T,ls=":",c="red")
plt.ylabel("Decision_statistic")
plt.tight_layout()

# ERLE
ax = fig.add_subplot(6, 1, 6)
ax.plot(time, ERLE, 'b')
plt.ylabel("ERLE")
plt.tight_layout()

plt.show()
librosa.output.write_wav("./output.wav", (near - y).astype(np.float32), sr)