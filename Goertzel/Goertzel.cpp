/** Author:       Plyashkevich Viatcheslav <plyashkevich@yandex.ru> 
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License 
 * All rights reserved. 
 */


#include <stdio.h>
#include "DtmfDetector.hpp"
#include "DtmfGenerator.hpp"

#define FRAME_SIZE (160)


int main()
{ 
	char dialButtons[16] = {'1', '2', '3', '4'};
	short int samples[FRAME_SIZE];
	char FileName[128];
	FILE *fin, *fout;
	int length = 4;

	sprintf(FileName, "%s", "1234.pcm");
	fout = fopen(FileName, "wb");

	DtmfDetector dtmfDetector(FRAME_SIZE);
	DtmfGenerator dtmfGenerator(FRAME_SIZE, 400, 200);

	dtmfGenerator.dtmfGeneratorReset();
	dtmfDetector.zerosIndexDialButton();
	dtmfGenerator.transmitNewDialButtonsArray(dialButtons, length);


	while(!dtmfGenerator.getReadyFlag())
	{
		dtmfGenerator.dtmfGenerating(samples);
		fwrite(samples, sizeof(short), FRAME_SIZE, fout);
	}
	fclose(fout);
	printf("DTMF Encoding... %s\n", dialButtons);

	fin = fopen(FileName, "rb");
	while(fread(samples, sizeof(short), FRAME_SIZE, fin))
	{
		dtmfDetector.dtmfDetecting(samples);
	}
	fclose(fin);
	printf("DTMF Decoding result is %s\n", dtmfDetector.getDialButtonsArray());

	printf("Done\n");
  return 0;
}
