"""
@FileName: train.py
@Description: Implement train
@Author: Ryuk
@CreateDate: 2020/05/13
@LastEditTime: 2020/05/13
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
    total = len(loader.dataset) * 333

    for input, target in loader:
        with torch.no_grad():
            pred = model(input)
            pred[pred > 0.5] = 1
            pred[pred <= 0.5] = 0
            correct += torch.eq(pred, target).sum().item()

    return correct / total


def main():
    best_acc = 0.

    train_set = VADDataset(config.data_path, mode="train")
    train_loader = DataLoader(train_set, batch_size=config.batch_size, shuffle=True, num_workers=1)
    val_set = VADDataset(config.data_path, mode="val")
    val_loader = DataLoader(val_set, batch_size=config.batch_size, shuffle=True, num_workers=1)

    test_set = VADDataset(config.data_path, mode="test")
    test_loader = DataLoader(test_set, batch_size=config.batch_size, shuffle=True, num_workers=1)

    logger.info("Data Load Successfully")

    model = VADNet()
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=config.lr)

    logger.info("Start Training")
    for epoch in range(config.iters):
        for step, (input, target) in enumerate(train_loader):
            optimizer.zero_grad()
            logits = model(input)
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