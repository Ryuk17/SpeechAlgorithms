"""
@FileName: analysis.py
@Description: Implement analysis
@Author: Ryuk
@CreateDate: 2020/06/06
@LastEditTime: 2020/06/06
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import matplotlib.pyplot as plt
import librosa
import numpy as np
from utils import *

male = "./data/male/wav/sample001.wav"
male_vad = "./data/male/vad/sample001.txt"
female = "./data/female/wav/sample001.wav"
female_vad = "./data/female/vad/sample001.txt"

male_vad = extractVad(male_vad)
female_vad = extractVad(female_vad)

male_feature, male_lens = extractFeature(male, male_vad)
female_feature, female_lens = extractFeature(female, female_vad)

m_feature= male_feature[:,27:]
f_feature = female_feature[:,27:]

cmap = "summer"
fig = plt.figure()
ax = fig.add_subplot(2, 1, 1)
ax.imshow(m_feature.T, aspect='auto')
ax.set_title("Male Spectral Contrast")
ax = fig.add_subplot(2, 1, 2)
ax.imshow(f_feature.T, aspect='auto')
ax.set_title("Female Spectral Contrast")

fig.tight_layout()
plt.show()



