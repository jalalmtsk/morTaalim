import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart';
import 'UserInfoPage7.dart';

class UserInfoPage6 extends StatefulWidget {
  const UserInfoPage6({Key? key}) : super(key: key);

  @override
  _UserInfoPage6State createState() => _UserInfoPage6State();
}

class _UserInfoPage6State extends State<UserInfoPage6> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final experience = Provider.of<ExperienceManager>(context, listen: false);
    _emailController.text = experience.email;
  }

  void _next() {
    if (_formKey.currentState!.validate()) {
      Provider.of<ExperienceManager>(context, listen: false)
          .setEmail(_emailController.text.trim());
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserInfoPage7()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Étape 6: Email")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Entrez votre email";
                  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  return !regex.hasMatch(v) ? "Email invalide" : null;
                },
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
