import 'package:cbor/cbor.dart';
import 'package:mcumgr/client.dart';
import 'package:mcumgr/msg.dart';
import 'package:mcumgr/util.dart';

const _imgGroup = 1;
const _imgCmdState = 0;
const _imgCmdUpload = 1;
const _imgCmdFile = 2;
const _imgCmdCoreList = 3;
const _imgCmdCoreLoad = 4;
const _imgCmdErase = 5;

class ImageState {
  final List<ImageStateImage> images;
  final int splitStatus;

  ImageState(CborMap input)
      : images = (input[CborString("images")] as CborList)
            .map((value) => ImageStateImage(value as CborMap))
            .toList(),
        splitStatus = (input[CborString("splitStatus")] as CborInt).toInt();

  @override
  String toString() {
    return 'ImageState{images: $images, splitStatus: $splitStatus}';
  }
}

class ImageStateImage {
  final int slot;
  final String version;
  final List<int> hash;
  final bool bootable;
  final bool pending;
  final bool confirmed;
  final bool active;
  final bool permanent;

  ImageStateImage(CborMap input)
      : slot = (input[CborString("slot")] as CborInt).toInt(),
        version = (input[CborString("version")] as CborString).toString(),
        hash = (input[CborString("hash")] as CborBytes).bytes,
        bootable = (input[CborString("bootable")] as CborBool).value,
        pending = (input[CborString("pending")] as CborBool).value,
        confirmed = (input[CborString("confirmed")] as CborBool).value,
        active = (input[CborString("active")] as CborBool).value,
        permanent = (input[CborString("permanent")] as CborBool).value;

  @override
  String toString() {
    return 'Image{slot: $slot, version: $version, hash: $hash, bootable: $bootable, pending: $pending, confirmed: $confirmed, active: $active, permanent: $permanent}';
  }
}

class ImageUploadResponse {
  final int nextOffset;

  ImageUploadResponse(CborMap input)
      : nextOffset = (input[CborString("off")] as CborInt).toInt();
}

extension ClientImgExtension on Client {
  Future<ImageState> readImageState(Duration timeout) {
    return execute(
      Message(
        op: Operation.read,
        group: _imgGroup,
        id: _imgCmdState,
        flags: 0,
        data: CborMap({}),
      ),
      timeout,
    ).unwrap().then((value) => ImageState(value.data));
  }

  Future<ImageState> setPendingImage(
      List<int> hash, bool confirm, Duration timeout) {
    return execute(
      Message(
        op: Operation.write,
        group: _imgGroup,
        id: _imgCmdState,
        flags: 0,
        data: CborMap({
          CborString("hash"): CborBytes(hash),
          CborString("confirm"): CborBool(confirm),
        }),
      ),
      timeout,
    ).unwrap().then((value) => ImageState(value.data));
  }

  Future<ImageState> confirmImageState(Duration timeout) {
    // empty hash = currently booted image
    return setPendingImage([], true, timeout);
  }

  Future<ImageUploadResponse> startImageUpload(
    int image,
    List<int> data,
    int length,
    List<int> sha256,
    Duration timeout,
  ) {
    return execute(
      Message(
        op: Operation.write,
        group: _imgGroup,
        id: _imgCmdUpload,
        flags: 0,
        data: CborMap({
          CborString("image"): CborSmallInt(image),
          CborString("data"): CborBytes(data),
          CborString("len"): CborSmallInt(length),
          CborString("off"): CborSmallInt(0),
          CborString("sha"): CborBytes(sha256),
        }),
      ),
      timeout,
    ).unwrap().then((value) => ImageUploadResponse(value.data));
  }

  Future<ImageUploadResponse> continueImageUpload(
    int offset,
    List<int> data,
    Duration timeout,
  ) {
    return execute(
      Message(
        op: Operation.write,
        group: _imgGroup,
        id: _imgCmdUpload,
        flags: 0,
        data: CborMap({
          CborString("data"): CborBytes(data),
          CborString("off"): CborSmallInt(offset),
        }),
      ),
      timeout,
    ).unwrap().then((value) => ImageUploadResponse(value.data));
  }

  Future<void> uploadImage(
    int image,
    List<int> data,
    List<int> hash,
    int chunkSize,
    Duration chunkTimeout, {
    void Function(int)? onProgress,
  }) async {
    int offset = 0;
    while (offset != data.length) {
      int size = data.length - offset;
      if (size > chunkSize) {
        size = chunkSize;
      }

      List<int> chunk = data.sublist(offset, offset + size);

      final Future<ImageUploadResponse> future;
      if (offset == 0) {
        future = startImageUpload(
          image,
          chunk,
          data.length,
          hash,
          chunkTimeout,
        );
      } else {
        future = continueImageUpload(
          offset,
          chunk,
          chunkTimeout,
        );
      }

      final response = await future;
      offset = response.nextOffset;
      onProgress?.call(offset);
    }
  }

  Future<void> erase(Duration timeout) {
    return execute(
      Message(
        op: Operation.write,
        group: _imgGroup,
        id: _imgCmdErase,
        flags: 0,
        data: CborMap({}),
      ),
      timeout,
    ).unwrap();
  }
}
