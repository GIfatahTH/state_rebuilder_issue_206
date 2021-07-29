import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

/// Helper functions (disregard)

bool isEmptyOrNull(Object object) {
  if (object == null) return true;

  assert(
    object is List || object is String || object is Map || object is Set,
    'Type must be either String, List, Set or Map. Type = ${object.runtimeType} is not valid.',
  );

  if (object is List) {
    return object.isEmpty;
  }

  if (object is Map) {
    return object.isEmpty;
  }

  if (object is Set) {
    return object.isEmpty;
  }

  if (object is String) {
    return object.isEmpty;
  }

  return false;
}

void showSnackBar({@required String message, Duration duration}) {
  if (message == null) return;

  RM.scaffold.removeCurrentSnackBarm();
  RM.scaffold.showSnackBar<void>(
    SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}

Future<bool> showSnackBarOnError(AsyncCallback function) async {
  assert(function != null);
  try {
    await function();
  } catch (error) {
    showSnackBar(message: error.toString());
    return false;
  }
  return true;
}

extension FileExtension on File {
  /// Rename the file, updating only the name and keeping its path and extension.
  ///
  /// IMPORTANT:  Will not work properly for files that have more than one dot in their extension.
  Future<File> updateName(String newName) async {
    if (isEmptyOrNull(path)) {
      throw Exception('The file does not have a path.');
    }

    if (!(await exists())) {
      throw Exception('The file does not exist.');
    }

    final String newPath = getPathWitUpdatedName(newName);
    return rename(newPath);
  }

  /// Rename the file path but the file name updated, keeping its path and extension.
  ///
  /// IMPORTANT:  Will not work properly for files that have more than one dot in their extension.
  String getPathWitUpdatedName(String newName) => folderPath + newName + (extension ?? '');

  String get folderPath {
    if (isEmptyOrNull(path) == null) return null;

    final int lastSeparatorIndex = path.lastIndexOf(Platform.pathSeparator);

    if (lastSeparatorIndex == -1) return path;

    return path.substring(0, lastSeparatorIndex + 1);
  }

  /// Returns the file extension with the dot in it (ex: '.png').
  ///
  /// IMPORTANT: Will not work properly for files that have more than one dot in their extension.
  String get extension {
    if (isEmptyOrNull(path) == null) return null;

    final int lastDotIndex = path.lastIndexOf('.');

    if (lastDotIndex == -1) return null;

    return path.substring(lastDotIndex, path.length);
  }
}

class BaseButton extends StatelessWidget {
  static const double smallWidth = 140;
  static const double standardWidth = 175;
  final VoidCallback onTap;
  final VoidCallback onDisabledTap;
  final Color backgroundColor;
  final Color borderColor;
  final String text;
  final Color textColor;
  final bool isDisabled;
  final double minWidth;
  final double minHeight;
  final MainAxisSize mainAxisSize;

  EdgeInsets get padding => const EdgeInsets.symmetric(horizontal: 12);

  const BaseButton({
    this.onTap,
    this.backgroundColor = Colors.orange,
    this.borderColor,
    this.text,
    this.textColor = Colors.white,
    bool hasFixedSize = false,
    bool isDisabled = false,
    this.onDisabledTap,
    double minWidth,
    double minHeight,
    MainAxisSize mainAxisSize = MainAxisSize.min,
  })  : minWidth = minWidth ?? 0,
        minHeight = minHeight ?? 37,
        isDisabled = isDisabled ?? false,
        mainAxisSize = mainAxisSize ?? MainAxisSize.min;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(minHeight * 0.5),
            color: backgroundColor,
            border: borderColor == null
                ? null
                : Border.all(
                    width: 2,
                    color: borderColor,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: mainAxisSize,
            children: <Widget>[
              Flexible(
                child: Text(
                  text ?? '',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}
