
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'package:flutter/services.dart';

import 'log.dart';

const _TAG = "Git";

class GitInfo {
  String branch;
  String commitId;

  GitInfo(this.branch, this.commitId);

  String displayString() {
    return "${branch.substring(0, 1)}:${commitId.substring(0, 6)}";
  }

  @override
  String toString() {
    return 'GitInfo { branch: $branch, commitId: $commitId }';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitInfo &&
          runtimeType == other.runtimeType &&
          branch == other.branch &&
          commitId == other.commitId;

  @override
  int get hashCode => branch.hashCode ^ commitId.hashCode;
}

Future<GitInfo> getGitInfo({ String? path, String? package, }) async {
  path ??= '.git';

  final _head = await rootBundle.loadString(AssetUtil.getAssetPath('$path/HEAD', package: package));
  bool isRef = _head.startsWith('ref: ');

  final branch = isRef ? _head.split('/').last : "";
  final ref = isRef ? _head.split(': ').last : "";
  final commitId = isRef
      ? await rootBundle.loadString(AssetUtil.getAssetPath('$path/$ref', package: package))
      : _head
  ;

  Log.d(_TAG, () => "package: $package, path: $path, branch: ${branch.trim()}, commit: ${commitId.trim()}.");

  return GitInfo(branch, commitId);
}

class AssetUtil {

  ///
  /// path support prefix:
  ///
  /// 1. '+' 格式为 "+path"，表示从 ripp_link 库里面加载 assets，等于 wrapPackage = true
  /// 2. '-' 格式为 "-path"，表示从最外层的 assets 加载，等于 wrapPackage = false
  /// 3. 'packages/' 格式为 "packages/package_name/path"，表示从 package_name 库加载 path 的 assets。
  ///
  static String getAssetPath(String path, { bool? wrapPackage, bool? isPackageWrapped, String? package }) {
    if (path.startsWith('+')) {
      wrapPackage = true;
      path = path.substring(1);
    } else if (path.startsWith('-')) {
      wrapPackage = false;
      path = path.substring(1);
    } else if (path.startsWith('packages/')) {
      return path;
    } else {
      wrapPackage ??= package != null || (isPackageWrapped ?? false);
    }

    var fullPath = !wrapPackage
        ? path
        : 'packages/${package ?? 'ripp_link'}/$path'
    ;

    // Log.d(_TAG, () => 'getAssetPath: $path, wrapPackage: $wrapPackage, package: $package, fullPath: $fullPath.');
    return fullPath;
  }

}