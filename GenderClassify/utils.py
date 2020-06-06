"""
@FileName: utils.py
@Description: Implement utils
@Author: Ryuk
@CreateDate: 2020/05/20
@LastEditTime: 2020/05/20
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
from torch.nn.utils.rnn import pad_sequence
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

def extractSpectralContrast(frame, sr):
    spectral_contrast = librosa.feature.spectral_contrast(frame, sr, n_fft=512, hop_length=512, n_bands=4)
    return spectral_contrast.reshape(len(spectral_contrast))

def extractMFCC(frame, sr=8000):
    mfcc = librosa.feature.mfcc(frame, sr, n_mfcc=13)
    dmfcc = np.diff(mfcc, axis=0)
    mfcc = mfcc.reshape(len(mfcc))
    dmfcc = dmfcc.reshape(len(dmfcc))
    return np.hstack([mfcc, dmfcc])

def extractSpectralCentroid(frame, sr=8000):
    spectral_centroid = librosa.feature.spectral_centroid(frame, sr, n_fft=512, hop_length=512)
    return spectral_centroid[0]

def extractPitch(frame):
    accorrelation = np.correlate(frame, frame ,mode='full')
    accorrelation = accorrelation[int(accorrelation.size/2):]
    index = np.argmax(accorrelation[1:])
    return [index]

def extractVad(vad_path):
    with open(vad_path, "r") as f:
        data = f.read()
        label = [int(i) for i in data]
    return np.array(label,dtype=np.float32)

def extractFeature(wav_path, vad, frame_length=240, hop_length=240, sr=8000):
    wav, sr = librosa.load(wav_path, sr)
    frames = librosa.util.frame(wav, frame_length=frame_length, hop_length=hop_length)
    frames = frames.T
    k = 0
    lens = int(sum(vad))
    feature = np.zeros([lens, 32])
    for i in range(len(frames)):
        if vad[i] == 1:
            mfcc = extractMFCC(frames[i], sr)
            pitch = extractPitch(frames[i])
            spectral_centroid = extractSpectralCentroid(frames[i], sr)
            spectral_contrast = extractSpectralContrast(frames[i], sr)
            feature[k] = np.hstack([mfcc, pitch, spectral_centroid, spectral_contrast])
            k += 1
    return feature, lens


class GCDataset(Dataset):
    def __init__(self, txt_path,  Shuffle=True, mode="train"):
        fh = open(txt_path, 'r')
        files = []
        for line in fh:
            line = line.rstrip()
            words = line.split()
            files.append((words[0], words[1], words[2]))

        if Shuffle:
            random.shuffle(files)

        if mode == 'train':  # train set 60%
            self.commands = files[:int(0.6 * len(files))]
        elif mode == 'val':  # val set 20% = 60%->80%
            self.commands = files[int(0.6 * len(files)):int(0.8 * len(files))]
        else:  # test set 20% = 80%->100%
            self.commands = files[int(0.8 * len(files)):]

    def __getitem__(self, index):
        wav, vad, label = self.commands[index]
        label = int(label)
        vad = extractVad(vad)
        feature, lens = extractFeature(wav, vad)
        feature = torch.tensor(feature, dtype=torch.float32)
        return feature, label, lens

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
        parser.add_argument('--batch_size', type=int, default=2, help='batch size')
        parser.add_argument('--lr', type=float, default=0.075, help='lr for weights')
        parser.add_argument('--iters', type=int, default=201, help='train epochs')
        parser.add_argument('--params_path', type=str, default="./parameters.pkl", help='trained parameters')
        return parser

    def __init__(self):
        parser = self.build_parser()
        args = parser.parse_args()
        super().__init__(**vars(args))


def main():
    dataset = GCDataset("./data_list.txt")
    loader = DataLoader(dataset)
    for x, y, z in loader:
        print(x, y, z)



if __name__ == "__main__":
    main()