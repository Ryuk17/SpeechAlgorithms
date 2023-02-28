"""
@FileName: kalman.py
@Description: Implement kalman
@Author: Ryuk
@CreateDate: 2021/08/26
@LastEditTime: 2021/09/05
@LastEditors: Please set LastEditors
@Version: v0.1
"""
import numpy as np
import librosa
from tqdm import tqdm
import soundfile as sf

far, sr = librosa.load("./far.wav", sr=16000)
near, sr = librosa.load("./near.wav", sr=16000)

L = 256
P = 1
delta = 0.0001
w_cov = 0.01
v_conv = 0.1
sigma_e = 0.001
sigma_x = 0.001
alpha = 0.9
lambda_v = 0.999

h = np.zeros((L, 1))
h_hat = np.zeros((L, 1))

IL = np.identity(L)
IP = np.identity(P)

Rm = np.zeros((L, L))
Rmu = delta * IL
Rex = 1e-3 * np.ones((L, 1))

frame_num = len(far) // L

e = np.zeros(len(far))
for i in tqdm(range(len(far) - L)):
    X = np.expand_dims(far[i:i+L], axis=1)
    Rm = Rmu + w_cov * IL
    Re = X.T @ Rm @ X + v_conv * IP
    K = Rm @ X / (Re + 0.03)
    e[i] = near[i+L] - X.T @ h_hat
    h_old = h_hat
    h_hat = h_hat + K * e[i]
    Rmu = (IL - K @ X.T) * Rm
    delat_h = h_hat - h_old
    w_cov = alpha * w_cov + (1 - alpha) * (delat_h.T @ delat_h)
    Rex = lambda_v * Rex + (1 - lambda_v) * X * e[i]
    sigma_x = lambda_v * sigma_x + (1 - lambda_v) * X[-1] * X[-1]
    sigma_e = lambda_v * sigma_e + (1 - lambda_v) * e[i] * e[i]
    v_conv = sigma_e - (1/(sigma_x + 0.03) * (Rex.T @ Rex))

sf.write("./kalman_out.wav", e, sr)





