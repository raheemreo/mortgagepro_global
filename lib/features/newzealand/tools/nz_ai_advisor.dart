// lib/features/newzealand/tools/nz_ai_advisor.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../../providers/nz_rates_provider.dart';
import '../../../services/remote_config_service.dart';

class NZAIAdvisorScreen extends ConsumerStatefulWidget {
  const NZAIAdvisorScreen({super.key});

  @override
  ConsumerState<NZAIAdvisorScreen> createState() => _NZAIAdvisorScreenState();
}

class _NZAIAdvisorScreenState extends ConsumerState<NZAIAdvisorScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final _incomeCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  String _buyerType = 'First Home Buyer';
  String _region = 'Auckland';

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  late AnimationController _pulseController;
  int _selectedTopicIndex = 0;

  static const _theme = CountryThemes.newZealand;

  // Hardcoded key fallback
  static const _hardcodedKey = String.fromEnvironment('GEMINI_API_KEY_NZ', defaultValue: String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''));

  final List<String> _topics = [
    'All',
    'OCR',
    'LVR',
    'KiwiSaver',
    'DTI',
    'Tax',
    'Grants'
  ];

  static final Map<String, List<String>> _topicPrompts = {
    'All': [
      '📊 RBNZ OCR Outlook',
      '🛡️ LVR Rules 2025',
      '🥝 KiwiSaver FHW',
      '📈 DTI 6x Cap',
      '🏘️ Interest Deduct.',
      '🏡 HomeStart Grant'
    ],
    'OCR': [
      'What is RBNZ OCR and how does it affect mortgage rates?',
      'When is the next RBNZ review?',
      'Are mortgage rates expected to fall in 2025?'
    ],
    'LVR': [
      'What is LVR and why does it matter?',
      'LVR limits for first home buyers',
      'LVR rules for property investors'
    ],
    'KiwiSaver': [
      'How to withdraw KiwiSaver for first home',
      'Can I use KiwiSaver for land purchase?',
      'Do employers match KiwiSaver on salary?'
    ],
    'DTI': [
      'What are DTI rules in NZ?',
      'How is DTI calculated by banks?',
      'Does DTI apply to investment loans?'
    ],
    'Tax': [
      'Bright-line test rules 2024-25',
      'Is rental property interest tax deductible?',
      'Ring-fencing rules for rental losses'
    ],
    'Grants': [
      'How to qualify for HomeStart Grant',
      'First Home Partner co-ownership',
      'Kainga Ora low deposit options'
    ],
  };

  List<String> get _currentPrompts {
    final topic = _topics[_selectedTopicIndex];
    return _topicPrompts[topic] ?? _topicPrompts['All']!;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initial welcome message
    _messages.add(const _ChatMessage(
      text: "",
      isUser: false,
      isWelcome: true,
    ));

    // Persist API key if not set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(settingsProvider);
      if (settings.geminiApiKey.isEmpty) {
        ref.read(settingsProvider.notifier).setGeminiKey(_hardcodedKey);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _incomeCtrl.dispose();
    _budgetCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();

    final storedKey = ref.read(settingsProvider).geminiApiKey;
    final apiKey = storedKey.isNotEmpty ? storedKey : _hardcodedKey;
    const groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

    String reply = '';
    if (apiKey.isNotEmpty) {
      reply = await _callGemini(text, apiKey);
    }
    if (reply.isEmpty && groqApiKey.isNotEmpty) {
      reply = await _callGroq(text, groqApiKey);
    }
    if (reply.isEmpty) {
      reply = _fallbackResponse(text);
    }

    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isLoading = false;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _fallbackResponse(String question) {
    final q = question.toLowerCase();
    final rc = RemoteConfigService.instance;
    final ocr = rc.nzOcrRate;
    final nzRates = ref.read(nzRatesProvider).valueOrNull;
    final f1 = nzRates?.fixed1yr.value ?? 5.59;
    final f2 = nzRates?.fixed2yr.value ?? 5.29;
    final fl = nzRates?.floating.value ?? 7.24;

    if (q.contains('ocr') || q.contains('rate') || q.contains('reserve bank')) {
      return "**RBNZ OCR & Mortgage Rates**\n\n"
          "• **RBNZ OCR:** $ocr% (RBNZ held steady through late 2024, cuts forecast in 2025)\n"
          "• **1-Year Fixed:** ~${f1.toStringAsFixed(2)}% (live market average)\n"
          "• **2-Year Fixed:** ~${f2.toStringAsFixed(2)}% (live market average)\n"
          "• **Floating Rate:** ~${fl.toStringAsFixed(2)}% average\n"
          "• **Outlook:** Economists project progressive cuts to the OCR in 2025, which should flow through to lower fixed and floating retail mortgage rates.";
    }
    if (q.contains('lvr') || q.contains('deposit')) {
      return "**NZ LVR Rules (Reserve Bank)**\n\n"
          "• **Owner-Occupiers:** Minimum 20% deposit required (LVR ≤ 80%) for standard approvals. Banks have a small quota (typically 15% of new lending) for low-deposit FHBs.\n"
          "• **Investors:** Minimum 35% deposit required (LVR ≤ 65%).\n"
          "• **New Builds:** Exempt from LVR limits. You can build with as little as a 10% deposit.";
    }
    if (q.contains('kiwisaver') || q.contains('withdrawal')) {
      return "**KiwiSaver First-Home Withdrawal**\n\n"
          "• **Eligibility:** Member for 3+ years. Must intend to live in the property as principal place of residence.\n"
          "• **What you can withdraw:** All contributions (employer + employee), member tax credits, and investment returns. You must leave a minimum of \$1,000 in your account.\n"
          "• **Process:** Contact your provider 4-6 weeks before settlement to obtain pre-approval. Your solicitor will execute the withdrawal request.";
    }
    if (q.contains('bright-line') || q.contains('tax') || q.contains('capital gains')) {
      return "**Bright-line Property Tax NZ**\n\n"
          "• **Rules (as of July 2024 change):** The bright-line test has been reduced to **2 years** for all residential properties.\n"
          "• If you sell a residential property within 2 years of buying, any capital gain is taxed at your personal income tax rate, unless an exemption (like main home) applies.";
    }
    if (q.contains('dti') || q.contains('income cap')) {
      return "**Debt-to-Income (DTI) Restrictions**\n\n"
          "• **RBNZ Cap:** Banks are restricted from lending more than **6×** gross annual income for owner-occupiers and **7×** for investors.\n"
          "• Banks have a 20% allowance for lending above these caps. Standard serviceability stress testing (+3% interest rate buffer) still applies in tandem.";
    }
    if (q.contains('grant') || q.contains('homestart')) {
      return "**Kāinga Ora First Home Grants**\n\n"
          "• **Grant Amount:** Up to \$5,000 for existing homes (\$1,000 per year member, max \$5,000) or up to \$10,000 for new builds (\$2,000 per year, max \$10,000). Double for couples.\n"
          "• **Caps:** Subject to regional price caps (e.g. Auckland \$875K new / \$650K existing) and annual income limits (Single \$95,000, Joint \$150,000).";
    }

    return "Kia ora! Thanks for asking about NZ mortgages. 🏡\n\n"
        "Here are key current indicators:\n"
        "• **RBNZ OCR:** $ocr%\n"
        "• **Best 1-yr Fixed:** ~${f1.toStringAsFixed(2)}%\n"
        "• **Min Owner Deposit:** 20%\n\n"
        "Please check the calculators on the NZ tab for exact figures, or add a Gemini API key in Settings to unlock the full AI advisor.";
  }

  String _buildSystemInstruction() {
    final rc = RemoteConfigService.instance;
    final ocr = rc.nzOcrRate;
    final nzRates = ref.read(nzRatesProvider).valueOrNull;
    final f1 = nzRates?.fixed1yr.value ?? 5.59;
    final f2 = nzRates?.fixed2yr.value ?? 5.29;
    final f3 = nzRates?.fixed3yr.value ?? 5.19;
    final f5 = nzRates?.fixed5yr.value ?? 5.09;
    final fl = nzRates?.floating.value ?? 7.24;

    String systemInstruction =
        "You are an expert New Zealand Mortgage and Property Finance Advisor. You specialise exclusively in NZ property, banking, KiwiSaver, and mortgage topics.\n\n"
        "Current data (2025):\n"
        "- RBNZ OCR: $ocr% (economists expect OCR cuts in 2025)\n"
        "- Average 1-year fixed retail mortgage: ~${f1.toStringAsFixed(2)}% (live market average)\n"
        "- Average 2-year fixed: ~${f2.toStringAsFixed(2)}%\n"
        "- Average 3-year fixed: ~${f3.toStringAsFixed(2)}%\n"
        "- Average 5-year fixed: ~${f5.toStringAsFixed(2)}%\n"
        "- Floating mortgage rate: ~${fl.toStringAsFixed(2)}% average\n"
        "- Construction loan rate: ~7.45% average\n"
        "- Revolving credit facility rate: ~8.70% average\n\n"
        "New Zealand Mortgage & Lending Rules:\n"
        "- LVR (Loan-to-Value) limits: Owner-occupier min 20% deposit (LVR 80%), Investors min 35% deposit (LVR 65%). New builds are LVR exempt (10% deposit typical)\n"
        "- RBNZ DTI (Debt-to-Income) Caps: Owner-occupier limited to 6x gross annual income, Investors limited to 7x gross annual income (introduced 2024)\n"
        "- KiwiSaver First-Home Withdrawal: Must be a member for 3+ years. Can withdraw all employee + employer contributions, tax credits, and returns, leaving \$1,000 minimum\n"
        "- Kainga Ora First Home Grant: Up to \$10K per buyer for new builds (\$20K joint), \$5K for existing (\$10K joint). Income limits: Single \$95K, Joint \$150K. Regional price caps apply\n"
        "- Bright-line property tax: Reduced to 2-year rule from July 2024 for all residential properties\n"
        "- Interest deductibility: Phased back to 100% deductibility for residential rental properties from April 2025\n"
        "- Ring-fencing: Rental losses cannot offset personal income (must carry forward to offset rental profits)\n\n"
        "Format responses clearly with key numbers highlighted. Use NZ terminology (LVR, KiwiSaver, FHB, OCR, RBNZ, IRD, CCC, fortnight, etc.). Be helpful, specific, and accurate. Mention that rates change and to verify details. Keep replies concise and under 300 words unless detail is required. Show calculations where applicable.";

    if (_incomeCtrl.text.isNotEmpty || _budgetCtrl.text.isNotEmpty || _depositCtrl.text.isNotEmpty) {
      systemInstruction += "\n\nUSER PROFILE:\n"
          "- Buyer Type: $_buyerType\n"
          "- Region: $_region\n"
          "${_incomeCtrl.text.isNotEmpty ? "- Income: ${_incomeCtrl.text}\n" : ""}"
          "${_budgetCtrl.text.isNotEmpty ? "- Budget: ${_budgetCtrl.text}\n" : ""}"
          "${_depositCtrl.text.isNotEmpty ? "- Deposit: ${_depositCtrl.text}\n" : ""}"
          "Tailor advice specifically based on these profile attributes.";
    }
    return systemInstruction;
  }

  Future<String> _callGemini(String question, String apiKey) async {
    const model = 'gemini-2.0-flash';
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final List<Map<String, dynamic>> contents = [];
    for (int i = 1; i < _messages.length; i++) {
      final msg = _messages[i];
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text},
        ],
      });
    }

    if (contents.isEmpty || contents.last['role'] == 'model') {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      });
    }

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ));

      final systemInstruction = _buildSystemInstruction();

      final response = await dio.post(
        url,
        data: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemInstruction},
            ],
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return (parts[0]['text'] as String? ?? '').trim();
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<String> _callGroq(String question, String apiKey) async {
    const model = 'llama-3.3-70b-versatile';
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    final List<Map<String, dynamic>> messages = [];
    messages.add({
      'role': 'system',
      'content': _buildSystemInstruction(),
    });
    for (int i = 1; i < _messages.length; i++) {
      final msg = _messages[i];
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }
    if (messages.isEmpty || messages.last['role'] == 'assistant') {
      messages.add({
        'role': 'user',
        'content': question,
      });
    }

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ));

      final response = await dio.post(
        url,
        data: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return content.trim();
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  void _applyProfile() {
    setState(() {
      final text = "Profile Applied! 👤\n"
          "• Buyer Type: $_buyerType\n"
          "• Region: $_region\n"
          "${_incomeCtrl.text.isNotEmpty ? "• Income: ${_incomeCtrl.text}\n" : ""}"
          "${_budgetCtrl.text.isNotEmpty ? "• Budget: ${_budgetCtrl.text}\n" : ""}"
          "${_depositCtrl.text.isNotEmpty ? "• Deposit: ${_depositCtrl.text}" : ""}";

      _messages.add(_ChatMessage(text: text, isUser: false, isProfileApplied: true));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0F0D) : const Color(0xFFEDF5F2);
    final cardBgColor = isDark ? const Color(0xFF13221C) : Colors.white;
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF0A0F0D);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF4A6358);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x140D3B2E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A0F0D),
                      Color(0xFF0D3B2E),
                      Color(0xFF1A6B4A),
                      Color(0xFF0EA5E9),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('←', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🤖  NZ AI Advisor',
                            style: AppTextStyles.dmSans(
                                size: 16, weight: FontWeight.w800, color: Colors.white)),
                        Text('RBNZ · LVR · KiwiSaver · Mortgages · Tax',
                            style: AppTextStyles.dmSans(
                                size: 9, color: Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  ],
                ),
              ),

              // Chat, Profile, disclaimer scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Status Bar
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0D3B2E), Color(0xFF1A6B4A)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _pulseController.value,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: Color(0xFF6EE7B7), shape: BoxShape.circle),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NZ Financial AI Advisor',
                                    style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: Colors.white),
                                  ),
                                  Text(
                                    'Trained on RBNZ rules · LVR · KiwiSaver · Tax',
                                    style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                              child: Text('Gemini 2.0', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white, weight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Disclaimer Alert Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                          ),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'General Advice Only',
                                    style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF92400E)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'This AI provides general NZ property and finance information only. Always consult a registered NZ financial adviser (FAP licence holder) before making investment decisions.',
                                    style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFB45309), height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Profile Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '👤 Tell the AI About You',
                              style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textPrimaryColor),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('BUYER TYPE', style: AppTextStyles.dmSans(size: 8, color: textMutedColor, weight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _buyerType,
                                            isExpanded: true,
                                            dropdownColor: cardBgColor,
                                            style: AppTextStyles.dmSans(size: 12, color: textPrimaryColor, weight: FontWeight.bold),
                                            items: const [
                                              DropdownMenuItem(value: 'First Home Buyer', child: Text('First Home Buyer')),
                                              DropdownMenuItem(value: 'Owner-Occupier', child: Text('Owner-Occupier')),
                                              DropdownMenuItem(value: 'Investor', child: Text('Investor')),
                                              DropdownMenuItem(value: 'Refinancing', child: Text('Refinancing')),
                                            ],
                                            onChanged: (val) => setState(() => _buyerType = val ?? 'First Home Buyer'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('APPROX. INCOME (NZD)', style: AppTextStyles.dmSans(size: 8, color: textMutedColor, weight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        height: 38,
                                        child: TextField(
                                          controller: _incomeCtrl,
                                          style: AppTextStyles.dmSans(size: 12, color: textPrimaryColor, weight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            hintText: r'e.g. $120,000',
                                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                                            filled: true,
                                            fillColor: bgColor,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PROPERTY BUDGET', style: AppTextStyles.dmSans(size: 8, color: textMutedColor, weight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        height: 38,
                                        child: TextField(
                                          controller: _budgetCtrl,
                                          style: AppTextStyles.dmSans(size: 12, color: textPrimaryColor, weight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            hintText: r'e.g. $850,000',
                                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                                            filled: true,
                                            fillColor: bgColor,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('DEPOSIT AVAILABLE', style: AppTextStyles.dmSans(size: 8, color: textMutedColor, weight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        height: 38,
                                        child: TextField(
                                          controller: _depositCtrl,
                                          style: AppTextStyles.dmSans(size: 12, color: textPrimaryColor, weight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            hintText: r'e.g. $170,000',
                                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                                            filled: true,
                                            fillColor: bgColor,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CITY / REGION', style: AppTextStyles.dmSans(size: 8, color: textMutedColor, weight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _region,
                                      isExpanded: true,
                                      dropdownColor: cardBgColor,
                                      style: AppTextStyles.dmSans(size: 12, color: textPrimaryColor, weight: FontWeight.bold),
                                      items: const [
                                        DropdownMenuItem(value: 'Auckland', child: Text('Auckland')),
                                        DropdownMenuItem(value: 'Wellington', child: Text('Wellington')),
                                        DropdownMenuItem(value: 'Christchurch', child: Text('Christchurch')),
                                        DropdownMenuItem(value: 'Hamilton', child: Text('Hamilton')),
                                        DropdownMenuItem(value: 'Tauranga', child: Text('Tauranga')),
                                        DropdownMenuItem(value: 'Dunedin', child: Text('Dunedin')),
                                        DropdownMenuItem(value: 'Other NZ', child: Text('Other NZ')),
                                      ],
                                      onChanged: (val) => setState(() => _region = val ?? 'Auckland'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            ElevatedButton(
                              onPressed: _applyProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _theme.primaryColor,
                                minimumSize: const Size(double.infinity, 42),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                              ),
                              child: Text(
                                'Apply Profile to AI Context',
                                style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick topic filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_topics.length, (idx) {
                            final active = _selectedTopicIndex == idx;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(_topics[idx]),
                                selected: active,
                                selectedColor: _theme.primaryColor,
                                labelStyle: AppTextStyles.dmSans(
                                  size: 10,
                                  weight: FontWeight.bold,
                                  color: active ? Colors.white : textPrimaryColor,
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedTopicIndex = idx);
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Prompt chips list
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _currentPrompts.map((p) {
                          return ActionChip(
                            label: Text(p),
                            backgroundColor: cardBgColor,
                            labelStyle: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: textPrimaryColor),
                            onPressed: () => _sendMessage(p.replaceAll(RegExp(r'[^\w\s\?]'), '').trim()),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Chat Messages Window
                      Container(
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _theme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                              ),
                              child: Row(
                                children: [
                                  const Text('🤖', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('NZ Financial Advisor AI',
                                          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textPrimaryColor)),
                                      Text('Ask about mortgages, LVR, KiwiSaver...',
                                          style: AppTextStyles.dmSans(size: 8.5, color: textMutedColor)),
                                    ],
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => setState(() => _messages.clear()),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.black12,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                    child: Text('Clear', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: textPrimaryColor)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 320),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(12),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  return _buildChatMessageItem(msg);
                                },
                              ),
                            ),

                            // Typing loader
                            if (_isLoading)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildTypingDot(0),
                                        _buildTypingDot(1),
                                        _buildTypingDot(2),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Input bar
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: borderCol)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      maxLines: 4,
                                      minLines: 1,
                                      style: AppTextStyles.dmSans(size: 12.5, color: textPrimaryColor),
                                      decoration: InputDecoration(
                                        hintText: 'Ask about NZ mortgages, KiwiSaver...',
                                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        filled: true,
                                        fillColor: bgColor,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _sendMessage(_controller.text),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: _theme.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text('↑', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom nav bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: 1,
              activeColor: _theme.primaryColor,
              countryIcon: _theme.flag,
              countryLabel: 'NZ',
              countryRoute: '/newzealand',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessageItem(_ChatMessage msg) {
    const theme = _theme;
    final isUser = msg.isUser;

    if (msg.isProfileApplied) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5).withValues(alpha: 0.8),
          border: Border.all(color: const Color(0xFF6EE7B7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg.text,
          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF065F46), height: 1.45),
        ),
      );
    }

    String displayText = msg.text;
    if (msg.isWelcome) {
      final rc = RemoteConfigService.instance;
      final ocr = rc.nzOcrRate;
      final nzRates = ref.watch(nzRatesProvider).valueOrNull;
      final f1 = nzRates?.fixed1yr.value;
      final f1Str = f1 != null ? "${f1.toStringAsFixed(2)}%" : "~5.59%";
      displayText = "Kia ora! I'm your New Zealand AI Mortgage Advisor. 🇳🇿\n\n"
          "I specialise in NZ property finance — RBNZ OCR decisions, LVR restrictions, KiwiSaver first-home withdrawals, Kāinga Ora grants, DTI ratios, and bright-line tax rules.\n\n"
          "Current OCR: $ocr%. Best 1-yr fixed rate: $f1Str. Owner-occupier LVR: min 20% deposit.\n\n"
          "What would you like to know about buying, building, or refinancing in New Zealand?";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isUser
                ? theme.primaryColor
                : Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1B2A23)
                    : const Color(0xFFF1F5F2),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
            ),
            border: !isUser ? Border.all(color: theme.getBorderColor(context)) : null,
          ),
          child: Text(
            displayText,
            style: AppTextStyles.dmSans(
              size: 11.5,
              color: isUser ? Colors.white : theme.getTextColor(context),
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: _theme.primaryColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isWelcome;
  final bool isProfileApplied;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isWelcome = false,
    this.isProfileApplied = false,
  });
}
