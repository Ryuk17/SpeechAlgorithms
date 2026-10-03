# -*- coding:utf-8 -*-
"""
@author:：Ryuk
@contact: jeryuklau@gmail.com
"""


import numpy as np
import matplotlib.pyplot as plt
import pyroomacoustics as pra
import librosa


if __name__ == "__main__":
    # The desired reverberation time and dimensions of the room
    rt60_tgt = 1.2  # seconds
    room_dim = [8, 8]  # meters

    # import a mono wavfile as the source signal
    # the sampling frequency should match that of the room
    audio, fs = librosa.load("./samples/raw.wav", sr=16000)

    # We invert Sabine's formula to obtain the parameters for the ISM simulator
    e_absorption, max_order = pra.inverse_sabine(rt60_tgt, room_dim)

    # Create the room
    room = pra.ShoeBox(
        room_dim, fs=fs, materials=pra.Material(e_absorption), max_order=max_order
    )

    # place the source in the room
    room.add_source([4, 7], signal=audio, delay=0)

    # define the locations of the microphones
    mic_num = 4
    mic_radius = 0.05
    R = pra.circular_2D_array([4, 4], mic_num, 0, mic_radius)

    room.add_microphone_array(pra.MicrophoneArray(R, room.fs))

    # Run the simulation (this will also build the RIR automatically)
    room.simulate()

    room.mic_array.to_wav(
        "./samples/room.wav",
        norm=True,
        bitdepth=np.int16,
    )

    # measure the reverberation time
    rt60 = room.measure_rt60()
    print("The desired RT60 was {}".format(rt60_tgt))
    print("The measured RT60 is {}".format(rt60[1, 0]))

    fig, ax = room.plot()
    plt.grid()
    plt.show()

    signals = room.mic_array.signals
    n_fft = 512

    s_FFT = librosa.stft(signals, n_fft=n_fft)


    doa = pra.doa.srp.SRP(R, fs, n_fft, c=343, max_four=4, num_src=1) #perform SRP approximation
    doa.locate_sources(s_FFT)

    doa.polar_plt_dirac()
    plt.title('SRP-PHAT')
    print('SRP-PHAT')
    print('Speakers at: ',np.sort(doa.azimuth_recon)/np.pi*180, 'degrees')
    plt.show()