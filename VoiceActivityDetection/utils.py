"""
@FileName: utils.py
@Description: Implement utils
@Author: Ryuk
@CreateDate: 2020/05/13
@LastEditTime: 2020/05/13
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import logging
import random
import argparse
import librosa
import numpy as np
from torch.utils.data import Dataset, DataLoader
from functools import partial
import scipy
import torch

def set_seed(seed=2020):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)


def getLogger():
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    logfile = './train.log'
    fh = logging.FileHandler(logfile, mode='a')
    fh.setLevel(logging.DEBUG)

    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)

    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)

    logger.addHandler(fh)
    logger.addHandler(ch)
    return logger


def sgn(data):
    if data >= 0 :
        return 1
    else :
        return 0

def calculateEnergy(frame):
    return np.sum(frame ** 2)

def calculateZcr(frame):
    count = 0
    for i in range(1, len(frame)):
        count += np.abs(sgn(frame[i]) - sgn(frame[i - 1]))
    zcr = count / (2 * len(frame))
    return zcr

def calculateSpectrum(frame, n_fft=256):
    spectrum = librosa.stft(frame, hop_length=n_fft, n_fft=n_fft)
    magnitude = np.abs(spectrum)
    skew = scipy.stats.skew(magnitude)[0]
    kurtosis  = scipy.stats.kurtosis(magnitude)[0]
    return skew, kurtosis

def extractLabel(label_path):
    with open(label_path, "r") as f:
        data = f.read()
        label = [int(i) for i in data]
    return np.array(label,dtype=np.float32)

def extractFeature(wav_path, frame_length=240, hop_length=240, sr=8000):
    wav, sr = librosa.load(wav_path, sr)
    frames = librosa.util.frame(wav, frame_length=frame_length, hop_length=hop_length)
    frames = frames.T
    feature = []
    for i in range(len(frames)):
        zcr = calculateZcr(frames[i])
        energy = calculateEnergy(frames[i])
        skew, kurtosis = calculateSpectrum(frames[i])
        feature.append([zcr, energy, skew, kurtosis])
    return np.array(feature, dtype=np.float32)


class VADDataset(Dataset):
    def __init__(self, txt_path,  Shuffle=True, mode="train"):
        fh = open(txt_path, 'r')
        files = []
        for line in fh:
            line = line.rstrip()
            words = line.split()
            files.append((words[0], words[1]))

        if Shuffle:
            random.shuffle(files)

        if mode == 'train':  # train set 60%
            self.commands = files[:int(0.6 * len(files))]
        elif mode == 'val':  # val set 20% = 60%->80%
            self.commands = files[int(0.6 * len(files)):int(0.8 * len(files))]
        else:  # test set 20% = 80%->100%
            self.commands = files[int(0.8 * len(files)):]

    def __getitem__(self, index):
        fn, label = self.commands[index]
        feature = extractFeature(fn)
        label = extractLabel(label)
        return feature, label

    def __len__(self):
        return len(self.commands)


def get_parser(name):
    parser = argparse.ArgumentParser(name, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument = partial(parser.add_argument, help=' ')
    return parser

class BaseConfig(argparse.Namespace):
    def print_params(self, prtf=print):
        prtf("")
        prtf("Parameters:")
        for attr, value in sorted(vars(self).items()):
            prtf("{}={}".format(attr.upper(), value))
        prtf("")

    def as_markdown(self):
        """ Return configs as markdown format """
        text = "|name|value|  \n|-|-|  \n"
        for attr, value in sorted(vars(self).items()):
            text += "|{}|{}|  \n".format(attr, value)
        return text


class Config(BaseConfig):
    def build_parser(self):
        parser = get_parser("Command Recognition Config")
        parser.add_argument('--data_path', type=str, default="./data_list.txt", help='data list')
        parser.add_argument('--batch_size', type=int, default=64, help='batch size')
        parser.add_argument('--lr', type=float, default=0.005, help='lr for weights')
        parser.add_argument('--iters', type=int, default=201, help='train epochs')
        parser.add_argument('--params_path', type=str, default="./parameters.pkl", help='trained parameters')
        return parser

    def __init__(self):
        parser = self.build_parser()
        args = parser.parse_args()
        super().__init__(**vars(args))


def main():
    dataset = VADDataset("./data_list.txt")
    loader = DataLoader(dataset)
    for x, y in loader:
        print(x.shape, y.shape)



if __name__ == "__main__":
    main()