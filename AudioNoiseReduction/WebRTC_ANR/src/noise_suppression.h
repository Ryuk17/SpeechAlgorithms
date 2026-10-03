/*
 *  Copyright (c) 2012 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */
#ifndef WEBRTC_MODULES_AUDIO_PROCESSING_NS_NOISE_SUPPRESSION_H_
#define WEBRTC_MODULES_AUDIO_PROCESSING_NS_NOISE_SUPPRESSION_H_

#include <stddef.h>
#include <stdint.h>

#define BLOCKL_MAX          160 // max processing block length: 160
#define ANAL_BLOCKL_MAX     256 // max analysis block length: 256
#define HALF_ANAL_BLOCKL    129 // half max analysis block length + 1
#define NUM_HIGH_BANDS_MAX  2   // max number of high bands: 2

#define QUANTILE            (float)0.25

#define SIMULT              3
#define END_STARTUP_LONG    200
#define END_STARTUP_SHORT   50
#define FACTOR              (float)40.0
#define WIDTH               (float)0.01

// Length of fft work arrays.
#define IP_LENGTH (ANAL_BLOCKL_MAX >> 1) // must be at least ceil(2 + sqrt(ANAL_BLOCKL_MAX/2))
#define W_LENGTH (ANAL_BLOCKL_MAX >> 1)

//PARAMETERS FOR NEW METHOD
#define DD_PR_SNR           (float)0.98 // DD update of prior SNR
#define LRT_TAVG            (float)0.50 // tavg parameter for LRT (previously 0.90)
#define SPECT_FL_TAVG       (float)0.30 // tavg parameter for spectral flatness measure
#define SPECT_DIFF_TAVG     (float)0.30 // tavg parameter for spectral difference measure
#define PRIOR_UPDATE        (float)0.10 // update parameter of prior model
#define NOISE_UPDATE        (float)0.90 // update parameter for noise
#define SPEECH_UPDATE       (float)0.99 // update parameter when likely speech
#define WIDTH_PR_MAP        (float)4.0  // width parameter in sigmoid map for prior model
#define LRT_FEATURE_THR     (float)0.5  // default threshold for LRT feature
#define SF_FEATURE_THR      (float)0.5  // default threshold for Spectral Flatness feature
#define PROB_RANGE          (float)0.20 // probability threshold for noise state in
// speech/noise likelihood
#define HIST_PAR_EST         1000       // histogram size for estimation of parameters
#define GAMMA_PAUSE         (float)0.05 // update for conservative noise estimate
//
#define B_LIM               (float)0.5  // threshold in final energy gain factor calculation


#include <assert.h>


typedef struct NsHandleT NsHandle;

#ifdef __cplusplus
extern "C" {
#endif

typedef struct NSParaExtract_ {
    // Bin size of histogram.
    float binSizeLrt;
    float binSizeSpecFlat;
    float binSizeSpecDiff;
    // Range of histogram over which LRT threshold is computed.
    float rangeAvgHistLrt;
    // Scale parameters: multiply dominant peaks of the histograms by scale factor
    // to obtain thresholds for prior model.
    float factor1ModelPars;  // For LRT and spectral difference.
    float factor2ModelPars;  // For spectral_flatness: used when noise is flatter
    // than speech.
    // Peak limit for spectral flatness (varies between 0 and 1).
    float thresPosSpecFlat;
    // Limit on spacing of two highest peaks in histogram: spacing determined by
    // bin size.
    float limitPeakSpacingSpecFlat;
    float limitPeakSpacingSpecDiff;
    // Limit on relevance of second peak.
    float limitPeakWeightsSpecFlat;
    float limitPeakWeightsSpecDiff;
    // Limit on fluctuation of LRT feature.
    float thresFluctLrt;
    // Limit on the max and min values for the feature thresholds.
    float maxLrt;
    float minLrt;
    float maxSpecFlat;
    float minSpecFlat;
    float maxSpecDiff;
    float minSpecDiff;
    // Criteria of weight of histogram peak to accept/reject feature.
    int thresWeightSpecFlat;
    int thresWeightSpecDiff;

} NSParaExtract;

typedef struct NoiseSuppressionC_ {
    uint32_t fs;
    size_t blockLen;
    size_t windShift;
    size_t anaLen;
    size_t magnLen;
    float normMagnLen;
    int aggrMode;
    const float *window;
    float analyzeBuf[ANAL_BLOCKL_MAX];
    float dataBuf[ANAL_BLOCKL_MAX];
    float syntBuf[ANAL_BLOCKL_MAX];

    int initFlag;
    // Parameters for quantile noise estimation.
    float density[SIMULT * HALF_ANAL_BLOCKL];
    float lquantile[SIMULT * HALF_ANAL_BLOCKL];
    float quantile[HALF_ANAL_BLOCKL];
    int counter[SIMULT];
    int updates;
    // Parameters for Wiener filter.
    float smooth[HALF_ANAL_BLOCKL];
    float log_lut[HALF_ANAL_BLOCKL];
    float log_lut_sqr[HALF_ANAL_BLOCKL];
    float overdrive;
    float denoiseBound;
    int gainmap;
    // FFT work arrays.
    size_t ip[IP_LENGTH];
    float wfft[W_LENGTH];

    // Parameters for new method: some not needed, will reduce/cleanup later.
    int32_t blockInd;  // Frame index counter.
    int modelUpdatePars[4];  // Parameters for updating or estimating.
    // Thresholds/weights for prior model.
    float priorModelPars[7];  // Parameters for prior model.
    float noise[HALF_ANAL_BLOCKL];  // Noise spectrum from current frame.
    float noisePrev[HALF_ANAL_BLOCKL];  // Noise spectrum from previous frame.
    // Magnitude spectrum of previous analyze frame.
    float magnPrevAnalyze[HALF_ANAL_BLOCKL];
    // Magnitude spectrum of previous process frame.
    float magnPrevProcess[HALF_ANAL_BLOCKL];
    float logLrtTimeAvg[HALF_ANAL_BLOCKL];  // Log LRT factor with time-smoothing.
    float priorSpeechProb;  // Prior speech/noise probability.
    float featureData[7];
    // Conservative noise spectrum estimate.
    float magnAvgPause[HALF_ANAL_BLOCKL];
    float signalEnergy;  // Energy of |magn|.
    float sumMagn;
    float whiteNoiseLevel;  // Initial noise estimate.
    float initMagnEst[HALF_ANAL_BLOCKL];  // Initial magnitude spectrum estimate.
    float pinkNoiseNumerator;  // Pink noise parameter: numerator.
    float pinkNoiseExp;  // Pink noise parameter: power of frequencies.
    float parametricNoise[HALF_ANAL_BLOCKL];
    // Parameters for feature extraction.
    NSParaExtract featureExtractionParams;
    // Histograms for parameter estimation.
    int histLrt[HIST_PAR_EST];
    int histSpecFlat[HIST_PAR_EST];
    int histSpecDiff[HIST_PAR_EST];
    // Quantities for high band estimate.
    float speechProb[HALF_ANAL_BLOCKL];  // Final speech/noise prob: prior + LRT.
    // Buffering data for HB.
    float dataBufHB[NUM_HIGH_BANDS_MAX][ANAL_BLOCKL_MAX];

} NoiseSuppressionC;

// Refer to fft4g.c for documentation.
void WebRtc_rdft(size_t n, int isgn, float *a, size_t *ip, float *w);

/****************************************************************************
 * WebRtcNs_InitCore(...)
 *
 * This function initializes a noise suppression instance
 *
 * Input:
 *      - self          : Instance that should be initialized
 *      - fs            : Sampling frequency
 *
 * Output:
 *      - self          : Initialized instance
 *
 * Return value         :  0 - Ok
 *                        -1 - Error
 */
int WebRtcNs_InitCore(NoiseSuppressionC *self, uint32_t fs);

/****************************************************************************
 * WebRtcNs_set_policy_core(...)
 *
 * This changes the aggressiveness of the noise suppression method.
 *
 * Input:
 *      - self          : Instance that should be initialized
 *      - mode          : 0: Mild (6dB), 1: Medium (10dB), 2: Aggressive (15dB)
 *
 * Output:
 *      - self          : Initialized instance
 *
 * Return value         :  0 - Ok
 *                        -1 - Error
 */
int WebRtcNs_set_policy_core(NoiseSuppressionC *self, int mode);

/****************************************************************************
 * WebRtcNs_AnalyzeCore
 *
 * Estimate the background noise.
 *
 * Input:
 *      - self          : Instance that should be initialized
 *      - speechFrame   : Input speech frame for lower band
 *
 * Output:
 *      - self          : Updated instance
 */
void WebRtcNs_AnalyzeCore(NoiseSuppressionC *self, const int16_t *speechFrame);

/****************************************************************************
 * WebRtcNs_ProcessCore
 *
 * Do noise suppression.
 *
 * Input:
 *      - self          : Instance that should be initialized
 *      - inFrame       : Input speech frame for each band
 *      - num_bands     : Number of bands
 *
 * Output:
 *      - self          : Updated instance
 *      - outFrame      : Output speech frame for each band
 */
void WebRtcNs_ProcessCore(NoiseSuppressionC *self,
                          const int16_t *const *inFrame,
                          size_t num_bands,
                          int16_t *const *outFrame);

/*
 * This function creates an instance of the floating point Noise Suppression.
 */
NsHandle *WebRtcNs_Create();

/*
 * This function frees the dynamic memory of a specified noise suppression
 * instance.
 *
 * Input:
 *      - NS_inst       : Pointer to NS instance that should be freed
 */
void WebRtcNs_Free(NsHandle *NS_inst);

/*
 * This function initializes a NS instance and has to be called before any other
 * processing is made.
 *
 * Input:
 *      - NS_inst       : Instance that should be initialized
 *      - fs            : sampling frequency
 *
 * Output:
 *      - NS_inst       : Initialized instance
 *
 * Return value         :  0 - Ok
 *                        -1 - Error
 */
int WebRtcNs_Init(NsHandle *NS_inst, uint32_t fs);

/*
 * This changes the aggressiveness of the noise suppression method.
 *
 * Input:
 *      - NS_inst       : Noise suppression instance.
 *      - mode          : 0: Mild, 1: Medium , 2: Aggressive
 *
 * Output:
 *      - NS_inst       : Updated instance.
 *
 * Return value         :  0 - Ok
 *                        -1 - Error
 */
int WebRtcNs_set_policy(NsHandle *NS_inst, int mode);

/*
 * This functions estimates the background noise for the inserted speech frame.
 * The input and output signals should always be 10ms (80 or 160 samples).
 *
 * Input
 *      - NS_inst       : Noise suppression instance.
 *      - spframe       : Pointer to speech frame buffer for L band
 *
 * Output:
 *      - NS_inst       : Updated NS instance
 */
void WebRtcNs_Analyze(NsHandle *NS_inst, const int16_t *spframe);

/*
 * This functions does Noise Suppression for the inserted speech frame. The
 * input and output signals should always be 10ms (80 or 160 samples).
 *
 * Input
 *      - NS_inst       : Noise suppression instance.
 *      - spframe       : Pointer to speech frame buffer for each band
 *      - num_bands     : Number of bands
 *
 * Output:
 *      - NS_inst       : Updated NS instance
 *      - outframe      : Pointer to output frame for each band
 */
void WebRtcNs_Process(NsHandle *NS_inst,
                      const int16_t *const *spframe,
                      size_t num_bands,
                      int16_t *const *outframe);

/* Returns the internally used prior speech probability of the current frame.
 * There is a frequency bin based one as well, with which this should not be
 * confused.
 *
 * Input
 *      - handle        : Noise suppression instance.
 *
 * Return value         : Prior speech probability in interval [0.0, 1.0].
 *                        -1 - NULL pointer or uninitialized instance.
 */
float WebRtcNs_prior_speech_probability(NsHandle *handle);

/* Returns a pointer to the noise estimate per frequency bin. The number of
 * frequency bins can be provided using WebRtcNs_num_freq().
 *
 * Input
 *      - handle        : Noise suppression instance.
 *
 * Return value         : Pointer to the noise estimate per frequency bin.
 *                        Returns NULL if the input is a NULL pointer or an
 *                        uninitialized instance.
 */
const float *WebRtcNs_noise_estimate(const NsHandle *handle);

/* Returns the number of frequency bins, which is the length of the noise
 * estimate for example.
 *
 * Return value         : Number of frequency bins.
 */
size_t WebRtcNs_num_freq();

#ifdef __cplusplus
}
#endif

#endif  // WEBRTC_MODULES_AUDIO_PROCESSING_NS_NOISE_SUPPRESSION_H_
