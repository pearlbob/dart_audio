import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:libao/libao.dart';

void main() {
  // print(Platform.operatingSystem);
  // print('processors: ${Platform.numberOfProcessors}');
  // // print('environment: ${Platform.environment}');
  // print('localHostname: ${Platform.localHostname}');
  // print('version: ${Platform.version}');

  //  required:    sudo apt-get install libao-dev
  final ao = Platform.version.contains('_x64') ? Libao.open() : Libao.open('/usr/lib/aarch64-linux-gnu/libao.so.4');

  ao.initialize();

  for (var info in ao.driverInfoList()) {
    print('$info');
  }
  print('\n');

  final driverId = ao.driverId('pulse'); //ao.defaultDriverId();
  //print('driverId: $driverId\n');

  print(ao.driverInfo(driverId).name);

  const bits = 16;
  const channels = 2;
  const rate = 48000;

  final device = ao.openLive(driverId,
      bits: bits,
      channels: channels,
      rate: rate,
      // byteFormat: ByteFormat.native,
      matrix: 'L,R');

  const volume = 0.15;
  const freq = 110.0;

  // Number of bytes * Channels * Sample rate.
  const seconds = 5;
  const bufferSize = bits ~/ 8 * channels * rate * seconds;
  final buffer = Uint8List(bufferSize);

  for (var i = 0; i < rate * seconds; i++) {
    final sample = (volume * 32768.0 * sin(2 * pi * freq * (i / rate))).round();
    // Left = Right.
    buffer[4 * i] = buffer[4 * i + 2] = sample & 0xff;
    buffer[4 * i + 1] = buffer[4 * i + 3] = (sample >> 8) & 0xff;
  }

  ao.play(device, buffer);

  ao.close(device);
  ao.shutdown();

  print('done $seconds s');
}
