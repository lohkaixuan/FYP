import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/BudgetController.dart';

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  late BudgetController _budgetController;
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountLimitController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  DateTime? _cycleStart;
  DateTime? _cycleEnd;

  @override
  void initState() {
    super.initState();
    _budgetController = Get.find<BudgetController>();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final startDate = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: DateTime(startDate.year + 5),
    );
    if (selectedDate != null) {
      setState(() {
        if (isStart) {
          _cycleStart = selectedDate;
          _cycleEnd ??= selectedDate.add(const Duration(days: 30));
        } else {
          _cycleEnd = selectedDate;
        }
      });
    }
  }

  bool _validate() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    if (_cycleStart == null || _cycleEnd == null) {
      Get.snackbar('Error', 'Please select the active period of the budget.');
      return false;
    } else {
      if (_cycleStart!.isAfter(_cycleEnd!) ||
          _cycleStart!.isAtSameMomentAs(_cycleEnd!)) {
        Get.snackbar('Error',
            'Please select an active date before the end date of the budget.');
        return false;
      }
    }
    return true;
  }

  void _submitBudget() async {
    if (_validate()) {
      await _budgetController.createBudget(
        Budget(
            category: _categoryController.text,
            limitAmount: double.tryParse(_amountLimitController.text) ?? 0,
            start: _cycleStart!,
            end: _cycleEnd!),
      );
    }

    if (_budgetController.lastOk.value != "") {
      Get.snackbar('Success', _budgetController.lastOk.value);
      Get.offAllNamed('/home');
    } else if (_budgetController.lastError.value != "") {
      Get.snackbar('Error', _budgetController.lastError.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: 'Create Budget',
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit Amount (RM)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid positive amount limit.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(_cycleStart == null
                    ? 'Select Cycle Start Date'
                    : 'Start: ${_cycleStart!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(true),
              ),
              ListTile(
                title: Text(_cycleEnd == null
                    ? 'Select Cycle End Date'
                    : 'End: ${_cycleEnd!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitBudget,
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
