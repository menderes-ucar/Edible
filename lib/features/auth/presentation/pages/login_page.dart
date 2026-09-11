import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/country_list.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({this.returnLocation = AppRoutes.home, super.key});

  final String returnLocation;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _hometownController = TextEditingController();
  String? _selectedCountryCode;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String? _gender;
  bool _signUpMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _hometownController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final hometown = _hometownController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = context.read<AuthProvider>();

    auth.clearError();

    if (_signUpMode && firstName.isEmpty) {
      _showMessage(context.l10n.text('firstName'));
      return;
    }
    if (_signUpMode && lastName.isEmpty) {
      _showMessage(context.l10n.text('lastName'));
      return;
    }
    if (_signUpMode && (age == null || age < 13 || age > 120)) {
      _showMessage('13–120 arası geçerli bir yaş gir.');
      return;
    }
    if (_signUpMode && hometown.isEmpty) {
      _showMessage(context.l10n.text('hometown'));
      return;
    }
    if (_signUpMode && (_gender == null || _gender!.isEmpty)) {
      _showMessage(context.l10n.text('gender'));
      return;
    }
    if (!_looksLikeEmail(email)) {
      _showMessage(context.l10n.text('invalidEmail'));
      return;
    }
    if (password.length < 6) {
      _showMessage(context.l10n.text('passwordTooShort'));
      return;
    }

    final success = _signUpMode
        ? await auth.signUp(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            age: age!,
            hometown: hometown,
            gender: _gender!,
          )
        : await auth.signIn(email: email, password: password);

    if (!mounted || !success) return;

    if (auth.isAuthenticated) {
      context.go(widget.returnLocation);
      return;
    }

    if (_signUpMode) {
      _showMessage(context.l10n.text('checkEmailToConfirm'));
      setState(() => _signUpMode = false);
    }
  }

  void _toggleMode(AuthProvider auth) {
    if (auth.isLoading) return;
    auth.clearError();
    setState(() {
      _signUpMode = !_signUpMode;
      _obscurePassword = true;
    });
    _passwordController.clear();
  }

  bool _looksLikeEmail(String value) {
    final at = value.indexOf('@');
    final dot = value.lastIndexOf('.');
    return at > 0 && dot > at + 1 && dot < value.length - 1;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _AuthTravelHero(isSignUp: _signUpMode),
            const SizedBox(height: 14),
            _ModeSwitcher(
              isSignUp: _signUpMode,
              onChanged: auth.isLoading ? null : (value) {
                if (value != _signUpMode) _toggleMode(auth);
              },
            ),
            const SizedBox(height: 12),
            _AuthForm(auth: auth, signUp: _signUpMode, l10n: l10n, parent: this),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () => context.go(AppRoutes.home),
              icon: const Icon(Icons.explore_outlined),
              label: Text(l10n.text('continueAsGuest')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                backgroundColor: const Color(0xFF383838),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countryField(String label) {
    final selected = _selectedCountryCode == null
        ? null
        : countryOptions.where((e) => e.code == _selectedCountryCode).firstOrNull;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickCountry,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.public_rounded),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          selected?.name ?? label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected == null ? AppColors.textMuted : AppColors.textPrimary,
            fontWeight: selected == null ? FontWeight.w500 : FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Future<void> _pickCountry() async {
    final searchController = TextEditingController();
    var filtered = List<CountryOption>.from(countryOptions);
    final selected = await showModalBottomSheet<CountryOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            height: MediaQuery.sizeOf(context).height * .78,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.surfaceDeep, borderRadius: BorderRadius.circular(99))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (query) => setSheetState(() {
                      final q = query.trim().toLowerCase();
                      filtered = countryOptions.where((country) => country.name.toLowerCase().contains(q) || country.code.toLowerCase().contains(q)).toList();
                    }),
                    decoration: InputDecoration(
                      labelText: 'Ülke ara',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(onPressed: () => searchController.clear(), icon: const Icon(Icons.clear_rounded)),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final country = filtered[index];
                      final isSelected = country.code == _selectedCountryCode;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceDeep,
                          child: Text(country.code, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : AppColors.textPrimary)),
                        ),
                        title: Text(country.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        onTap: () => Navigator.of(sheetContext).pop(country),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    searchController.dispose();
    if (!mounted || selected == null) return;
    setState(() {
      _selectedCountryCode = selected.code;
      _hometownController.text = selected.name;
    });
  }

  Widget _field(String label, IconData icon, TextEditingController controller) {
    return TextField(controller: controller, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)));
  }

  Widget _genderChip(String label, String value, IconData icon) {
    final selected = _gender == value;
    return ChoiceChip(selected: selected, onSelected: (v) { if (v) setState(() => _gender = value); }, avatar: Icon(icon, size: 17, color: selected ? AppColors.primaryDark : AppColors.textMuted), label: Text(label));
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({required this.auth, required this.signUp, required this.l10n, required this.parent});
  final AuthProvider auth;
  final bool signUp;
  final AppLocalizations l10n;
  final _LoginPageState parent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 15),
      decoration: BoxDecoration(
        color: AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withValues(alpha: .12)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .10), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark, size: 20)), const SizedBox(width: 10), Expanded(child: Text(signUp ? l10n.text('createExplorerAccount') : l10n.text('welcomeBackExplorer'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)))]),
        const SizedBox(height: 6),
        Text(signUp ? l10n.text('registerSubtitle') : l10n.text('loginSubtitle'), style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.35)),
        const SizedBox(height: 18),
        if (signUp) ...[
          Row(children: [Expanded(child: parent._field(l10n.text('firstName'), Icons.person_outline, parent._firstNameController)), const SizedBox(width: 10), Expanded(child: parent._field(l10n.text('lastName'), Icons.badge_outlined, parent._lastNameController))]),
          const SizedBox(height: 11),
          Row(children: [Expanded(child: TextField(controller: parent._ageController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.text('age'), prefixIcon: const Icon(Icons.cake_outlined)))), const SizedBox(width: 10), Expanded(child: parent._countryField(l10n.text('hometown')))]),
          const SizedBox(height: 14),
          Text(l10n.text('gender'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 7, runSpacing: 7, children: [parent._genderChip(l10n.text('female'), 'female', Icons.woman_rounded), parent._genderChip(l10n.text('male'), 'male', Icons.man_rounded), parent._genderChip(l10n.text('nonBinary'), 'non_binary', Icons.people_outline_rounded), parent._genderChip(l10n.text('preferNotToSay'), 'prefer_not_to_say', Icons.more_horiz_rounded)]),
          const SizedBox(height: 14),
        ],
        TextField(controller: parent._emailController, focusNode: parent._emailFocusNode, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.email], onSubmitted: (_) => parent._passwordFocusNode.requestFocus(), decoration: InputDecoration(labelText: l10n.text('email'), prefixIcon: const Icon(Icons.mail_outline_rounded))),
        const SizedBox(height: 10),
        TextField(controller: parent._passwordController, focusNode: parent._passwordFocusNode, obscureText: parent._obscurePassword, textInputAction: TextInputAction.done, autofillHints: [signUp ? AutofillHints.newPassword : AutofillHints.password], onSubmitted: (_) { if (!auth.isLoading) parent._submit(); }, decoration: InputDecoration(labelText: l10n.text('password'), prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: auth.isLoading ? null : () => parent.setState(() => parent._obscurePassword = !parent._obscurePassword), icon: Icon(parent._obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
        if (auth.errorMessage != null) ...[
          const SizedBox(height: 11),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: .08), borderRadius: BorderRadius.circular(15)), child: Text(AppErrorPresenter.message(context, auth.errorMessage), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: auth.isLoading ? null : parent._submit, child: auth.isLoading ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l10n.text(signUp ? 'createAccount' : 'signIn')))),
        const SizedBox(height: 4),
        Center(child: TextButton(onPressed: auth.isLoading ? null : () => parent._toggleMode(auth), child: Text(l10n.text(signUp ? 'alreadyHaveAccountSignIn' : 'newToEdibleCreateAccount')))),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.primaryDark), const SizedBox(width: 5), Text(l10n.text('secureAccount'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))]),
      ]),
    );
  }
}

class _AuthTravelHero extends StatelessWidget {
  const _AuthTravelHero({required this.isSignUp});
  final bool isSignUp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 214,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF383838),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(children: [
        Positioned(right: -38, top: -46, child: _Bubble(size: 160, opacity: .07)),
        Positioned(left: -50, bottom: -74, child: _Bubble(size: 160, opacity: .06)),
        Positioned.fill(child: CustomPaint(painter: _TravelRoutePainter())),
        Positioned(right: 24, top: 28, child: Container(width: 58, height: 58, decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(19)), child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primaryDark, size: 28))),
        Positioned(left: 22, top: 22, child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(999)), child: const Text('EDIBLE · TRAVEL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.6)))),
        Positioned(left: 22, bottom: 22, right: 22, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isSignUp ? l10n.text('joinEdible') : l10n.text('welcomeBackExplorer'), maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 27, height: 1.02, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(isSignUp ? 'Rotanı kaydet, şehirleri keşfet, kendi seyahat hikâyeni oluştur.' : 'Bir sonraki rotanı kaldığın yerden keşfet.', maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)),
          const SizedBox(height: 11),
          Wrap(spacing: 7, children: const [
            _TravelPill(icon: Icons.location_on_rounded, text: 'Şehirler'),
            _TravelPill(icon: Icons.restaurant_rounded, text: 'Lezzetler'),
            _TravelPill(icon: Icons.map_rounded, text: 'Rotalar'),
          ]),
        ])),
      ]),
    );
  }
}

class _TravelPill extends StatelessWidget {
  const _TravelPill({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: AppColors.orangeSoft), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))]));
}

class _TravelRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.orangeSoft.withValues(alpha: .28)..style = PaintingStyle.stroke..strokeWidth = 2;
    final path = Path()..moveTo(size.width * .12, size.height * .68)..cubicTo(size.width * .30, size.height * .32, size.width * .48, size.height * .80, size.width * .70, size.height * .45)..cubicTo(size.width * .78, size.height * .30, size.width * .86, size.height * .42, size.width * .91, size.height * .27);
    canvas.drawPath(path, paint);
    final dotPaint = Paint()..color = AppColors.orangeSoft;
    for (final point in [Offset(size.width*.12,size.height*.68), Offset(size.width*.70,size.height*.45), Offset(size.width*.91,size.height*.27)]) canvas.drawCircle(point, 4, dotPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});
  final double size; final double opacity;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)));
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.isSignUp, required this.onChanged});
  final bool isSignUp; final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _ModeItem(label: context.l10n.text('signIn'), selected: !isSignUp, onTap: onChanged == null ? null : () => onChanged!(false))),
    Expanded(child: _ModeItem(label: context.l10n.text('createAccount'), selected: isSignUp, onTap: onChanged == null ? null : () => onChanged!(true))),
  ]);
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({required this.label, required this.selected, required this.onTap});
  final String label; final bool selected; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(color: selected ? AppColors.darkNavy : Colors.transparent, borderRadius: BorderRadius.circular(17), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w900))))));
}
