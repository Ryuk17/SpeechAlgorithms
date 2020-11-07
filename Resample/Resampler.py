"""
@FileName: Resampler.py
@Description: Implement Resampler
@Author: Ryuk
@CreateDate: 2020/11/03
@LastEditTime: 2020/11/03
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import soundfile as sf
import librosa
from Algorithm import *
import time

upsample_sr = 32000
downsample_sr = 8000
sr = 16000
w = 2
data, fs = librosa.load("./test.wav", sr=sr)

method = ["Direct","Lagrange", "Sine"]
for m in method:
    if m == "Direct":
        print("Direct Interpolation")

        upsample_name = "upsample_" + m + ".wav"
        downsample_name = "downsample_" + m + ".wav"
        filtered_downsample_name = "filtered_downsample_" + m + ".wav"
        start = time.time()
        upsample_data = DirectInterpolation(data, fs, upsample_sr)
        end = time.time()
        print('Running time of Direct Interpolation upsample: %s Seconds' % (end - start))
        sf.write(upsample_name, upsample_data, upsample_sr)

        start = time.time()
        downsample_data = DirectInterpolation(data, fs, downsample_sr)
        end = time.time()
        print('Running time of Direct Interpolation downsample: %s Seconds' % (end - start))
        sf.write(downsample_name, downsample_data, downsample_sr)

        filtered_data = low_pass_FIR(downsample_data, 0.5)
        sf.write(filtered_downsample_name, filtered_data, downsample_sr)

    elif m == "Lagrange":
        print("Lagrange Interpolation")
        upsample_name = "upsample_" + m + ".wav"
        downsample_name = "downsample_" + m + ".wav"
        start = time.time()
        upsample_data = LagrangeInterpolation(data, w, fs, upsample_sr)
        end = time.time()
        print('Running time of Lagrange Interpolation upsample: %s Seconds' % (end - start))
        sf.write(upsample_name, upsample_data, upsample_sr)

        start = time.time()
        downsample_data = LagrangeInterpolation(data, w, fs, downsample_sr)
        end = time.time()
        print('Running time of Lagrange Interpolation downsample: %s Seconds' % (end - start))
        sf.write(downsample_name, downsample_data, downsample_sr)
    else:
        print("Sine Interpolation")
        upsample_name = "upsample_" + m + ".wav"
        downsample_name = "downsample_" + m + ".wav"
        start = time.time()
        upsample_data = SineInterpolation(data, w, fs, upsample_sr)
        end = time.time()
        print('Running time of Sine Interpolation upsample: %s Seconds' % (end - start))
        sf.write(upsample_name, upsample_data, upsample_sr)

        start = time.time()
        downsample_data = SineInterpolation(data, w, fs, downsample_sr)
        end = time.time()
        print('Running time of Sine Interpolation downsample: %s Seconds' % (end - start))
        sf.write(downsample_name, downsample_data, downsample_sr)


