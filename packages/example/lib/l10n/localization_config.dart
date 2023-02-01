import 'package:localize_it_annotation/localize_it_annotation.dart';

@localize_it
class LocaleConfiguration {
  /// Expects a lanugage code in **lowercase**.
  ///
  /// Supports all the currently available `source_lang`
  /// on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/).
  ///
  /// Defaults to: 'de' (German)
  static const String baseLanguageCode = 'en';

  /// Expects language codes in **lowercase**.
  /// Should *not* contain `baseLanguageCode`.
  ///
  /// Supports all the currently available `target_lang`
  /// on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/).
  ///
  /// Defaults to: `['en' (English), 'es' (Spanish)]`
  static const List<String> supportedLanguageCodes = [
    'de',
    'es',
  ];

  /// Providing a `deepLAuthKey` enables translation generation
  /// via the [DeepL API](https://www.deepl.com/de/pro-api?cta=header-pro-api/).
  /// If no key is provided (empty String), all *marked Strings* (end with `.tr`) in your project
  /// will get translated to `'--missing translation--'.`
  static const String deepLAuthKey = 'b5d442c3-cada-45a5-5686-a7ba7a6cae30:fx';

  /// Enabling `useGetX` generates `Map<String, Map<String,String>> translationKeys` which can
  /// simply be passed to `GetMaterialApp`.
  static const bool useGetX = false;

  /// By default localize_it is searching for `Strings` in *singel-quotes*.
  /// See [prefer_single_quotes](https://dart-lang.github.io/linter/lints/prefer_single_quotes.html) for more info.
  /// However if you prefer using double quotes in your project you can do this by settings
  /// `preferDoubleQuotes` to  `true`.
  static const bool preferDoubleQuotes = false;

  /// Choose between:
  /// default (default)
  /// more - for a more formal language
  /// less - for a more informal language
  /// prefer_more - for a more formal language if available, otherwise fallback to default formality
  /// prefer_less - for a more informal language if available, otherwise fallback to default formality
  static const String formality = 'less';
}
