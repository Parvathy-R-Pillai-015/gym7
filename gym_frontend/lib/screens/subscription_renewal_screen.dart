import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SubscriptionRenewalScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const SubscriptionRenewalScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<SubscriptionRenewalScreen> createState() =>
      _SubscriptionRenewalScreenState();
}

class _SubscriptionRenewalScreenState extends State<SubscriptionRenewalScreen> {
  int _selectedMonths = 1;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'gpay';
  final List<Map<String, String>> _paymentMethods = [
    {'key': 'gpay', 'label': 'GPay'},
    {'key': 'phonepe', 'label': 'PhonePe'},
    {'key': 'paytm', 'label': 'Paytm'},
    {'key': 'credit_card', 'label': 'Credit Card'},
    {'key': 'cash', 'label': 'Cash'},
  ];

  final List<Map<String, dynamic>> _renewalOptions = [
    {'months': 1, 'amount': 399, 'discount': 0},
    {'months': 2, 'amount': 499, 'discount': 5},
    {'months': 3, 'amount': 699, 'discount': 8},
    {'months': 6, 'amount': 1199, 'discount': 15},
    {'months': 8, 'amount': 1599, 'discount': 18},
    {'months': 12, 'amount': 2199, 'discount': 25},
  ];

  Future<void> _renewSubscription() async {
    setState(() => _isProcessing = true);

    try {
      final option = _renewalOptions.firstWhere(
        (o) => o['months'] == _selectedMonths,
      );

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/subscription/renew/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'renewal_months': _selectedMonths,
          'payment_method': _selectedPaymentMethod,
        }),
      );

      setState(() => _isProcessing = false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Subscription renewed! Valid until ${data['new_end_date'].split('T')[0]}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Renewal failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _renewalOptions.firstWhere(
      (o) => o['months'] == _selectedMonths,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renew Subscription'),
        backgroundColor: const Color(0xFF7B4EFF),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B4EFF),
                      const Color(0xFFBB86FC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Continue Your Fitness Journey',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Renew your subscription to keep accessing workouts and nutrition plans',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Renewal Options
              const Text(
                'Select Renewal Period',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Column(
                children: _renewalOptions
                    .map((option) {
                      final months = option['months'];
                      final amount = option['amount'];
                      final discount = option['discount'];
                      final isSelected = _selectedMonths == months;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedMonths = months);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF7B4EFF)
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? const Color(0xFF7B4EFF).withOpacity(0.05)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: months,
                                  groupValue: _selectedMonths,
                                  onChanged: (value) {
                                    setState(
                                        () => _selectedMonths = value ?? 1);
                                  },
                                  activeColor: const Color(0xFF7B4EFF),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$months Month${months > 1 ? 's' : ''}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (discount > 0)
                                        Text(
                                          'Save $discount%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹$amount',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7B4EFF),
                                      ),
                                    ),
                                    Text(
                                      '₹${(amount / months).toStringAsFixed(0)}/month',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 30),
              // Price Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Renewal Amount:',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          '₹${selectedOption['amount']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B4EFF),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'You will get:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${selectedOption['months']} Month${selectedOption['months'] > 1 ? 's' : ''} Access',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _paymentMethods.map((m) {
                  final isSelected = _selectedPaymentMethod == m['key'];
                  return ChoiceChip(
                    label: Text(m['label']!),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedPaymentMethod = m['key']!);
                    },
                    selectedColor: const Color(0xFF7B4EFF).withOpacity(0.15),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Renew Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _renewSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4EFF),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Renew Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7B4EFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B4EFF),
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
