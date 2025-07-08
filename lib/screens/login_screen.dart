import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/token_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String error = '';
  bool busy = false;

  Future<void> _login() async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final url = Uri.parse('${Constants.baseUrl}/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailCtrl.text.trim(),
          'password': passCtrl.text,
        }),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200)
        throw body['error'] ?? 'Credenciales inválidas';

      await TokenStorage.save(body['token'], body['rol']);
      if (!mounted) return;
      if (body['rol'] == 'mozo')
        Navigator.pushReplacementNamed(context, '/mozo');
      if (body['rol'] == 'cocina')
        Navigator.pushReplacementNamed(context, '/cocina');
      if (body['rol'] != 'mozo' && body['rol'] != 'cocina')
        setState(() => error = 'Rol no permitido');
    } catch (e) {
      setState(() => error = e.toString());
    }
    setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Login')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passCtrl,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          if (error.isNotEmpty)
            Text(error, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: busy ? null : _login,
            child: Text(busy ? 'Cargando…' : 'Entrar'),
          ),
        ],
      ),
    ),
  );
}
