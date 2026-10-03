# Speech Algorithms

The implementation of various speech algorithms can be downloaded individually through [DownGit](https://minhaskamal.github.io/DownGit/#/home).

# Content

## Speech Signal Processing
| Title        |  Code  |
| --------   | :----:  |
| Resample Speech Signal at Arbitrary Sample Rate     |   [Code](./Resample)     |
| Audio Alignment with Cross-correlation  | [Code](./AudioProcess/AudioAlignment)     |
| Music Recognition System Based on Audio Fingerprinting |  [Code](./AudioProcess/AudioFingerPrinting)     |
| Goertzel Algorithm  |    [Code](./AudioProcess/Goertzel)     |
| Voice Speed and Pitch Changes       |   [Code](./AudioProcess/VoiceChange)     |
| Embedding and Extracting Audio Digital Watermarkings     |   [Code](./AudioProcess/Watermarking)     |
| Enframe, Windowing and DFT     |   [Code](./AudioProcess/EnframeWindowFFT)     |
| CTC Prefix Beam Search      |   [Code](./AudioProcess/CtcSearcher)     |
| Speech Similarity Evaluation (Dynamic Time Warping)      |   [Code](./AudioProcess/DynamicTimeWarping)     |

## Sound Design
| Title        |  Code  |
| --------   | :----:  |
| Generate the Sound of Rain       |   [Code](./DesignSound/rain)     |
| Generate the Sound of Wind       |   [Code](./DesignSound/wind)     |

## Acoustic Echo Cancellation
| Title        |   Code  |
| --------   |  :----:  |
| Introduction of Adaptive Filter (LMS) Echo Cancellation   |  [Code](./AcousticEchoCancellation/lms)  |
| Acoustic Echo Cancellation Algorithm Based on Kalman Filter     |    [Code](./AcousticEchoCancellation/kalman)     |
| Introduction of WebRTC AEC      |   [Code](./AcousticEchoCancellation/WebRTC_AEC)     |

## Automatic Gain Control
| Title        |   Code  |
| --------   |  :----:  |
| Introduction of WebRTC AGC     |   [Code](./AudioGainControl/WebRTC_AGC)     |

## Noise Reduction
| Title        |   Code  |
| --------   |  :----:  |
| Speech Enhancement Using Spectral Subtraction |  [Code](./AudioNoiseReduction/SpectralSubtraction)     |
| Transient Noise Suppression      |    [Code](./AudioNoiseReduction/TransientInterferenceSuppression)     |
| Introduction of WebRTC ANR |   [Code](./AudioNoiseReduction/WebRTC_ANR)     |

## Speech Enhancement
| Title        |   Code  |
| --------   |  :----:  |
| Generate Speech Samples with noisy/echo/reverbed/howling    |   [Code](./SpeechEnhancement/SpeechAugmentation)  |
| Single Channel Speech Enhancement Using DNN       |    [Code](./SpeechEnhancement/SpeechMask)  |
| Speech Speration Based on TF Mask   |  [Code](./SpeechEnhancement/SpeechSperation)   |
| Data Augmentations for Speech Enhancement  |[Code](https://github.com/Ryuk17/noise-xorcist/tree/main/datasets)  |
| How to Generate Howling Samples     |   [Code](https://github.com/Ryuk17/noise-xorcist/tree/main/datasets)     |

## Voice Activity Detection
| Title        |   Code  |
| --------   |  :----:  |
| Introduction of WebRTC VAD     |   [Code](./VoiceActivityDetection/WebRTC_VAD)     |
| Endpoint Detection Using LSTM    | [Code](./VoiceActivityDetection/LSTM_VAD)  |
| Generate VAD Labels Using AMR Codec      |  [Code](./VoiceActivityDetection/LSTM_VAD/VADCoder) |

## Microphone Array Algorithms
| Title        |   Code  |
| --------   |  :----:  |
| CGMM-MVDR   | [Code](./MicrophoneArray/Beamforming/CGMM-MVDR)  |
| Sound Source Localization Based on TDOA      |    [Code](./MicrophoneArray/SoundSourceLocalization)     |
| Sound Source Localization Based on SRP-PHAT      |    [Code](./MicrophoneArray/SoundSourceLocalization)     |

## Speech Pattern Recognition
| Title        |   Code  |
| --------   |  :----:  |
| Speech Commands Recognition Using CNN   |  [Code](./AudioPatternReognition/CommandRecognition) |
| Speaker Gender Identification  | [Code](./AudioPatternReognition/GenderClassify)  |
| Environmental Sound Classification Using XGBoost       |   [Code](./AudioPatternReognition/EnvironmentSoundClassification)     |
| Keyword Spotting Using Deep Learning   |  [Code](./AudioPatternReognition/KeyWordSpotting) |
| Vowel and Consonant Division  | [Code](./AudioPatternReognition/VowelConsonantDivision)  |

## Speech Codec
| Title        | Code  |
| --------   | :----:  |
| AI Speech Codec (Lyra)     |   [Code](./SpeechCodec/Lyra)     |
| G.711 Speech Codec     |    [Code](./SpeechCodec/G711)     |

## Speech Metrics
| Title        |  Code  |
| --------   |  :----:  |
| Speech Quality Metrics     |  [Code](./SpeechMetrics/SpeechQualityMeasures)     |
| Speech Intelligibility Metrics      |  [Code](./SpeechMetrics/SpeechIntelligibilityMetrics)     |
