import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_header_bar.dart';

/// Screen 4: Add New Tenant Owner matching Add owner.png.
class AdminAddOwnerScreen extends ConsumerStatefulWidget {
  const AdminAddOwnerScreen({super.key});

  @override
  ConsumerState<AdminAddOwnerScreen> createState() => _AdminAddOwnerScreenState();
}

class _AdminAddOwnerScreenState extends ConsumerState<AdminAddOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedPlan = 'Free trial';
  String _selectedLanguage = 'አማርኛ (default)';
  bool _approveNow = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveOwner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // In local offline mode or server, simulate registration
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_businessNameController.text} added successfully!'),
          backgroundColor: AdminColors.navy,
        ),
      );

      // Invalidate owners list
      await ref.read(adminOwnersProvider.notifier).loadOwners();
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding owner: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Navy Header matching Add owner.png
            _buildNavyHeader(context),

            // 2. Form Fields (Add owner.png)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business Name
                    _buildFieldLabel('የንግድ ስም · Business name'),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      controller: _businessNameController,
                      hintText: 'Spare parts business name',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter business name' : null,
                    ),
                    const SizedBox(height: 18),

                    // Phone Number
                    _buildFieldLabel('ስልክ ቁጥር · Phone number'),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      controller: _phoneController,
                      hintText: '09•• ••• •••',
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().length < 9 ? 'Please enter valid phone' : null,
                    ),
                    const SizedBox(height: 18),

                    // Temporary Password
                    _buildFieldLabel('የይለፍ ቃል · Temporary password'),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      controller: _passwordController,
                      hintText: '••••••••',
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                    ),
                    const SizedBox(height: 18),

                    // Plan Dropdown
                    _buildFieldLabel('እቅድ · Plan'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedPlan,
                      items: const ['Free trial', 'Standard', 'Pro'],
                      onChanged: (val) => setState(() => _selectedPlan = val!),
                    ),
                    const SizedBox(height: 18),

                    // Language Dropdown
                    _buildFieldLabel('ቋንቋ · Language'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedLanguage,
                      items: const ['አማርኛ (default)', 'English'],
                      onChanged: (val) => setState(() => _selectedLanguage = val!),
                    ),
                    const SizedBox(height: 20),

                    // Approve Now Switch Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5EBF2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'አሁኑኑ አጽድቅ · Approve now',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C2340),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Owner can log in immediately',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5E6D82),
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _approveNow,
                            activeThumbColor: const Color(0xFF0C2340),
                            onChanged: (val) => setState(() => _approveNow = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Note Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'The owner gets a separate, private inventory. Only phone, business name and password are required.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Owner Primary Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.keraOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _handleSaveOwner,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'አስቀምጥ · Save owner',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavyHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AdminHeaderIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => context.pop(),
              ),
              const Text(
                'ባለቤት ጨምር · Add owner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.settings_suggest_rounded,
                    color: AdminColors.headerNavy,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0C2340),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(fontSize: 15, color: Color(0xFF0C2340)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF5E6D82)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

