// Conditional export: native ONNX on mobile/desktop, mock on web
export 'compost_inference_service_native.dart'
    if (dart.library.html) 'compost_inference_service_web.dart';
