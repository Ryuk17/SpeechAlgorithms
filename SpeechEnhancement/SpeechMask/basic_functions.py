"""
@FileName: basic_functions.py
@Description: Implement basic_functions
@Author  : Ryuk
@CreateDate: 2019/11/13 13:47
@LastEditTime: 2020/05/16 13:47
@LastEditors: Please set LastEditors
@Version: v1.0
"""

import numpy as np
import matplotlib.pyplot as plt
import subprocess
from scipy import signal
from numpy.linalg import norm


def sgn(data):
    """
    sign function
    :param data:
    :return: sign
    """
    if data >= 0 :
        return 1
    else :
        return 0

def normalization(data):
    """
    normalize data into [-1, 1]
    :param data: input data
    :return: normalized data
    """
    normalized_data = 2 * (data - min(data)) / (max(data) - min(data)) - 1
    return normalized_data

def preEmphasis(samples, fs, alpha=0.9375, overlapping=0, window_length=240, window_type='Rectangle', display=False):
    """
    per emphasis speech
    :param samples: sample data
    :param fs: sample frequency
    :param alpha: parameter
    :param overlapping: overlapping length
    :param window_length: the length of window
    :param window_type: the type of window
    :param display: whether to display processed speech
    :return: processed speech
    """
    y = np.zeros(len(samples))
    y[0] = samples[0]

    # pre emphasis
    for i in range(1, len(samples)):
        y[i] = samples[i] - alpha * samples[i-1]

    if display:
        time = np.arange(0, len(samples)) * (1.0 / fs)
        plt.plot(time, samples)
        plt.title("Pre-emphasis")
        plt.ylabel("Waveform")
        plt.xlabel("Time (seconds)")
        plt.show()

    return y


def displaySpeech(samples, fs):
    """
    display waveform of a given speech sample
    :param sample_name: speech sample name
    :param fs: sample frequency
    :return:
    """
    time = np.arange(0, len(samples)) * (1.0 / fs)

    plt.plot(time, samples)
    plt.title("Speech")
    plt.xlabel("time (seconds)")
    plt.show()


def pesqTest(raw_wav_path, deg_wav_path, fs):
    """
    pesq test
    :param raw_wav_path: raw speech samples file path
    :param deg_wav_path: degradation speech samples file path
    :param fs: sample frequency
    :return: save pesq value in current fold pesq_result.txt
    """
    pesq_exe = "../tools/pesq.exe"
    commad = str('+') + str(fs) + ' ' + raw_wav_path + ' ' + deg_wav_path
    subprocess.Popen(pesq_exe + ' ' + commad)


def addNoise(clean, noise, sr, snr, display=False):
    """
    add noise with specific snr
    :param clean: clean speech
    :param noise: noise
    :param sr: sample rate
    :param snr: snr
    :param display: whether to display processed speech
    :return: mix speech
    """
    if len(noise) > len(clean):
        noise = noise[:len(clean)]
    else:
        times = len(clean) // len(noise)
        noise = np.tile(noise, times)
        padding = [0] * (len(clean) - len(noise))
        noise = np.hstack([noise, padding])

    noise = noise / norm(noise) * norm(clean) / (10.0 ** (0.05 * snr))
    mix = clean + noise

    if display:
        time = np.arange(0, len(clean)) * (1.0 / sr)

        plt.subplot(2, 1, 1)
        plt.plot(time, clean)
        plt.title("Clean Speech")
        plt.xlabel("time (seconds)")

        plt.subplot(2, 1, 2)
        plt.plot(time, mix)
        plt.title("Mix Speech")
        plt.xlabel("time (seconds)")
        plt.show()

    return mix

def addEcho(clean, sr, alpha, beta=0.5, delay=0.1, type=1):
    """
    add echo signal to raw speech
    :param clean: clean speech
    :param sr: sample rate
    :param alpha: parameters for type1
    :param beta: parameters for type2
    :param delay: parameters for type2
    :param type: echo type
    :return: mix signal
    """
    if type == 1:
        h = [1]
        h.extend([0] * int(alpha * sr))
        h.extend([0.5])
        h.extend([0] * int(alpha * sr))
        h.extend([0.25])
        mix = signal.convolve(clean, h)
    else:
        mix = clean.copy()
        shift = int(delay * sr)
        for i in range(shift, len(clean)):
            mix[i] = beta * clean[i] + (1 - beta) * clean[i - shift]
    return mix



def addReverberation(clean, alpha=0.8, R=2000):
    """
    add reverberation
    :param clean: clean speech
    :param alpha: factor
    :param R:
    :return: mix speech
    """
    b = [0] * (R+1)
    b[0], b[-1] = alpha, 1
    a = [0] * (R+1)
    a[0], a[-1] = 1, 0.5
    mix = signal.filtfilt(b, a, clean)
    return mix

def addHowl(clean, K=0.2):
    """
    add howl
    :param clean: clean speech
    :param K: factors
    :return: mix speech
    """
    g = np.loadtxt("../tool/path.txt")
    c = np.array([0,0,0,0,1]).T
    h = np.zeros(201)
    h[100] = 1

    xs1 = np.zeros(c.shape[0])
    xs2 = np.zeros(g.shape)
    xs3 = np.zeros(h.shape)

    mix = np.zeros(len(clean))
    temp = 0

    for i in range(len(clean)):
        xs1[1:] = xs1[: - 1]
        xs1[0] =  clean[i] + temp
        mix[i] = K * np.dot(xs1.T, c)

        xs3[1:] = xs3[: - 1]
        xs3[0] = mix[i]
        mix[i] = np.dot(xs3.T, h)

        mix[i] = min(1, mix[i])
        mix[i] = max(-1, mix[i])

        xs2[1:] = xs2[: - 1]
        xs2[0] = mix[i]
        temp = np.dot(xs2.T, g)
    return mix

def getSNR(signal, noise):
    """
    calcluate getSNR
    :param signal: signal
    :param noise: noise
    :return: SNR in log
    """
    return 20 * np.log10(norm(signal) / norm(noise))


def nextPow2(x):
    """
    calculate the nearest pow2 of x
    :param x:
    :return: the nearest pow2 of x
    """
    if x == 0:
        return 0
    else:
        return np.ceil(np.log2(x))
