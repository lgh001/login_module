import 'dart:convert';

import 'package:login_module/bean/Banner.dart';
import 'package:login_module/http/Api.dart';
import 'package:login_module/http/HttpError.dart';
import 'package:login_module/http/HttpManager.dart';
import 'package:login_module/http/ResultData.dart';
import 'package:login_module/utils/LogUtil.dart';

getBanner() async {
  ResultData res = await HttpManager().get(
    url: BANNER,
    tag: "BANNER",
  );

  if (res != null && res.result) {
    BannerData banner = BannerData.fromJson(res.data);
    LogUtil.v(banner,tag: "ccc");
    return ResultData(banner, true, 0);
  } else {
    return ResultData(null, false, -1);
  }
}
