import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/discount.dart';
import '../models/discount_provider.dart';
import '../styles/colors.dart';

class AddDiscountScreen extends StatefulWidget {
  final Discount? discount;

  const AddDiscountScreen({
    Key? key,
    this.discount,
  }) : super(key: key);

  @override
  State<AddDiscountScreen> createState() => _AddDiscountScreenState();
}

class _AddDiscountScreenState extends State<AddDiscountScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _codeController = TextEditingController();
  final _storeController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  
  final List<String> _categories = [
    'Electronics',
    'Fashion',
    'Groceries',
    'Food',
    'Travel',
    'Entertainment',
    'Health',
    'Beauty',
    'Home',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    
    // If editing an existing discount, populate the form
    if (widget.discount != null) {
      _titleController.text = widget.discount!.title;
      _descriptionController.text = widget.discount!.description;
      _discountPercentageController.text = widget.discount!.discountPercentage.toString();
      _codeController.text = widget.discount!.code;
      _storeController.text = widget.discount!.store;
      _selectedCategory = widget.discount!.category;
      _expiryDate = widget.discount!.expiryDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _codeController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _saveDiscount() {
    if (_formKey.currentState!.validate()) {
      final discountProvider = Provider.of<DiscountProvider>(context, listen: false);
      
      final discount = Discount(
        id: widget.discount?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        discountPercentage: double.parse(_discountPercentageController.text),
        code: _codeController.text,
        store: _storeController.text,
        category: _selectedCategory,
        expiryDate: _expiryDate,
        imageUrl: widget.discount?.imageUrl ?? '',
        isFavorite: widget.discount?.isFavorite ?? false,
      );
      
      if (widget.discount == null) {
        // Add new discount
        discountProvider.addDiscount(discount);
      } else {
        // Update existing discount
        discountProvider.updateDiscount(discount);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.discount != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Discount' : 'Add Discount'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. 50% Off on Electronics',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the discount offer',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Discount percentage and code
                Row(
                  children: [
                    // Discount percentage
                    Expanded(
                      child: TextFormField(
                        controller: _discountPercentageController,
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                          hintText: 'e.g. 50',
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final percentage = double.tryParse(value);
                          if (percentage == null || percentage <= 0 || percentage > 100) {
                            return 'Invalid %';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Discount code
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Discount Code',
                          hintText: 'e.g. SUMMER50',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Store
                TextFormField(
                  controller: _storeController,
                  decoration: const InputDecoration(
                    labelText: 'Store',
                    hintText: 'e.g. Amazon, Walmart',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a store name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Expiry date
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(_expiryDate),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveDiscount,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        isEditing ? 'Update Discount' : 'Add Discount',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 