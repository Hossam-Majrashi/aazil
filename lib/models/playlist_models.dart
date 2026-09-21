enum VideoRepeatMode {
  off,
  repeatOne,
  repeatAll,
}

extension VideoRepeatModeExtension on VideoRepeatMode {
  String get label {
    switch (this) {
      case VideoRepeatMode.off:
        return 'Off';
      case VideoRepeatMode.repeatOne:
        return 'Repeat One';
      case VideoRepeatMode.repeatAll:
        return 'Repeat All';
    }
  }

  VideoRepeatMode next() {
    switch (this) {
      case VideoRepeatMode.off:
        return VideoRepeatMode.repeatOne;
      case VideoRepeatMode.repeatOne:
        return VideoRepeatMode.repeatAll;
      case VideoRepeatMode.repeatAll:
        return VideoRepeatMode.off;
    }
  }
}
