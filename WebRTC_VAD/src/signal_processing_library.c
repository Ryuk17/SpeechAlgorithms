/*
 *  Copyright (c) 2012 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */
#include "signal_processing_library.h"

// TODO(bugs.webrtc.org/9553): These function pointers are useless. Refactor
// things so that we simply have a bunch of regular functions with different
// implementations for different platforms.

#if defined(WEBRTC_HAS_NEON)

const MaxAbsValueW16 WebRtcSpl_MaxAbsValueW16 = WebRtcSpl_MaxAbsValueW16Neon;
const MaxAbsValueW32 WebRtcSpl_MaxAbsValueW32 = WebRtcSpl_MaxAbsValueW32Neon;
const MaxValueW16 WebRtcSpl_MaxValueW16 = WebRtcSpl_MaxValueW16Neon;
const MaxValueW32 WebRtcSpl_MaxValueW32 = WebRtcSpl_MaxValueW32Neon;
const MinValueW16 WebRtcSpl_MinValueW16 = WebRtcSpl_MinValueW16Neon;
const MinValueW32 WebRtcSpl_MinValueW32 = WebRtcSpl_MinValueW32Neon;


#elif defined(MIPS32_LE)

const MaxAbsValueW16 WebRtcSpl_MaxAbsValueW16 = WebRtcSpl_MaxAbsValueW16_mips;
const MaxAbsValueW32 WebRtcSpl_MaxAbsValueW32 =
#ifdef MIPS_DSP_R1_LE
    WebRtcSpl_MaxAbsValueW32_mips;
#else
    WebRtcSpl_MaxAbsValueW32C;
#endif
const MaxValueW16 WebRtcSpl_MaxValueW16 = WebRtcSpl_MaxValueW16_mips;
const MaxValueW32 WebRtcSpl_MaxValueW32 = WebRtcSpl_MaxValueW32_mips;
const MinValueW16 WebRtcSpl_MinValueW16 = WebRtcSpl_MinValueW16_mips;
const MinValueW32 WebRtcSpl_MinValueW32 = WebRtcSpl_MinValueW32_mips;


#else

const MaxAbsValueW16 WebRtcSpl_MaxAbsValueW16 = WebRtcSpl_MaxAbsValueW16C;
const MaxAbsValueW32 WebRtcSpl_MaxAbsValueW32 = WebRtcSpl_MaxAbsValueW32C;
const MaxValueW16 WebRtcSpl_MaxValueW16 = WebRtcSpl_MaxValueW16C;
const MaxValueW32 WebRtcSpl_MaxValueW32 = WebRtcSpl_MaxValueW32C;
const MinValueW16 WebRtcSpl_MinValueW16 = WebRtcSpl_MinValueW16C;
const MinValueW32 WebRtcSpl_MinValueW32 = WebRtcSpl_MinValueW32C;

#endif

// Table used by WebRtcSpl_CountLeadingZeros32_NotBuiltin. For each uint32_t n
// that's a sequence of 0 bits followed by a sequence of 1 bits, the entry at
// index (n * 0x8c0b2891) >> 26 in this table gives the number of zero bits in
// n.
const int8_t kWebRtcSpl_CountLeadingZeros32_Table[64] = {
        32, 8, 17, -1, -1, 14, -1, -1, -1, 20, -1, -1, -1, 28, -1, 18,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 26, 25, 24,
        4, 11, 23, 31, 3, 7, 10, 16, 22, 30, -1, -1, 2, 6, 13, 9,
        -1, 15, -1, 21, -1, 29, 19, -1, -1, -1, -1, -1, 1, 27, 5, 12,
};

int32_t WebRtcSpl_DivW32W16(int32_t num, int16_t den) {
    // Guard against division with 0
    if (den != 0) {
        return (int32_t) (num / den);
    } else {
        return (int32_t) 0x7FFFFFFF;
    }
}



// TODO(bjorn/kma): Consolidate function pairs (e.g. combine
//   WebRtcSpl_MaxAbsValueW16C and WebRtcSpl_MaxAbsIndexW16 into a single one.)
// TODO(kma): Move the next six functions into min_max_operations_c.c.

// Maximum absolute value of word16 vector. C version for generic platforms.
int16_t WebRtcSpl_MaxAbsValueW16C(const int16_t *vector, size_t length) {
    size_t i = 0;
    int absolute = 0, maximum = 0;

    RTC_DCHECK_GT(length, 0);

    for (i = 0; i < length; i++) {
        absolute = abs((int) vector[i]);

        if (absolute > maximum) {
            maximum = absolute;
        }
    }

    // Guard the case for abs(-32768).
    if (maximum > WEBRTC_SPL_WORD16_MAX) {
        maximum = WEBRTC_SPL_WORD16_MAX;
    }

    return (int16_t) maximum;
}

// Maximum absolute value of word32 vector. C version for generic platforms.
int32_t WebRtcSpl_MaxAbsValueW32C(const int32_t *vector, size_t length) {
    // Use uint32_t for the local variables, to accommodate the return value
    // of abs(0x80000000), which is 0x80000000.

    uint32_t absolute = 0, maximum = 0;
    size_t i = 0;

    RTC_DCHECK_GT(length, 0);

    for (i = 0; i < length; i++) {
        absolute = abs((int) vector[i]);
        if (absolute > maximum) {
            maximum = absolute;
        }
    }

    maximum = WEBRTC_SPL_MIN(maximum, WEBRTC_SPL_WORD32_MAX);

    return (int32_t) maximum;
}

// Maximum value of word16 vector. C version for generic platforms.
int16_t WebRtcSpl_MaxValueW16C(const int16_t *vector, size_t length) {
    int16_t maximum = WEBRTC_SPL_WORD16_MIN;
    size_t i = 0;

    RTC_DCHECK_GT(length, 0);

    for (i = 0; i < length; i++) {
        if (vector[i] > maximum)
            maximum = vector[i];
    }
    return maximum;
}

// Maximum value of word32 vector. C version for generic platforms.
int32_t WebRtcSpl_MaxValueW32C(const int32_t *vector, size_t length) {
    int32_t maximum = WEBRTC_SPL_WORD32_MIN;
    size_t i = 0;

    RTC_DCHECK_GT(length, 0);

    for (i = 0; i < length; i++) {
        if (vector[i] > maximum)
            maximum = vector[i];
    }
    return maximum;
}

// Minimum value of word16 vector. C version for generic platforms.
int16_t WebRtcSpl_MinValueW16C(const int16_t *vector, size_t length) {
    int16_t minimum = WEBRTC_SPL_WORD16_MAX;
    size_t i = 0;

    RTC_DCHECK_GT(length, 0);

    for (i = 0; i < length; i++) {
        if (vector[i] < minimum)
            minimum = vector[i];
    }
    return minimum;
}

// Minimum value of word32 vector. C version for generic platforms.
int32_t WebRtcSpl_MinValueW32C(const int32_t *vector, size_t length) {
    int32_t minimum = WEBRTC_SPL_WORD32_MAX;
    size_t i = 0;

    RTC_DCHECK_GT(length, 0);

    for (i = 0; i < length; i++) {
        if (vector[i] < minimum)
            minimum = vector[i];
    }
    return minimum;
}

// allpass filter coefficients.
static const int16_t kResampleAllpass[2][3] = {
        {821,  6110, 12382},
        {3050, 9368, 15063}
};

//
//   decimator
// input:  int32_t (shifted 15 positions to the left, + offset 16384) OVERWRITTEN!
// output: int16_t (saturated) (of length len/2)
// state:  filter state array; length = 8

void   // bugs.webrtc.org/5486
WebRtcSpl_DownBy2IntToShort(int32_t *in, int32_t len, int16_t *out,
                            int32_t *state) {
    int32_t tmp0, tmp1, diff;
    int32_t i;

    len >>= 1;

// lower allpass filter (operates on even input samples)
    for (i = 0; i < len; i++) {
        tmp0 = in[i << 1];
        diff = tmp0 - state[1];
// UBSan: -1771017321 - 999586185 cannot be represented in type 'int'

// scale down and round
        diff = (diff + (1 << 13)) >> 14;
        tmp1 = state[0] + diff * kResampleAllpass[1][0];
        state[0] = tmp0;
        diff = tmp1 - state[2];
// scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        tmp0 = state[1] + diff * kResampleAllpass[1][1];
        state[1] = tmp1;
        diff = tmp0 - state[3];
// scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        state[3] = state[2] + diff * kResampleAllpass[1][2];
        state[2] = tmp0;

// divide by two and store temporarily
        in[i << 1] = (state[3] >> 1);
    }

    in++;

// upper allpass filter (operates on odd input samples)
    for (i = 0; i < len; i++) {
        tmp0 = in[i << 1];
        diff = tmp0 - state[5];
// scale down and round
        diff = (diff + (1 << 13)) >> 14;
        tmp1 = state[4] + diff * kResampleAllpass[0][0];
        state[4] = tmp0;
        diff = tmp1 - state[6];
// scale down and round
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        tmp0 = state[5] + diff * kResampleAllpass[0][1];
        state[5] = tmp1;
        diff = tmp0 - state[7];
// scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        state[7] = state[6] + diff * kResampleAllpass[0][2];
        state[6] = tmp0;

// divide by two and store temporarily
        in[i << 1] = (state[7] >> 1);
    }

    in--;

// combine allpass outputs
    for (i = 0; i < len; i += 2) {
// divide by two, add both allpass outputs and round
        tmp0 = (in[i << 1] + in[(i << 1) + 1]) >> 15;
        tmp1 = (in[(i << 1) + 2] + in[(i << 1) + 3]) >> 15;
        if (tmp0 > (int32_t) 0x00007FFF)
            tmp0 = 0x00007FFF;
        if (tmp0 < (int32_t) 0xFFFF8000)
            tmp0 = 0xFFFF8000;
        out[i] = (int16_t) tmp0;
        if (tmp1 > (int32_t) 0x00007FFF)
            tmp1 = 0x00007FFF;
        if (tmp1 < (int32_t) 0xFFFF8000)
            tmp1 = 0xFFFF8000;
        out[i + 1] = (int16_t) tmp1;
    }
}

//
//   decimator
// input:  int16_t
// output: int32_t (shifted 15 positions to the left, + offset 16384) (of length len/2)
// state:  filter state array; length = 8

void    // bugs.webrtc.org/5486
WebRtcSpl_DownBy2ShortToInt(const int16_t *in,
                            int32_t len,
                            int32_t *out,
                            int32_t *state) {
    int32_t tmp0, tmp1, diff;
    int32_t i;

    len >>= 1;

    // lower allpass filter (operates on even input samples)
    for (i = 0; i < len; i++) {
        tmp0 = ((int32_t) in[i << 1] << 15) + (1 << 14);
        diff = tmp0 - state[1];
        // scale down and round
        diff = (diff + (1 << 13)) >> 14;
        tmp1 = state[0] + diff * kResampleAllpass[1][0];
        state[0] = tmp0;
        diff = tmp1 - state[2];
        // UBSan: -1379909682 - 834099714 cannot be represented in type 'int'

        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        tmp0 = state[1] + diff * kResampleAllpass[1][1];
        state[1] = tmp1;
        diff = tmp0 - state[3];
        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        state[3] = state[2] + diff * kResampleAllpass[1][2];
        state[2] = tmp0;

        // divide by two and store temporarily
        out[i] = (state[3] >> 1);
    }

    in++;

    // upper allpass filter (operates on odd input samples)
    for (i = 0; i < len; i++) {
        tmp0 = ((int32_t) in[i << 1] << 15) + (1 << 14);
        diff = tmp0 - state[5];
        // scale down and round
        diff = (diff + (1 << 13)) >> 14;
        tmp1 = state[4] + diff * kResampleAllpass[0][0];
        state[4] = tmp0;
        diff = tmp1 - state[6];
        // scale down and round
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        tmp0 = state[5] + diff * kResampleAllpass[0][1];
        state[5] = tmp1;
        diff = tmp0 - state[7];
        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        state[7] = state[6] + diff * kResampleAllpass[0][2];
        state[6] = tmp0;

        // divide by two and store temporarily
        out[i] += (state[7] >> 1);
    }

    in--;
}

//   lowpass filter
// input:  int32_t (shifted 15 positions to the left, + offset 16384)
// output: int32_t (normalized, not saturated)
// state:  filter state array; length = 8
void  // bugs.webrtc.org/5486
WebRtcSpl_LPBy2IntToInt(const int32_t *in, int32_t len, int32_t *out,
                        int32_t *state) {
    int32_t tmp0, tmp1, diff;
    int32_t i;

    len >>= 1;

    // lower allpass filter: odd input -> even output samples
    in++;
    // initial state of polyphase delay element
    tmp0 = state[12];
    for (i = 0; i < len; i++) {
        diff = tmp0 - state[1];
        // scale down and round
        diff = (diff + (1 << 13)) >> 14;
        tmp1 = state[0] + diff * kResampleAllpass[1][0];
        state[0] = tmp0;
        diff = tmp1 - state[2];
        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        tmp0 = state[1] + diff * kResampleAllpass[1][1];
        state[1] = tmp1;
        diff = tmp0 - state[3];
        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        state[3] = state[2] + diff * kResampleAllpass[1][2];
        state[2] = tmp0;

        // scale down, round and store
        out[i << 1] = state[3] >> 1;
        tmp0 = in[i << 1];
    }
    in--;

    // upper allpass filter: even input -> even output samples
    for (i = 0; i < len; i++) {
        tmp0 = in[i << 1];
        diff = tmp0 - state[5];
        // UBSan: -794814117 - 1566149201 cannot be represented in type 'int'

        // scale down and round
        diff = (diff + (1 << 13)) >> 14;
        tmp1 = state[4] + diff * kResampleAllpass[0][0];
        state[4] = tmp0;
        diff = tmp1 - state[6];
        // scale down and round
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        tmp0 = state[5] + diff * kResampleAllpass[0][1];
        state[5] = tmp1;
        diff = tmp0 - state[7];
        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        state[7] = state[6] + diff * kResampleAllpass[0][2];
        state[6] = tmp0;

        // average the two allpass outputs, scale down and store
        out[i << 1] = (out[i << 1] + (state[7] >> 1)) >> 15;
    }

    // switch to odd output samples
    out++;

    // lower allpass filter: even input -> odd output samples
    for (i = 0; i < len; i++) {
        tmp0 = in[i << 1];
        diff = tmp0 - state[9];
        // scale down and round
        diff = (diff + (1 << 13)) >> 14;
        tmp1 = state[8] + diff * kResampleAllpass[1][0];
        state[8] = tmp0;
        diff = tmp1 - state[10];
        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        tmp0 = state[9] + diff * kResampleAllpass[1][1];
        state[9] = tmp1;
        diff = tmp0 - state[11];
        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        state[11] = state[10] + diff * kResampleAllpass[1][2];
        state[10] = tmp0;

        // scale down, round and store
        out[i << 1] = state[11] >> 1;
    }

    // upper allpass filter: odd input -> odd output samples
    in++;
    for (i = 0; i < len; i++) {
        tmp0 = in[i << 1];
        diff = tmp0 - state[13];
        // scale down and round
        diff = (diff + (1 << 13)) >> 14;
        tmp1 = state[12] + diff * kResampleAllpass[0][0];
        state[12] = tmp0;
        diff = tmp1 - state[14];
        // scale down and round
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        tmp0 = state[13] + diff * kResampleAllpass[0][1];
        state[13] = tmp1;
        diff = tmp0 - state[15];
        // scale down and truncate
        diff = diff >> 14;
        if (diff < 0)
            diff += 1;
        state[15] = state[14] + diff * kResampleAllpass[0][2];
        state[14] = tmp0;

        // average the two allpass outputs, scale down and store
        out[i << 1] = (out[i << 1] + (state[15] >> 1)) >> 15;
    }
}

// interpolation coefficients
static const int16_t kCoefficients48To32[2][8] = {
        {778, -2050, 1087,  23285, 12903, -3783, 441,   222},
        {222, 441,   -3783, 12903, 23285, 1087,  -2050, 778}
};


//   Resampling ratio: 2/3
// input:  int32_t (normalized, not saturated) :: size 3 * K
// output: int32_t (shifted 15 positions to the left, + offset 16384) :: size 2 * K
//      K: number of blocks

void WebRtcSpl_Resample48khzTo32khz(const int32_t *In, int32_t *Out, size_t K) {
    /////////////////////////////////////////////////////////////
    // Filter operation:
    //
    // Perform resampling (3 input samples -> 2 output samples);
    // process in sub blocks of size 3 samples.
    int32_t tmp;
    size_t m;

    for (m = 0; m < K; m++) {
        tmp = 1 << 14;
        tmp += kCoefficients48To32[0][0] * In[0];
        tmp += kCoefficients48To32[0][1] * In[1];
        tmp += kCoefficients48To32[0][2] * In[2];
        tmp += kCoefficients48To32[0][3] * In[3];
        tmp += kCoefficients48To32[0][4] * In[4];
        tmp += kCoefficients48To32[0][5] * In[5];
        tmp += kCoefficients48To32[0][6] * In[6];
        tmp += kCoefficients48To32[0][7] * In[7];
        Out[0] = tmp;

        tmp = 1 << 14;
        tmp += kCoefficients48To32[1][0] * In[1];
        tmp += kCoefficients48To32[1][1] * In[2];
        tmp += kCoefficients48To32[1][2] * In[3];
        tmp += kCoefficients48To32[1][3] * In[4];
        tmp += kCoefficients48To32[1][4] * In[5];
        tmp += kCoefficients48To32[1][5] * In[6];
        tmp += kCoefficients48To32[1][6] * In[7];
        tmp += kCoefficients48To32[1][7] * In[8];
        Out[1] = tmp;

        // update pointers
        In += 3;
        Out += 2;
    }
}


#ifdef WEBRTC_ARCH_ARM_V7

// allpass filter coefficients.
static const uint32_t kResampleAllpass1[3] = {3284, 24441, 49528 << 15};
static const uint32_t kResampleAllpass2[3] =
  {12199, 37471 << 15, 60255 << 15};

// Multiply two 32-bit values and accumulate to another input value.
// Return: state + ((diff * tbl_value) >> 16)

static __inline int32_t MUL_ACCUM_1(int32_t tbl_value,
                                    int32_t diff,
                                    int32_t state) {
  int32_t result;
  __asm __volatile ("smlawb %0, %1, %2, %3": "=r"(result): "r"(diff),
                                   "r"(tbl_value), "r"(state));
  return result;
}

// Multiply two 32-bit values and accumulate to another input value.
// Return: Return: state + (((diff << 1) * tbl_value) >> 32)
//
// The reason to introduce this function is that, in case we can't use smlawb
// instruction (in MUL_ACCUM_1) due to input value range, we can still use
// smmla to save some cycles.

static __inline int32_t MUL_ACCUM_2(int32_t tbl_value,
                                    int32_t diff,
                                    int32_t state) {
  int32_t result;
  __asm __volatile ("smmla %0, %1, %2, %3": "=r"(result): "r"(diff << 1),
                                  "r"(tbl_value), "r"(state));
  return result;
}

#else

// Multiply a 32-bit value with a 16-bit value and accumulate to another input:
#define MUL_ACCUM_1(a, b, c) WEBRTC_SPL_SCALEDIFF32(a, b, c)
#define MUL_ACCUM_2(a, b, c) WEBRTC_SPL_SCALEDIFF32(a, b, c)

#endif  // WEBRTC_ARCH_ARM_V7


////////////////////////////
///// 48 kHz ->  8 kHz /////
////////////////////////////

// 48 -> 8 resampler
void WebRtcSpl_Resample48khzTo8khz(const int16_t *in, int16_t *out,
                                   WebRtcSpl_State48khzTo8khz *state, int32_t *tmpmem) {
    ///// 48 --> 24 /////
    // int16_t  in[480]
    // int32_t out[240]
    /////
    WebRtcSpl_DownBy2ShortToInt(in, 480, tmpmem + 256, state->S_48_24);

    ///// 24 --> 24(LP) /////
    // int32_t  in[240]
    // int32_t out[240]
    /////
    WebRtcSpl_LPBy2IntToInt(tmpmem + 256, 240, tmpmem + 16, state->S_24_24);

    ///// 24 --> 16 /////
    // int32_t  in[240]
    // int32_t out[160]
    /////
    // copy state to and from input array
    memcpy(tmpmem + 8, state->S_24_16, 8 * sizeof(int32_t));
    memcpy(state->S_24_16, tmpmem + 248, 8 * sizeof(int32_t));
    WebRtcSpl_Resample48khzTo32khz(tmpmem + 8, tmpmem, 80);

    ///// 16 --> 8 /////
    // int32_t  in[160]
    // int16_t out[80]
    /////
    WebRtcSpl_DownBy2IntToShort(tmpmem, 160, out, state->S_16_8);
}

// initialize state of 48 -> 8 resampler
void WebRtcSpl_ResetResample48khzTo8khz(WebRtcSpl_State48khzTo8khz *state) {
    memset(state->S_48_24, 0, 8 * sizeof(int32_t));
    memset(state->S_24_24, 0, 16 * sizeof(int32_t));
    memset(state->S_24_16, 0, 8 * sizeof(int32_t));
    memset(state->S_16_8, 0, 8 * sizeof(int32_t));
}

////////////////////////////
/////  8 kHz -> 48 kHz /////
////////////////////////////

int16_t WebRtcSpl_GetScalingSquare(int16_t *in_vector,
                                   size_t in_vector_length,
                                   size_t times) {
    int16_t nbits = WebRtcSpl_GetSizeInBits((uint32_t) times);
    size_t i;
    int16_t smax = -1;
    int16_t sabs;
    int16_t *sptr = in_vector;
    int16_t t;
    size_t looptimes = in_vector_length;

    for (i = looptimes; i > 0; i--) {
        sabs = (*sptr > 0 ? *sptr++ : -*sptr++);
        smax = (sabs > smax ? sabs : smax);
    }
    t = WebRtcSpl_NormW32(WEBRTC_SPL_MUL(smax, smax));

    if (smax == 0) {
        return 0; // Since norm(0) returns 0
    } else {
        return (t > nbits) ? 0 : nbits - t;
    }
}

int32_t WebRtcSpl_Energy(int16_t *vector,
                         size_t vector_length,
                         int *scale_factor) {
    int32_t en = 0;
    size_t i;
    int scaling =
            WebRtcSpl_GetScalingSquare(vector, vector_length, vector_length);
    size_t looptimes = vector_length;
    int16_t *vectorptr = vector;

    for (i = 0; i < looptimes; i++) {
        en += (*vectorptr * *vectorptr) >> scaling;
        vectorptr++;
    }
    *scale_factor = scaling;

    return en;
}
