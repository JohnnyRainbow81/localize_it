Map<String, dynamic> extractUncommonSubset(Map<String, dynamic> oldMap, Map<String, dynamic> actualMap) {
  Map<String, dynamic> newMap = {};

  actualMap.forEach((key, value) {
    if (oldMap.containsKey(key)) {
      if (value is Map<String, dynamic> && oldMap[key] is Map<String, dynamic>) {
        newMap[key] = extractUncommonSubset(oldMap[key], value);
      }
    } else {
      newMap[key] = value;
    }
  });

  return newMap;
}

// Map<String, dynamic> extractUncommonSubset2(Map<String, dynamic> oldMap, Map<String, dynamic> actualMap) {
//   Map<String, dynamic> newMap = {};

//   for (int i = 0; i < actualMap.entries.length; i++) {
//     MapEntry<String, dynamic> currentNode = actualMap.entries.elementAt(i);

//     if (oldMap.containsKey(currentNode.key)) {
//       continue;
//     } else {
//       if (currentNode.value is MapEntry<String, dynamic>) {
//         extractUncommonSubset2(oldMap, currentNode.value);
//       } else if (currentNode.value is String) {
//         newMap.addEntries([currentNode]);
//       }
//     }
//   }
// }

String removeEscapeCharacters(String string) {
  if (string.contains(r'\\')) {
    string = string.replaceAll(r'\\', r'\');
  }
  if (string.contains(r'\')) {
    string = string.replaceAll(r'\', '');
  }
  return string;
}

/// Because DeepL strangely adds additional double quotes and double backslashes
/// Might be a bug in *my* code though?
String cleanAfterTranslation(String string) {
  if (string.contains('"')) {
    string = string.replaceAll('"', '');
  }
  if (string.contains(r'\\')) {
    string = string.replaceAll(r'\\', r'');
  }
  // In case there are single backslashes left (Shouldn't be)
  if (string.contains(r'\')) {
    string = string.replaceAll(r'\', r'');
  }
  //string = unescapeDots(string);
  return string;
}

Map<String, dynamic> updateMapWithSubsetMap(Map<String, dynamic> map, Map<String, dynamic> subset) {
  subset.forEach((key, value) {
    if (map.containsKey(key)) {
      if (value is Map<String, dynamic> && map[key] is Map<String, dynamic>) {
        map[key] = updateMapWithSubsetMap(map[key], value);
      } else if (value is String && value.isNotEmpty) {
        map[key] = value;
      }
    } else {
      map.remove(key);
      // map[key] = value;
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
