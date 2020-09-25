

import 'dart:math';

import 'package:utils/src/storage/index.dart';

import 'log.dart';

const _TAG = "FilterList";

class FilterList<T> {
  static final A = 'a'.codeUnitAt(0), Z = 'z'.codeUnitAt(0);

  List<T>     _all;
  List<T>     _filtered;
  /// [a-z, others] ==> [0-25, 26]
  List<int>   _alphaOffset = List<int>.filled(27, -1);


  bool                  sort = false;
  bool                  alphabet = true;

  bool Function(T t)    boolFilter;
  String Function(T t)  stringFilter;

  String                _filterString;

  FilterList(this._all, this.boolFilter, this.stringFilter);


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

  List<T> get    source => _all;

  set            source(List<T> source) {
    _all = source;
    clearCache();
  }

  set            filterString(String f) {
    _filterString = f?.trim()?.toLowerCase();
    if (_filterString?.isEmpty == true)
      _filterString = null;

    clearCache();
  }

  List<T> get filtered {
    if (_filtered != null)
      return _filtered;

    if (boolFilter == null && _filterString == null) {
      _filtered = _all;
    } else {
      _filtered = _all.where((t) {
        if (boolFilter != null && boolFilter(t) != true) {
          return false;
        }

        if (stringFilter != null && _filterString != null) {
          var s = stringFilter(t)?.toLowerCase();

          if (s == null || !s.contains(_filterString))
            return false;
        }

        return true;
      }).toList();
    }

    if (sort) {
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
        T t = _filtered[idx];

        var s = stringFilter(t).compareString();

        var code = s.length > 0 ? s.codeUnitAt(0) : 0;

        if (code < preCode) {
          Log.e(_TAG, "should provide a sorted list.", Error().thrown());
        }

        preCode = code;

        var offs = (code >= A && code <= Z ? code : Z + 1) - A;

        var isAlpha = offs < 26;
        if (isAlpha) {
          if (firstAz < 0)
            firstAz = idx;
          lastAz = offs;
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
  }

}