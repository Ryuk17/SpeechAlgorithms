"""
@FileName: model.py
@Description: Implement model
@Author: Ryuk
@CreateDate: 2020/05/13
@LastEditTime: 2020/05/13
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import torch
import torch.nn.functional as F
import torch.nn as nn

class VADNet(nn.Module):
    def __init__(self, in_dim=4, hidden_dim=32, n_layer=2, n_class=333):
        super(VADNet, self).__init__()
        self.n_layer = n_layer
        self.hidden_dim = hidden_dim
        self.lstm = nn.LSTM(in_dim, hidden_dim, n_layer, batch_first=True)
        self.classifier = nn.Linear(hidden_dim, n_class)

    def forward(self, x):
        out, _ = self.lstm(x)
        out = out[:, -1, :]
        out = self.classifier(out)
        out =F.torch.sigmoid(out)
        return out

def main():
    x = torch.rand([1, 333, 4])
    model = VADNet()
    print(model(x))

if __name__ == "__main__":
    main()