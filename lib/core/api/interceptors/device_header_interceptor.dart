import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../services/device_info_service.dart';

/// Adds device + app metadata headers to every request. Values are resolved
/// once and cached for the process lifetime.
class DeviceHeaderInterceptor extends Interceptor {
  DeviceHeaderInterceptor({
    required AppConfig config,
    required DeviceInfoService deviceInfo,
  }) : _config = config,
       _deviceInfo = deviceInfo;

  final AppConfig _config;
  final DeviceInfoService _deviceInfo;

  String? _serial;
  String? _os;
  String? _osVersion;
  String? _version;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _serial ??= await _deviceInfo.deviceSerial();
    _os ??= await _deviceInfo.osDescriptor();
    // Cache for the process lifetime — the user can't switch OS versions
    // without relaunching the app, so resolving once is safe.
    _osVersion ??= await _deviceInfo.osVersion();
    _version ??= await _deviceInfo.appVersion();

    options.headers['X-Device-SN'] = _serial!;
    options.headers['X-Device-OS'] = _os!;
    options.headers['X-Device-OS-Version'] = _osVersion!;
    options.headers['X-App-Version'] = _version!;
    options.headers['X-App-Type'] = _config.appType.header;
    options.headers['X-Timezone'] = _deviceInfo.timezone();
    handler.next(options);
  }
}
