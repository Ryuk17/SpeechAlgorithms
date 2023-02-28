/*
 ============================================================================
 Name        : g711_codec.c
 Author      : Ryuk
 Version     :
 Copyright   : Your copyright notice
 Description : Hello World in C, Ansi-style
 ============================================================================
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "g711_table.h"


typedef enum {
	A_LAW_TO_PCM = 0,
	MU_LAW_TO_PCM,
	PCM_TO_A_LAW,
	PCM_TO_MU_LAW,
}encode_mode;

long get_file_size(FILE *f)
{
    long file_size;

    /* Go to end of file */
    fseek(f, 0L, SEEK_END);

    /* Get the number of bytes */
    file_size = ftell(f);

    /* reset the file position indicator to
    the beginning of the file */
    fseek(f, 0L, SEEK_SET);

    return file_size;
}

char * allocate_buffer(long buffer_size)
{
    char *buffer;

    /* grab sufficient memory for the
    buffer to hold the audio */
    buffer = (char*)calloc(buffer_size, sizeof(char));
    /* memory error */
    if(buffer == NULL)
    {
        perror("Error while allocating memory for write buffer.\n");
        exit(EXIT_FAILURE);
    }

    return buffer;
}

int main(int argc, char *argv[])
{
    FILE    *fRead, *fWrite;
    char    *bufferRead, *bufferWrite;
    long    bufferReadSize, bufferWriteSize;
    size_t  readed;

    encode_mode mode = A_LAW_TO_PCM;

    fRead = fopen("sample/g711-encoded.pcm", "rb");
    if( fRead == NULL )
    {
       perror("Error while opening read file.\n");
       exit(EXIT_FAILURE);
    }
    printf("Open sample/g711-encoded.pcm\n");


    bufferReadSize = get_file_size(fRead);
    bufferRead = allocate_buffer(bufferReadSize);

    readed = fread(bufferRead, sizeof(char), bufferReadSize, fRead);
    if (readed != bufferReadSize)
    {
        perror("Incorrect bytes readed\n");
        exit(EXIT_FAILURE);
    }
    fclose(fRead);

    if (mode == A_LAW_TO_PCM)
    {
        alaw_pcm16_tableinit();
        bufferWriteSize = bufferReadSize * 2;
        bufferWrite = allocate_buffer(bufferWriteSize);
        alaw_to_pcm16(bufferReadSize, bufferRead, bufferWrite);
    }
    else if (mode == MU_LAW_TO_PCM)
    {
        ulaw_pcm16_tableinit();
        bufferWriteSize = bufferReadSize * 2;
        bufferWrite = allocate_buffer(bufferWriteSize);
        ulaw_to_pcm16(bufferReadSize, bufferRead, bufferWrite);
    }
    else if (mode == PCM_TO_A_LAW)
    {
        pcm16_alaw_tableinit();
        bufferWriteSize = bufferReadSize / 2;
        bufferWrite = allocate_buffer(bufferWriteSize);
        pcm16_to_alaw(bufferReadSize, bufferRead, bufferWrite);
    }
    else if (mode == PCM_TO_MU_LAW)
    {
        pcm16_ulaw_tableinit();
        bufferWriteSize = bufferReadSize / 2;
        bufferWrite = allocate_buffer(bufferWriteSize);
        pcm16_to_ulaw(bufferReadSize, bufferRead, bufferWrite);
    }
    else
    {
        perror("Incorrect Mode.\n");
        exit(EXIT_FAILURE);
    }

    fWrite = fopen("sample/g711-decoded.pcm", "wb");
    if( fWrite == NULL )
    {
       perror("Error while opening the write file.\n");
       exit(EXIT_FAILURE);
    }
    printf("Write sample/g711-decoded.pcm\n");

    fwrite (bufferWrite , sizeof(char), bufferWriteSize, fWrite);
    fclose (fWrite);

    free(bufferWrite);
    free(bufferRead);

    return 0;
}
