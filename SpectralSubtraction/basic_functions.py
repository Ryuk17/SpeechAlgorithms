"""
@FileName: basic_functions.py
@Description: Implement basic_functions
@Author  : Ryuk
@CreateDate: 2019/11/13 13:47
@LastEditTime: 2019/11/13 13:47
@LastEditors: Please set LastEditors
@Version: v1.0
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import special
import subprocess
from numpy.linalg import norm


def normalization(data):
    """
    normalize data into [-1, 1]
    :param data: input data
    :return: normalized data
    """
    normalized_data = 2 * (data - min(data)) / (max(data) - min(data)) - 1
    return normalized_data


def enframe(samples, beta=8.5, overlapping=0, window_length=240, window_type='Rectangle'):
    """
    divede samples into frame
    :param samples:
    :param beta: parameter for kaiser window
    :param frame_num:
    :param window_length:
    :param window_type:
    :return: enframed frames
    """

    frames_num = len(samples) // (window_length - overlapping)
    frames = np.zeros([frames_num, window_length])
    for i in range(frames_num):
        start = i * (window_length - overlapping)
        end = start + window_length
        data = samples[start:end]

        N = len(data)
        x = np.linspace(0, N - 1, N, dtype=np.int64)

        if window_type == 'Rectangle':
            data = data
        elif window_type == 'Triangle':
            for i in range(N):
                if i < N:
                    data[i] = 2 * i / (N - 1)
                else:
                    data[i] = 2 - 2 * i / (N - 1)
        elif window_type == 'Hamming':
            w = 0.54 - 0.46 * np.cos(2 * np.pi * x / (N - 1))
            data = data * w
        elif window_type == 'Hanning':
            w = 0.5 * (1 - np.cos(2 * np.pi * x / (N - 1)))
            data = data * w
        elif window_type == 'Blackman':
            w = 0.42 - 0.5 * (1 - np.cos(2 * np.pi * x / (N - 1))) + 0.08 * np.cos(4 * np.pi * x / (N - 1))
            data = data * w
        elif window_type == 'Kaiser':
            w = special.j0(beta * np.sqrt(1 - np.square(1 - 2 * x / (N - 1)))) / special.j0(beta)
            data = data * w
        else:
            raise NameError('Unrecongnized window type')

        frames[i] = data
    return frames


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
    pesq_exe = "./utils/PESQ/pesq.exe"
    commad = str('+') + str(fs) + ' ' + raw_wav_path + ' ' + deg_wav_path
    subprocess.Popen(pesq_exe + ' ' + commad)


def addNoise(samples, fs, mu=0, sigma=0.1, lam=1, n=1000, p=0.613, noise_type='', display=False):

    raw_samples = samples
    noise_samples = normalization(samples)

    if noise_type == ' Impulse':
        noise = np.zeros(len(samples))
    elif noise_type == 'Gaussian':
        noise = np.random.normal(mu, sigma, len(samples))
    elif noise_type == 'Binomial':
        noise = np.random.binomial(n, p, len(samples))
    elif noise_type == 'Monte Carlo':
        noise = np.random.random(len(samples))
    elif noise_type == 'Poisson':
        noise = np.random.poisson(lam, len(samples))
    else:
        raise NameError('Unrecongnized noise type')

    noise_samples += noise


    if display:
        time = np.arange(0, len(samples)) * (1.0 / fs)

        plt.subplot(2, 1, 1)
        plt.plot(time, samples)
        plt.title("Raw Speech")
        plt.xlabel("time (seconds)")

        plt.subplot(2, 1, 2)
        plt.plot(time, noise_samples)
        plt.title("Raw Speech")
        plt.xlabel("time (seconds)")
        plt.show()

    return samples


def getSNR(signal, noise):
    """
    calcluate getSNR
    :param signal: signal
    :param noise: noise
    :return: SNR in log
    """
    return 20 * np.log10(norm(signal) / norm(noise))


def nextpow2(x):
    if x == 0:
        return 0
    else:
        return np.ceil(np.log2(x))