"""
@FileName: fft-window.py
@Description: Implement fft-window
@Author: Ryuk
@CreateDate: 2021/04/22
@LastEditTime: 2021/04/22
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import numpy as np
import librosa
import soundfile as sf

def Overlap1():
    block_size = 512
    shift_size = 256
    NFFT = 512
    x, sr = librosa.load("./test.wav", sr=16000)
    x = np.hstack([np.zeros(shift_size), x])
    window = np.hanning(NFFT)
    M = int(np.floor(len(x) / shift_size))
    output = np.zeros(len(x))

    for m in range(1, M):
        index = np.arange((m-1)*shift_size, (m+1)*shift_size)
        xframe = x[index]
        y = xframe * window
        X = np.fft.rfft(y, NFFT)

        y_ifft = np.fft.irfft(X, NFFT)
        #y_ifft = y_ifft * window
        output[index] += y_ifft

    sf.write("./1_2_overlap_nowindow.wav", output, 16000)

def Overlap2():
    block_size = 512
    shift_size = 128
    NFFT = 512
    x, sr = librosa.load("./test.wav", sr=16000)
    x = np.hstack([np.zeros(shift_size), x])
    window = np.hanning(NFFT)
    M = int(np.floor((len(x)) / shift_size)) - 3
    output = np.zeros(len(x))

    for m in range(M):
        index = np.arange(m*shift_size, m*shift_size+block_size)
        xframe = x[index]
        y = xframe * window
        X = np.fft.rfft(y, NFFT)

        y_ifft = np.fft.irfft(X, NFFT)
        #y_ifft = y_ifft * window
        output[index] += y_ifft

    sf.write("./3_4_overlap_nowindow.wav", output, 16000)

if __name__ == "__main__":
    Overlap1()
    Overlap2()
