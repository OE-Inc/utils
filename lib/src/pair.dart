
class Pair <F, S> {
  F		  f;
  S		  s;

  Pair(this.f, this.s);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Pair && f == other.f && s == other.s;

  @override
  int get hashCode => f.hashCode ^ s.hashCode;

  @override
  String toString() {
    return "{ first: $f, second: $s }";
  }

}
