import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart';
import 'UserInfoPage6.dart';

class UserInfoPage5 extends StatefulWidget {
  const UserInfoPage5({Key? key}) : super(key: key);

  @override
  _UserInfoPage5State createState() => _UserInfoPage5State();
}

class _UserInfoPage5State extends State<UserInfoPage5> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final experience = Provider.of<ExperienceManager>(context, listen: false);
    _countryController.text = experience.country;
  }

  void _next() {
    if (_formKey.currentState!.validate()) {
      Provider.of<ExperienceManager>(context, listen: false)
          .setCountry(_countryController.text.trim());
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserInfoPage6()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Étape 5: Pays")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: "Pays"),
                validator: (v) => v == null || v.isEmpty ? "Entrez votre pays" : null,
              ),
              const Spacer(),
              ElevatedButton(onPressed: _next, child: const Text("Suivant")),
            ],
          ),
        ),
      ),
    );
  }
}
