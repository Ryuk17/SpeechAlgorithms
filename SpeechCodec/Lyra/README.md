
This repo is based on [Lyra](https://github.com/google/lyra)  


You can run `encoder_main` to encode a test .wav file with some speech in it,
specified by `--input_path`.  The `--model_path` flag contains the model data
necessary to encode, and `--output_path` specifies where to write the encoded
(compressed) representation.

```shell
.bin/encoder_main --model_path=wavegru --output_dir=sample/ --input_path=sample/16khz_sample_000001.wav
```

Similarly, you can build decoder_main and use it on the output of encoder_main
to decode the encoded data back into speech.

```shell
bin/decoder_main  --model_path=wavegru --output_dir=sample/ --encoded_path=sample/16khz_sample_000001.lyra
```
