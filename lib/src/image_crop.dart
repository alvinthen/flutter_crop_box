import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';
import 'package:image_size_getter/image_size_getter.dart' as imageGetter;

class ImageCropOutputFormatQuality {
  static const int VeryHigh = 100;
  static const int High = 75;
  static const int Middle = 50;
  static const int Low = 25;
  static const int VeryLow = 5;
}

class ImageCrop {
  /// get crop result image, type is Uint8List
  static Future<Uint8List?> getResult(
      {required Rect clipRect,
      required Uint8List image,
      int? outputQuality,
      Size? outputSize}) async {
    final Size memoryImageSize = await getImageSize(image);
    final editorOption = ImageEditorOption();
    final x = clipRect.left * memoryImageSize.width;
    final y = clipRect.top * memoryImageSize.height;
    final width = clipRect.width * memoryImageSize.width;
    final height = clipRect.height * memoryImageSize.height;

    editorOption.addOption(
      ClipOption(
        x: x,
        y: y,
        width: width.floor(),
        height: height.floor(),
      ),
    );

    if (outputSize != null) {
      editorOption.addOption(
          ScaleOption(outputSize.width.toInt(), outputSize.height.toInt()));
    }

    editorOption.outputFormat =
        OutputFormat.jpeg(outputQuality ?? ImageCropOutputFormatQuality.High);
    final result = await ImageEditor.editImage(
        image: image, imageEditorOption: editorOption);
    return result;
  }

  /// get image size with exif
  static Future<Size> getImageSize(Uint8List bytes) async {
    try {
      final data = await readExifFromBytes(bytes);
      double width =
          data['EXIF ExifImageWidth']!.values.firstAsInt().toDouble();
      double height =
          data['EXIF ExifImageLength']!.values.firstAsInt().toDouble();
      if (width > height) {
        if (data['Image Orientation']!.printable.contains('Horizontal')) {
          return Size(width.toDouble(), height);
        } else {
          return Size(height, width);
        }
      } else {
        return Size(width, height);
      }
    } catch (e) {
      imageGetter.ImageInput imageInput = imageGetter.MemoryInput(bytes);
      double width =
          imageGetter.ImageSizeGetter.getSize(imageInput).width.toDouble();
      double height =
          imageGetter.ImageSizeGetter.getSize(imageInput).height.toDouble();
      final Size memoryImageSize = Size(width, height);
      return Size(memoryImageSize.width, memoryImageSize.height);
    }
  }
}
