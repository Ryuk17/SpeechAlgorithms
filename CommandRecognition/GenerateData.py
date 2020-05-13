"""
@FileName: GenerateData.py
@Description: Implement GenerateData
@Author: Ryuk
@CreateDate: 2020/05/12
@LastEditTime: 2020/05/12
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import glob
from tqdm import tqdm

commands = ['yes', 'no', 'up', 'down', 'left', 'right']


fn = "./data_list.txt"

with open(fn, "a") as file:
    for i in tqdm(range(len(commands))):
        path = "./data/%s/*.wav" % commands[i]
        files = glob.glob(path)
        for j in range(500):
            try:
                name = files[j].replace("\\", "/")
                file.write(name + "\t "+ str(i) + "\n")
            except:
                exit()