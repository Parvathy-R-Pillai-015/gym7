import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class AddTrainerScreen extends StatefulWidget {
  const AddTrainerScreen({super.key});

  @override
  State<AddTrainerScreen> createState() => _AddTrainerScreenState();
}

class _AddTrainerScreenState extends State<AddTrainerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _experienceController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedSpecialization;
  String? _selectedJoiningPeriod;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _specializationOptions = [
    'Weight Training',
    'Cardio',
    'Yoga',
    'CrossFit',
    'Personal Training',
    'Nutrition',
    'Pilates',
    'Zumba',
    'Boxing',
    'Aerobics'
  ];
  final List<String> _joiningPeriodOptions = [
    '7 days',
    '2 weeks',
    '3 months',
    '6 months',
    '1 year'
  ];

  String _generatePassword() {
    // Password format: trainername+tr
    return '${_nameController.text.trim()}+tr';
  }

  Future<void> _submitTrainer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null || _selectedSpecialization == null || _selectedJoiningPeriod == null) {
      _showError('Please fill all dropdown fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Generate password for trainer
    final password = _generatePassword();

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/trainers/create/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text.trim(),
          'emailid': _emailController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'gender': _selectedGender,
          'experience': _experienceController.text.trim(),
          'specialization': _selectedSpecialization,
          'joining_period': _selectedJoiningPeriod,
          'password': password,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        if (mounted) {
          _showSuccessDialog(password);
        }
      } else {
        _showError(data['message'] ?? 'Failed to add trainer');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Network error: $e');
    }
  }

  void _showSuccessDialog(String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Trainer Added Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trainer has been registered successfully.'),
            const SizedBox(height: 15),
            const Text(
              'Login Credentials:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Email: ${_emailController.text}'),
            const SizedBox(height: 5),
            Text('Password: $password'),
            const SizedBox(height: 15),
            const Text(
              'Please save these credentials and share with the trainer.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Add Trainer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7B4EFF),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trainer Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email ID',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Mobile Number
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.length != 10) {
                    return 'Mobile number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Years of Experience
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Years of Working Experience',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter years of experience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Specialization
              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  prefixIcon: const Icon(Icons.fitness_center),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _specializationOptions.map((spec) {
                  return DropdownMenuItem(
                    value: spec,
                    child: Text(spec),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialization = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select specialization';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Immediate Joiners
              DropdownButtonFormField<String>(
                value: _selectedJoiningPeriod,
                decoration: InputDecoration(
                  labelText: 'Immediate Joiners',
                  prefixIcon: const Icon(Icons.schedule),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _joiningPeriodOptions.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedJoiningPeriod = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select joining period';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTrainer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SUBMIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
