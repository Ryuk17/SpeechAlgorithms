"""
@FileName: train.py
@Description: Implement train
@Author: Ryuk
@CreateDate: 2020/05/22
@LastEditTime: 2020/05/22
@LastEditors: Please set LastEditors
@Version: v0.1
"""

from model import *
from utils import *


logger = getLogger()
logger.info("====================================Programm Start====================================")

set_seed()
config = Config()
config.print_params(logger.info)

def infer(model, loader):
    model.eval()
    correct = 0.

    for input, target, lens in loader:
        with torch.no_grad():
            target = np.expand_dims(target, axis=1)
            pred = model(input, lens).numpy()
            pred[pred > 0.5] = 1
            pred[pred <= 0.5] = 0
            correct = np.equal(pred, target).sum()
    return correct / config.batch_size

def pad_collate(batch):
    x, y, lens = zip(*batch)
    x_pad = pad_sequence(x, batch_first=True, padding_value=0)
    return x_pad, torch.tensor(y, dtype=torch.float32), torch.tensor(lens)

def main():
    best_acc = 0.

    train_set = GCDataset(config.data_path, mode="train")
    train_loader = DataLoader(train_set, batch_size=config.batch_size, collate_fn=pad_collate, shuffle=True, num_workers=1, drop_last=True)

    val_set = GCDataset(config.data_path, mode="val")
    val_loader = DataLoader(val_set, batch_size=config.batch_size, collate_fn=pad_collate, shuffle=True, num_workers=1, drop_last=True)

    test_set = GCDataset(config.data_path, mode="test")
    test_loader = DataLoader(test_set, batch_size=config.batch_size, collate_fn=pad_collate, shuffle=True, num_workers=1, drop_last=True)

    logger.info("Data Load Successfully")

    model = GCNet()
    criterion = nn.BCELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=config.lr)

    logger.info("Start Training")
    for epoch in range(config.iters):
        for step, batch in enumerate(train_loader):
            input, target, lens = batch
            optimizer.zero_grad()
            logits = model(input, lens)
            loss = criterion(logits, target)
            loss.backward()
            optimizer.step()

        # val
        if epoch % 10 == 0:
            val_acc = infer(model, val_loader)
            logger.info("Epoch:%d, Val_acc:%f" % (epoch,val_acc))
            if val_acc > best_acc:
                best_acc = val_acc
                torch.save(model.state_dict(), config.params_path)

    logger.info("Finished Training")

    logger.info("==================Testing==================")
    test_acc = infer(model, test_loader)
    logger.info("Test_acc:%f" % test_acc)

if __name__ == "__main__":
    main()