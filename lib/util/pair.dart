
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

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

  Pair<F, S> clone() => Pair(f, s);

}


class Triple <T1, T2, T3> {
  T1		  v1;
  T2		  v2;
  T3		  v3;

  Triple(this.v1, this.v2, this.v3);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Triple && v1 == other.v1 && v2 == other.v2 && v3 == other.v3;

  @override
  int get hashCode => v1.hashCode ^ v2.hashCode ^ v3.hashCode;

  @override
  String toString() {
    return "{ 1: $v1, 2: $v2, 3: $v3 }";
  }

}
