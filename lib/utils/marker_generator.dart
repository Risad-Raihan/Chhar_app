import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  // Convert a widget to a bitmap for use as a marker
  static Future<BitmapDescriptor> widgetToMarker(Widget widget, 
    {double widgetWidth = 100, double widgetHeight = 100}) async {
    
    // Create a GlobalKey to get the rendered widget as an image
    final RenderRepaintBoundary boundary = RenderRepaintBoundary();
    final RenderView view = RenderView(
      window: ui.window,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: boundary,
      ),
      configuration: ViewConfiguration(
        size: Size(widgetWidth, widgetHeight),
        devicePixelRatio: ui.window.devicePixelRatio,
      ),
    );
    
    // Create a RepaintBoundary widget with the widget to render
    final Element element = BuildOwner(focusManager: FocusManager()).buildScope(
      view, 
      () => RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
        child: RepaintBoundary(
          child: SizedBox(
            width: widgetWidth,
            height: widgetHeight,
            child: widget,
          ),
        ),
      ).attachToRenderTree,
    ) as Element;
    
    // Ensure the widget is laid out
    BuildOwner(focusManager: FocusManager())
      ..buildScope(element)
      ..finalizeTree();
      
    // Wait for the layout to complete
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Render the widget to an image
    final ui.Image image = await boundary.toImage(
      pixelRatio: 3.0, // Higher for better quality
    );
    
    // Convert the image to byte data
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    if (byteData == null) {
      throw Exception('Failed to convert widget to image bytes');
    }
    
    // Create a BitmapDescriptor from the byte data
    final Uint8List bytes = byteData.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }
} 