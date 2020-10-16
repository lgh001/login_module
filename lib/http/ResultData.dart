class ResultData {
  var data;
  bool result;//true 如果正常返回结果
  int code;
  var headers;

  ResultData(this.data, this.result, this.code, {this.headers});
}
