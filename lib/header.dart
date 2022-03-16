const _imageHeaderMagic = 0x96f3b83d;
const _imageTLVMagic = 0x6907;

int _decodeInt(List<int> input, int offset, int length) {
  var result = 0;
  for (var i = 0; i < length; i++) {
    result |= input[offset + i] << (8 * i);
  }
  return result;
}

/// The version number of an image.
class ImageVersion {
  final int major;
  final int minor;
  final int revision;
  final int build;

  ImageVersion(
    this.major,
    this.minor,
    this.revision,
    this.build,
  );

  ImageVersion.decode(List<int> input)
      : this(
          _decodeInt(input, 0, 1),
          _decodeInt(input, 1, 1),
          _decodeInt(input, 2, 2),
          _decodeInt(input, 4, 4),
        );

  @override
  String toString() {
    var result = '$major.$minor.$revision';
    if (build != 0) {
      result += '.$build';
    }
    return result;
  }
}

/// The header of an image file.
class McuImageHeader {
  final int loadAddress;
  final int headerSize;
  final int imageSize;
  final int flags;
  final ImageVersion version;

  McuImageHeader(
    this.loadAddress,
    this.headerSize,
    this.imageSize,
    this.flags,
    this.version,
  );

  factory McuImageHeader.decode(List<int> input) {
    final magic = _decodeInt(input, 0, 4);
    if (magic != _imageHeaderMagic) {
      throw FormatException("incorrect magic");
    }

    return McuImageHeader(
      _decodeInt(input, 4, 4),
      _decodeInt(input, 8, 2),
      _decodeInt(input, 12, 4),
      _decodeInt(input, 16, 4),
      ImageVersion.decode(input.sublist(20, 28)),
    );
  }

  @override
  String toString() {
    return 'McuImageHeader{loadAddress: $loadAddress, headerSize: $headerSize, imageSize: $imageSize, flags: $flags, version: $version}';
  }
}

/// TLV section of an image file.
class McuImageTLV {
  final List<McuImageTLVEntry> entries;

  McuImageTLV(this.entries);

  factory McuImageTLV.decode(List<int> input, int offset) {
    final magic = _decodeInt(input, offset, 2);
    if (magic != _imageTLVMagic) {
      throw FormatException("incorrect magic");
    }

    final length = _decodeInt(input, offset + 2, 2);
    final end = offset + length;
    offset += 4;

    final entries = <McuImageTLVEntry>[];
    while (offset < end) {
      final entry = McuImageTLVEntry.decode(input, offset, end);
      entries.add(entry);
      offset += entry.length + 4;
    }

    return McuImageTLV(entries);
  }

  @override
  String toString() {
    return 'McuImageTLV{entries: $entries}';
  }
}

/// An entry of the TLV section of an image file.
class McuImageTLVEntry {
  final int type;
  final int length;
  final List<int> value;

  McuImageTLVEntry(this.type, this.length, this.value);

  factory McuImageTLVEntry.decode(List<int> input, int start, int end) {
    if (start + 4 > end) {
      throw FormatException("tlv header doesn't fit");
    }
    final type = _decodeInt(input, start, 1);
    final length = _decodeInt(input, start + 2, 2);
    if (start + 4 + length > end) {
      throw FormatException("tlv value doesn't fit");
    }
    final value = input.sublist(start + 4, start + 4 + length);
    return McuImageTLVEntry(type, length, value);
  }

  @override
  String toString() {
    return 'McuImageTLVEntry{type: $type, length: $length, value: $value}';
  }
}

/// An image file which can be uploaded to a device.
class McuImage {
  final McuImageHeader header;
  final McuImageTLV tlv;
  final List<int> hash;

  static List<int> _getHash(McuImageTLV tlv) {
    for (final entry in tlv.entries) {
      if (entry.type == 0x10) {
        return entry.value;
      }
    }
    throw FormatException("image doesn't contain hash");
  }

  McuImage(this.header, this.tlv) : hash = _getHash(tlv);

  /// Decodes an image file.
  factory McuImage.decode(List<int> input) {
    final header = McuImageHeader.decode(input);
    final tlv = McuImageTLV.decode(input, header.headerSize + header.imageSize);
    return McuImage(header, tlv);
  }

  @override
  String toString() {
    return 'McuImage{header: $header, tlv: $tlv, hash: $hash}';
  }
}
