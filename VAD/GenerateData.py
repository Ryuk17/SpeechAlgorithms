"""
@FileName: GenerateData.py
@Description: Implement GenerateData
@Author: Ryuk
@CreateDate: 2020/05/13
@LastEditTime: 2020/05/13
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import glob
from tqdm import tqdm

fn = "./data_list.txt"

wav_path = "./data/wav/*.wav"
vad_path = "./data/vad/*.txt"

wav_files = glob.glob(wav_path)
vad_files = glob.glob(vad_path)

with open(fn, "a") as file:
    for i in tqdm(range(len(wav_files))):
        try:
            file.write(wav_files[i].replace("\\", "/") + "\t " + vad_files[i].replace("\\", "/") + "\n")
        except:
            exit()

