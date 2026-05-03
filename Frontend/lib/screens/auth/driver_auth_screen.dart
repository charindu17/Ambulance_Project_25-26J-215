import 'package:dileesara_project/screens/driver_home/driver_home_screen.dart';
import 'package:flutter/material.dart';
import '../../core/app_validations.dart';
import '../../services/services.dart';
import '../../utils/navigation_mixin.dart';
import '../../widgets/widgets.dart';

class DriverAuthScreen extends StatelessWidget {
  const DriverAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ambulance User'),
          centerTitle: true,
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Login'),
              Tab(text: 'Sign Up'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_DriverLoginForm(), _DriverSignupForm()],
        ),
      ),
    );
  }
}

class _DriverLoginForm extends StatefulWidget {
  const _DriverLoginForm();

  @override
  State<_DriverLoginForm> createState() => _DriverLoginFormState();
}

class _DriverLoginFormState extends State<_DriverLoginForm>
    with AppValidations, NavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _driverService = DriverService();
  late final StorageService _storageService;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initStorageService();
  }

  Future<void> _initStorageService() async {
    _storageService = await StorageService.getInstance();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _driverService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.isSuccess && response.driver != null) {
        await _storageService.saveDriver(response.driver!);
        if (!mounted) return;
        showSuccessSnackbar(context, 'Login successful!');
        pushReplacementTo(context, const DriverHomeScreen());
      } else {
        showErrorSnackbar(context, response.error ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/ambulance.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              AppTextField(
                controller: _emailController,
                labelText: 'Email/ Username',
                hintText: 'Enter your email/ username',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (value) {
                  return validateRequired(value, fieldName: 'Email') ??
                      validateEmail(value);
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter your password',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: (value) {
                  return validateRequired(value, fieldName: 'Password');
                },
                onFieldSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 24),

              AppLoadingButton(
                text: 'Login',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverSignupForm extends StatefulWidget {
  const _DriverSignupForm();

  @override
  State<_DriverSignupForm> createState() => _DriverSignupFormState();
}

class _DriverSignupFormState extends State<_DriverSignupForm>
    with AppValidations, NavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _nicController = TextEditingController();
  final _staffIdController = TextEditingController();

  final _driverService = DriverService();
  late final StorageService _storageService;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initStorageService();
  }

  Future<void> _initStorageService() async {
    _storageService = await StorageService.getInstance();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _vehicleNumberController.dispose();
    _nicController.dispose();
    _staffIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final staffId = _staffIdController.text.trim();
      final response = await _driverService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        vehicleNumber: _vehicleNumberController.text.trim(),
        nic: _nicController.text.trim(),
        staffId: staffId.isNotEmpty ? staffId : null,
      );

      if (!mounted) return;

      if (response.isSuccess && response.driver != null) {
        await _storageService.saveDriver(response.driver!);
        if (!mounted) return;
        showSuccessSnackbar(context, 'Account created successfully!');
        pushReplacementTo(context, const DriverHomeScreen());
      } else {
        showErrorSnackbar(context, response.error ?? 'Registration failed');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/ambulance.png', height: 64, width: 64),
              const SizedBox(height: 16),
              Text(
                'Create Ambulance User Account',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in your details to get started',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              AppTextField(
                controller: _nameController,
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  return validateRequired(value, fieldName: 'Name') ??
                      validateMinLength(value, 2, fieldName: 'Name');
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (value) {
                  return validateRequired(value, fieldName: 'Email') ??
                      validateEmail(value);
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Create a password',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: (value) {
                  return validateRequired(value, fieldName: 'Password') ??
                      validatePassword(value);
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _vehicleNumberController,
                labelText: 'Vehicle Number',
                hintText: 'Enter your vehicle number',
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.directions_car_outlined),
                validator: (value) {
                  return validateRequired(value, fieldName: 'Vehicle Number');
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _nicController,
                labelText: 'NIC',
                hintText: 'Enter your NIC number',
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: (value) {
                  return validateRequired(value, fieldName: 'NIC');
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _staffIdController,
                labelText: 'Staff ID (Optional)',
                hintText: 'Enter your staff ID',
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.work_outline),
              ),
              const SizedBox(height: 24),

              AppLoadingButton(
                text: 'Create Account',
                isLoading: _isLoading,
                onPressed: _handleSignup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
