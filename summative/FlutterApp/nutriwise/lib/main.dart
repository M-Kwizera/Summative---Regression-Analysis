import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

void main() => runApp(const NutriWiseApp());

class NutriWiseApp extends StatelessWidget {
  const NutriWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237A57)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          helperMaxLines: 4,
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

/// Describes one model input and checks what the user typed.
class InputField {
  InputField.number(this.name, this.label, this.helper,
      {required this.min, required this.max, this.wholeNumber = false})
      : options = const [];

  InputField.text(this.name, this.label, this.options)
      : helper = 'Type one of: ${options.join(', ')}',
        min = 0,
        max = 0,
        wholeNumber = false;

  final String name; // The field name the API expects.
  final String label;
  final String helper;
  final num min;
  final num max;
  final bool wholeNumber;
  final List<String> options;
  final controller = TextEditingController();

  bool get isNumber => options.isEmpty;

  /// Returns the value to send, or throws a FormatException with a message.
  Object read() {
    final text = controller.text.trim();
    if (text.isEmpty) throw FormatException('$label is missing.');

    if (!isNumber) {
      // Ignore capitals, and treat spaces like underscores.
      final typed = text.toLowerCase().replaceAll(' ', '_');
      for (final option in options) {
        if (option.toLowerCase() == typed) return option;
      }
      throw FormatException('$label: "$text" is not one of the listed values.');
    }

    final num? value = wholeNumber ? int.tryParse(text) : double.tryParse(text);
    if (value == null || !value.isFinite) {
      throw FormatException(
          '$label must be a ${wholeNumber ? 'whole number' : 'number'}.');
    }
    if (value < min || value > max) {
      throw FormatException('$label must be between $min and $max.');
    }
    return value;
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  // One text field per model input, with the same limits as the API.
  final _fields = [
    InputField.number('HHsizemembers', 'Household size',
        'Number of people, 1 to 30', min: 1, max: 30, wholeNumber: true),
    InputField.number('LandCultivated', 'Land cultivated',
        'Hectares, 0 to 50', min: 0, max: 50),
    InputField.number('LivestockHoldings', 'Livestock holdings',
        'Tropical livestock units, 0 to 50', min: 0, max: 50),
    InputField.number('NrofMonthsFoodInsecure', 'Food-insecure months',
        'Months per year, 0 to 12', min: 0, max: 12, wholeNumber: true),
    InputField.number('NrofMonthsWildFoodCons', 'Months eating wild foods',
        'Months per year, 0 to 12', min: 0, max: 12, wholeNumber: true),
    InputField.number('Gender_FemaleControl', 'Share controlled by women',
        'From 0 (none) to 1 (all), such as 0.3', min: 0, max: 1),
    InputField.text('Country', 'Country', const [
      'Burkina_Faso', 'Burundi', 'DRC', 'Ethiopia', 'Ghana', 'Kenya',
      'Malawi', 'Mali', 'Tanzania', 'Uganda', 'Zambia',
    ]),
    InputField.text('HouseholdType', 'Household type', const [
      'couple', 'couple_man_works_away', 'couple_woman_works_away',
      'man_single', 'woman_single', 'single', 'together', 'polygamous',
      'workaway', 'nonparenthead', 'other',
    ]),
    InputField.text('Head_EducationLevel', 'Education of household head', const [
      'primary', 'secondary', 'postsecondary', 'no_school', 'illiterate',
      'literate', 'adult_education', 'religious_school', 'islamic_school',
      'informal',
    ]),
    InputField.text('HFIAS_status', 'Food insecurity (FI) status', const [
      'FoodSecure', 'MildlyFI', 'ModeratelyFI', 'SeverelyFI',
    ]),
  ];

  bool _loading = false;
  bool _isError = false;
  String _message = 'Fill in all the fields, then press Predict.';

  @override
  void dispose() {
    for (final field in _fields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  void _show(String message, {bool isError = false, bool loading = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isError = isError;
      _loading = loading;
    });
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();

    // 1. Check every field before calling the API.
    final body = <String, Object>{};
    final errors = <String>[];
    for (final field in _fields) {
      try {
        body[field.name] = field.read();
      } on FormatException catch (e) {
        errors.add(e.message);
      }
    }
    if (errors.isNotEmpty) {
      _show(errors.join('\n'), isError: true);
      return;
    }

    // 2. Send the values to the API and show the result.
    _show('Predicting... the server can take a minute to wake up.', loading: true);
    try {
      final baseUrl = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final value =
            jsonDecode(response.body)['predicted_kcal_per_adult_per_day'] as num;
        _show('Predicted food availability:\n'
            '${value.toStringAsFixed(0)} kcal per adult per day');
      } else if (response.statusCode == 422) {
        _show(_readableApiError(response.body), isError: true);
      } else {
        _show('The server had a problem (code ${response.statusCode}). '
            'Please try again.', isError: true);
      }
    } on TimeoutException {
      _show('The server took too long to answer. Please try again.', isError: true);
    } on http.ClientException {
      _show('Could not reach the server. Check your internet connection.',
          isError: true);
    } catch (_) {
      _show('Something went wrong. Please try again.', isError: true);
    }
  }

  /// Turns the API's validation error into sentences a person can read.
  String _readableApiError(String responseBody) {
    final detail = jsonDecode(responseBody)['detail'];
    if (detail is! List) return 'The server rejected the values.';
    return detail.map((item) {
      final name = (item['loc'] as List).last;
      final matches = _fields.where((f) => f.name == name);
      final label = matches.isEmpty ? name : matches.first.label;
      return '$label: ${item['msg']}';
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('NutriWise')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Predict the food available to a farm household.'),
              const SizedBox(height: 16),
              for (final field in _fields) ...[
                TextField(
                  key: Key(field.name),
                  controller: field.controller,
                  keyboardType: field.isNumber
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: field.label,
                    helperText: field.helper,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _loading ? null : _predict,
                child: const Text('Predict'),
              ),
              const SizedBox(height: 16),
              // Display area: shows the prediction or the error message.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isError
                      ? colors.errorContainer
                      : colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message,
                  key: const Key('display'),
                  style: TextStyle(
                    fontSize: 16,
                    color: _isError
                        ? colors.onErrorContainer
                        : colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
