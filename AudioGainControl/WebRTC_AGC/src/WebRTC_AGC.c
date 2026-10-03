/*
 ============================================================================
 Name        : WebRTC_AGC.c
 Author      : Ryuk
 Version     : 0.1.0
 Copyright   : Your copyright notice
 Description : Hello World in C, Ansi-style
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>

#include "agc.h"

#define FRAME_LENGTH 160

int main(int argc, char *argv[]) {

	struct timeval start, end;
    static float runtime = 0.0;
    static float avg = 0.0;

	char inFileName[128];
	char outFileName[128];

	int16_t *input = (int16_t *)calloc(FRAME_LENGTH, sizeof(int16_t));
	int16_t *output = (int16_t *)calloc(FRAME_LENGTH, sizeof(int16_t));

	FILE *in;
	FILE *out;

	sprintf(inFileName, "%s", "../sample/agc_test.wav");
	sprintf(outFileName, "%s", "../sample/agc_test_out.wav");

	in = fopen(inFileName, "rb");
	if(in == NULL)
	{
		perror(inFileName);
	}
	printf("Open %s\n", inFileName);

	out = fopen(outFileName, "w");
	if(out == NULL)
	{
		perror(outFileName);
	}
	printf("Open %s\n", outFileName);

	fread(input, sizeof(char), 44, in);
	fwrite(input, sizeof(char), 44, out);

	int ret;
	int counter = 0;
	int sample_rate = 16000;

	//===================Set AGC Parameters=======================
	void *agc_handle = WebRtcAgc_Create();
    if (agc_handle == NULL)
    {
    	printf("AGC create fail\n");
    	return -1;
    }
    printf("AGC create success\n");
    int min_level = 0;
    int max_level = 255;
	int agc_mode = kAgcModeAdaptiveDigital;

    ret = WebRtcAgc_Init(agc_handle, min_level, max_level, agc_mode, sample_rate);
	if(ret != 0)
	{
		printf("AGC init fail\n");
		return -1;
	}
	printf("AGC init success\n");

    WebRtcAgcConfig agc_config;
    agc_config.compressionGaindB = 9; 	// default 9 dB
    agc_config.limiterEnable = 1; 		// default kAgcTrue (on)
    agc_config.targetLevelDbfs = 3; 	// default 3 (-3 dBOv)
	ret = WebRtcAgc_set_config(agc_handle, agc_config);
	if(ret != 0)
	{
		printf("AGC set fail\n");
		return -1;
	}
	printf("AGC set success\n");

    size_t num_bands = 1;
    int inMicLevel = 0, outMicLevel = 0;
    uint8_t saturationWarning = 1;
    int16_t echo = 0;
	//===================Set AGC Parameters=======================


	while(fread(input, sizeof(short), FRAME_LENGTH, in))
	{
		counter++;
		gettimeofday(&start, NULL);
		ret =  WebRtcAgc_Process(agc_handle, &input, num_bands, FRAME_LENGTH,
                &output, inMicLevel, &outMicLevel, echo, &saturationWarning);
		gettimeofday(&end, NULL);
		runtime += 1000000 * (end.tv_sec - start.tv_sec) + end.tv_usec - start.tv_usec;

		if(counter % 100 == 0)
		{
			avg = runtime / counter;
			printf("Avg runtime: %.4f ms\n", avg/1000);
		}

		fwrite(output, sizeof(short), FRAME_LENGTH, out);
	}

	WebRtcAgc_Free(agc_handle);
	free(input);
	free(output);
	fclose(in);
	fclose(out);
	printf("AGC DONE!\n");
    return 0;
}
