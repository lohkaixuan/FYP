import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Register(),
    ),
  );
}

class Register extends StatefulWidget{
  const Register({super.key});

  @override 
  State<Register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register>{
  bool registerMerchant = false; // Toggle between user and merchant registration
  bool passwordVisible = false; // Toggle password visibility
  late List<Map<String, dynamic>> registerField;

  @override
  void initState() {
    super.initState();
    _updateRegisterField();
  }

  void _updateRegisterField(){
    registerField = [
      {
        'label': 'Full Name',
        'key': 'fullName',
        'icon': Icons.person,
        //'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
      {
        'label': 'Email',
        'key': 'email',
        'icon': Icons.email,
        //'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
      {
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
      {
        'label': 'Confirm Password',
        'key': 'Confirm password',
        'icon': Icons.lock,
        //'controller': TextEditingController(),
        'validator': (v) => v!.isEmpty ? 'Required' : null
      },
    ];
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          heightFactor: 1.2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SwitchListTile(
                title: Text(registerMerchant ? 'Registering as Merchant' : 'Registering as User'),
                value: registerMerchant,
                onChanged: (value) {
                  setState(() {
                    registerMerchant = value;
                    _updateRegisterField();
                  });
                },
              ),
              ...registerField.map((field) => Container(
                height: 100,
                padding: const EdgeInsets.all(30.0),
                child:TextFormField(
                  keyboardType: field['key'] == 'email'
                      ? TextInputType.emailAddress
                      : field['key'] == 'phone'
                          ? TextInputType.phone
                          : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: field['label'] as String,
                            prefixIcon: Icon(field['icon'] as IconData),
                            suffixIcon: field['key'] == 'password' || field['key'] == 'Confirm password'
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
                                obscureText: field['key'] == 'password' && !passwordVisible,
                          ),
                )),
                if(registerMerchant)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const Text('Please upload your business license:'),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Implement image picker functionality here
                          //final ImagePicker picker = ImagePicker();
                          //final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          //setState(() {
                            // Handle the selected image
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Choose File'),
                      ),
                      //if (_businessImage != Null)
                      //Image.file(File(_businessImage!.path), height: 100),
                    ]
                  ),
                ),
                
                    
                ElevatedButton(
                  onPressed:() {
                    if (registerMerchant) {
                      // Handle merchant registration
                    } else {
                      // Handle user registration
                    }
                  }, 
                  child: const Text('Register'),
                )
            ],
          )
        ))
    );
  }
}