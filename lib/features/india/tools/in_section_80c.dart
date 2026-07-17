// lib/features/india/tools/in_section_80c.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INSection80C extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INSection80C({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INSection80C> createState() => _INSection80CState();
}

class _INSection80CState extends ConsumerState<INSection80C> {
  double _grossIncome = 1200000;
  double _hlPrincipal = 50000;
  double _ppf = 30000;
  double _elss = 20000;
  double _lic = 15000;
  double _nsc = 0;
  double _epf = 25000;
  double _fd = 0;
  int _taxSlab = 30; // 5, 20, 30
  String _regime = 'old'; // 'old', 'new'

  bool _calculated = false;
  double _calcGrossIncome = 1200000;
  double _calcHlPrincipal = 50000;
  double _calcPpf = 30000;
  double _calcElss = 20000;
  double _calcLic = 15000;
  double _calcNsc = 0;
  double _calcEpf = 25000;
  double _calcFd = 0;
  int _calcTaxSlab = 30;
  String _calcRegime = 'old';

  final GlobalKey _resultPanelKey = GlobalKey();

  void _reset() {
    setState(() {
      _grossIncome = 1200000;
      _hlPrincipal = 50000;
      _ppf = 30000;
      _elss = 20000;
      _lic = 15000;
      _nsc = 0;
      _epf = 25000;
      _fd = 0;
      _taxSlab = 30;
      _regime = 'old';
      _calculated = false;

      _calcGrossIncome = 1200000;
      _calcHlPrincipal = 50000;
      _calcPpf = 30000;
      _calcElss = 20000;
      _calcLic = 15000;
      _calcNsc = 0;
      _calcEpf = 25000;
      _calcFd = 0;
      _calcTaxSlab = 30;
      _calcRegime = 'old';
    });
  }

  void _calculate() {
    setState(() {
      _calculated = true;
      _calcGrossIncome = _grossIncome;
      _calcHlPrincipal = _hlPrincipal;
      _calcPpf = _ppf;
      _calcElss = _elss;
      _calcLic = _lic;
      _calcNsc = _nsc;
      _calcEpf = _epf;
      _calcFd = _fd;
      _calcTaxSlab = _taxSlab;
      _calcRegime = _regime;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultPanelKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  bool _areInputsChanged() {
    return _grossIncome != _calcGrossIncome ||
        _hlPrincipal != _calcHlPrincipal ||
        _ppf != _calcPpf ||
        _elss != _calcElss ||
        _lic != _calcLic ||
        _nsc != _calcNsc ||
        _epf != _calcEpf ||
        _fd != _calcFd ||
        _taxSlab != _calcTaxSlab ||
        _regime != _calcRegime;
  }

  String _fmt(double n) {
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    double total = _calcHlPrincipal + _calcPpf + _calcElss + _calcLic + _calcNsc + _calcEpf + _calcFd;
    if (_calcRegime == 'new') total = 0.0;
    final eligible = _calcRegime == 'old' ? (total > 150000 ? 150000.0 : total) : 0.0;
    final taxSaved = eligible * (_calcTaxSlab / 100);

    final labelCtrl = TextEditingController(text: 'Section 80C Deductions');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_section_80c'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Deductions', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Total Deductions ${_fmt(eligible)} · Tax Saved ${_fmt(taxSaved)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. FY 2024-25 80C)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05F00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Section 80C';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Section 80C',
        inputs: {
          'grossIncome': _calcGrossIncome,
          'hlPrincipal': _calcHlPrincipal,
          'ppf': _calcPpf,
          'elss': _calcElss,
          'lic': _calcLic,
          'nsc': _calcNsc,
          'epf': _calcEpf,
          'fd': _calcFd,
          'taxSlab': _calcTaxSlab.toDouble(),
          'regime': _calcRegime == 'old' ? 0.0 : 1.0,
        },
        results: {
          'eligibleDeductions': eligible,
          'taxSaved': taxSaved,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Deductions saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double total = _calcHlPrincipal + _calcPpf + _calcElss + _calcLic + _calcNsc + _calcEpf + _calcFd;
    if (_calcRegime == 'new') total = 0.0;
    final eligible = _calcRegime == 'old' ? (total > 150000 ? 150000.0 : total) : 0.0;
    final taxSaved = eligible * (_calcTaxSlab / 100);
    final taxable = _calcGrossIncome - eligible;
    final remaining = 150000 - total;
    final pct = (total / 150000).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Regime Toggles & Slab Toggles Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax Settings', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w700)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFE05F00), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Regime selectors
              Text('TAX REGIME', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _buildRegimeBtn('Old Regime (Deductions Allowed)', _regime == 'old', () => setState(() => _regime = 'old'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildRegimeBtn('New Regime (No 80C Allowed)', _regime == 'new', () => setState(() => _regime = 'new'))),
                ],
              ),

              const Divider(height: 24),

              // Slab selectors
              Text('EXPECTED TAX SLAB BRACKET', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildSlabBtn('5% Slab', _taxSlab == 5, () => setState(() => _taxSlab = 5))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildSlabBtn('20% Slab', _taxSlab == 20, () => setState(() => _taxSlab = 20))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildSlabBtn('30% Slab', _taxSlab == 30, () => setState(() => _taxSlab = 30))),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Investment details (Old Regime)', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w700)),
              const SizedBox(height: 16),

              _buildSliderRow('GROSS ANNUAL INCOME', _grossIncome, 200000, 5000000, 96, (v) => setState(() => _grossIncome = v)),
              _buildSliderRow('HOME LOAN PRINCIPAL', _hlPrincipal, 0, 200000, 40, (v) => setState(() => _hlPrincipal = v)),
              _buildSliderRow('PPF CONTRIBUTIONS', _ppf, 0, 150000, 30, (v) => setState(() => _ppf = v)),
              _buildSliderRow('ELSS MUTUAL FUNDS', _elss, 0, 150000, 30, (v) => setState(() => _elss = v)),
              _buildSliderRow('LIC PREMIUM', _lic, 0, 100000, 20, (v) => setState(() => _lic = v)),
              _buildSliderRow('EPF CONTRIBUTIONS', _epf, 0, 150000, 30, (v) => setState(() => _epf = v)),
              _buildSliderRow('TAX SAVER FD', _fd, 0, 150000, 30, (v) => setState(() => _fd = v)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE05F00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('⚙️ Calculate Section 80C Deductions', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),

        if (_calculated) ...[
          const SizedBox(height: 20),
          // Warning banner if inputs changed
          if (_areInputsChanged())
            Container(
              key: _resultPanelKey,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs changed. Tap Calculate Section 80C Deductions to update results.',
                      style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.amber[200]! : Colors.amber[900]!, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(key: _resultPanelKey, height: 0),

          // Results Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTIMATED 80C TAX SAVINGS', style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  _calcRegime == 'new' ? 'NIL (New Regime)' : _fmt(taxSaved),
                  style: AppTextStyles.playfair(size: 30, color: const Color(0xFFFFDEA0), weight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _resultBox('Total 80C Invested', _fmt(total)),
                    const SizedBox(width: 8),
                    _resultBox('Eligible Deduction', _fmt(eligible)),
                    const SizedBox(width: 8),
                    _resultBox('New Taxable Inc', _fmt(taxable)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Limit progress bar
          if (_calcRegime == 'old') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sec 80C Deductions Utilized', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                      Text('${(pct * 100).round()}%', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFFE05F00))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 8,
                      color: Colors.grey[200],
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(color: const Color(0xFFE05F00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Utilized: ${_fmt(eligible)}', style: AppTextStyles.dmSans(size: 10.5, color: theme.getMutedColor(context))),
                      Text(remaining > 0 ? 'Remaining: ${_fmt(remaining)}' : 'Limit Exhausted! ✅', style: AppTextStyles.dmSans(size: 10.5, color: theme.getMutedColor(context))),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          // Save bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              border: Border.all(color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save Deduction Report', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
                      Text('Save details for future reference', style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save', style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSliderRow(String title, double val, double min, double max, int div, ValueChanged<double> onChanged) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
            Text(_fmt(val), style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
          ],
        ),
        Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          divisions: div,
          activeColor: const Color(0xFFE05F00),
          inactiveColor: const Color(0xFFE05F00).withValues(alpha: 0.15),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRegimeBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE05F00) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFFE05F00) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w700,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSlabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE05F00) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFFE05F00) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w700,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _resultBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
