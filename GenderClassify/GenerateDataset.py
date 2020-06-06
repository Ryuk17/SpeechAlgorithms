"""
@FileName: GenerateDataset.py
@Description: Implement GenerateDataset
@Author: Ryuk
@CreateDate: 2020/05/19
@LastEditTime: 2020/05/19
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import glob
import numpy

import glob
from tqdm import tqdm

fn = "./data_list.txt"

gender = ['male', 'female']


with open(fn, "a") as file:
    for sex in gender:
        wav_path = "./data/%s/wav/*.wav" %sex
        vad_path = "./data/%s/vad/*.txt" %sex

        wav_files = glob.glob(wav_path)
        vad_files = glob.glob(vad_path)
        for i in tqdm(range(len(wav_files))):
            try:
                if sex == 'male':
                    label = 0
                else:
                    label = 1
                file.write(wav_files[i].replace("\\", "/") + "\t " + vad_files[i].replace("\\", "/") + "\t " + str(label) + "\n")
            except:
                exit()