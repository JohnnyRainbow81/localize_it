import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:build/build.dart';
import 'package:http/http.dart' as http;

import 'package:analyzer/dart/element/element.dart';
import 'package:localize_it_annotation/localize_it_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'model_visitor.dart';

/// This is a comment to get Pub Points
class Localizer extends GeneratorForAnnotation<LocalizeItAnnotation> {
  String baseLanguageCode = '';
  List<String> supportedLanguageCodes = [];

  late bool useDeepL;
  late String deepLAuthKey;
  late bool useGetX;
  late bool preferDoubleQuotes;

  late String baseFilePath;
  late String localizationFilePath;
  late String formality;
  late bool asJsonFile;

  int missingLocalizationsCounter = 0;
  int successfullyLocalizedCounter = 0;

  late final String escapedQuote;
  late final missingTranslationPlaceholderText;

  @override
  Future<void> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final visitor = ModelVisitor();

    // Visits all the children of element in no particular order.
    element.visitChildren(
      visitor,
    );

    deepLAuthKey = visitor.deepLAuthKey;
    useDeepL = deepLAuthKey.isNotEmpty;
    useGetX = visitor.useGetX;
    preferDoubleQuotes = visitor.preferDoubleQuotes;
    formality = visitor.formality.isEmpty ? "default" : visitor.formality;
    asJsonFile = visitor.asJsonFile;

    // If we prefer double quotes OR want a JSON file, use double quotes, else use single quotes
    escapedQuote = (preferDoubleQuotes || asJsonFile) ? '"' : '\'';
    missingTranslationPlaceholderText = '$escapedQuote--missing translation--$escapedQuote';

    final rawLocation = visitor.location;

    final pathForDirectory = rawLocation.substring(
      rawLocation.indexOf(
        'lib',
      ),
      rawLocation.lastIndexOf('/'),
    );
    const directoryName = '/localizations';

    // Make Directory with path lib/l10n/localizations
    final localizationsDirectory = Directory(
      pathForDirectory + directoryName,
    );

    if (!localizationsDirectory.existsSync()) {
      await localizationsDirectory.create();
    }

    // Make Directory for Base Localization
    final baseLocalizationDir = Directory(
      '${localizationsDirectory.path}/base',
    );

    if (!baseLocalizationDir.existsSync()) {
      await baseLocalizationDir.create();
    }

    baseFilePath = baseLocalizationDir.path;
    localizationFilePath = localizationsDirectory.path;

    baseLanguageCode = visitor.baseLanguageCode;
    supportedLanguageCodes = visitor.supportedLanguageCodes;

    await translate();

    if (useGetX) {
      await _generateTranslationKeysForGetX(pathForDirectory);
    }

    return;
  }

  /// Maps [supportedLanguageCodes] to their localizations-files.
  /// `translation_keys` can simply be passed to `GetMaterialApp`
  /// to enable Localization.
  Future<void> _generateTranslationKeysForGetX(String path) async {
    const fileName = 'translation_keys.dart';
    final filePath = '$path/$fileName';
    File file = File(filePath);

    if (!file.existsSync()) {
      await file.create();
    }
    final sink = file.openWrite();
    const relativeDirectoryPathForLocalizations = 'localizations/';

    sink.writeln(
      'import \'$relativeDirectoryPathForLocalizations/base/$baseLanguageCode.g.dart\';',
    );
    for (String code in supportedLanguageCodes) {
      sink.writeln(
        'import \'$relativeDirectoryPathForLocalizations$code.g.dart\';',
      );
    }
    sink.write('\n');

    sink.writeln('const Map<String, Map<String, String>> translationsKeys = {');
    sink.writeln('\t\'$baseLanguageCode\': $baseLanguageCode,');
    for (String code in supportedLanguageCodes) {
      sink.writeln('\t\'$code\': $code,');
    }
    sink.writeln('};');

    await sink.flush();
    await sink.close();
  }

  Future<void> translate() async {
    final nestedKeysWithTranslations =
        await _parseDartFilesAndGenerateKeyValueMap(); // _getFileNamesWithTranslations();
    // generate en.g.json
    await _writeToFile(
      await _getBaseFile(),
      nestedKeysWithTranslations,
      language: baseLanguageCode,
    );

    await _translateToAllLanguages(
      // allTranslations,
      nestedKeysWithTranslations,
    );
  }

  // by Stefan
  Future<Map<String, dynamic>> _parseDartFilesAndGenerateKeyValueMap() async {
    final currentDir = Directory.current;
    Map<String, dynamic> keysWithTranslation = {};

    try {
      final files = await _getDirectorysContents(currentDir);
      final dartFiles = _getDartFiles(files);
      final List<String> keysAndValueStrings = [];

      await Future.forEach(dartFiles, (File fileEntity) async {
        final translationForSpecificFile = List<String>.empty(growable: true);

        final fileContent = await _readFileContent(fileEntity.path);

        final regex = RegExp(r"'[^']*(\\'[^']*)*'\.tr");
        final wordMatches = regex.allMatches(fileContent);

        // tokenize string like 'Login.Message.sag hello'
        for (final wordMatch in wordMatches) {
          final rawKeysAndValue = wordMatch.group(0)!;
          String cleanedKeyAndValue = _cleanKeyAndValue(rawKeysAndValue);

          keysAndValueStrings.add(cleanedKeyAndValue);
        }
      });
      keysWithTranslation = toNestedMap(keysAndValueStrings);

      stdout.writeln("keysWithTranslation: $keysWithTranslation");

      stdout.writeln('✅    Done!\n\n');
      return keysWithTranslation;
    } catch (exception) {
      stdout.writeln('❌    Something went wrong while localizing. \n');
      stdout.writeln('      Error: $exception\n\n');
      return keysWithTranslation;
    }
  }

  Map<String, dynamic> toNestedMap(List<String> stringList) {
    // list = "Auth.Login.This is my leaf", "Auth.Login.This is my second lef"

    RegExp regExp = RegExp(r"(?<!\\)\."); // Only use "." as delimiter, not "\."

    Map<String, dynamic> finalMap = {};

    for (String string in stringList) {
      final segments = string.split(regExp);

      // LEAF
      final leafIndex = segments.length - 1;

      var currentRootNode = finalMap;

      // HANDLE GROUPS
      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];

        if (currentRootNode.containsKey(segment)) {
          // NODE exists
          if (i == leafIndex) {
            currentRootNode.addEntries([MapEntry(segment, segment)]);
          } else {
            currentRootNode = currentRootNode[segment];
          }
        } else {
          // NODE doesn't yet exist
          if (i == leafIndex) {
            currentRootNode.addEntries([MapEntry(segment, segment)]);
          } else {
            final deeperNode = <String, dynamic>{};
            currentRootNode.addEntries([MapEntry(segment, deeperNode)]);
            currentRootNode = deeperNode;
          }
        }
      }
    }
    return finalMap;
  }

  String _cleanKeyAndValue(String input) {
    var cleanedString = "";
    if (input.endsWith(".tr")) {
      cleanedString = input.substring(0, input.length - 3);
    }
    if ((cleanedString[0] == '"' || cleanedString[0] == "'") &&
        (cleanedString[cleanedString.length - 1] == '"' || cleanedString[cleanedString.length - 1] == "'")) {
      cleanedString = cleanedString.substring(1, cleanedString.length - 1);
    }
    return cleanedString;
  }

  // by Stefan
  Future<void> _writeToFile(
    File file,
    Map<String, dynamic> keysWithTranslation, {
    required String language,
  }) async {
    final sink = file.openWrite();

    try {
      sink.write(jsonEncode(keysWithTranslation));

      await sink.flush();
    } catch (e) {
      stdout.writeln("Error writing translations");
      stderr.writeln(e);
    } finally {
      await sink.close();
    }
  }

  /// Searching for all Strings in the project that use the `.tr` extension.
  ///
  /// Returns a map where the key is the file in which the translation were found
  /// and the values are all translation for that specific file.
  /// ```dart
  /// {
  ///   'example.dart': ["'Hello'", "'World'"],
  /// }
  /// ```
  Future<Map<String, List<String>>> _getFileNamesWithTranslations() async {
    stdout.writeln('\n');

    stdout.writeln('Getting all Strings to localize...\n');

    final currentDir = Directory.current;

    /// Keeps track of all the words to translate to avoid duplicates
    final allStringsToTranslate = List<String>.empty(growable: true);

    final fileNamesWithTranslation = <String, List<String>>{};

    try {
      final files = await _getDirectorysContents(currentDir);
      final dartFiles = _getDartFiles(files);

      await Future.forEach(dartFiles, (File fileEntity) async {
        final translationForSpecificFile = List<String>.empty(growable: true);

        final fileContent = await _readFileContent(fileEntity.path);

        final matchTranslationExtension = preferDoubleQuotes
            ? RegExp(r""""[^"\\]*(?:\\.[^"\\]*)*"\s*\.tr\b""")
            : RegExp(r"('[^'\\]*(?:\\.[^'\\]*)*'\s*\.tr\b)");
        final wordMatches = matchTranslationExtension.allMatches(fileContent);

        for (final wordMatch in wordMatches) {
          final word = wordMatch.group(0)!;

          final wordCleaned = _cleanWord(word);

          if (!allStringsToTranslate.contains(wordCleaned)) {
            allStringsToTranslate.add(wordCleaned);
            translationForSpecificFile.add(wordCleaned);
          }
        }

        if (translationForSpecificFile.isNotEmpty) {
          final fileName = _basePath(fileEntity);
          fileNamesWithTranslation[fileName] = translationForSpecificFile;
        }
      });

      stdout.writeln('✅    Done!\n\n');
      return fileNamesWithTranslation;
    } catch (exception) {
      stdout.writeln('❌    Something went wrong while localizing. \n');
      stdout.writeln('      Error: $exception\n\n');
      return fileNamesWithTranslation;
    }
  }

  /// Returns all files and directorys of a given [directory].
  Future<List<FileSystemEntity>> _getDirectorysContents(Directory directory) {
    final files = <FileSystemEntity>[];
    final completer = Completer<List<FileSystemEntity>>();
    final lister = directory.list(recursive: true);
    lister.listen((file) => files.add(file),
        onError: (Object error) => completer.completeError(error), onDone: () => completer.complete(files));
    return completer.future;
  }

  /// Returns an iterable of all dart files in a list of [files].
  Iterable<File> _getDartFiles(List<FileSystemEntity> files) => files.whereType<File>().where(
        (file) => file.path.endsWith('.dart'),
      );

  /// Reads, decodes and returns the content of a given [filePath]
  Future<String> _readFileContent(String filePath) async {
    final readStream = File(filePath).openRead();
    return utf8.decodeStream(readStream);
  }

  /// Removes the trailing `.tr` but more importantly removes whitespaces
  /// between the String and `.tr`
  /// Example:
  /// ```
  /// Text(
  ///   'This is a very long String. It goes on and on and on and on'
  ///    .tr,
  /// )
  /// ```
  String _cleanWord(String word) => word.substring(
        0,
        word.lastIndexOf(preferDoubleQuotes ? '"' : '\'') + 1,
      );

  String _basePath(FileSystemEntity fileEntity) => fileEntity.uri.pathSegments.last;

  /// Writes all found Strings with the `tr` exentsion [fileNamesWithTranslation] into the base translation file.
  Future<void> _writeTranslationsToBaseFile(
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    stdout.writeln('Updating base localization file...\n');

    await _writeTranslationsToFile(
      // creates the base language file, like en.g.dart
      await _getBaseFile(),
      fileNamesWithTranslation,
      language: baseLanguageCode,
      writeKeyAndValue: (translation, sink) {
        sink.write('\t$translation: $translation');
      },
    );

    stdout.writeln('✅    Done!\n\n');
  }

  /// Helper function to get the language of a given localization [file]
  ///
  /// The file should have the format `{languageCode}.dart`
  String _getLanguage(FileSystemEntity file) => _basePath(file).split('.')[0];

  /// Function which writes the translations to the given [file]
  ///
  /// Needs the [fileNameWithTranslation] because based on that, the content of the [file]
  /// gets ordered.
  /// [writeKeyAndValue] is a callback function for a custom implementation on how to write
  /// the key and value of [fileNameWithTranslation].
  /// You should not flush the IOSink that get's passed to [writeKeyAndValue], because that happens at the end of this function.
  /// Creates a file with the [language] as a name.
  Future<void> _writeTranslationsToFile(
    File file,
    Map<String, List<String>> fileNamesWithTranslation, {
    required void Function(String, IOSink) writeKeyAndValue,
    required String language,
  }) async {
    final sink = file.openWrite();

    sink.writeln(asJsonFile ? '{ \n\t "$language" : {' : 'const Map<String, String> $language = {');

    // inkrementelles update von den files und nicht immer alles neuschreiben
    await Future.forEach(fileNamesWithTranslation.entries, (MapEntry<String, List<String>> entry) async {
      // This adds a comment about which file the string to translate was found. Like "// login_screen.dart"
      // Skip this for JSON, because JSON must not have comments
      if (!asJsonFile) sink.writeln('\n\t//  ${entry.key}');

      for (int i = 0; i < entry.value.length; i++) {
        writeKeyAndValue(entry.value[i], sink);

        if (entry.value.length - 1 != i) {
          sink.write(',');
        }
        sink.write('\n');
      }
      // await Future.forEach(
      //   entry.value,
      //   (String translation) {
      //     stdout.writeln("Writing $translation ...");
      //     writeKeyAndValue(translation, sink);
      //   },
      // );
    });
    sink.writeln(asJsonFile ? '}\n }' : '};');

    await sink.flush();
    await sink.close();
  }

  /// Gets all Localization Files based on `supportedLanguageCodes`.
  /// Creates File if it does not exist.
  Future<List<File>> _getLocalizationFiles() async {
    final localizationFiles = <File>[];
    for (final code in supportedLanguageCodes) {
      final file = asJsonFile ? File('$localizationFilePath/$code.g.json') : File('$localizationFilePath/$code.g.dart');
      if (!file.existsSync()) {
        await file.create();
      }
      localizationFiles.add(file);
    }
    return localizationFiles;
  }

  Future<File> _getBaseFile() async {
    final file =
        asJsonFile ? File('$baseFilePath/$baseLanguageCode.g.json') : File('$baseFilePath/$baseLanguageCode.g.dart');
    if (!file.existsSync()) {
      await file.create();
    }
    return file;
  }

  /// Gets all language files in the `lib/locale/translations` path and updates the files
  /// incrementally with [allTranslations] and [fileNamesWithTranslation]
  Future<void> _writeTranslationsToAllTranslationFiles(
    List<String> allTranslations,
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    final localizationFiles = await _getLocalizationFiles();

    await Future.forEach(localizationFiles, (File file) async {
      await _updateTranslations(
        file,
        allTranslations,
        fileNamesWithTranslation,
      );
    });

    stdout.writeln('\n🍻🍻🍻 Successfully updated localizations! 🍻🍻🍻\n\n\n');
  }

  Future<void> _translateToAllLanguages(
    //Map<String, dynamic> allTranslations,
    Map<String, dynamic> keysWithTranslation,
  ) async {
    final localizationFiles = await _getLocalizationFiles();

    await Future.forEach(localizationFiles, (File file) async {
      await _updateTranslation(
        file,
        // allTranslations,
        keysWithTranslation,
      );
    });

    stdout.writeln('\n🍻🍻🍻 Successfully updated localizations! 🍻🍻🍻\n\n\n');
  }

  /// by Stefan
  Future<void> _updateTranslation(
    FileSystemEntity fileEntity,
    // Map<String, dynamic> allTranslations,
    Map<String, dynamic> toTranslateMap,
  ) async {
    // Reset counter for each file
    successfullyLocalizedCounter = 0;
    missingLocalizationsCounter = 0;

    stdout.writeln('Update localizations in ${_basePath(fileEntity)} ...\n');
    stdout.writeln('fileNamesWithTranslation: $toTranslateMap');

    // get current state of tranlation for de, es, fr, ...
    final fileContent = await _readFileContent(fileEntity.path);

    final file = File(fileEntity.path);
    final language = _getLanguage(file);

    //Do this:

    // Only send new keys to Deepl (compare with old file content)
    toTranslateMap = await iterateMap(toTranslateMap, language);
    /* writeKeyAndValue: (singleKeyToTranslate, sink) async {
        var value = useDeepL
            // Stefan put String in here
            ? await _deepLTranslate(
                _removeFirstAndLastCharacter(
                  singleKeyToTranslate,
                ),
                language,
              )
            : "<<Could not translate value>>";

        Map<String, dynamic> translations = {};
        // Add translated String to map
        sink.writeln(jsonEncode(translations));
      }, */

    await _writeToFile(
      file,
      toTranslateMap,
      language: language,
    );

    stdout.writeln(
      '💡    Missing Localizations: $missingLocalizationsCounter',
    );
    if (useDeepL) {
      stdout.writeln(
        '💡    New Localizations:     $successfullyLocalizedCounter\n',
      );
    }
    stdout.writeln('✅    Done!\n\n');
  }

  Future<Map<String, dynamic>> iterateMap(Map<String, dynamic> toTranslate, String language) async {
    Map<String, dynamic> currentNode = toTranslate;

    for (int i = 0; i < toTranslate.entries.length; i++) {
      var currentKey = currentNode.entries.elementAt(i).key;
      var currentValue = currentNode.entries.elementAt(i).value;

      if (currentValue is String) {
        var translation = useDeepL
            // Stefan put String in here
            ? await _deepLTranslate(
                _removeFirstAndLastCharacter(
                  currentValue,
                ),
                language,
              )
            : "<<Could not translate value>>";
        currentNode.update(currentNode.entries.elementAt(i).key, (value) => translation);
      } else if (currentValue is Map) {
        currentNode = currentNode[currentKey];
        // iterateMap(currentNode, language);
      }
    }
    return currentNode;
  }

  /// Updates each translation file and keeps track of all
  /// missing translations, or updates missing translations with the DeepL API
  ///
  Future<void> _updateTranslations(
    FileSystemEntity fileEntity,
    List<String> allTranslations,
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    // Reset counter for each file
    successfullyLocalizedCounter = 0;
    missingLocalizationsCounter = 0;

    stdout.writeln('Update localizations in ${_basePath(fileEntity)} ...\n');
    stdout.writeln('fileNamesWithTranslation: $fileNamesWithTranslation');

    final fileContent = await _readFileContent(fileEntity.path);

    Map<String, String> oldTranslations = {};

    // Gets called when translation files were already initiated
    if (fileContent.isNotEmpty) {
      final matchComments = RegExp(r'\/\/.*\n?');

      // Remove Comments
      var keysAndValues = fileContent.replaceAll(matchComments, '');
      stdout.writeln("keysAndValues before Json-manipulation: \n $keysAndValues");

      if (asJsonFile) {
        keysAndValues = _jsonToRawKeysAndValues(keysAndValues);
      } else {
        // Remove first line
        keysAndValues = keysAndValues.split('= {')[1].trim();
        // Remove last closing curly bracket
        keysAndValues.substring(0, keysAndValues.length - 1);
      }

      final splittedKeysAndValues = keysAndValues.split(',\n');

      for (final keyAndValue in splittedKeysAndValues) {
        // Last element is empty so this check is neccessary
        if (keyAndValue.contains('$escapedQuote:')) {
          final keyAndValueSeperated = keyAndValue.split(escapedQuote);
          // Add single quote for key since it was removed when splitting it
          oldTranslations['${keyAndValueSeperated[0].trim()}$escapedQuote'] = keyAndValueSeperated[1].trim();
        }
      }
    }

    // Remove translations from file that are no longer in the project
    for (final key in [...oldTranslations.keys]) {
      if (!allTranslations.contains(key)) {
        oldTranslations.remove(key);
      }
    }

    final file = File(fileEntity.path);
    final language = _getLanguage(file);

    await _writeTranslationsToFile(
      file,
      fileNamesWithTranslation,
      language: language,
      writeKeyAndValue: (oldTranslationKey, sink) async {
        stdout.writeln("_writeTranslationsToFile with oldTranslationKey");

        final entryExistsForTranslation = oldTranslations.containsKey(oldTranslationKey);

        final entryExistsButIsEmpty = entryExistsForTranslation && (oldTranslations[oldTranslationKey] ?? '').isEmpty;

        final entryExistsButIsMissingTranslation =
            oldTranslations[oldTranslationKey] == missingTranslationPlaceholderText;

        final isMissing = !entryExistsForTranslation || entryExistsButIsEmpty || entryExistsButIsMissingTranslation;

        if (isMissing && !useDeepL) {
          missingLocalizationsCounter++;
        }

        var value = isMissing
            ? useDeepL
                ? await _deepLTranslate(
                    _removeFirstAndLastCharacter(
                      oldTranslationKey,
                    ),
                    language,
                  )
                : missingTranslationPlaceholderText
            : oldTranslations[oldTranslationKey] ?? '';

        sink.writeln("\t$oldTranslationKey: $value");
      },
    );
    stdout.writeln(
      '💡    Missing Localizations: $missingLocalizationsCounter',
    );
    if (useDeepL) {
      stdout.writeln(
        '💡    New Localizations:     $successfullyLocalizedCounter\n',
      );
    }
    stdout.writeln('✅    Done!\n\n');
  }

  /// Helper function used to get the raw String without
  /// leading and trailing quote
  String _removeFirstAndLastCharacter(String string) {
    return string.substring(
      1,
      string.length - 1,
    );
  }

  String _jsonToRawKeysAndValues(String input) {
    int lastPositionOfOpeningBrace = input.lastIndexOf('{') + 1;
    int firstPositionOfClosingBrace = input.indexOf('}');
    input = input.substring(lastPositionOfOpeningBrace, firstPositionOfClosingBrace);
    stdout.writeln("keysAndValues after Json-manipulation: \n $input");
    return input;
  }

  /// Returns the translation for the given [text] and the [language] in which it should be translated
  /// via the DeepL API
  Future<String> _deepLTranslate(String text, String language) async {
    stdout.writeln("Calling DeepL with $text for language $language");
    try {
      final url = Uri.https('api-free.deepl.com', '/v2/translate');

      final body = <String, dynamic>{
        'auth_key': deepLAuthKey,
        'text': text,
        'target_lang': language,
        'source_lang': baseLanguageCode.toUpperCase(),
        'formality': formality
      };

      final response = await http.post(url, body: body);

      stdout.write(response);

      if (response.statusCode != 200) {
        stdout.writeln(
          '❗️   Something went wrong while translating with DeepL.',
        );
        missingLocalizationsCounter++;
        return missingTranslationPlaceholderText;
      }

      final json = jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as Map<String, dynamic>?;

      if (json != null) {
        successfullyLocalizedCounter++;

        var text = json['translations'][0]['text'] as String;

        text = _escapeSingleQuotes(text);
        // Remove double escape characters
        text = text.replaceAll("\\\\'", "\\'");

        return '$escapedQuote$text$escapedQuote';
      }

      missingLocalizationsCounter++;

      return missingTranslationPlaceholderText;
    } on Exception {
      stderr.writeln(
        '❗️    Something went wrong while translating with DeepL.',
      );
      stderr.writeln(
        '❗️    Make sure that you are connected to the Internet.',
      );
      return missingTranslationPlaceholderText;
    }
  }

  /// Makes sure to skip single-quotes in actual Strings.
  /// Escpecially common for English (e.g. "I'm Christian.").
  String _escapeSingleQuotes(String word) {
    return word.replaceAll('\'', '\\\'');
  }
}
