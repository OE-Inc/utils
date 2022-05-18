

class ValueWrapper<T> {
  T val;

  ValueWrapper(this.val);

  @override
  String toString() {
    return "$runtimeType { val: $val }";
  }
}