"""
@FileName: model.py
@Description: Implement model
@Author: Ryuk
@CreateDate: 2020/05/20
@LastEditTime: 2020/05/20
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import torch
import torch.nn.functional as F
import torch.nn as nn
from torch.nn.utils.rnn import pad_sequence, pack_padded_sequence, pad_packed_sequence

class GCNet(nn.Module):
    def __init__(self, in_dim=32, hidden_dim=64, n_layer=2, n_class=1):
        super(GCNet, self).__init__()
        self.n_layer = n_layer
        self.hidden_dim = hidden_dim
        self.lstm = nn.LSTM(in_dim, hidden_dim, n_layer, batch_first=True, bidirectional=True)
        self.classifier = nn.Linear(2 * hidden_dim, n_class)

    def forward(self, x, lens):
        lens = torch.as_tensor(lens, dtype=torch.int64)
        x = pack_padded_sequence(x, lens, batch_first=True,enforce_sorted=False)
        out, _ = self.lstm(x)
        out, lens = pad_packed_sequence(out, batch_first=True)
        out = out[:, -1, :]
        out = self.classifier(out)
        out = F.torch.sigmoid(out)
        return out

def main():
    x = torch.rand([1, 333, 32])        # (batch, seq_len, feature_dim)
    lens = [333]
    model = GCNet()
    print(model(x, lens))

if __name__ == "__main__":
    main()

