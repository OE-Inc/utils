import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utils/utils.dart';
import 'package:utils/src/http/method.dart';

void main() {

  test("http method toString", (){
    Method.values.forEach((element) {
      var string = element.toString();
      var index = string.lastIndexOf(".");
      if(index >= 0) {
        string = string.substring(index + 1);
      }
      print(string);
    });
  });

  test("Locale test", (){
    print(Locale.fromSubtags().countryCode);
  });

  test("DIO", () async {
    try {
      var response = await Dio().request(
          "http://news-at.zhihu.com/story/9724333",
          queryParameters: null,
          options: Options(
              method: "GET",
              headers: null,
              responseType: ResponseType.json
          ),
          onSendProgress: (count, total) { },
          onReceiveProgress: (count, total) { }
      );
      print(response.data);
    } on DioError catch (e, s) {
      e.type;
      print(e);
      print(e?.response?.statusCode);
      print(s);
    } on Exception catch (e, s) {
      /*print(e);
      print(s);*/
    }
  });

  test("DIOENGINE", () async {
    var request = HttpRequest(
      Method.GET,
      //"http://news-at.zhihu.com/story/9724333",
      "http://news-at.zhihu.com/api/3/news/latest",
      headers: {
        "Accept-Language": "zh_CN",
        "Content-Type": "application/json"
      },
      queryParams: {
        "a": "a",
        "b": "b"
      },
      data: {
        "a": "a",
        "b": "b"
      }
    );

    var r = await HttpEngine.engine.execute(request);
    print(r);
  });
}
