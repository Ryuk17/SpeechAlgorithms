"""
@FileName: NoiseReduce.py
@Description: Implement NoiseReduce
@Author: Ryuk
@CreateDate: 2020/04/24
@LastEditTime: 2020/04/24
@LastEditors: Please set LastEditors
@Version: v0.1
"""

import librosa
from basic_functions import *

class SpectralSubtraction:
    def __init__(self, data, sr, win_length=240, overlapping_rate=0.5, beta=0.002, noise_frames=5):
        self.data, self.fs = data, sr                                          # wave data and sample rate
        self.noise_frames = noise_frames                                       # frame number to estimate noise spectral
        self.win_length = win_length                                           # the number of samples in a frame
        self.overlapping_rate = overlapping_rate                               # overlapping rate
        self.overlapping_length = int(overlapping_rate * win_length)           # overlapping length
        self.hop_length = int((1 - overlapping_rate) * win_length)             # frame shift length
        self.beta = beta                                                       # beta for Berouti spectral subtraction
        self.nfft = 2 * int(pow(2, nextpow2(win_length)))                      # fft points
        self.output = None                                                     # output wave

    def getNoiseSpectrum(self):
        """
        estimate noise spectrum by using the front self.noise_frames frames
        :return: noise spectrum
        """
        noise_spectrum = np.zeros([self.nfft//2 + 1,1])
        for i in range(self.noise_frames):
            frame = self.data[i*self.win_length:(i+1)*self.win_length]
            noise_spectrum += np.abs(librosa.stft(frame, n_fft=self.nfft, hop_length=self.nfft))

        noise_spectrum = noise_spectrum / self.noise_frames
        return noise_spectrum

    def simpleSpectralSubtraction(self):
        """
        simple spectral subtraction
        :return: enhanced speech
        """
        noise_spectrum = self.getNoiseSpectrum()
        frames_nums = len(self.data)//self.hop_length

        processed_data = np.zeros(frames_nums * self.hop_length)

        k = 0
        for i in range(frames_nums):
            frame = self.data[k:k+self.win_length]
            spectrum = librosa.stft(frame, n_fft=self.nfft, hop_length=self.nfft)
            magnitude = np.abs(spectrum)
            phase = np.angle(spectrum)

            # spectral subtraction and truncation
            sub_speech = magnitude - noise_spectrum
            sub_speech[sub_speech < 0] = 0
            sub_speech_spectrum = sub_speech * np.exp(1.0j * phase)
            frame = librosa.istft(sub_speech_spectrum,window="hann", hop_length=self.nfft, length=self.win_length)

            processed_data[k:k + self.hop_length] = frame[0:self.hop_length]
            k = k + self.hop_length

        self.output = processed_data
        return processed_data

    def getAlpha(self, snr):
        """
        determine alpha
        :param snr:
        :return: alpha
        """
        if -5 <= snr <= 20:
            return 3 - snr*2/20
        else:
            if snr < -5.0:
                return 4
            else:
                return 1

    def BeroutiSpectralSubtraction(self):
        """
        Berouti spectral subtraction
        :return: enhanced speech
        """
        noise_spectrum = self.getNoiseSpectrum()
        frames_nums = len(self.data) // self.hop_length
        processed_data = np.zeros(len(self.data))

        k = 0
        for i in range(frames_nums):
            frame = self.data[k:k + self.win_length]
            spectrum = librosa.stft(frame, n_fft=self.nfft, hop_length=self.nfft)
            magnitude = np.abs(spectrum)
            phase = np.angle(spectrum)

            snr = getSNR(magnitude, noise_spectrum)
            alpha = self.getAlpha(snr)
            sub_speech = magnitude - alpha * noise_spectrum

            for j in range(len(sub_speech)):
                if sub_speech[j] < 0:
                    sub_speech[j] = self.beta * noise_spectrum[j]

            sub_speech_spectrum = sub_speech * np.exp(1.0j * phase)
            frame = librosa.istft(sub_speech_spectrum, window="hann", hop_length=self.nfft, length=self.win_length)

            processed_data[k:k + self.hop_length] = frame[0:self.hop_length]
            k = k + self.hop_length

        self.output = processed_data
        return processed_data

    def saveWave(self, output_path):
        librosa.output.write_wav(output_path, self.output.astype(np.float32), self.fs)


if __name__ == '__main__':

    x, sr = librosa.load("./sample.wav", sr=8000)
    ss = SpectralSubtraction(x, sr)
    x1 = ss.simpleSpectralSubtraction()
    x2 = ss.BeroutiSpectralSubtraction()
    displaySpeech(x, 8000)
    displaySpeech(x1, 8000)
    displaySpeech(x2, 8000)
    ss.saveWave("./output.wav")