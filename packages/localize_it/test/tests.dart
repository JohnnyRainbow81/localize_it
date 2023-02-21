import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:localize_it/src/helpers.dart';

void main() {
  test("test extraction of new keys", (() {
    final newMap = extractUncommonSubset(oldMap, actualMap);

    final jsonNewMap = jsonEncode(newMap);
    stdout.writeln("jsonNewMap: $jsonNewMap");

    final jsonExpectedMap = jsonEncode(expectedMap);
    stdout.writeln("jsonExpectedMap: $jsonExpectedMap");

    expect(checkforEquality(newMap, expectedMap), true);
  }));

  test("test extraction of new keys2", (() {
    final newMap = extractUncommonSubset(oldMap2, actualMap2);

    final jsonNewMap = jsonEncode(newMap);
    stdout.writeln("jsonNewMap: $jsonNewMap");

    final jsonExpectedMap = jsonEncode(expectedMap);
    stdout.writeln("jsonExpectedMap: $jsonExpectedMap");

    expect(checkforEquality(newMap, expectedMap2), true);
  }));

  test("integrate new translations into actual translations", (() {
    final updatedTranslations = updateMapWithSubsetMap(actualMap, newTranslatedMap);

    final jsonUpdatedTranslations = jsonEncode(updatedTranslations);
    stdout.writeln("jsonUpdatedTranslations: $jsonUpdatedTranslations");

    expect(checkforEquality(updatedTranslations, expectedActualMapWithIntegrations), true);
  }));
}

Map<String, dynamic> oldMap = {
  "Auth": {
    "Login": {"Enter your name": "Enter your name", "Your password": "Your password"},
    "Onboarding": {
      "Welcome to our app": "Welcome to our app",
      "See what you can do": "See what you can do",
      "Peak": {"New feature": "New feature", "Another feature": "Another feature"}
    },
    "Help": "Help",
  }
};

Map<String, dynamic> actualMap = {
  "Auth": {
    "Login": {
      "Enter your name": "Enter your name",
      "Your password": "Your password",
      "Reset password": "Reset password"
    },
    "Welcome screen": {
      "Welcome by Olli": "Welcome by Olli",
      "Little insight": {"My life": "My life", "What I do": "What I do"}
    },
    "Onboarding": {
      "Welcome to this cool app": "Welcome to this cool app",
      "See what you can do": "See what you can do",
      "Another screen here!": "Another screen here!",
      "Peak": {
        "New feature": "New feature",
        "Another feature": "Another feature",
        "And another one": "And another one",
        "See what V2 can do": {"New this!": "New this!", "New that!": "New that!"}
      }
    },
    "Help": "Help",
    "Settings": {"Change picture": "Change picture"}
  }
};

Map<String, dynamic> expectedMap = {
  "Auth": {
    "Login": {"Reset password": "Reset password"},
    "Welcome screen": {
      "Welcome by Olli": "Welcome by Olli",
      "Little insight": {"My life": "My life", "What I do": "What I do"}
    },
    "Onboarding": {
      "Welcome to this cool app": "Welcome to this cool app",
      "Another screen here!": "Another screen here!",
      "Peak": {
        "And another one": "And another one",
        "See what V2 can do": {"New this!": "New this!", "New that!": "New that!"}
      },
    },
    "Settings": {"Change picture": "Change picture"}
  }
};

Map<String, dynamic> resultMap = {
  "Auth": {
    "Login": {"Reset password": "Reset password"},
    "Welcome screen": {
      "Welcome by Olli": "Welcome by Olli",
      "Little insight": {"My life": "My life", "What I do": "What I do"}
    },
    "Onboarding": {
      "Welcome to this cool app": "Welcome to this cool app",
      "Another screen here!": "Another screen here!",
      "Peak": {
        "And another one": "And another one",
        "See what V2 can do": {"New this!": "New this!", "New that!": "New that!"}
      }
    },
    "Settings": {"Change picture": "Change picture"}
  }
};

/////// V2
///
///
Map<String, dynamic> oldMap2 = {
  "Blabla": "Hello",
  "Headline": {"Father": "Flash"}
};

Map<String, dynamic> actualMap2 = {"Gustav": "Courbet"};

Map<String, dynamic> expectedMap2 = {"Gustav" : "Courbet"};

/////////////
/// second test
///

Map<String, dynamic> newTranslatedMap = {
  "Auth": {
    "Login": {"Reset password": "1231223"},
    "Welcome screen": {
      "Welcome by Olli": "5454345345",
      "Little insight": {"My life": "fdfgdfgdfg", "What I do": "tzutzughj"}
    },
    "Onboarding": {
      "Welcome to this cool app": "456456345345",
      "Another screen here!": "bcvbcfdgdfg!",
      "Peak": {
        "And another one": "qweweergcffb",
        "See what V2 can do": {"New this!": "bfgfh", "New that!": "asfghgfh"}
      },
    },
    "Settings": {"Change picture": "fghfghfghfgh"}
  }
};

Map<String, dynamic> expectedActualMapWithIntegrations = {
  "Auth": {
    "Login": {"Enter your name": "Enter your name", "Your password": "Your password", "Reset password": "1231223"},
    "Welcome screen": {
      "Welcome by Olli": "5454345345",
      "Little insight": {"My life": "fdfgdfgdfg", "What I do": "tzutzughj"}
    },
    "Onboarding": {
      "Welcome to this cool app": "456456345345",
      "See what you can do": "See what you can do",
      "Another screen here!": "bcvbcfdgdfg!",
      "Peak": {
        "New feature": "New feature",
        "Another feature": "Another feature",
        "And another one": "qweweergcffb",
        "See what V2 can do": {"New this!": "bfgfh", "New that!": "asfghgfh"}
      }
    },
    "Help": "Help",
    "Settings": {"Change picture": "fghfghfghfgh"}
  }
};
