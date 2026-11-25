import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

void main() {
  runApp(const NutriWiseApp());
}

class NutriWiseApp extends StatelessWidget {
  const NutriWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF237A57);
    return MaterialApp(
      title: 'NutriWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF6F8F5),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7E1)),
          ),
        ),
      ),
      home: const NutritionFormPage(),
    );
  }
}

class NutritionFormPage extends StatefulWidget {
  const NutritionFormPage({super.key});

  @override
  State<NutritionFormPage> createState() => _NutritionFormPageState();
}

class _NutritionFormPageState extends State<NutritionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController(text: '25');
  final _household = TextEditingController(text: '4');
  final _incomeRatio = TextEditingController(text: '2.5');
  final _height = TextEditingController(text: '170');
  final _weight = TextEditingController(text: '70');
  final _bmi = TextEditingController(text: '24.2');
  final _waist = TextEditingController(text: '82');

  int? _gender = 1;
  int? _race = 3;
  int? _education = 4;
  bool _loading = false;
  String? _error;
  double? _prediction;
  String? _modelName;

  @override
  void dispose() {
    for (final controller in [
      _age, _household, _incomeRatio, _height, _weight, _bmi, _waist,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _numberValidator(String? value, String label, double min, double max) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Enter a valid $label.';
    if (parsed < min || parsed > max) {
      return '$label must be between $min and $max.';
    }
    return null;
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _prediction = null;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_gender == null || _race == null || _education == null) {
      setState(() => _error = 'Please select all demographic categories.');
      return;
    }

    final baseUrl = ApiConfig.baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (baseUrl.contains('YOUR-RENDER-SERVICE')) {
      setState(() => _error = 'Add your actual Render URL in lib/api_config.dart first.');
      return;
    }

    final payload = {
      'RIDAGEYR': double.parse(_age.text),
      'DMDHHSIZ': double.parse(_household.text),
      'INDFMPIR': double.parse(_incomeRatio.text),
      'BMXHT': double.parse(_height.text),
      'BMXWT': double.parse(_weight.text),
      'BMXBMI': double.parse(_bmi.text),
      'BMXWAIST': double.parse(_waist.text),
      'RIAGENDR': _gender,
      'RIDRETH3': _race,
      'DMDEDUC2': _education,
    };

    setState(() => _loading = true);
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _prediction = (decoded['predicted_day1_kcal'] as num).toDouble();
          _modelName = decoded['model']?.toString();
        });
      } else {
        final detail = decoded is Map ? decoded['detail'] : null;
        setState(() => _error = 'API error (${response.statusCode}): ${detail ?? response.body}');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach NutriWise API. Check your Render URL and internet connection. Details: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String helper,
    double min,
    double max,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, helperText: helper),
      validator: (value) => _numberValidator(value, label, min, max),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String helper,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, helperText: helper),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriWise'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.eco_outlined, color: theme.colorScheme.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2E9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NUTRITION INSIGHTS', style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF237A57), letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Understand your nutrition data.',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Enter the requested details to estimate reported Day 1 calorie intake.',
                    style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Your information', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field('Age', _age, 'Years (0–120)', 0, 120),
                  const SizedBox(height: 12),
                  _field('Household size', _household, 'Number of people (1–20)', 1, 20),
                  const SizedBox(height: 12),
                  _field('Family income-to-poverty ratio', _incomeRatio, 'Survey ratio (0–5)', 0, 5),
                  const SizedBox(height: 12),
                  _field('Height', _height, 'Centimetres (50–250)', 50, 250),
                  const SizedBox(height: 12),
                  _field('Weight', _weight, 'Kilograms (10–350)', 10, 350),
                  const SizedBox(height: 12),
                  _field('BMI', _bmi, 'Body mass index (5–100)', 5, 100),
                  const SizedBox(height: 12),
                  _field('Waist circumference', _waist, 'Centimetres (30–200)', 30, 200),
                  const SizedBox(height: 12),
                  _dropdown<int>(
                    label: 'NHANES gender code',
                    value: _gender!,
                    helper: '1 = Male, 2 = Female (survey coding)',
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 — Male')),
                      DropdownMenuItem(value: 2, child: Text('2 — Female')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 12),
                  _dropdown<int>(
                    label: 'NHANES race / ethnicity code',
                    value: _race!,
                    helper: 'Select the dataset category code',
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 — Mexican American')),
                      DropdownMenuItem(value: 2, child: Text('2 — Other Hispanic')),
                      DropdownMenuItem(value: 3, child: Text('3 — White')),
                      DropdownMenuItem(value: 4, child: Text('4 — Black')),
                      DropdownMenuItem(value: 6, child: Text('6 — Asian')),
                      DropdownMenuItem(value: 7, child: Text('7 — Other / multiracial')),
                    ],
                    onChanged: (v) => setState(() => _race = v),
                  ),
                  const SizedBox(height: 12),
                  _dropdown<int>(
                    label: 'NHANES education code',
                    value: _education!,
                    helper: 'Survey education category',
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 — Less than 9th grade')),
                      DropdownMenuItem(value: 2, child: Text('2 — 9th–11th grade')),
                      DropdownMenuItem(value: 3, child: Text('3 — High school graduate / GED')),
                      DropdownMenuItem(value: 4, child: Text('4 — Some college / AA degree')),
                      DropdownMenuItem(value: 5, child: Text('5 — College graduate or above')),
                    ],
                    onChanged: (v) => setState(() => _education = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _predict,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.insights),
              label: Text(_loading ? 'Getting estimate…' : 'Get nutrition insight'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _MessageCard(color: const Color(0xFFFFE9E7), icon: Icons.error_outline, text: _error!),
            ],
            if (_prediction != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F3EA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB9D9C4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ESTIMATED DAY 1 INTAKE', style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF237A57))),
                    const SizedBox(height: 8),
                    Text('${_prediction!.toStringAsFixed(0)} kcal',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (_modelName != null) Text('Model: $_modelName', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            const _MessageCard(
              color: Color(0xFFFFF3D9),
              icon: Icons.info_outline,
              text: 'Important: this model estimates calories reported during one 24-hour dietary recall. It is not a recommended calorie target, medical advice, or a measure of energy expenditure. The model was trained on US NHANES data and has not been validated for Rwanda.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
