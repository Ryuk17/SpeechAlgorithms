/*
 *  Copyright (c) 2012 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

/*
 * This header file includes all of the fix point signal processing library
 * (SPL) function descriptions and declarations. For specific function calls,
 * see bottom of file.
 */

#ifndef COMMON_AUDIO_SIGNAL_PROCESSING_INCLUDE_SIGNAL_PROCESSING_LIBRARY_H_
#define COMMON_AUDIO_SIGNAL_PROCESSING_INCLUDE_SIGNAL_PROCESSING_LIBRARY_H_

#include <string.h>
#include <stdint.h>

#include <stdlib.h>

#include <assert.h>
// If you for some reson need to know if DCHECKs are on, test the value of
// RTC_DCHECK_IS_ON. (Test its value, not if it's defined; it'll always be
// defined, to either a true or a false value.)
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
#define RTC_DCHECK_IS_ON 1
#else
#define RTC_DCHECK_IS_ON 0
#endif


#define RTC_DCHECK(condition)                                                 \
  do {                                                                        \
    if (RTC_DCHECK_IS_ON) {                                   \
      assert(condition); \
    }                                                                         \
  } while (0)

#define RTC_DCHECK_EQ(a, b) RTC_DCHECK((a) == (b))
#define RTC_DCHECK_NE(a, b) RTC_DCHECK((a) != (b))
#define RTC_DCHECK_LE(a, b) RTC_DCHECK((a) <= (b))
#define RTC_DCHECK_LT(a, b) RTC_DCHECK((a) < (b))
#define RTC_DCHECK_GE(a, b) RTC_DCHECK((a) >= (b))
#define RTC_DCHECK_GT(a, b) RTC_DCHECK((a) > (b))

// Processor architecture detection.  For more info on what's defined, see:
//   http://msdn.microsoft.com/en-us/library/b0084kay.aspx
//   http://www.agner.org/optimize/calling_conventions.pdf
//   or with gcc, run: "echo | gcc -E -dM -"
#if defined(_M_X64) || defined(__x86_64__)
#define WEBRTC_ARCH_X86_FAMILY
#define WEBRTC_ARCH_X86_64
#define WEBRTC_ARCH_64_BITS
#define WEBRTC_ARCH_LITTLE_ENDIAN
#elif defined(_M_ARM64) || defined(__aarch64__)
#define WEBRTC_ARCH_ARM_FAMILY
#define WEBRTC_ARCH_64_BITS
#define WEBRTC_ARCH_LITTLE_ENDIAN
#elif defined(_M_IX86) || defined(__i386__)
#define WEBRTC_ARCH_X86_FAMILY
#define WEBRTC_ARCH_X86
#define WEBRTC_ARCH_32_BITS
#define WEBRTC_ARCH_LITTLE_ENDIAN
#elif defined(__ARMEL__)
#define WEBRTC_ARCH_ARM_FAMILY
#define WEBRTC_ARCH_32_BITS
#define WEBRTC_ARCH_LITTLE_ENDIAN
#elif defined(__MIPSEL__)
#define WEBRTC_ARCH_MIPS_FAMILY
#if defined(__LP64__)
#define WEBRTC_ARCH_64_BITS
#else
#define WEBRTC_ARCH_32_BITS
#endif
#define WEBRTC_ARCH_LITTLE_ENDIAN
#elif defined(__pnacl__)
#define WEBRTC_ARCH_32_BITS
#define WEBRTC_ARCH_LITTLE_ENDIAN
#elif defined(__EMSCRIPTEN__)
#define WEBRTC_ARCH_32_BITS
#define WEBRTC_ARCH_LITTLE_ENDIAN
#else
#error Please add support for your architecture in rtc_base/system/arch.h
#endif

// Macros specific for the fixed point implementation
#define WEBRTC_SPL_WORD16_MAX 32767
#define WEBRTC_SPL_WORD16_MIN -32768
#define WEBRTC_SPL_WORD32_MAX (int32_t)0x7fffffff
#define WEBRTC_SPL_WORD32_MIN (int32_t)0x80000000
#define WEBRTC_SPL_MIN(A, B) (A < B ? A : B)  // Get min value
// TODO(kma/bjorn): For the next two macros, investigate how to correct the code
// for inputs of a = WEBRTC_SPL_WORD16_MIN or WEBRTC_SPL_WORD32_MIN.

#define WEBRTC_SPL_MUL(a, b) ((int32_t)((int32_t)(a) * (int32_t)(b)))
#define WEBRTC_SPL_MUL_16_U16(a, b) ((int32_t)(int16_t)(a) * (uint16_t)(b))

// clang-format off
// clang-format would choose some identation
// leading to presubmit error (cpplint.py)
#ifndef WEBRTC_ARCH_ARM_V7
// For ARMv7 platforms, these are inline functions in spl_inl_armv7.h
#ifndef MIPS32_LE
// For MIPS platforms, these are inline functions in spl_inl_mips.h
#define WEBRTC_SPL_MUL_16_16(a, b) ((int32_t)(((int16_t)(a)) * ((int16_t)(b))))
#endif
#endif

// clang-format on

// C + the 32 most significant bits of A * B
#define WEBRTC_SPL_SCALEDIFF32(A, B, C) \
  (C + (B >> 16) * A + (((uint32_t)(B & 0x0000FFFF) * A) >> 16))

// Shifting with negative numbers allowed
// Positive means left shift

// Shifting with negative numbers not allowed
// We cannot do casting here due to signed/unsigned problem

#ifdef __cplusplus
extern "C" {
#endif

// inline functions:
#include "spl_inl.h"


int16_t WebRtcSpl_GetScalingSquare(int16_t *in_vector,
                                   size_t in_vector_length,
                                   size_t times);


// Minimum and maximum operation functions and their pointers.
// Implementation in min_max_operations.c.

// Returns the largest absolute value in a signed 16-bit vector.
//
// Input:
//      - vector : 16-bit input vector.
//      - length : Number of samples in vector.
//
// Return value  : Maximum absolute value in vector.
typedef int16_t (*MaxAbsValueW16)(const int16_t *vector, size_t length);

extern const MaxAbsValueW16 WebRtcSpl_MaxAbsValueW16;

int16_t WebRtcSpl_MaxAbsValueW16C(const int16_t *vector, size_t length);

#if defined(WEBRTC_HAS_NEON)
int16_t WebRtcSpl_MaxAbsValueW16Neon(const int16_t* vector, size_t length);
#endif
#if defined(MIPS32_LE)
int16_t WebRtcSpl_MaxAbsValueW16_mips(const int16_t* vector, size_t length);
#endif

// Returns the largest absolute value in a signed 32-bit vector.
//
// Input:
//      - vector : 32-bit input vector.
//      - length : Number of samples in vector.
//
// Return value  : Maximum absolute value in vector.
typedef int32_t (*MaxAbsValueW32)(const int32_t *vector, size_t length);

extern const MaxAbsValueW32 WebRtcSpl_MaxAbsValueW32;

int32_t WebRtcSpl_MaxAbsValueW32C(const int32_t *vector, size_t length);

#if defined(WEBRTC_HAS_NEON)
int32_t WebRtcSpl_MaxAbsValueW32Neon(const int32_t* vector, size_t length);
#endif
#if defined(MIPS_DSP_R1_LE)
int32_t WebRtcSpl_MaxAbsValueW32_mips(const int32_t* vector, size_t length);
#endif

// Returns the maximum value of a 16-bit vector.
//
// Input:
//      - vector : 16-bit input vector.
//      - length : Number of samples in vector.
//
// Return value  : Maximum sample value in |vector|.
typedef int16_t (*MaxValueW16)(const int16_t *vector, size_t length);

extern const MaxValueW16 WebRtcSpl_MaxValueW16;

int16_t WebRtcSpl_MaxValueW16C(const int16_t *vector, size_t length);

#if defined(WEBRTC_HAS_NEON)
int16_t WebRtcSpl_MaxValueW16Neon(const int16_t* vector, size_t length);
#endif
#if defined(MIPS32_LE)
int16_t WebRtcSpl_MaxValueW16_mips(const int16_t* vector, size_t length);
#endif

// Returns the maximum value of a 32-bit vector.
//
// Input:
//      - vector : 32-bit input vector.
//      - length : Number of samples in vector.
//
// Return value  : Maximum sample value in |vector|.
typedef int32_t (*MaxValueW32)(const int32_t *vector, size_t length);

extern const MaxValueW32 WebRtcSpl_MaxValueW32;

int32_t WebRtcSpl_MaxValueW32C(const int32_t *vector, size_t length);

#if defined(WEBRTC_HAS_NEON)
int32_t WebRtcSpl_MaxValueW32Neon(const int32_t* vector, size_t length);
#endif
#if defined(MIPS32_LE)
int32_t WebRtcSpl_MaxValueW32_mips(const int32_t* vector, size_t length);
#endif

// Returns the minimum value of a 16-bit vector.
//
// Input:
//      - vector : 16-bit input vector.
//      - length : Number of samples in vector.
//
// Return value  : Minimum sample value in |vector|.
typedef int16_t (*MinValueW16)(const int16_t *vector, size_t length);

extern const MinValueW16 WebRtcSpl_MinValueW16;

int16_t WebRtcSpl_MinValueW16C(const int16_t *vector, size_t length);

#if defined(WEBRTC_HAS_NEON)
int16_t WebRtcSpl_MinValueW16Neon(const int16_t* vector, size_t length);
#endif
#if defined(MIPS32_LE)
int16_t WebRtcSpl_MinValueW16_mips(const int16_t* vector, size_t length);
#endif

// Returns the minimum value of a 32-bit vector.
//
// Input:
//      - vector : 32-bit input vector.
//      - length : Number of samples in vector.
//
// Return value  : Minimum sample value in |vector|.
typedef int32_t (*MinValueW32)(const int32_t *vector, size_t length);

extern const MinValueW32 WebRtcSpl_MinValueW32;

int32_t WebRtcSpl_MinValueW32C(const int32_t *vector, size_t length);

#if defined(WEBRTC_HAS_NEON)
int32_t WebRtcSpl_MinValueW32Neon(const int32_t* vector, size_t length);
#endif
#if defined(MIPS32_LE)
int32_t WebRtcSpl_MinValueW32_mips(const int32_t* vector, size_t length);
#endif

// Divisions. Implementations collected in division_operations.c and
// descriptions at bottom of this file.
int32_t WebRtcSpl_DivW32W16(int32_t num, int16_t den);
// End: Divisions.

int32_t WebRtcSpl_Energy(int16_t *vector,
                         size_t vector_length,
                         int *scale_factor);


void WebRtcSpl_Resample48khzTo32khz(const int32_t *In, int32_t *Out, size_t K);

typedef struct {
    int32_t S_48_24[8];
    int32_t S_24_24[16];
    int32_t S_24_16[8];
    int32_t S_16_8[8];
} WebRtcSpl_State48khzTo8khz;

void WebRtcSpl_Resample48khzTo8khz(const int16_t *in,
                                   int16_t *out,
                                   WebRtcSpl_State48khzTo8khz *state,
                                   int32_t *tmpmem);

void WebRtcSpl_ResetResample48khzTo8khz(WebRtcSpl_State48khzTo8khz *state);

#ifdef __cplusplus
}
#endif  // __cplusplus
#endif  // COMMON_AUDIO_SIGNAL_PROCESSING_INCLUDE_SIGNAL_PROCESSING_LIBRARY_H_