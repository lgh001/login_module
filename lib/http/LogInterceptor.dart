
import 'package:dio/dio.dart';
import 'package:login_module/utils/LogUtil.dart';

void log2Console(Object object) {
  LogUtil.v(object);
}

class LogInterceptor extends Interceptor {
  LogInterceptor({
    this.request = true,
    this.requestHeader = true,
    this.requestBody = false,
    this.responseHeader = true,
    this.responseBody = false,
    this.error = true,
    this.logPrint = log2Console,
  });

  ///是否打印链接
  bool request;

  ///是否打印请求 header
  bool requestHeader;

  ///是否打印请求体
  bool requestBody;

  ///是否打印响应 header
  bool responseHeader;

  ///是否打印响应体
  bool responseBody;

  ///是否打印错误信息
  bool error;

  ///打印器 默认打印在console
  ///如果有需要，可以定义打印器打印到本地文件
  ///例如下面的示例代码
  ///```dart
  ///  var file=File("./log.txt");
  ///  var sink=file.openWrite();
  ///  dio.interceptors.add(LogInterceptor(logPrint: sink.writeln));
  ///  ...
  ///  await sink.close();
  ///```
  void Function(Object object) logPrint;

  @override
  Future onRequest(RequestOptions options) async {
    logPrint('*** Request ***');
    printKV('uri', options.uri);

    if (request) {
      printKV('method', options.method);
      printKV("responseType", options.followRedirects);
      printKV('followRedirects', options.followRedirects);
      printKV('connectTimeout', options.connectTimeout);
      printKV('receiveTimeout', options.receiveTimeout);
      printKV('extra', options.extra);
    }

    if (requestHeader) {
      logPrint('headers:');
      options.headers.forEach((key, value) => printKV(key, value));
    }

    if (requestBody) {
      logPrint('data:');
      printAll(options.data);
    }

    logPrint("");
    return super.onRequest(options);
  }

  @override
  Future onResponse(Response response) {
    logPrint("*** Response ***");
    _printResponse(response);
    return super.onResponse(response);
  }

  @override
  Future onError(DioError err) {
    if (error) {
      logPrint('*** DioError ***');
      logPrint('uri:${err.request.uri}');
      logPrint('$err');
      if (err.response != null) {
        _printResponse(err.response);
      }
      logPrint("");
    }
    return super.onError(err);
  }

  void _printResponse(Response response) {
    printKV('uri', response.request?.uri);
    if (responseHeader) {
      printKV('statusCode', response.statusCode);
      if (response.isRedirect) {
        printKV('redirect', response.realUri);
      }
      if (response.headers != null) {
        logPrint("headers:");
        response.headers.forEach((key, v) => printKV(" $key", v.join(",")));
      }
    }
    if (responseBody) {
      logPrint("Response Text:");
      printAll(response.toString());
    }
    logPrint("");
  }

  printKV(String key, Object v) {
    logPrint('$key: $v');
  }

  printAll(msg) {
    msg.toString().split("\n").forEach(logPrint);
  }
}
