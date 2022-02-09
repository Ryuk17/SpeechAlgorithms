<<<<<<< HEAD
"""
@FileName: train.py
@Description: Implement train
@Author: Ryuk
@CreateDate: 2022/01/04
@LastEditTime: 2022/01/04
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import argparse
import torch

parser = argparse.ArgumentParser(description="kws experiment")
parser.add_argument('--cfg', type=str, description="config", required=True)
args = parser.parse_args()

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(device)

if __name__ == "__main__":
    pass
=======
"""
@FileName: train.py
@Description: Implement train
@Author: Ryuk
@CreateDate: 2022/01/04
@LastEditTime: 2022/01/04
@LastEditors: Please set LastEditors
@Version: v0.1
"""
>>>>>>> e388a991089d83481569c3e972ca094d6db0d172
