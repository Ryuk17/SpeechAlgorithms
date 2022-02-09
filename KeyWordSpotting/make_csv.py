"""
@FileName: make_csv.py
@Description: Implement make_csv
@Author: Ryuk
@CreateDate: 2022/01/10
@LastEditTime: 2022/01/10
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import glob
import pandas as pd
import argparse
from sklearn.utils import shuffle


parser = argparse.ArgumentParser()
parser.add_argument('--target', '-t', type=str, default="./dataset/target", help="target folder")
parser.add_argument('--background', '-b',  type=str, default="./dataset/background", help="background folder")
parser.add_argument('--csv', '-c',  type=str, default="./dataset/data.csv", help="output csv")

def make_csv(target_folder, background_folder):
    target_pattern = target_folder + "/*.wav"
    background_pattern = background_folder + "/*.wav"

    target_list = glob.glob(target_pattern)
    target_label = [1] * len(target_list)

    background_list = glob.glob(background_pattern)
    background_label = [0] * len(background_list)

    target_df = pd.DataFrame({"path": target_list, "label":target_label})
    background_df = pd.DataFrame({"path": background_list, "label": background_label})

    data_df = pd.concat((target_df, background_df))
    data_df = shuffle(data_df)
    data_df.to_csv(args.csv, index=0)


if __name__ == "__main__":
    args = parser.parse_args()
    make_csv(args.target, args.background)
    print(__file__, "Finished")