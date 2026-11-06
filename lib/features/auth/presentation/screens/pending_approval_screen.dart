import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../controllers/auth_controller.dart';

/// Screen displayed after a new spare parts owner registers and waits for admin approval.
class PendingApprovalScreen extends ConsumerStatefulWidget {
  final String? businessName;
  final String? phoneNumber;

  const PendingApprovalScreen({
    super.key,
    this.businessName,
    this.phoneNumber,
  });

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _checkApprovalStatus() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final authRepo = ref.read(authRepositoryProvider);
    final userRes = await authRepo.currentUser();

    if (!mounted) return;
    setState(() => _isChecking = false);

    userRes.when(
      onSuccess: (user) {
        if (user != null && user.status.toUpperCase() == 'ACTIVE') {
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  'መለያዎ እስካሁን አልተፈቀደም። እባክዎ ጥቂት ይጠብቁ።',
                  'Your account is still pending administrator approval. Please check again soon.',
                ),
                style: const TextStyle(color: KeraColors.navy900, fontWeight: FontWeight.w600),
              ),
              backgroundColor: KeraColors.brandOrange,
            ),
          );
        }
      },
      onFailure: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'መለያዎ በማጽደቅ ላይ ነው። እባክዎ ጥቂት ይጠብቁ።',
                'Your account is still pending administrator review.',
              ),
              style: const TextStyle(color: KeraColors.navy900, fontWeight: FontWeight.w600),
            ),
            backgroundColor: KeraColors.brandOrange,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bName = widget.businessName ?? context.tr('አዲሱ ሱቅ', 'Your Store');
    final phone = widget.phoneNumber ?? '';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar: Language switcher
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  KeraLogoWidget(size: 36, borderRadius: 10),
                  LanguageSegmentedSwitch(),
                ],
              ),
              const SizedBox(height: 36),

              // Hero Illustration Container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F264A) : KeraColors.orange100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: KeraColors.brandOrange,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KeraColors.brandOrange.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: KeraColors.brandOrange,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                context.tr('መለያዎ በማጽደቅ ላይ ነው', 'Account Pending Approval'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                context.tr(
                  'የምዝገባ ጥያቄዎ ለአስተዳዳሪው ደርሷል። ፍቃድ እንደተሰጠው በቀጥታ ወደ ሲስተሙ መግባት ይችላሉ።',
                  'Your registration has been submitted to the administrator. Once approved, you can log in.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 28),

              // Store Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080C2340),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F264A) : KeraColors.navy50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: KeraColors.brandNavy,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: context.borderColor),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('የመለያ ሁኔታ', 'Status'),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F264A) : KeraColors.orange100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: KeraColors.brandOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('በማረጋገጥ ላይ', 'Pending Review'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: KeraColors.orange700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Primary: Check Status button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkApprovalStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(KeraColors.navy900),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20, color: KeraColors.navy900),
                  label: Text(
                    context.tr('ሁኔታውን አረጋግጥ', 'Check Status'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: KeraColors.navy900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeraColors.brandOrange,
                    foregroundColor: KeraColors.navy900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary: Back to Login
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    context.tr('ወደ መግቢያ ገጽ ተመለስ', 'Back to Login'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
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

