
import 'package:flutter/foundation.dart';
import 'package:utils/utils.dart';

import 'log.dart';

const _TAG = "FilterList";

class FilterList<RAW_TYPE, OUT_TYPE> extends ChangeNotifier {
  static final A = 'a'.codeUnitAt(0), Z = 'z'.codeUnitAt(0);

  int?        _lastAllLen = 0;
  List<RAW_TYPE>    _all;
  List<RAW_TYPE>?   _filtered;
  List<OUT_TYPE>?   _filteredOut;
  /// [a-z, others] ==> [0-25, 26]
  List<int>   _alphaOffset = List<int>.filled(27, -1);


  int get               totalLength => _all.length;
  int get               filteredLength => filtered.length;

  bool                  sort = false;
  bool                  alphabet = true;

  bool Function(RAW_TYPE t)?    boolFilter;
  String Function(RAW_TYPE t)?  stringFilter;
  OUT_TYPE Function(RAW_TYPE t)? outTransfer;

  String?               _filterString;

  FilterList(this._all, this.boolFilter, this.stringFilter, { this.outTransfer, })
    : assert(RAW_TYPE == OUT_TYPE || outTransfer != null, "Should provide outTransfer when RAW_TYPE(${RAW_TYPE}) == OUT_TYPE($OUT_TYPE)") {
  }


  List<int> get  alphaOffset => _alphaOffset;

  List<int> get  alphaOffsetFilled {
    var ao = [..._alphaOffset];
    var preVal = ao[ao.length - 1];
    if (preVal < 0)
      preVal = 0;

    for (var idx = 1; idx < ao.length; ++idx) {
      var offs = ao.length - idx - 1;
      var val = ao[offs];

      if (val < 0)
        ao[offs] = preVal;
      else
        preVal = val;
    }

    return ao;
  }

  List<RAW_TYPE> get    source => _all;

  set            source(List<RAW_TYPE> source) {
    _all = source;
    _lastAllLen = _all.length;
    clearCache();
  }

  String? get    filterString => _filterString;

  set            filterString(String? f) {
    _filterString = f;
    if (_filterString?.isEmpty == true)
      _filterString = null;

    clearCache();
  }

  List<OUT_TYPE>? get filteredOut {
    if (_filteredOut != null)
      return _filteredOut;

    var fs = filtered;
    if (filtered == null)
      return null;

    if (outTransfer == null)
      return fs as List<OUT_TYPE>;

    return _filteredOut = fs.map(outTransfer!).toList();
  }

  List<RAW_TYPE> get filtered {
    return _filtered = _doFiltered;
  }

  List<RAW_TYPE> get _doFiltered {
    if (_lastAllLen != _all.length) {
      _lastAllLen = _all.length;
      clearCache();
    }

    var _filtered = this._filtered;
    final boolFilter = this.boolFilter;
    final stringFilter = this.stringFilter;

    if (_filtered != null)
      return _filtered;

    var fs = _filterString?.trim().toLowerCase();
    if (fs == "") fs == null;

    if (boolFilter == null && fs == null) {
      _filtered = [..._all];
    } else {
      _filtered = [];
      for (var t in _all) {
        if (boolFilter != null) {
          var bf = boolFilter(t);
          // if (bf is Future) bf = await bf;

          if (bf != true)
            continue;
        }

        if (stringFilter != null && fs != null) {
          var s = stringFilter(t).toLowerCase();

          if (s == null || !s.contains(fs))
            continue;
        }

        _filtered.add(t);
      };
    }

    if (sort && stringFilter != null) {
      _filtered.sort((l, r) => stringFilter(l).localCompare(stringFilter(r)));
    }

    if (stringFilter == null) {
      _alphaOffset = List<int>.filled(27, -1);
      return _filtered;
    }

    if (alphabet) {
      int preCode = -1, lastAz = -1, firstAz = -1;

      _alphaOffset.fill(-1);
      for (var idx = 0; idx < _filtered.length; ++idx) {
        RAW_TYPE t = _filtered[idx];

        var s = stringFilter(t).compareString();

        var code = s.length > 0 ? s.codeUnitAt(0) : 0;

        if (code < preCode) {
          Log.e(_TAG, () => "should provide a sorted list.", Error().thrown());
        }

        preCode = code;

        var offs = (code >= A && code <= Z ? code : Z + 1) - A;

        var isAlpha = offs < 26;
        if (isAlpha) {
          if (firstAz < 0)
            firstAz = idx;
          lastAz = idx;
        }

        if (_alphaOffset[offs] < 0)
          _alphaOffset[offs] = idx;
      }

      if (firstAz > 0) {
        for (var idx = 0; idx < _alphaOffset.length; ++idx) {
          int offs = _alphaOffset[idx];
          _alphaOffset[idx] = offs < 0 ? offs : offs - firstAz;
        }

        _alphaOffset[26] = lastAz - firstAz;
        var leading = _filtered.sublist(0, firstAz);
        // Log.d(_TAG, () => "lastAz: $lastAz, firstAz: $firstAz, list: $_alphaOffset, _filtered(${_filtered.length}/${_all.length}): ${source.map((s) => stringFilter(s))}");

        _filtered.removeRange(0, firstAz);
        _filtered.insertAll(lastAz + 1 - firstAz, leading);
      }
    }

    return _filtered;
  }

  int offsetOf(String a_z) {
    a_z = a_z.toLowerCase();
    assert(a_z.length == 1);
    var offs = a_z.codeUnitAt(0) - A;
    assert(offs < 27);

    return _alphaOffset.length < offs ? -1 : _alphaOffset[offs];
  }

  String alphabetOfOffset(int offset) {
    var code = 0;

    for (var offs in _alphaOffset) {
      if (offset < offs)
        break;
      code++;
    }

    return String.fromCharCode(A + code);
  }

  void clearCache() {
    _filtered = null;
    _filteredOut = null;
    notifyListeners();
  }

}