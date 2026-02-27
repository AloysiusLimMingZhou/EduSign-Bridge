import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class NativeSignLanguageCamera extends StatelessWidget {
  final Function(String, double) onResult;
  final Function(String, double) onEmotionResult;

  const NativeSignLanguageCamera({
    super.key,
    required this.onResult,
    required this.onEmotionResult,
  });

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'camera_view';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: viewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () {
                params.onFocusChanged(true);
              },
            )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..addOnPlatformViewCreatedListener((id) {
              _setupMethodChannel(id);
            })
            ..create();
        },
      );
    } else {
      return const Center(child: Text("Platform not supported"));
    }
  }

  void _setupMethodChannel(int id) {
    final channel = MethodChannel('sign_language_camera_$id');
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onResult':
          final String label = call.arguments['label'];
          final double score = call.arguments['score'];
          onResult(label, score);
          break;
        case 'onEmotionResult':
          final String label = call.arguments['label'];
          final double score = call.arguments['score'];
          onEmotionResult(label, score);
          break;
      }
    });
  }
}
