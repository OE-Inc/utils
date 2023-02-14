

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'package:utils/util/pending_promises.dart';

import 'log.dart';

class OnceExecutor<T> {
  T?          result;
  bool        loading = false;
  String      key;
  int         timeout;
  bool        cacheResult;

  Future<T> Function()  runner;

  OnceExecutor(this.key, this.runner, { this.timeout = 10*1000, this.cacheResult = true, });

  Future<T> get() async {

    if (result != null) {
      return result as T;
    }

    if (loading) {
      return await PendingPromises.pendingTasks.wait('/executor/once/result/$key', 10*1000);
    }

    loading = true;
    T r;
    try {
      r = await runner();
      if (cacheResult)
        result = r;

      PendingPromises.pendingTasks.resolve('/executor/once/result/$key', r);
    } catch(e) {
      Log.e('$runtimeType', () => 'OnceExecutor occurs error: ', e);
      PendingPromises.pendingTasks.reject('/executor/once/result/$key', e);
      rethrow;
    } finally {
      loading = false;
    }

    return r;
  }
}