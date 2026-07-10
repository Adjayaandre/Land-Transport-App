import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideUp =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
        );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(10);
    final borderColor = theme.dividerTheme.color ?? scheme.outline;
    final focusColor = scheme.primary;
    final hintColor = scheme.onSurface.withValues(alpha: 0.45);
    final iconColor = scheme.onSurface.withValues(alpha: 0.55);

    OutlineInputBorder outlineBorder({Color? color, double width = 1}) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color ?? borderColor, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: iconColor)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: outlineBorder(),
      enabledBorder: outlineBorder(),
      focusedBorder: outlineBorder(color: focusColor, width: 1.5),
      errorBorder: outlineBorder(color: scheme.error),
      focusedErrorBorder: outlineBorder(color: scheme.error, width: 1.5),
      errorStyle: TextStyle(color: scheme.error, fontSize: 12),
    );
  }

  SystemUiOverlayStyle _overlayStyle(bool isDark) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? AppColors.darkSurface : AppColors.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        setState(() => _errorMessage = next.errorMessage);
      } else if (next.status == AuthStatus.loading) {
        setState(() => _errorMessage = null);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle(isDarkMode),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 48),
                          _buildForm(authState),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: Material(
                    color: scheme.surface
                        .withValues(alpha: isDarkMode ? 0.6 : 0.9),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            size: 20,
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mode Gelap',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                          Switch(
                            value: isDarkMode,
                            onChanged: (enabled) => ref
                                .read(themeModeProvider.notifier)
                                .setDarkMode(enabled),
                          ),
                        ],
                      ),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'LT',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: 'MS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Land Transport Management System',
          style: AppTextColors.style(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.65),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !authState.isLoading,
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
            },
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: _inputDecoration(
              hint: 'Username / Email',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.errorRequired;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !authState.isLoading,
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
            },
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: _inputDecoration(
              hint: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                  size: 20,
                ),
                onPressed: authState.isLoading
                    ? null
                    : () =>
                        setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.errorRequired;
              }
              if (value.length < 6) return 'Minimal 6 karakter';
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.danger),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                disabledBackgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.6),
                disabledForegroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.8),
              ),
              child: authState.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}