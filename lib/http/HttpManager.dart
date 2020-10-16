import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:login_module/http/HttpError.dart';
import 'package:login_module/http/ResultData.dart';
import 'package:login_module/utils/LogUtil.dart';

///http请求成回调
typedef HttpSuccessCallback<T> = void Function(dynamic data);

///http请求失败回调
typedef HttpFailureCallback<T> = void Function(HttpError data);

///数据解析回调
typedef T JsonParse<T>(dynamic data);

///@desc 封装请求
class HttpManager {
  Map<String, CancelToken> _cancelTokens = Map<String, CancelToken>();

  ///超时时间
  static const int CONNECT_TIMEOUT = 30000;
  static const int RECEIVE_TIMEOUT = 30000;

  /// http request methods
  static const String GET = 'get';
  static const String POST = 'post';

  ///dio client
  Dio _client;

  static final HttpManager _instance = HttpManager._internal();

  factory HttpManager() => _instance;

  Dio get client => _client;

  HttpManager._internal() {
    if (_client == null) {
      BaseOptions options = BaseOptions(
          connectTimeout: CONNECT_TIMEOUT, receiveTimeout: RECEIVE_TIMEOUT);
      _client = Dio(options);
    }
  }

  void init({
    String baseUrl,
    int connectTimeout = CONNECT_TIMEOUT,
    receiveTimeout = RECEIVE_TIMEOUT,
    List<Interceptor> interceptors,
  }) {
    _client.options = _client.options.merge(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout);
    if (interceptors != null && interceptors.isNotEmpty) {
      _client.interceptors..addAll(interceptors);
    }
  }

  ///GET网络请求
  ///
  ///[url] 网络请求地址，不包含域名
  ///[params] url请求参数,支持restful
  ///[options] 请求配置
  ///[tag] 请求统一标识，用于取消网络请求
  get({
    @required String url,
    Map<String, dynamic> params,
    Options options,
    @required String tag,
  }) async {
    return await _request(url: url, params: params, method: GET, tag: tag);
  }

  ///POST网络请求
  ///
  ///[url] 网络请求地址，不包含域名
  ///[data] post 请求参数
  ///[params] url请求参数,支持restful
  ///[options] 请求配置
  ///[tag] 请求统一标识，用于取消网络请求
  post({
    @required String url,
    data,
    Map<String, dynamic> params,
    Options options,
    @required String tag,
  }) async {
    return await _request(
        url: url, data: data, method: POST, params: params, tag: tag);
  }

  ///统一网络请求
  ///
  ///[url] 网络请求地址不包含域名
  ///[data] post 请求参数
  ///[params] url请求参数支持restful
  ///[options] 请求配置
  ///[successCallback] 请求成功回调
  ///[errorCallback] 请求失败回调
  ///[tag] 请求统一标识，用于取消网络请求
  _request({
    @required String url,
    String method,
    data,
    Map<String, dynamic> params,
    Options options,
    @required String tag,
  }) async {
    //检查网络是否连接
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      LogUtil.v("请求网络异常，请稍后重试！");
      return ResultData(
          HttpError(HttpError.NETWORK_ERROR, "网络异常，请稍后重试！"), false, -1);
    }

    params = params ?? {};
    method = method ?? 'GET';

    options?.method = method;

    options = options ??
        Options(
          method: method,
        );

    //restful支持
    url = _restfulUrl(url, params);

    try {
      CancelToken cancelToken;
      if (tag != null) {
        cancelToken =
            _cancelTokens[tag] == null ? CancelToken() : _cancelTokens[tag];
        _cancelTokens[tag] = cancelToken;
      }

      Response<Map<String, dynamic>> response = await _client.request(url,
          data: data,
          queryParameters: params,
          options: options,
          cancelToken: cancelToken);
      // String statusCode = response.data["statusCode"];
      if (response.statusCode == 200) {
        //成功
        return ResultData(response.data, true, 0);
      } else {
        return ResultData(
            HttpError(response.statusCode.toString(), response.statusMessage),
            false,
            -1);
      }
    } on DioError catch (e, s) {
      LogUtil.v("请求出错:$e\n$s");
      if (e.type != DioErrorType.CANCEL) {
        return ResultData(HttpError.dioError(e), false, -1);
      } else {
        return ResultData(
            HttpError(HttpError.CANCEL, "请求以被取消,请重新请求"), false, -1);
      }
    } catch (e, s) {
      LogUtil.v("未知错误:$e\n$s");
      return ResultData(HttpError(HttpError.UNKNOWN, '网络异常，请稍后重试！'), false, -1);
    }
  }

  ///restful处理
  String _restfulUrl(String url, Map<String, dynamic> params) {
    params.forEach((key, value) {
      if (url.indexOf(key) != -1) {
        url = url.replaceAll(':$key', value.toString());
      }
    });
    return url;
  }
}
