<<<<<<< HEAD
"""
@FileName: kws_dataset.py
@Description: Implement kws_dataset
@Author: Ryuk
@CreateDate: 2022/01/17
@LastEditTime: 2022/01/17
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import torch
from torch.utils.data import Dataset
import torchaudio
import pandas as pd


class KwsDataset(Dataset):
    def __init__(self, config, mode='train'):
        self.n_fft = config['FFT_LEN']
        self.hop_length = config['HOP_LEN']
        self.fmin = config['FMIN']
        self.fmax = config['FMAX']
        self.n_mels = config['MELS']
        self.duration = config['DURATION']
        if mode == "train":
            self.csv_path = config['CSV_PATH'] + "train.csv"
        else:
            self.csv_path = config['CSV_PATH'] + "val.csv"
        self.csv = pd.read_csv(self.csv_path)

    def __getitem__(self, index):
        audio_path = self.csv.iloc[index]['path']
        label = self.csv.iloc[index]['label']

        waveform, sample_rate = torchaudio.load(audio_path)
        assert sample_rate == 16000, f"{sample_rate} is not 16000"
        length = self.duration * sample_rate

        #truncate or padding to duration
        if waveform.shape[0] < length:
            while waveform.shape[0] < length:
                waveform = torch.cat([waveform, waveform],dim=0)
        waveform = waveform[:length]

        #modify amplitude
        rmsclean = (waveform ** 2).mean() ** 0.5
        scalarclean = 10 ** (-25 / 20) / rmsclean
        clean = waveform * scalarclean

        return

    def __len__(self):
        return len(self.csv)

if __name__ == "__main__":
    pass
=======
"""
@FileName: kws_dataset.py
@Description: Implement kws_dataset
@Author: Ryuk
@CreateDate: 2022/01/17
@LastEditTime: 2022/01/17
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import argparse
import yaml
import torch


if __name__ == "__main__":
    pass
>>>>>>> e388a991089d83481569c3e972ca094d6db0d172
