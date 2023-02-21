import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:build/build.dart';
import 'package:http/http.dart' as http;

import 'package:analyzer/dart/element/element.dart';
import 'package:localize_it/src/helpers.dart';
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

  //late final String escapedQuote;
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
    //escapedQuote = (preferDoubleQuotes || asJsonFile) ? '"' : '\'';
    missingTranslationPlaceholderText = '--missing translation--';

    final rawLocation = visitor.location;

    final pathForDirectory = rawLocation.substring(
      rawLocation.indexOf(
        'lib',
      ),
      rawLocation.lastIndexOf('/'),
    );

    //const directoryName = '/translations';

    // // Make Directory with path lib/l10n/localizations
    // final localizationsDirectory = Directory(
    //   pathForDirectory + directoryName,
    // );

    // if (!localizationsDirectory.existsSync()) {
    //   await localizationsDirectory.create();
    // }

    // // Make Directory for Base Localization
    // final baseLocalizationDir = Directory(
    //   '${localizationsDirectory.path}/base',
    // );

    // if (!baseLocalizationDir.existsSync()) {
    //   await baseLocalizationDir.create();
    // }

    //String baseDir = rawLocation.substring(1, rawLocation.indexOf("lib"));

    final translationDirectory = Directory(
      "assets/translations",
    );

    baseFilePath = translationDirectory.path; // baseLocalizationDir.path;
    localizationFilePath = translationDirectory.path; //localizationsDirectory.path;

    baseLanguageCode = visitor.baseLanguageCode;
    supportedLanguageCodes = visitor.supportedLanguageCodes;

    await translate();

    return;
  }

  Future<void> translate() async {
    stdout.writeln("*** Translated by Stefan's customized version of localize_it");

    final translatableMap = await _parseFilesForTranslatableStrings();

    // generate our base lang file, in our case en.g.json
    await _saveJSONFile(
      await _getBaseFile(),
      translatableMap,
      language: baseLanguageCode,
    );

    await _translateToChosenLanguages(
      translatableMap,
    );
  }

  Future<Map<String, dynamic>> _parseFilesForTranslatableStrings() async {
    final currentDir = Directory.current;
    Map<String, dynamic> translatablesMap = {};

    try {
      final files = await _getDirectorysContents(currentDir);
      final dartFiles = _getDartFiles(files);
      final List<String> translatables = [];

      await Future.forEach(dartFiles, (File fileEntity) async {
        final fileContent = await _readFileContent(fileEntity.path);

        final regex = RegExp(r"'[^']*(\\'[^']*)*'\.tr");
        final wordMatches = regex.allMatches(fileContent);

        for (final wordMatch in wordMatches) {
          final rawTranslatable = wordMatch.group(0)!;

          // Clean up our strings like "'Auth.Login.This is my value'.tr"
          translatables.add(_cleanRawString(rawTranslatable));

          // keysAndValueStrings.add(cleanedKeyAndValue);
        }
      });
      translatablesMap = toNestedMap(translatables);

      stdout.writeln('✅    Done!\n\n');
      return translatablesMap;
    } catch (exception) {
      stdout.writeln('❌    Something went wrong while localizing. \n');
      stdout.writeln('      Error: $exception\n\n');
      return translatablesMap;
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
            currentRootNode.addEntries([MapEntry(segment, unescapeDots(segment))]);
          } else {
            currentRootNode = currentRootNode[segment];
          }
        } else {
          // NODE doesn't yet exist
          if (i == leafIndex) {
            currentRootNode.addEntries([MapEntry(segment, unescapeDots(segment))]);
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

 

  String _cleanRawString(String input) {
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

  Future<void> _saveJSONFile(
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
    String loadedString = await utf8.decodeStream(readStream);
    if (loadedString.contains(r"\\")) {
      loadedString = loadedString.replaceAll(r"\\", r"\");
    }
    return loadedString;
  }

  String _basePath(FileSystemEntity fileEntity) => fileEntity.uri.pathSegments.last;

  /// Helper function to get the language of a given localization [file]
  ///
  /// The file should have the format `{languageCode}.dart`
  String _getLanguage(FileSystemEntity file) => _basePath(file).split('.')[0];

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

  Future<void> _translateToChosenLanguages(
    Map<String, dynamic> translatableMap,
  ) async {
    final localizationFiles = await _getLocalizationFiles();

    await Future.forEach(localizationFiles, (File file) async {
      await _updateTranslation(
        file,
        translatableMap,
      );
    });

    stdout.writeln('\n🍻🍻🍻 Successfully updated localizations! 🍻🍻🍻\n\n\n');
  }

  Future<void> _updateTranslation(
    FileSystemEntity fileEntity,
    // Map<String, dynamic> allTranslations,
    Map<String, dynamic> presentTranslations,
  ) async {
    // Reset counter for each file
    successfullyLocalizedCounter = 0;
    missingLocalizationsCounter = 0;

    stdout.writeln('Update localizations in ${_basePath(fileEntity)} ...\n');

    // // get current state of tranlation for de, es, fr, ...
    String fileContent = "";
    try {
      // TODO This file should also be a JSON for consistency
      fileContent = await _readFileContent(fileEntity.path);
    } catch (e) {
      stderr.writeln("Couldn't load fileContent, error: $e");
    }

    Map<String, dynamic> oldTranslations = {};

    if (fileContent.isNotEmpty) {
      // if fileContent contains single quotes, swap them out for double quotes
      // FIXME won't be necessary for
      if (fileContent.contains(r'\')) {
        fileContent = fileContent.replaceAll(r'\', r'\\');
      }
      oldTranslations = jsonDecode(fileContent);
    }

    final file = File(fileEntity.path);
    final language = _getLanguage(file);

    //TODO IMPLEMENT FUNCTION: Only send NEW, UNTRANSLATED keys to Deepl (compare with old file content)
    //like: Map<String, dynamic> onlyNewKeyValues = compareMaps(oldMap, newMap)

    var onlyNewTranslatables = extractUncommonSubset(oldTranslations, presentTranslations);

    final onlyNewTranslations = await translateMap(onlyNewTranslatables, language);

    final updatedTranslations = updateMapWithSubsetMap(presentTranslations, onlyNewTranslations);

    await _saveJSONFile(
      file,
      updatedTranslations,
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

  Future<Map<String, dynamic>> translateMap(Map<String, dynamic> currentNode, String language) async {
    for (int i = 0; i < currentNode.keys.length; i++) {
      var currentKey = currentNode.keys.elementAt(i);
      var currentValue = currentNode.entries.elementAt(i).value;

      if (currentValue is String) {
        var translation = useDeepL
            // Stefan put String in here
            ? await _deepLTranslate(
                // clean string from escape characters before sending to DeepL
                removeEscapeCharacters(currentKey),
                language,
              )
            : "<<Could not translate value>>";
        currentNode[currentKey] = cleanAfterTranslation(translation);
      } else if (currentValue is Map<String, dynamic>) {
        await translateMap(currentValue, language);
      }
    }
    return currentNode;
  }

  /// Clean up leaf string from escape backslashes "\""

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

        return text;
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
