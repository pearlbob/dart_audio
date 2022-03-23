/*
 *  This extra small demo sends a random samples to your speakers.
 *
 *
 * linux:
aplay -f S16_LE -Dplughw:CARD=USB,DEV=0 alan.wav

pi:
aplay -f S16_LE -Ddefault:CARD=Headphones j.wav
 */

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:dart_alsa/alsa_generated_bindings.dart' as a;

final device = 'plughw:CARD=USB,DEV=0'.toNativeUtf8().cast<Int8>(); /* playback device */
List<Uint8> buffer = List<Uint8>.filled(16 * 1024, 0 as Uint8);

const channels = 2;

final alsa = a.ALSA(DynamicLibrary.open('libasound.so.2'));

void main(List<String> args) {
  var err = 0;
  final pcmHandlePtr = calloc<Pointer<a.snd_pcm_>>();

  final framesPtr = calloc<Uint64>();

  if ((err = alsa.snd_pcm_open(pcmHandlePtr, device, a.snd_pcm_stream_t.SND_PCM_STREAM_PLAYBACK, 0)) < 0) {
    final errMesg = alsa.snd_strerror(err).cast<Utf8>().toDartString();
    print(
      'Playback open error: $errMesg',
    );
    exit(a.EXIT_FAILURE);
  }
  if ((err = alsa.snd_pcm_set_params(pcmHandlePtr.value, a.snd_pcm_format_t.SND_PCM_FORMAT_U8,
          a.snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED, 1, 48000, 1, 500000)) <
      0) {
    /* 0.5sec */
    print(
      "Playback open error: ${alsa.snd_strerror(err)}\n",
    );
    exit(a.EXIT_FAILURE);
  }

  final bufferSize = framesPtr.value * channels * 2 /* 2 -> sample size */;
  final bufferPtr = calloc<Uint8>(bufferSize);
  for (var i = 0; i < bufferSize; i++) {
    bufferPtr[i] = (0x80 & 0xff);
  }
  for (var i = 0; i < 16; i++) {
    var pcm = alsa.snd_pcm_writei(pcmHandlePtr.value, bufferPtr.cast<Void>(), framesPtr.value);
    if (pcm < 0) {
      pcm = alsa.snd_pcm_recover(pcmHandlePtr.value, pcm, 0);
    }
    if (pcm < 0) {
      print("snd_pcm_writei failed: ${alsa.snd_strerror(pcm)}\n");
      break;
    }
    if (pcm > 0 && pcm < bufferSize) {
      print("Short write (expected $bufferSize, wrote $pcm)\n");
    }
  }

/* pass the remaining samples, otherwise they're dropped in close */
  err = alsa.snd_pcm_drain(pcmHandlePtr.value);
  if (err < 0) {
    print(
      'snd_pcm_drain failed: ${alsa.snd_strerror(err)}\n',
    );
  }
  alsa.snd_pcm_close(pcmHandlePtr.value);

  calloc.free(bufferPtr);
  calloc.free(pcmHandlePtr);

  exit(0);
}
