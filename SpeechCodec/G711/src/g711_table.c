#ifndef G711_TABLE_H
#define G711_TABLE_H

#include "g711.h"

/* 16384 entries per table (16 bit) */
unsigned char linear_to_alaw[65536];
unsigned char linear_to_ulaw[65536];

/* 16384 entries per table (8 bit) */
unsigned short alaw_to_linear[256];
unsigned short ulaw_to_linear[256];

static void build_linear_to_xlaw_table(unsigned char *linear_to_xlaw,
                                       unsigned char (*linear2xlaw)(short))
{
    int i;

    for (i=0; i<65536;i++){
        linear_to_xlaw[i] = linear2xlaw((short) i);
    }
}

static void build_xlaw_to_linear_table(unsigned short *xlaw_to_linear,
                                       short (*xlaw2linear)(unsigned char))
{
    int i;

    for (i=0; i<256;i++){
        xlaw_to_linear[i] = (unsigned short) xlaw2linear(i);
    }
}

static void pcm16_to_xlaw(unsigned char *linear_to_xlaw, int src_length, const char *src_samples, char *dst_samples)
{
    int i;
    const unsigned short *s_samples;

    s_samples = (const unsigned short *)src_samples;

    for (i=0; i < src_length / 2; i++)
    {
        dst_samples[i] = linear_to_xlaw[s_samples[i]];
    }
}

static void xlaw_to_pcm16(unsigned short *xlaw_to_linear, int src_length, const char *src_samples, char *dst_samples)
{
    int i;
    unsigned char *s_samples;
    unsigned short *d_samples;

    s_samples = (unsigned char *) src_samples;
    d_samples = (unsigned short *)dst_samples;

    for (i=0; i < src_length; i++)
    {
        d_samples[i] = xlaw_to_linear[s_samples[i]];
    }
}

void pcm16_to_alaw(int src_length, const char *src_samples, char *dst_samples)
{
    pcm16_to_xlaw(linear_to_alaw, src_length, src_samples, dst_samples);
}

void pcm16_to_ulaw(int src_length, const char *src_samples, char *dst_samples)
{
    pcm16_to_xlaw(linear_to_ulaw, src_length, src_samples, dst_samples);
}

void alaw_to_pcm16(int src_length, const char *src_samples, char *dst_samples)
{
    xlaw_to_pcm16(alaw_to_linear, src_length, src_samples, dst_samples);
}

void ulaw_to_pcm16(int src_length, const char *src_samples, char *dst_samples)
{
    xlaw_to_pcm16(ulaw_to_linear, src_length, src_samples, dst_samples);
}

void pcm16_alaw_tableinit()
{
    build_linear_to_xlaw_table(linear_to_alaw, linear2alaw);
}

void pcm16_ulaw_tableinit()
{
    build_linear_to_xlaw_table(linear_to_ulaw, linear2ulaw);
}

void alaw_pcm16_tableinit()
{
    build_xlaw_to_linear_table(alaw_to_linear, alaw2linear);
}

void ulaw_pcm16_tableinit()
{
    build_xlaw_to_linear_table(ulaw_to_linear, ulaw2linear);
}

#endif // G711_TABLE_H
