"""
@FileName: Inference.py
@Description: Implement Inference
@Author: Ryuk
@CreateDate: 2020/05/12
@LastEditTime: 2020/05/12
@LastEditors: Please set LastEditors
@Version: v0.1
"""

from model import *
from utils import *
import torch
import matplotlib.pyplot as plt

commands = ['yes', 'no', 'up', 'down', 'left', 'right']
model = ResNet18()
model.load_state_dict(torch.load('./parameters.pkl'))

test, sr = librosa.load("./test.wav", sr=16000)
test = PaddingOrTruncate(test)
mfcc = librosa.feature.mfcc(test, sr, n_mfcc=50)
feature = np.expand_dims(mfcc, axis=0)
feature = np.expand_dims(feature, axis=0)
feature = torch.tensor(feature)

model.eval()
with torch.no_grad():
    pred = model(feature)
    _, predicted = torch.max(pred.data, 1)
    print("This command is ", commands[int(predicted)])

length = np.arange(0, len(test)) * (1.0 / sr)
fig = plt.figure()
ax = fig.add_subplot(2, 1, 1)
ax.plot(length, test, 'b')
ax = fig.add_subplot(2, 1, 2)
cmap = "hsv"
ax.imshow(mfcc[::-1], cmap=cmap)
plt.show()