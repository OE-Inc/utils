
class Pair <F, S> {
  F		  f;
  S		  s;

  Pair(this.f, this.s);

  @override
  int get hashCode {
    return f.hashCode | s.hashCode;
  }

  @override
  String toString() {
    return "{ first: $f, second: $s }";
  }

  @override
  bool operator ==(r) {
    return r == this
    || (r is Pair<F, S> && f == r.f && s == r.s);
  }
}
