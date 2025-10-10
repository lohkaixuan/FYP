import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Login(),
    ),
  );
}

class Login extends StatefulWidget {
  const Login({super.key});

  // This widget is the root of your application.
  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
// Controller for email and phone input fields
  bool useEmailLogin = false; // Toggle between email and phone login
  bool passwordVisible = false; // Toggle password visibility

  late List<Map<String, dynamic>> loginField;

  @override
  void initState() {
    super.initState();
    _updateLoginField();
  }

  void _updateLoginField() {
    loginField = [
      useEmailLogin //switch between email and phone
          ? {
              'label': 'Email',
              'key': 'email',
              'icon': Icons.email,
              //'controller': TextEditingController(),
              'validator': (v) => v!.isEmpty ? 'Required' : null
            }
          : {
              'label': 'Phone',
              'key': 'phone',
              'icon': Icons.phone,
              //'controller': TextEditingController(),
              'validator': (v) => v!.isEmpty ? 'Required' : null
            },
      {
        'label': 'Password',
        'key': 'password',
        'icon': Icons.lock,
        //'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SwitchListTile(
                title: Text(useEmailLogin ? 'Email Login' : 'Phone Login'),
                value: useEmailLogin,
                onChanged: (value) {
                  setState(() {
                    useEmailLogin = value;
                    _updateLoginField(); //rebuild field list
                  });
                },
              ),
              ...loginField.map((field) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      keyboardType: field['key'] == 'email'
                          ? TextInputType.emailAddress
                          : field['key'] == 'phone'
                              ? TextInputType.phone
                              : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: field['label'] as String,
                        prefixIcon: Icon(field['icon'] as IconData),
                        border: const OutlineInputBorder(),
                        suffixIcon: field['key'] == 'password'
                            ? IconButton(
                                icon: Icon(
                                  passwordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    passwordVisible = !passwordVisible;
                                  });
                                },
                              )
                            : null,
                      ),
                      obscureText:
                          field['key'] == 'password' && !passwordVisible,
                      //validator: field['validator'],
                    ),
                  )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  /*final id = loginField[0]['controller'].text.trim();
                  final password = loginField[1]['controller'].text.trim();

                  if (id.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                      ),
                    );
                    return;
                  }*/

                  if (useEmailLogin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid email address'),
                      ),
                    );
                    return;
                  }
                },
                child: const Text('Login'),
              ),
              /*Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  const Text('New user? '),
                  GestureDetector(
                onTap: () => Get.toNamed('/register'),
                child: const Text("Sign Up New Account Here",
                style: TextStyle(
                  color: Colors.blueAccent),))
                ],
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
