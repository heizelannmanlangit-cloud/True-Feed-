import 'package:flutter/material.dart';

import '../viewmodels/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  final AuthViewModel viewModel;

  const LoginScreen({super.key, required this.viewModel});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isRegister = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() {
    if (isRegister) {
      widget.viewModel.register(
        nameController.text,
        emailController.text,
        passwordController.text,
      );
    } else {
      widget.viewModel.login(emailController.text, passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, child) {
            final loading = widget.viewModel.isLoading;
            final error = widget.viewModel.errorMessage;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                
                const SizedBox(height: 32),
                
                const Text(
                  'TRUE FEED',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Check the headline before you share.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  isRegister ? 'Create an account' : 'Log in',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (isRegister) ...[
                  TextField(
                    controller: nameController,
                    enabled: !loading,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: 12),             
                  ],


                TextField(
                  controller: emailController,
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  enabled: !loading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (error != null) ...[
                  Text(error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isRegister ? 'Register' : 'Log in'),
                ),
                
                const SizedBox(height: 8),
                
              TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            isRegister = !isRegister;
                          });
                          widget.viewModel.clearError();
                        },
                    child: Text(
                      isRegister
                        ? 'I already have an account. Log in'
                        : 'No account yet? Register',
                      ),
                  ),
                ],
              );
            },
         ),
        ),
    );
  }
}
