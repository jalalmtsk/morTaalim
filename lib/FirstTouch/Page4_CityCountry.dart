import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart';

class CityCountryPage extends StatefulWidget {
  const CityCountryPage({Key? key}) : super(key: key);

  @override
  State<CityCountryPage> createState() => _CityCountryPageState();
}

class _CityCountryPageState extends State<CityCountryPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  final Color _primaryColor = Colors.deepOrange.shade700;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

      setState(() {
        _cityController.text = experienceManager.city;
        _countryController.text = experienceManager.country;
      });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = "Please fill all fields correctly.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

      experienceManager.setCity(_cityController.text.trim());
      experienceManager.setCountry(_countryController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("City and country saved successfully!")),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error saving data: $e";
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Information"),
        backgroundColor: _primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: "City"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your city.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: "Country"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your country.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save & Continue",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
