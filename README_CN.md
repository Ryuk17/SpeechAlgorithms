# 语音算法

各类语音算法的实现代码可通过 [DownGit](https://minhaskamal.github.io/DownGit/#/home) 单独下载。

# 目录

## 语音信号处理
| 标题 | 代码链接 |
| ---- | :------: |
| 语音信号任意采样率重采样 | [代码](./Resample) |
| 基于互相关的音频对齐 | [代码](./AudioProcess/AudioAlignment) |
| 基于音频指纹的音乐识别系统 | [代码](./AudioProcess/AudioFingerPrinting) |
| 格尔泽尔算法（Goertzel Algorithm） | [代码](./AudioProcess/Goertzel) |
| 语音语速与音调调整 | [代码](./AudioProcess/VoiceChange) |
| 音频数字水印的嵌入与提取 | [代码](./AudioProcess/Watermarking) |
| 分帧、加窗与离散傅里叶变换（DFT） | [代码](./AudioProcess/EnframeWindowFFT) |
| CTC前缀束搜索算法 | [代码](./AudioProcess/CtcSearcher) |
| 语音相似度评估（动态时间规整） | [代码](./AudioProcess/DynamicTimeWarping) |

## 声音设计
| 标题 | 代码链接 |
| ---- | :------: |
| 雨声生成 | [代码](./DesignSound/rain) |
| 风声生成 | [代码](./DesignSound/wind) |

## 回声消除
| 标题 | 代码链接 |
| ---- | :------: |
| 自适应滤波（LMS）回声消除原理与实现 | [代码](./AcousticEchoCancellation/lms) |
| 基于卡尔曼滤波的声学回声消除算法 | [代码](./AcousticEchoCancellation/kalman) |
| WebRTC AEC（声学回声消除）原理与实现 | [代码](./AcousticEchoCancellation/WebRTC_AEC) |

## 自动增益控制
| 标题 | 代码链接 |
| ---- | :------: |
| WebRTC AGC（自动增益控制）原理与实现 | [代码](./AudioGainControl/WebRTC_AGC) |

## 噪声抑制
| 标题 | 代码链接 |
| ---- | :------: |
| 基于谱减法的语音增强 | [代码](./AudioNoiseReduction/SpectralSubtraction) |
| 瞬态噪声抑制 | [代码](./AudioNoiseReduction/TransientInterferenceSuppression) |
| WebRTC ANR（自动噪声抑制）原理与实现 | [代码](./AudioNoiseReduction/WebRTC_ANR) |

## 语音增强
| 标题 | 代码链接 |
| ---- | :------: |
| 生成含噪声/回声/混响/啸叫的语音样本 | [代码](./SpeechEnhancement/SpeechAugmentation) |
| 基于深度神经网络（DNN）的单通道语音增强 | [代码](./SpeechEnhancement/SpeechMask) |
| 基于时频掩码的语音分离 | [代码](./SpeechEnhancement/SpeechSperation) |
| 语音增强的数据增强方法 | [代码](https://github.com/Ryuk17/noise-xorcist/tree/main/datasets) |
| 啸叫样本生成方法 | [代码](https://github.com/Ryuk17/noise-xorcist/tree/main/datasets) |

## 语音活动检测
| 标题 | 代码链接 |
| ---- | :------: |
| WebRTC VAD（语音活动检测）原理与实现 | [代码](./VoiceActivityDetection/WebRTC_VAD) |
| 基于长短期记忆网络（LSTM）的端点检测 | [代码](./VoiceActivityDetection/LSTM_VAD) |
| 利用AMR编解码器生成语音活动检测（VAD）标签 | [代码](./VoiceActivityDetection/LSTM_VAD/VADCoder) |

## 麦克风阵列算法
| 标题 | 代码链接 |
| ---- | :------: |
| CGMM-MVDR波束形成算法 | [代码](./MicrophoneArray/Beamforming/CGMM-MVDR) |
| 基于到达时间差（TDOA）的声源定位 | [代码](./MicrophoneArray/SoundSourceLocalization) |
| 基于SRP-PHAT的声源定位 | [代码](./MicrophoneArray/SoundSourceLocalization) |

## 语音模式识别
| 标题 | 代码链接 |
| ---- | :------: |
| 基于卷积神经网络（CNN）的语音指令识别 | [代码](./AudioPatternReognition/CommandRecognition) |
| 说话人性别识别 | [代码](./AudioPatternReognition/GenderClassify) |
| 基于XGBoost的环境声音分类 | [代码](./AudioPatternReognition/EnvironmentSoundClassification) |
| 基于深度学习的关键词识别 | [代码](./AudioPatternReognition/KeyWordSpotting) |
| 元音与辅音划分 | [代码](./AudioPatternReognition/VowelConsonantDivision) |

## 语音编解码
| 标题 | 代码链接 |
| ---- | :------: |
| 人工智能语音编解码器（Lyra） | [代码](./SpeechCodec/Lyra) |
| G.711语音编解码器 | [代码](./SpeechCodec/G711) |

## 语音评估指标
| 标题 | 代码链接 |
| ---- | :------: |
| 语音质量评估指标 | [代码](./SpeechMetrics/SpeechQualityMeasures) |
| 语音可懂度评估指标 | [代码](./SpeechMetrics/SpeechIntelligibilityMetrics) |
