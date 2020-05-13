# coding: utf-8
"""
@FileName: train.py
@Description: Implement train
@Author: Ryuk
@CreateDate: 2020/05/12
@LastEditTime: 2020/05/12
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import logging
from torch.utils.data import DataLoader
from model import *
from utils import *


logger = getLogger()
config = Config()
config.print_params(logger.info)

def infer(model, loader, criterion):
    model.eval()
    correct = 0.
    loss = 0.
    total = len(loader.dataset)

    for input, target in loader:
        with torch.no_grad():
            logits = model(input)
            pred = torch.argmax(logits, dim=1)
            correct += torch.eq(pred, target).sum().item()
            loss += criterion(logits, target).item()

    return loss / total, correct / total


def main():
    logger.info("Programm Start")
    best_acc = 0.

    train_set = CommandDataset(config.data_path, mode="train")
    train_loader = DataLoader(train_set, batch_size=config.batch_size, shuffle=True, num_workers=1)

    val_set = CommandDataset(config.data_path, mode="val")
    val_loader = DataLoader(val_set, batch_size=config.batch_size, shuffle=True, num_workers=1)

    test_set = CommandDataset(config.data_path, mode="test")
    test_loader = DataLoader(test_set, batch_size=config.batch_size, shuffle=True, num_workers=1)

    logger.info("Data Load Successfully")

    model = ResNet18()
    criterion = nn.CrossEntropyLoss()
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
            val_loss, val_acc = infer(model, val_loader, criterion)
            logger.info("Epoch:%d, Val_loss:%f, Val_acc:%f" %(epoch, val_loss, val_acc))
            if val_acc > best_acc:
                best_acc = val_acc
                torch.save(model.state_dict(), config.params_path)


    logger.info("Finished Training")

    logger.info("==================Testing==================")
    test_loss, test_acc = infer(model, test_loader, criterion)
    logger.info(" Test_loss:%f, Test_acc:%f" % (test_loss, test_acc))


if __name__ == "__main__":
    main()
