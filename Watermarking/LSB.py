"""
@FileName: LSB.py
@Description: Implement LSB Algorithm
@Author: Ryuk
@CreateDate: 2020/12/06
@LastEditTime: 2020/12/06
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import scipy.io.wavfile as wav
import numpy as np

np.random.seed(2020)
stop_mark = np.random.randint(0, 2, 128)


class LSBEmbedder:
    def __init__(self, seed, rate=0.9, mode='single'):
        self.rate = rate
        self.seed = seed
        self.mode = mode
        self.stop_mark = stop_mark
        self.channels = None
        self.fs = None
        self.left_signal = None
        self.right_signal = None
        self.wavsignal = None
        self.embed_length = None

    def _waveReader(self, path):
        """
        read wave file and its corresponding
        :param path: wav fi
        :return:
        """
        fs, wavsignal = wav.read(path)
        self.fs = fs
        if len(wavsignal) == 2:
            self.channels = 2
            self.left_signal = wavsignal[0]
            self.right_signal = wavsignal[1]
        else:
            self.channels = 1
            self.wavsignal = wavsignal

    def _LSBReplace(self, wavsignal, secret_message):
        """
        embed watermarking a single wave
        :param secret_message: secret message
        :return:
        """

        # choose random embedding location with roulette
        np.random.seed(self.seed)
        roulette = np.random.rand(len(wavsignal))

        stego = np.array(wavsignal)
        k = 0
        for i in range(len(wavsignal)):
            if roulette[i] <= self.rate:
                value = wavsignal[i]
                if value < 0:
                    value = -value
                    negative = True
                else:
                    negative = False

                # embed secret bit
                if k < len(secret_message) and int(secret_message[k]) == 0:
                    value = value & 0b1111111111111110
                    k += 1
                elif k < len(secret_message) and int(secret_message[k]) == 1:
                    value = value | 0b0000000000000001
                    k += 1

                if negative:
                    stego[i] = -value
                else:
                    stego[i] = value

        stego = np.array(stego).astype(np.int16)
        return stego

    def _saveWave(self, stego, cover_path, stego_path, inplace=False):
        """
        save stego wave
        :param stego: stego wavsignal
        :param cover_path: cover path
        :param stego_path: stego path
        :param inplace: whether to save in cover path
        :return:
        """
        if inplace:
            wav.write(cover_path, self.fs, stego)
        else:
            assert stego_path is not None
            wav.write(stego_path, self.fs, stego)

    def embed(self, cover_path, stego_path, secret_message, inplace=False):
        """
        steganogaphy
        :param cover_path: cover wave path
        :param stego_path: stego wave path
        :param secret_message: secret message
        :param inplace: steganogarphy in place
        :return:
        """

        # add stop mark
        secret_message = np.concatenate([secret_message, self.stop_mark], axis=0)
        # pre check
        self._waveReader(cover_path)
        assert self.channels * len(self.wavsignal) * self.rate >= 1.1 * len(secret_message)
        assert self.channels in [1, 2]

        # embed secret message
        if self.channels == 1:
            if self.mode == 'single':
                stego = self._LSBReplace(self.wavsignal, secret_message)
                self._saveWave(stego, cover_path, stego_path, inplace)
            elif self.mode == 'batch':
                for i in range(len(cover_path)):
                    stego = self._LSBReplace(self.wavsignal, secret_message)
                    self._saveWave(stego, cover_path, stego_path, inplace)
        elif self.channels == 2:
            if self.mode == 'single':
                left_stego = self._LSBReplace(self.left_signal, secret_message)
                right_stego = self._LSBReplace(self.right_signal, secret_message)
                stego = [left_stego, right_stego]
                self._saveWave(stego, cover_path, stego_path, inplace)
            elif self.mode == 'batch':
                # the same secret messages are embedding in different carrier
                for i in range(len(stego_path)):
                    left_stego = self._LSBReplace(self.left_signal, secret_message)
                    right_stego = self._LSBReplace(self.right_signal, secret_message)
                    stego = [left_stego, right_stego]
                    self._saveWave(stego, cover_path[i], stego_path[i], inplace)

class LSBExtractor:
    def __init__(self, seed, rate=0.9):
        self.seed = seed
        self.stop_mark = stop_mark
        self.rate = rate
        self.fs = None
        self.channels= None
        self.wavsignal = None
        self.left_signal = None
        self.right_signal = None

    def _waveReader(self, path):
        """
        read wave file and its corresponding
        :param path: wav fi
        :return:
        """
        fs, wavsignal = wav.read(path)
        self.fs = fs
        if len(wavsignal) == 2:
            self.channels = 2
            self.left_signal = wavsignal[0]
            self.right_signal = wavsignal[1]
        else:
            self.channels = 1
            self.wavsignal = wavsignal

    def _checkHeader(self, header):
        """
        check the validness of header
        :param header: header
        :return: True/False
        """
        return True

    def _checkStop(self, message):
        """
        check stop
        :param message: secret message
        :return: True/False
        """

        message_stop = message[-len(self.stop_mark):]
        count = 0
        for i in range(len(self.stop_mark)):
            if message_stop[i] == self.stop_mark[i]:
                count += 1

        if count == len(self.stop_mark):
            return True
        else:
            return False

    def _LSBExtract(self, roulette, wavsignal):
        """
        extract LSB from stego wavsignal
        :param roulette:
        :param wavsignal:
        :return: secret message
        """
        message = []
        for i in range(len(wavsignal)):
            if roulette[i] <= self.rate:
                value = wavsignal[i]
                value = '{:016b}'.format(value)
                message.append(int(value[-1]))

                # check the validness of header
                if len(message) == 44:
                    assert self._checkHeader(message) is True

                # check stop mark
                if len(message) >= len(self.stop_mark) and self._checkStop(message):
                    return message
        return message

    def extract(self, wave_path, message_path):
        """
        extract message in wave
        :param wave_path: wave path
        :param message_path:  message path
        :return:
        """

        # choose random embedding location with roulette
        self._waveReader(wave_path)
        np.random.seed(self.seed)
        roulette = np.random.rand(len(self.wavsignal))


        if self.channels == 1:
            message = self._LSBExtract(roulette, self.wavsignal)
        elif self.channels == 2:
            message_left = self._LSBExtract(roulette, self.left_signal)
            message_right = self._LSBExtract(roulette, self.right_signal)
            message = np.hstack((message_left, message_right))

        with open(message_path, "w", encoding='utf-8') as f:
            f.write(''.join(str(i) for i in message))
        return message

def main():
    np.random.seed(0)
    wave_path = './org.wav'
    stego_path = './marked.wav'
    message_path = './s.txt'
    secret_message = np.random.randint(0, 2, 1600)
    alice = LSBEmbedder(0)
    alice.embed(wave_path, stego_path, secret_message)

    bob = LSBExtractor(0)
    m = bob.extract(stego_path, message_path)

    assert len(m) - len(stop_mark) == len(secret_message)
    count = 0
    for i in range(len(secret_message)):
        if int(m[i]) != int(secret_message[i]):
            count += 1

    print('BER', count / len(m))

if __name__ == '__main__':
    main()




