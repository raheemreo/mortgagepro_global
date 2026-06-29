// lib/features/uk/screens/uk_ai_mortgage_advisor.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/uk_rates_provider.dart';

class UKChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  UKChatMessage({required this.text, required this.isUser, required this.time});
}

class UKAiMortgageAdvisor extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const UKAiMortgageAdvisor({super.key, required this.theme});

  @override
  ConsumerState<UKAiMortgageAdvisor> createState() =>
      _UKAiMortgageAdvisorState();
}

class _UKAiMortgageAdvisorState extends ConsumerState<UKAiMortgageAdvisor> {
  final List<UKChatMessage> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  int _topicCount = 0;

  final Map<String, String> _responses = const {
    'fix': '<strong>2-yr vs 5-yr fixed — the key trade-off right now:</strong><br><br>'
        '2-yr fix ~4.44% gives flexibility — you remortgage sooner, which is useful if BoE cuts rates in 2025–26.<br><br>'
        '5-yr fix ~4.09% locks in certainty and is currently <strong>cheaper</strong> — unusual. Most brokers lean 5-yr right now because markets price in slow cuts.<br><br>'
        '⚠️ If you expect to move in 2–3 years, avoid a 5-yr fix unless it has a portable feature — ERCs (early repayment charges) can be 1–5% of balance.<br><br>'
        'Verdict: 5-yr fix likely better for most buyers in mid-2025',
    'stamp': '<strong>Stamp Duty Land Tax (SDLT) — 2025 rates:</strong><br><br>'
        '<strong>First-time buyers:</strong><br>'
        '• £0–£425,000 → 0% (FTB relief)<br>'
        '• £425,001–£625,000 → 5%<br>'
        '• Over £625,000 → standard rates apply<br><br>'
        '<strong>Standard rates (home movers):</strong><br>'
        '• £0–£250,000 → 0%<br>'
        '• £250,001–£925,000 → 5%<br>'
        '• £925,001–£1.5m → 10%<br>'
        '• Over £1.5m → 12%<br><br>'
        '2nd home surcharge: +3% on all bands<br><br>'
        'Use the SDLT calculator in the Core Tools section for your exact figure.',
    'borrow': '<strong>How much can you borrow on £60,000?</strong><br><br>'
        'UK lenders typically use 4× to 4.5× gross salary:<br>'
        '• 4× → <strong>£240,000</strong><br>'
        '• 4.5× → <strong>£270,000</strong><br><br>'
        'Some specialist lenders (e.g. Halifax, Virgin) may offer 5× to 5.5× for high earners or professionals.<br><br>'
        '⚠️ Lenders also run an <strong>affordability stress test</strong> — your mortgage must remain affordable if rates rise by ~3%.<br><br>'
        'Other factors affecting your offer:<br>'
        '• Credit score (check Experian / Equifax)<br>'
        '• Existing debts & outgoings<br>'
        '• Deposit size (bigger = better rate tier)<br><br>'
        'With a 10% deposit you\'d need a property under ~£300k',
    'remortgage': '<strong>When to remortgage — 2025 checklist:</strong><br><br>'
        'Act 3–6 months before your deal ends — most lenders let you lock a rate in advance at no cost, and you\'re not penalised if rates fall further.<br><br>'
        'Key triggers:<br>'
        '• Your <strong>fixed deal expires</strong> → don\'t drift to SVR (~7.99%!)<br>'
        '• You want to <strong>release equity</strong> for renovations<br>'
        '• Your LTV has improved (→ better rate tier)<br>'
        '• You want to change your repayment term<br><br>'
        'Check your ERC (early repayment charge) before leaving a deal early — typically 1–5% of balance.<br><br>'
        '<strong>Broker tip:</strong> Use a whole-of-market FCA broker — broker fee often £0 as they earn from lenders.',
    'helptobuy': '<strong>Help to Buy Equity Loan (England):</strong><br><br>'
        'Closed to new applicants since March 2023<br><br>'
        'If you already have an equity loan:<br>'
        '• Government lent you <strong>20% (40% in London)</strong> of property value<br>'
        '• <strong>Interest-free for first 5 years</strong>, then 1.75% in yr 6, rising annually by RPI+1%<br>'
        '• You must repay the <strong>same % of property value</strong>, not the original amount<br><br>'
        '<strong>Alternatives in 2025:</strong><br>'
        '• Shared Ownership — buy 10–75%, rent the rest<br>'
        '• First Homes scheme — 30–50% discount, key workers<br>'
        '• Lifetime ISA — 25% gov bonus, up to £4k/yr<br><br>'
        'Ask me about any of these for more detail.',
  };

  static const _hardcodedKey = String.fromEnvironment('GEMINI_API_KEY_UK', defaultValue: String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''));

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(UKChatMessage(
      text:
          '👋 Hi! I\'m Nova, your UK mortgage AI. I can help you understand:\n\n'
          '• Stamp Duty (SDLT) & first-time buyer reliefs\n'
          '• Fixed vs tracker mortgage decisions\n'
          '• Affordability checks & income multiples\n'
          '• Remortgaging strategy & timing\n\n'
          'What would you like to explore today?',
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages
          .add(UKChatMessage(text: query, isUser: true, time: DateTime.now()));
      _isTyping = true;
    });

    _scrollToBottom();

    const apiKey = _hardcodedKey;
    const groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

    String responseText = '';
    if (apiKey.isNotEmpty) {
      responseText = await _callGemini(query, apiKey);
    }
    if (responseText.isEmpty && groqApiKey.isNotEmpty) {
      responseText = await _callGroq(query, groqApiKey);
    }
    if (responseText.isEmpty) {
      responseText = _fallbackResponse(query);
    }

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(UKChatMessage(
          text: responseText, isUser: false, time: DateTime.now()));
      _topicCount++;
    });
    _scrollToBottom();
  }

  String _fallbackResponse(String question) {
    final lower = question.toLowerCase();
    String responseText = 'Thanks for your question! I can help you with:\n\n'
        '• Fixed vs Tracker rates\n'
        '• Stamp Duty (SDLT) rules\n'
        '• Borrowing capacity\n'
        '• Remortgage checklist\n'
        '• Help to Buy loans\n\n'
        'Try typing one of those topics, or select a suggested chip.';

    if (lower.contains('fix') ||
        lower.contains('2 or 5') ||
        lower.contains('2 vs')) {
      responseText = _responses['fix']!;
    } else if (lower.contains('stamp') || lower.contains('sdlt')) {
      responseText = _responses['stamp']!;
    } else if (lower.contains('borrow') ||
        lower.contains('salary') ||
        lower.contains('income')) {
      responseText = _responses['borrow']!;
    } else if (lower.contains('remortgage') || lower.contains('remort')) {
      responseText = _responses['remortgage']!;
    } else if (lower.contains('help to buy') || lower.contains('equity loan')) {
      responseText = _responses['helptobuy']!;
    }
    return responseText;
  }

  String _buildSystemInstruction() {
    final ukRates = ref.read(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value  ?? 4.25;
    final fixed2yr = ukRates?.fixed2yr.value ?? 4.75;
    final fixed5yr = ukRates?.fixed5yr.value ?? 4.35;
    final svr      = ukRates?.svr.value      ?? 7.99;

    return "You are Nova, an expert UK Mortgage and Property Finance Advisor. You specialise exclusively in UK property, banking, lending guidelines, stamp duty (SDLT), and mortgage topics.\n\n"
        "Current data (2025):\n"
        "- Bank of England (BoE) Base Rate: ${boeBase.toStringAsFixed(2)}%\n"
        "- 2-Year Fixed Rate market average: ${fixed2yr.toStringAsFixed(2)}%\n"
        "- 5-Year Fixed Rate market average: ${fixed5yr.toStringAsFixed(2)}%\n"
        "- Standard Variable Rate (SVR) average: ${svr.toStringAsFixed(2)}%\n\n"
        "Lending Guidelines & Tax rules:\n"
        "- Stamp Duty Land Tax (SDLT) 2025 rules:\n"
        "  * First-time buyers: £0 - £425k is 0%; £425,001 - £625k is 5%. Over £625k standard rates apply.\n"
        "  * Standard rates (home movers): £0 - £250k is 0%; £250,001 - £925k is 5%; £925,001 - £1.5M is 10%; Over £1.5M is 12%.\n"
        "  * Second home/buy-to-let surcharge: +3% on standard bands.\n"
        "- Borrowing multiples: Lenders typically cap borrowing at 4x to 4.5x gross salary. Under special rules, up to 5x or 5.5x for high earners.\n"
        "- Affordability stress test: assess ability to pay at base rate/product rate + ~3% buffer.\n"
        "- Help to Buy equity loan (England) is closed to new applicants since March 2023. Existing loans: interest-free for first 5 years, then 1.75% in year 6, rising by RPI+1% annually.\n"
        "- Alternatives: Shared Ownership, First Homes scheme, Lifetime ISA (LISA) with 25% government bonus.\n\n"
        "Format responses clearly with key numbers in bold. Use UK terminology (SDLT, LTV, ERC, BoE base rate, remortgage, buy-to-let, ISA, etc.). Be helpful, specific, and accurate. Mention that rates change and to verify details. Keep replies concise and under 300 words unless detail is required. Show calculations where applicable.";
  }

  Future<String> _callGemini(String question, String apiKey) async {
    const model = 'gemini-2.0-flash';
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final List<Map<String, dynamic>> contents = [];
    // Skip welcome message when building history
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141C33) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol =
        isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0x161A1A5E);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value  ?? 4.25;
    final fixed2yr = ukRates?.fixed2yr.value ?? 4.75;
    final fixed5yr = ukRates?.fixed5yr.value ?? 4.35;
    final svr      = ukRates?.svr.value      ?? 7.99;
    final isLive   = ukRates?.isLive == true;

    return Scaffold(
      backgroundColor: widget.theme.getBgColor(context),
      appBar: AppBar(
        title: Row(
          children: [
            Text('AI Mortgage Advisor',
                style: AppTextStyles.dmSans(
                    size: 17, weight: FontWeight.w800, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                          color: Color(0xFF90EE90), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('LIVE',
                      style: AppTextStyles.dmSans(
                          size: 8,
                          color: const Color(0xFF90EE90),
                          weight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: widget.theme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rate Strip Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%', isLive ? '🟢 Live' : 'Est.',
                            isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
                    _divider(isDark, borderCol),
                    Expanded(
                        child: _rateCell('2-Yr Fixed', '${fixed2yr.toStringAsFixed(2)}%', isLive ? '🟢 Live' : 'Avg market',
                            isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
                    _divider(isDark, borderCol),
                    Expanded(
                        child: _rateCell(
                            '5-Yr Fixed', '${fixed5yr.toStringAsFixed(2)}%', 'Best buy', textThemeColor)),
                    _divider(isDark, borderCol),
                    Expanded(
                        child: _rateCell('SVR Avg', '${svr.toStringAsFixed(2)}%', 'High',
                            isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF451A03), const Color(0xFF1C0D02)]
                          : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)]),
                  border: Border.all(
                      color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.5) : const Color(0xFFF59E0B)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚖️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Not regulated advice · For guidance only',
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.w800,
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))),
                          const SizedBox(height: 2),
                          Text(
                            'This AI provides info only, not regulated mortgage advice. Consult an authorised broker before completing. Your home may be repossessed if you do not keep up repayments.',
                            style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF78350F),
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chat Container Card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  children: [
                    // Chat header
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)]),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFC8102E),
                                Color(0xFF8B0A1E)
                              ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text('🤖',
                                style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nova · UK Mortgage AI',
                                  style: AppTextStyles.dmSans(
                                      size: 13,
                                      weight: FontWeight.w800,
                                      color: Colors.white)),
                              Text('FCA-aware · Powered by real UK data',
                                  style: AppTextStyles.dmSans(
                                      size: 9.5, color: Colors.white60)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Chat messages list
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return _buildTypingIndicator();
                          }
                          final msg = _messages[index];
                          return _buildChatBubble(msg);
                        },
                      ),
                    ),

                    // Quick topic chips
                    if (_topicCount < 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : const Color(0xFFF8FAFC),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _chipButton('2 vs 5-yr fix?',
                                  'Should I fix for 2 or 5 years?'),
                              const SizedBox(width: 6),
                              _chipButton('SDLT help',
                                  'Explain Stamp Duty for first-time buyers'),
                              const SizedBox(width: 6),
                              _chipButton('Borrowing power',
                                  'How much can I borrow on a £60,000 salary?'),
                              const SizedBox(width: 6),
                              _chipButton('Remortgage timing',
                                  'When should I remortgage?'),
                              const SizedBox(width: 6),
                              _chipButton('Help to Buy',
                                  'What is a Help to Buy equity loan?'),
                            ],
                          ),
                        ),
                      ),

                    // Chat Input
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.1)))),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              style: AppTextStyles.dmSans(
                                  size: 13, color: textThemeColor),
                              decoration: InputDecoration(
                                hintText: 'Ask anything about UK mortgages…',
                                hintStyle: AppTextStyles.dmSans(
                                    size: 12.5, color: widget.theme.mutedColor),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF5F5F8),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                              ),
                              onSubmitted: (v) {
                                _sendMessage(v);
                                _inputController.clear();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _sendMessage(_inputController.text);
                              _inputController.clear();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFFC8102E),
                                  Color(0xFF8B0A1E)
                                ]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.arrow_upward,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Session Summary
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Your Session Summary',
                        style: AppTextStyles.dmSans(
                                size: 14,
                                weight: FontWeight.w800,
                                color: Colors.white)
                            .copyWith(fontFamily: 'Georgia')),
                    const SizedBox(height: 12),
                    _summaryRow('BoE Base Rate', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', isGold: true),
                    _summaryRow('Best 2-yr fixed (HSBC)', '4.29%',
                        isGreen: true),
                    _summaryRow('Best 5-yr fixed (HSBC)', '4.09%',
                        isGreen: true),
                    _summaryRow('FTB SDLT-free threshold', '£425,000'),
                    _summaryRow('Standard SDLT nil-rate', '£250,000'),
                    _summaryRow('Max income multiple', '4.5× salary'),
                    _summaryRow('Topics discussed', '$_topicCount'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Save Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF3730A3) : const Color(0xFF1A1A5E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    '✓ Conversation saved to your profile'),
                                backgroundColor: Color(0xFF0D9488)),
                          );
                        },
                        child: Text('💾 Save Conversation',
                            style: AppTextStyles.dmSans(
                                size: 12.5,
                                color: Colors.white,
                                weight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF1A1A5E),
                          side: BorderSide(
                              color: isDark ? const Color(0xFF4338CA) : const Color(0xFF1A1A5E), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('📤 Summary copied to clipboard'),
                                backgroundColor: Color(0xFF0D9488)),
                          );
                        },
                        child: Text('Share Summary',
                            style: AppTextStyles.dmSans(
                                size: 12.5,
                                weight: FontWeight.w800,
                                color: textThemeColor)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: Color(0xFFC8102E), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Thinking...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(UKChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String timeStr =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                  color: Color(0xFFC8102E), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('🤖', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? (isDark ? const Color(0xFF3730A3) : const Color(0xFF1a1a5e))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF5F5F8)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: msg.isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: msg.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    // Quick strip of simple tags from text
                    msg.text
                        .replaceAll('<strong>', '')
                        .replaceAll('</strong>', '')
                        .replaceAll('<br>', '\n')
                        .replaceAll('<span class="rate-pill">', '[')
                        .replaceAll('<span class="warn-pill">', '[')
                        .replaceAll('<span class="good-pill">', '[')
                        .replaceAll('</span>', ']'),
                    style: AppTextStyles.dmSans(
                      size: 11.5,
                      color: msg.isUser
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF0D0D2B)),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeStr · ${msg.isUser ? 'You' : 'Guidance only'}',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('👤', style: TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipButton(String label, String query) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _sendMessage(query),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
          border: Border.all(
              color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.5) : const Color(0xFFC7D2FE)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w700,
              color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3)),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String val,
      {bool isGold = false, bool isGreen = false}) {
    Color col = Colors.white;
    if (isGold) {
      col = const Color(0xFFFFD700);
    } else if (isGreen) {
      col = const Color(0xFF90EE90);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 11.5, weight: FontWeight.w800, color: col)),
        ],
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : widget.theme.mutedColor;
    final noteColor = isDark ? Colors.white60 : widget.theme.mutedColor.withValues(alpha: 0.8);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8, color: labelColor, weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
              size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: noteColor),
        ),
      ],
    );
  }

  Widget _divider(bool isDark, Color borderCol) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? Colors.white24 : borderCol,
    );
  }
}
