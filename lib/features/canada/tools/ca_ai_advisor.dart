// lib/features/canada/tools/ca_ai_advisor.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/canada_rates_provider.dart';

class CAAiAdvisor extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CAAiAdvisor({super.key, required this.theme});

  @override
  ConsumerState<CAAiAdvisor> createState() => _CAAiAdvisorState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isWelcome;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isWelcome = false,
  });
}

class _CAAiAdvisorState extends ConsumerState<CAAiAdvisor> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  int _selectedTopicIndex = 0;

  static const _hardcodedKey = String.fromEnvironment('GEMINI_API_KEY_CA', defaultValue: String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''));

  final List<String> _topics = [
    'All',
    'Stress Test',
    'CMHC Slabs',
    'FHSA & HBP',
    'LTT Rebates',
    'Amortization',
    'Renewals',
  ];

  static final Map<String, List<String>> _topicPrompts = {
    'All': [
      'What is the stress test in 2026?',
      'CMHC premium for \$650K, 10% down?',
      'FHSA vs RRSP HBP — which is better?',
      'Best mortgage strategy for renewal 2026?',
      'How much home can I afford on \$100K?',
      'Variable vs fixed mortgage in 2026?',
    ],
    'Stress Test': [
      'What is the OSFI stress test floor?',
      'How do I calculate stress test qualifying rate?',
      'Can I pass the stress test with \$90K income?',
    ],
    'CMHC Slabs': [
      'What down payment is needed to avoid CMHC?',
      'Calculate CMHC premium for \$800,000 purchase',
      'Can I add the CMHC premium to my mortgage loan?',
    ],
    'FHSA & HBP': [
      'What is the 2026 FHSA contribution limit?',
      'How does the RRSP Home Buyers Plan work?',
      'Can a couple combine their FHSA accounts?',
    ],
    'LTT Rebates': [
      'How much is first-time buyer rebate in Ontario?',
      'Does Toronto have municipal land transfer tax?',
      'Are there LTT rebates in British Columbia?',
    ],
    'Amortization': [
      'What is the max amortization for insured mortgages?',
      'Is 30-year amortization allowed in Canada?',
      'How does bi-weekly payment save interest vs monthly?',
    ],
    'Renewals': [
      'What happens when my mortgage term expires?',
      'Best renewal strategy for ultra-low rates ending in 2026',
      'Should I renew with my current lender or switch?',
    ],
  };

  List<String> get _currentPrompts {
    final topic = _topics[_selectedTopicIndex];
    return _topicPrompts[topic] ?? _topicPrompts['All']!;
  }

  @override
  void initState() {
    super.initState();

    // Initial welcome message matching cad_screen_ai_advisor.html
    _messages.add(const _ChatMessage(
      text: "👋 **Hi! I'm your Canada Mortgage AI Advisor.**\n\n"
          "I'm up to date on 2026 Canadian mortgage rules, CMHC insurance, the stress test, BoC rate decisions, FHSA/HBP limits, and land transfer taxes by province.\n\n"
          "Ask me anything — like *\"Can I pass the stress test with \$90K income?\"* or *\"How much CMHC premium for 10% down on a \$650K home?\"*",
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
    _controller.dispose();
    _scrollController.dispose();
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

    final ratesAsync = ref.read(canadaCalculatedRatesProvider);
    final currentPrime = ratesAsync.valueOrNull?.prime.value ?? 4.45;
    final currentOvernight = ratesAsync.valueOrNull?.overnight.value ?? 2.25;
    final current5YrFixed = ratesAsync.valueOrNull?.rate5yrFixed ?? 4.99;
    final currentVariable = ratesAsync.valueOrNull?.rateVariable ?? 5.95;
    final currentStressTest = ratesAsync.valueOrNull?.stressTestRate ?? 7.00;

    if (q.contains('stress') || q.contains('qualify') || q.contains('floor')) {
      return "**Canada Mortgage Stress Test (2026 Rules)**\n\n"
          "• **What it is:** OSFI regulations require all buyers (even with >20% down) to qualify at a higher interest rate to ensure they can handle rate increases.\n"
          "• **Qualifying Rate:** You must qualify at the **higher** of:\n"
          "  - **5.25%** (the OSFI regulatory floor rate), or\n"
          "  - Your contract interest rate + **2.00%**.\n"
          "• **Example:** If your lender offers you a 5-year fixed rate of ${current5YrFixed.toStringAsFixed(2)}%, you must prove you can afford payments at **${(current5YrFixed + 2.0).toStringAsFixed(2)}%** (since ${current5YrFixed.toStringAsFixed(2)}% + 2% is higher than the floor).\n\n"
          "📋 *Note: The stress test reduces your maximum purchasing power by approximately 18% to 22% compared to non-stressed math.*";
    }

    if (q.contains('cmhc') || q.contains('insurance') || q.contains('premium') || q.contains('slab')) {
      return "**CMHC Mortgage Default Insurance (2026 Rules)**\n\n"
          "• **When Required:** If your down payment is less than **20%** of the purchase price.\n"
          "• **Purchase Price Cap:** Insured mortgages are capped at a maximum purchase price of **\$1.5 Million** (raised from \$1.0M in February 2025).\n"
          "• **CMHC Premium Rates (added to mortgage balance):**\n"
          "  - **5.00% – 9.99% down payment:** 4.00% premium rate\n"
          "  - **10.00% – 14.99% down payment:** 3.10% premium rate\n"
          "  - **15.00% – 19.99% down payment:** 2.80% premium rate\n"
          "• **Example:** On a \$650,000 home with 10% down (\$65,000), the base loan is \$585,000. The CMHC premium is 3.10% of \$585,000 = **\$18,135**, raising the total mortgage to **\$603,135**.";
    }

    if (q.contains('fhsa') || q.contains('hbp') || q.contains('rrsp') || q.contains('savings')) {
      return "**FHSA vs RRSP Home Buyers' Plan (HBP) — 2026 Rules**\n\n"
          "You can combine both programs to maximize your down payment!\n\n"
          "• **First Home Savings Account (FHSA):**\n"
          "  - **Limit:** \$8,000 annual contribution limit; **\$40,000** lifetime limit.\n"
          "  - **Benefits:** Tax-deductible contributions (reduces income tax owing) + tax-free growth + tax-free withdrawals.\n"
          "  - **Repayment:** **None** required.\n\n"
          "• **RRSP Home Buyers' Plan (HBP):**\n"
          "  - **Limit:** Withdraw up to **\$60,000** per person tax-free from your RRSP (raised in April 2024).\n"
          "  - **Repayment:** Must repay the amount back into your RRSP over **15 years**, starting 2 years after withdrawal.";
    }

    if (q.contains('ltt') || q.contains('land transfer') || q.contains('rebate') || q.contains('tax')) {
      return "**Land Transfer Tax (LTT) & Rebates in Canada**\n\n"
          "Land transfer tax varies by province and municipality. First-time home buyer rebates offer relief:\n\n"
          "• **Ontario (ON):** Marginal rate from 0.5% up to 2.5% on luxury homes. First-time buyers get up to a **\$4,000 rebate**.\n"
          "• **Toronto:** Municipal LTT duplicates Ontario rates. First-time buyers get an additional **\$4,475 rebate** (total max rebate in Toronto is \$8,475).\n"
          "• **British Columbia (BC):** Exemption for first-time buyers on homes valued up to **\$500,000** (pro-rated phase-out up to \$525,000).\n"
          "• **Alberta:** \$0 LTT. You only pay a small land registration fee (approx \$380 on a \$750K home).";
    }

    if (q.contains('renewal') || q.contains('term') || q.contains('renew')) {
      return "**Mortgage Renewal Strategy for 2026**\n\n"
          "Over 2 million Canadian homeowners are renewing mortgages in 2025–2026, many transitioning from historic 1.5%–2.0% rates to ~5% market rates.\n\n"
          "• **Start Early:** Begin shopping at least **120 days** before your renewal date. Banks can lock in rates for 120 days.\n"
          "• **Switching Lenders:** You do not have to stress test again if switching a straight renewal (insured mortgage) to another lender under current rules.\n"
          "• **Lump Sum Payments:** If you have extra cash, make a prepayment right before renewal. It goes 100% to principal and lowers your new monthly payment impact.";
    }

    if (q.contains('afford') || q.contains('income') || q.contains('home')) {
      return "**Canadian Affordability Guidelines (GDS & TDS)**\n\n"
          "Lenders use debt service ratios to cap your max mortgage qualifying balance:\n\n"
          "• **GDS (Gross Debt Service) Limit: 39%**\n"
          "  - Housing costs (Mortgage + Taxes + Heat + 50% Condo fees) must not exceed 39% of your gross pre-tax income.\n"
          "• **TDS (Total Debt Service) Limit: 44%**\n"
          "  - Total debt payments (Housing costs + Credit cards + Car loans + Student loans) must not exceed 44% of gross income.\n"
          "• **Rule of Thumb:** Your maximum purchase price is usually **3.5x to 4.5x** your gross household annual income.";
    }

    if (q.contains('rate') || q.contains('overnight') || q.contains('boc') || q.contains('prime') || q.contains('fixed') || q.contains('variable')) {
      return "**Current Canadian Interest Rates (2026)**\n\n"
          "• **BoC Overnight Rate:** **${currentOvernight.toStringAsFixed(2)}%** (held on March 18, 2026).\n"
          "• **Prime Rate:** **${currentPrime.toStringAsFixed(2)}%** (overnight rate + 2.20% standard margin set by retail banks).\n"
          "• **Variable Mortgage Rates:** ~Prime − 0.50% = **${currentVariable.toStringAsFixed(2)}%**.\n"
          "• **5-Year Fixed Mortgage Rates:** Average **${current5YrFixed.toStringAsFixed(2)}%** (based on bond yields).\n\n"
          "📋 *Fixed vs. Variable:* Variable rates change instantly with BoC monetary policy. Fixed rates remain locked for the duration of your 1-to-5-year term.";
    }

    return "Thank you for your query! 🍁\n\n"
        "Here are the current core Canadian mortgage indicators:\n"
        "• **BoC Policy Rate:** ${currentOvernight.toStringAsFixed(2)}%\n"
        "• **Retail Prime Rate:** ${currentPrime.toStringAsFixed(2)}%\n"
        "• **Stress Test Floor:** ${currentStressTest.toStringAsFixed(2)}%\n"
        "• **Insured Price Cap:** \$1.5 Million\n\n"
        "Please use the specific calculators in the Canada section for precise mathematical answers, or configure a Gemini API key in Settings to enable deep personalized answers.";
  }

  String _buildSystemInstruction() {
    final ratesAsync = ref.read(canadaCalculatedRatesProvider);
    final currentPrime = ratesAsync.valueOrNull?.prime.value ?? 4.45;
    final currentOvernight = ratesAsync.valueOrNull?.overnight.value ?? 2.25;
    final current5YrFixed = ratesAsync.valueOrNull?.rate5yrFixed ?? 4.99;
    final currentVariable = ratesAsync.valueOrNull?.rateVariable ?? 5.95;
    final currentStressTest = ratesAsync.valueOrNull?.stressTestRate ?? 7.00;

    return "You are an expert Canadian Mortgage, Real Estate, and Personal Finance Advisor. You specialize exclusively in Canadian property finance, tax rules, lending regulations, and bank comparisons.\n\n"
        "Current Canadian Financial Indicators (as at 2026):\n"
        "- Bank of Canada overnight rate: ${currentOvernight.toStringAsFixed(2)}% (held March 18, 2026; next decision June 4, 2026)\n"
        "- Retail Prime rate: ${currentPrime.toStringAsFixed(2)}% (BoC + 220bps)\n"
        "- 5-year fixed rate: ~${current5YrFixed.toStringAsFixed(2)}%; Variable: ~${currentVariable.toStringAsFixed(2)}% (Prime −0.5%)\n"
        "- Stress test: qualify at higher of ${currentStressTest.toStringAsFixed(2)}% (OSFI floor) or contract rate + 2%\n"
        "- CMHC insurance: required if down payment < 20%; max purchase price \$1.5M (raised Feb 2025)\n"
        "- CMHC premiums: 5–9.99% down = 4.00%; 10–14.99% = 3.10%; 15–19.99% = 2.80%\n"
        "- Max amortization: 25 years for insured; 30 years for uninsured (since Aug 2024 policy)\n"
        "- FHSA 2026: \$8,000/year, \$40,000 lifetime; tax-deductible contributions, tax-free qualifying withdrawals; no repayment needed\n"
        "- RRSP Home Buyers' Plan: \$60,000 per person (raised April 2024), repay over 15 years\n"
        "- Ontario LTT: 0.5%–2.5% (marginal); Toronto adds equal MLTT; FTHB rebate up to \$4,000 ON + \$4,475 Toronto\n"
        "- BC PTT: 1%–3%; FTHB full exemption ≤\$500K\n"
        "- Alberta: no LTT, only ~\$380 registration fee\n"
        "- GDS ratio: typically max 39%; TDS ratio: max 44%\n"
        "- 2M+ Canadian mortgages renewed 2025–2026 (from ~1% ultra-low rates)\n"
        "- Prepayment: most lenders allow 10–20% lump sum + 10–20% payment increase annually\n"
        "- BoC cut 2.75% total from peak 5.00% (Jun 2024 to Dec 2025)\n\n"
        "Format responses clearly using bullet points, paragraphs, and highlight key terms with double asterisks. Use Canadian dollar symbol (\$). Keep answers helpful, specific, and concise. Advise users to cross-verify rates with banking portals and consult professional CA mortgage brokers.";
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFEFF7F3);
    final cardBgColor = isDark ? const Color(0xFF141C33) : Colors.white;
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF071F12);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF3D6650);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x141A5C35);

    return Column(
      children: [
        // Topic selection row
        Container(
          height: 38,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _topics.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedTopicIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTopicIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF071F12) : bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF071F12) : const Color(0x2B1A5C35),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _topics[index],
                    style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF1A5C35),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Quick prompts scroll view
        Container(
          height: 38,
          margin: const EdgeInsets.only(top: 6, bottom: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _currentPrompts.length,
            itemBuilder: (context, index) {
              final prompt = _currentPrompts[index];
              return GestureDetector(
                onTap: () => _sendMessage(prompt),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0x3B1A5C35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    prompt,
                    style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: const Color(0xFF1A5C35),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Chat Area
        Expanded(
          child: Container(
            color: bgColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingBubble(borderCol);
                }
                final message = _messages[index];
                return _buildMessageBubble(message, cardBgColor, textPrimaryColor, borderCol, textMutedColor);
              },
            ),
          ),
        ),

        // Input bar & Disclaimer docked at bottom
        Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            border: Border(
              top: BorderSide(
                color: const Color(0xFF1A5C35).withValues(alpha: 0.1),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              )
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x3B1A5C35),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: AppTextStyles.dmSans(
                            size: 13,
                            color: textPrimaryColor,
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'Ask about Canadian mortgages, stress test...',
                            hintStyle: AppTextStyles.dmSans(
                              size: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(_controller.text),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF071F12), Color(0xFF14492A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A5C35).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '➤',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'AI advice only — consult a licensed mortgage broker for personalized guidance.',
                  style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: isDark ? Colors.white54 : const Color(0xFF1A5C35).withValues(alpha: 0.7),
                    weight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingBubble(Color borderCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF071F12), Color(0xFF14492A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('🍁', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: borderCol),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A5C35),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    _ChatMessage message,
    Color cardBgColor,
    Color textPrimaryColor,
    Color borderCol,
    Color textMutedColor,
  ) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Spacer(flex: 2),
            Flexible(
              flex: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF071F12), Color(0xFF14492A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: AppTextStyles.dmSans(
                    size: 13,
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF071F12), Color(0xFF14492A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('🍁', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      border: Border.all(color: borderCol),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: _buildRichMessage(message.text, textPrimaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.isWelcome
                        ? 'Canada Mortgage Tools · 2026'
                        : 'Canada AI Advisor · Just now',
                    style: AppTextStyles.dmSans(
                      size: 9,
                      color: textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRichMessage(String text, Color textColor) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*');
    int lastIndex = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: AppTextStyles.dmSans(size: 13, color: textColor, height: 1.45),
        ));
      }

      if (match.group(1) != null) {
        // Double asterisks (bold)
        spans.add(TextSpan(
          text: match.group(1),
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.bold,
            color: textColor,
            height: 1.45,
          ),
        ));
      } else if (match.group(2) != null) {
        // Single asterisks (italic)
        spans.add(TextSpan(
          text: match.group(2),
          style: AppTextStyles.dmSans(
            size: 13,
            color: textColor,
            height: 1.45,
          ).copyWith(fontStyle: FontStyle.italic),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: AppTextStyles.dmSans(size: 13, color: textColor, height: 1.45),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
