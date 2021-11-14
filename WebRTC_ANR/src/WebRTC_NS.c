#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>

#include "noise_suppression.h"

#define FRAME_LENGTH 160


enum nsLevel {
    kLow,
    kModerate,
    kHigh,
    kVeryHigh
};


int main(int argc, char *argv[]) {
    struct timeval start, end;
	static float runtime = 0.0;
	static float avg = 0.0;
	int ret = 0;
	int counter = 0;

	char inFileName[128];
	char outFileName[128];

	int16_t *input = (int16_t *)calloc(FRAME_LENGTH, sizeof(int16_t));
	int16_t *output = (int16_t *)calloc(FRAME_LENGTH, sizeof(int16_t));

	FILE *in;
	FILE *out;

	sprintf(inFileName, "%s", "../sample/noisy.wav");
	sprintf(outFileName, "%s", "../sample/processed.wav");

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


	//===================Set ANR Parameters=======================

	int sample_rate = 16000;
	int channels = 1;
	int num_bands = 1;
	enum nsLevel mode = kModerate;

    NsHandle *anr_handle = (NsHandle *) malloc(channels * sizeof(NsHandle *));
    anr_handle = WebRtcNs_Create();
    ret = WebRtcNs_Init(anr_handle, sample_rate);
    if(ret != 0)
    {
    	printf("ANR init fail\n");
    	return -1;
    }

    ret = WebRtcNs_set_policy(anr_handle, mode);
    if(ret != 0)
    {
    	printf("ANR set fail\n");
    	return -1;
    }

	//===================Set ANR Parameters=======================

	while(fread(input, sizeof(short), FRAME_LENGTH, in))
	{
		counter++;
		gettimeofday(&start, NULL);
		WebRtcNs_Analyze(anr_handle, input);
		WebRtcNs_Process(anr_handle, (const int16_t *const *) &input, num_bands, &output);
		gettimeofday(&end, NULL);
		runtime += 1000000 * (end.tv_sec - start.tv_sec) + end.tv_usec - start.tv_usec;

		if(counter % 100 == 0)
		{
			avg = runtime / counter;
			printf("Avg runtime: %.4f ms\n", avg/1000);
		}

		fwrite(output, sizeof(short), FRAME_LENGTH, out);
	}

    WebRtcNs_Free(anr_handle);
	free(input);
	free(output);
	fclose(in);
	fclose(out);
	printf("ANR DONE!\n");
    return 0;
}
