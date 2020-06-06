"""
@FileName: Inference.py
@Description: Implement Inference
@Author: Ryuk
@CreateDate: 2020/06/06
@LastEditTime: 2020/06/06
@LastEditors: Please set LastEditors
@Version: v0.1
"""

from model import *
from utils import *
import torch

gender = ['male', 'female']

model = GCNet()
model.load_state_dict(torch.load('./parameters.pkl'))

test = "./test.wav"
test_vad = extractVad("./test_vad.txt")
feature, lens = extractFeature(test, test_vad)
feature = np.expand_dims(feature, axis=0)
feature = torch.tensor(feature, dtype=torch.float32)

with torch.no_grad():
    pred = model(feature, [lens])
    if pred < 0.5:
        predicted = 0
    else:
        predicted = 1
    print("This sample's gender is", gender[int(predicted)])