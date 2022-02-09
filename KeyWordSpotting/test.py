"""
@FileName: test.py
@Description: Implement test
@Author: Ryuk
@CreateDate: 2022/02/08
@LastEditTime: 2022/02/08
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import librosa
import soundfile as sf

waveform, sr = librosa.load("./assets/test.wav", sr=16000)
rmsclean = (waveform ** 2).mean() ** 0.5
scalarclean = 10 ** (-25 / 20) / rmsclean
clean = waveform * scalarclean
sf.write("./assets/test_out.wav", clean, sr)