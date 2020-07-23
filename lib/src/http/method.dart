enum Method {
  GET, POST, PUT, DELETE, OPTIONS, HEAD, TRACE, CONNECT, PATCH
}

extension MethodExt on Method {

  String get name {
    var string = this.toString();
    var index = string.lastIndexOf(".");
    if(index >= 0) {
      string = string.substring(index + 1);
    }
    return string;
  }

}