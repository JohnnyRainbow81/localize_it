Map<String, dynamic> extractUncommonSubset(Map<String, dynamic> oldMap, Map<String, dynamic> actualMap) {
  Map<String, dynamic> newMap = {};

  actualMap.forEach((key, value) {
    if (oldMap.containsKey(key)) {
      if (value is Map<String, dynamic> && oldMap[key] is Map) {
        newMap[key] = extractUncommonSubset(oldMap[key], value);
      }
    } else {
      newMap[key] = value;
    }
  });

  return newMap;
}

String removeEscapeCharacters(String string) {
  if (string.contains(r'\')) {
    string = string.replaceAll(r'\', '');
  }
  if (string.contains(r'\\')) {
    string = string.replaceAll(r'\\', r'\');
  }
  return string;
}

/// Because DeepL strangely adds additional double quotes
String cleanAfterTranslation(String string) {
  if (string.contains('"')) {
    string = string.replaceAll('"', '');
  }
  if (string.contains(r'\\')) {
    string = string.replaceAll(r'\\', r'');
  }
  string = unescapeDots(string);
  return string;
}

Map<String, dynamic> updateMapWithSubsetMap(Map<String, dynamic> map, Map<String, dynamic> subset) {
  subset.forEach((key, value) {
    if (map.containsKey(key)) {
      if (value is Map<String, dynamic> && map[key] is Map<String, dynamic>) {
        map[key] = updateMapWithSubsetMap(map[key], value);
      } else {
        map[key] = value;
      }
    } else {
      map[key] = value;
    }
  });
  return map;
}

bool checkforEquality(Map<String, dynamic> first, Map<String, dynamic> second) {
  if (first.length != second.length) {
    return false;
  }

  for (var key in first.keys) {
    if (!second.containsKey(key)) {
      return false;
    }

    var firstValue = first[key];
    var secondValue = second[key];

    if (firstValue is Map<String, dynamic> && secondValue is Map<String, dynamic>) {
      if (!checkforEquality(firstValue, secondValue)) {
        return false;
      }
    } else if (firstValue is List<dynamic> && secondValue is List<dynamic>) {
      if (firstValue.length != secondValue.length) {
        return false;
      }
      for (var i = 0; i < firstValue.length; i++) {
        if (firstValue[i] is Map<String, dynamic> && secondValue[i] is Map<String, dynamic>) {
          if (!checkforEquality(firstValue[i], secondValue[i])) {
            return false;
          }
        } else if (firstValue[i] != secondValue[i]) {
          return false;
        }
      }
    } else if (firstValue != secondValue) {
      return false;
    }
  }

  return true;
}

String unescapeDots(String input) {
  if (input.contains(r'\.')) {
    input = input.replaceAll(r'\.', r'.');
  }
  return input;
}
