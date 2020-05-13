"""
@FileName: utils.py
@Description: Implement utils
@Author: Ryuk
@CreateDate: 2020/05/12
@LastEditTime: 2020/05/12
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import logging
import random
import argparse
import librosa
import numpy as np
from torch.utils.data import Dataset
from functools import partial



def PaddingOrTruncate(sample, length=16000):
    if len(sample) < length:
        pad = np.zeros(length - len(sample))
        sample = np.hstack([sample, pad])
    elif len(sample) > length:
        sample = sample[-length:]

    assert len(sample) == length
    return sample

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

class CommandDataset(Dataset):
    def __init__(self, txt_path,  Shuffle=True, mode="train"):
        fh = open(txt_path, 'r')
        files = []
        for line in fh:
            line = line.rstrip()
            words = line.split()
            files.append((words[0], int(words[1])))

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
        wav, sr = librosa.load(fn, sr=16000)
        wav = PaddingOrTruncate(wav)
        feature = librosa.feature.mfcc(wav, sr, n_mfcc=50)
        feature = np.expand_dims(feature, axis=0)
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
        parser.add_argument('--batch_size', type=int, default=128, help='batch size')
        parser.add_argument('--lr', type=float, default=1e-3, help='lr for weights')
        parser.add_argument('--iters', type=int, default=101, help='train epochs')
        parser.add_argument('--print_interval', type=int, default=500, help='print interval when training')
        parser.add_argument('--params_path', type=str, default="./parameters.pkl", help='trained parameters')
        return parser

    def __init__(self):
        parser = self.build_parser()
        args = parser.parse_args()
        super().__init__(**vars(args))



