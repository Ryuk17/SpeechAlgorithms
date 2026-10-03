//============================================================================
// Name        : WebRTC_AEC.cpp
// Author      : Ryuk
// Version     : 0.1.0
// Copyright   : Your copyright notice
// Description : Hello World in C++, Ansi-style
//============================================================================

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "echo_cancellation.h"

#define  NN 160

int main()
{
    short far_frame[NN], near_frame[NN], out_frame[NN];
    void *aecmInst = NULL;
    FILE *fp_far  = fopen("../sample/far.wav", "rb");
    FILE *fp_near = fopen("../sample/near.wav", "rb");
    FILE *fp_out  = fopen("../sample/webrtc_aec_out.wav", "wb");
    AecConfig config;

    if (!fp_far) {
        printf("../sample/far.wav error\n");
        return -1;
    }
    if (!fp_near) {
        fclose(fp_far);
        printf("../sample/near.wav error\n");
        return -1;
    }

    WebRtcAec_Create(&aecmInst);
    WebRtcAec_Init(aecmInst, 16000, 16000);
    config.nlpMode = kAecNlpAggressive;
    WebRtcAec_set_config(aecmInst, config);

    printf("Start\n");
    while(true)
    {
        if (NN == fread(far_frame, sizeof(short), NN, fp_far))
        {
            fread(near_frame, sizeof(short), NN, fp_near);
            WebRtcAec_BufferFarend(aecmInst, far_frame, NN);
            WebRtcAec_Process(aecmInst, near_frame, NULL, out_frame, NULL, NN, 40, 0);
            fwrite(out_frame, sizeof(short), NN, fp_out);
        } else
        {
            break;
        }
    }

    fclose(fp_far);
    fclose(fp_near);
    fclose(fp_out);
    WebRtcAec_Free(aecmInst);
    printf("WebRTC AEC Finished\n");
	return 0;
}
