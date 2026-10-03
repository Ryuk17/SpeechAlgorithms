"""
@FileName: inference.py
@Description: Implement inference
@Author: Ryuk
@CreateDate: 2020/05/15
@LastEditTime: 2020/05/15
@LastEditors: Please set LastEditors
@Version: v0.1
"""

from model import *
from utils import *
import torch
import matplotlib.pyplot as plt


model = VADNet()
model.load_state_dict(torch.load('./parameters.pkl'))

wav, sr = librosa.load("./test.wav", sr=8000)
feature = extractFeature("./test.wav")
feature = np.array(feature, dtype=np.float32)
label = extractLabel("./test.wav")

frame_num = np.arange(0, len(feature))
feature = np.expand_dims(feature, axis=0)
feature = torch.tensor(feature)

model.eval()
with torch.no_grad():
    vad = model(feature)
vad = vad.numpy().reshape(333)
vad[vad > 0.5] = 1
vad[vad <= 0.5] = 0


correct = np.equal(vad, label).sum()
print(correct / len(label))

frame_length = 240
length = np.arange(0, len(wav)) * (1.0 / sr)
frames = librosa.util.frame(wav, frame_length=frame_length, hop_length=frame_length)
frames = frames.T

fig = plt.figure()

for i in range(len(vad)):
    if vad[i] == 0:
        plt.plot(np.arange(i*frame_length, (i+1)*frame_length), frames[i], 'r')
    else:
        plt.plot(np.arange(i*frame_length, (i+1)*frame_length), frames[i], 'b')


plt.show()


