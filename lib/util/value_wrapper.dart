

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

class ValueWrapper<T> {
  T val;

  ValueWrapper(this.val);

  @override
  String toString() {
    return "$runtimeType { val: $val }";
  }
}