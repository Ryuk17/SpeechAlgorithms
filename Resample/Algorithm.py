"""
@FileName: Algorithm.py
@Description: Implement Algorithm
@Author: Ryuk
@CreateDate: 2020/11/03
@LastEditTime: 2020/11/03
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import numpy as np
import math
from scipy import signal

def DirectInterpolation(x, L, M):
    N = len(x)
    K = int((M / L) * N)
    factor = L / M
    y = np.zeros(K)
    for k in range(K):
        nk = factor * k
        n = math.floor(nk)
        if n + 1 >= len(x): continue
        w1 = nk - n
        w2 = 1 - w1
        y[k] = w1 * x[n + 1] + w2 * x[n]
    return y

def LagrangeInterpolation(x, w, L, M):
    N = len(x)
    K = int((M / L) * N)
    factor = L / M
    y = np.zeros(K)
    for k in range(K):
        nk = factor * k
        n = math.floor(nk) - 1
        for i in range(-w, w, 1):
            numerator = 1
            denominator = 1
            if n  -  i >= len(x): continue
            for j in range(-w, w, 1):
                if i != j:
                    numerator *= nk - (n - j)
                    denominator *= (j - i)
            y[k] += x[n - i] * numerator / denominator
    return y


def SineInterpolation(x, w, L, M):
    N = len(x)
    K = int((M / L) * N)
    factor = L / M
    y = np.zeros(K)
    for k in range(K):
        nk = factor * k
        n = math.floor(nk)
        for i in range(-w, w, 1):
            if n  -  i >= len(x): continue
            if nk - n + i == 0: continue
            numerator = math.sin((nk - n + i))
            denominator = math.pi * (nk - n +i)
            y[k] += x[n - i] * numerator / denominator
    return y

def low_pass_FIR(data, f):
    b = signal.firwin(15, f)
    low_data = signal.lfilter(b, 1, data)
    return low_data
