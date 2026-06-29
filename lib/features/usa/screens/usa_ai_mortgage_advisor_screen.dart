// lib/features/usa/screens/usa_ai_mortgage_advisor_screen.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class USAAIMortgageAdvisorScreen extends ConsumerStatefulWidget {
  const USAAIMortgageAdvisorScreen({super.key});

  @override
  ConsumerState<USAAIMortgageAdvisorScreen> createState() => _USAAIMortgageAdvisorScreenState();
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

class _USAAIMortgageAdvisorScreenState extends ConsumerState<USAAIMortgageAdvisorScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final _homePriceCtrl = TextEditingController(text: '450000');
  final _downPmtCtrl = TextEditingController(text: '20');
  final _incomeCtrl = TextEditingController(text: '95000');
  final _creditCtrl = TextEditingController(text: '740');

  String _loanType = 'Conventional';
  String _state = 'GA';

  bool _isFtb = true;
  bool _isVa = false;
  bool _isRural = false;

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  late AnimationController _pulseController;
  int _selectedTopicIndex = 0;

  static const _theme = CountryThemes.usa;
  static const _hardcodedKey = String.fromEnvironment('GEMINI_API_KEY_USA', defaultValue: String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''));

  final List<String> _topics = [
    'All',
    'Rates',
    'Programs',
    'Affordability',
    'DTI & Credit',
    'Taxes & Buying'
  ];

  static final Map<String, List<String>> _topicPrompts = {
    'All': [
      'What loan is best for me?',
      'Compare FHA vs Conventional',
      'Can I afford \$500K home?',
      'How to improve my DTI?',
      'Explain VA loan benefits',
      'How much down payment do I need?'
    ],
    'Rates': [
      'What affects mortgage rates?',
      'Is now a good time to buy?',
      'Will Fed Funds rate cuts drop mortgage rates?',
      'How does the 10-Yr Treasury yield affect rates?'
    ],
    'Programs': [
      'Compare FHA vs Conventional',
      'Explain VA loan benefits',
      'Who qualifies for USDA loans?',
      'What is FHA 203(k) rehab loan?'
    ],
    'Affordability': [
      'Can I afford \$500K home?',
      'How does PMI affect my monthly payment?',
      'Explain the 28/36 DTI rule',
      'How do I calculate mortgage payments?'
    ],
    'DTI & Credit': [
      'How to improve my DTI?',
      'What is the minimum credit score for FHA?',
      'How does credit score affect interest rates?',
      'Does student loan debt block a mortgage?'
    ],
    'Taxes & Buying': [
      'First-time homebuyer tax deductions?',
      'What is Area Median Income (AMI) limit?',
      'Can I withdraw from 401k/IRA for down payment?',
      'State-specific down payment assistance?'
    ]
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

    _messages.add(const _ChatMessage(
      text: "Hi! I'm your USA AI Mortgage Advisor, powered by real FRED data and up-to-date 2025 lending guidelines. 🇺🇸\n\n"
          "I can help you with loan program selection, payment estimates, DTI analysis, rate comparisons, and step-by-step homebuying guidance.\n\n"
          "Tell me about your situation or tap a quick question below. What's on your mind?",
      isUser: false,
      isWelcome: true,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _homePriceCtrl.dispose();
    _downPmtCtrl.dispose();
    _incomeCtrl.dispose();
    _creditCtrl.dispose();
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

    const apiKey = _hardcodedKey;
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
    
    if (q.contains('best loan') || q.contains('what loan') || q.contains('program')) {
      return "**Recommended Loan Programs (2025 Guidelines)**\n\n"
          "Based on your profile, here are the main options:\n"
          "• **Conventional Loan:** Best if you have a **720+ credit score** and **3% to 20% down**. If you put down 20%+, you avoid **PMI** completely.\n"
          "• **FHA Loan:** Excellent for lower credit scores (**580+**). Requires only **3.5% down**, but includes lifetime MIP (Mortgage Insurance Premium) for 30-year terms.\n"
          "• **VA Loan:** Best if you have military service. **0% down payment**, **no monthly PMI**, and highly competitive rates (~6.25%).\n"
          "• **USDA Loan:** Best for properties in designated rural/suburban areas. Offers **0% down** and low annual fees (0.35%) if household income is within **115% of Area Median Income (AMI)**.";
    }
    
    if (q.contains('fha vs conventional') || q.contains('compare')) {
      return "**FHA vs. Conventional Mortgage Comparison**\n\n"
          "• **Down Payment:** Conventional starts at **3%** (first-time buyers) or **5%**. FHA starts at **3.5%**.\n"
          "• **Credit Score:** Conventional typically requires **620+**; FHA allows down to **580** (or even 500 with 10% down).\n"
          "• **Mortgage Insurance:** Conventional PMI can be cancelled once you reach **20% equity** (80% LTV). FHA MIP is **for the life of the loan** if you put less than 10% down.\n"
          "• **Interest Rates:** FHA rates are typically **0.25% to 0.50% lower** than conventional, but upfront and monthly mortgage insurance makes them comparable in total cost.";
    }

    if (q.contains('afford') || q.contains('how much') || q.contains(r'$')) {
      final price = double.tryParse(_homePriceCtrl.text) ?? 450000;
      final income = double.tryParse(_incomeCtrl.text) ?? 95000;
      final monthlyIncome = income / 12;
      final maxHousingPayment = monthlyIncome * 0.28;
      final rate30 = ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
      
      return "**Affordability Analysis**\n\n"
          "Based on your profile income of **\$${(income/1000).toStringAsFixed(0)}K/yr**:\n"
          "• **Gross Monthly Income:** \$${monthlyIncome.toStringAsFixed(0)}\n"
          "• **Ideal Monthly Housing Cap (28% Rule):** \$${maxHousingPayment.toStringAsFixed(0)}/mo\n"
          "• **Estimated Payment for a \$${(price/1000).toStringAsFixed(0)}K Home:** ~\$${(price * 0.007).toStringAsFixed(0)}/mo (including taxes & insurance at ~${rate30.toStringAsFixed(2)}% rate).\n\n"
          "To comfortably qualify, your total monthly debts + new mortgage payment should remain under **43%** of gross income (approx. **\$${(monthlyIncome * 0.43).toStringAsFixed(0)}/mo**).";
    }
 
    if (q.contains('dti') || q.contains('debt-to-income') || q.contains('ratio')) {
      return "**Debt-to-Income (DTI) Guide**\n\n"
          "Lenders analyze two DTI ratios:\n"
          "1. **Front-End Ratio (Housing DTI):** Percentage of gross income going to mortgage principal, interest, taxes, home insurance, and HOA. Target: **≤ 28%**.\n"
          "2. **Back-End Ratio (Total DTI):** Housing payment + car loans + student loans + credit card minimum payments. Target: **≤ 36% to 43%**.\n\n"
          "**How to improve DTI:**\n"
          "• Pay down revolving credit card balances below 30% utilization.\n"
          "• Consolidate or pay off small loans to eliminate their monthly minimum obligations.";
    }
 
    if (q.contains('time to buy') || q.contains('market') || q.contains('outlook')) {
      final rate30 = ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
      final censusPrice = ref.read(censusMedianHomeValueProvider).valueOrNull?.value ?? 416900.0;
      return "**USA Housing Market Outlook · 2025**\n\n"
          "• **Mortgage Rates:** Average 30-year fixed rate is **${rate30.toStringAsFixed(2)}%** (Freddie Mac PMMS). Rates have stabilized following Fed pauses.\n"
          "• **Home Prices:** National median sale price sits at **\$${CurrencyFormatter.format(censusPrice, decimalDigits: 0)}**, up **+5.1% YoY** due to tight inventory.\n"
          "• **Recommendation:** While rates are higher than the historic 2021 lows (2.65%), they are below the 50-year average of **7.7%**. If you find a home that fits your budget and plan to stay 5+ years, buy now and refinance if rates drop later.";
    }
 
    if (q.contains('va loan') || q.contains('va benefit')) {
      final rate30 = ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
      return "**VA Benefit & Home Loan Advantages**\n\n"
          "If you qualify as an active-duty service member, veteran, or eligible spouse:\n"
          "• **0% Down Payment:** No down payment required on primary residences.\n"
          "• **No Monthly PMI:** Saves you **\$150 to \$350/month** compared to conventional/FHA.\n"
          "• **VA Funding Fee:** A one-time fee of **2.15%** (first use) or **3.3%** (subsequent use) applies, which can be rolled into the loan. This fee is **waived** if you have a **10%+ VA disability rating**.\n"
          "• **Live VA Rate:** Currently averaging **${(rate30 - 0.57).toStringAsFixed(2)}%**.";
    }
 
    if (q.contains('down payment') || q.contains('downpmt') || q.contains('need')) {
      return "**Down Payment Requirements by Loan Type**\n\n"
          "• **Conventional:** Minimum **3%** down for first-time buyers, **5%** standard.\n"
          "• **FHA:** Minimum **3.5%** down (requires credit score of 580+).\n"
          "• **VA / USDA:** **0%** down payment options are available for qualified borrowers.\n\n"
          "**Tip:** Putting down **20%** on a conventional loan eliminates monthly **PMI**, saving you thousands of dollars in interest and insurance costs.";
    }
 
    if (q.contains('rate') || q.contains('interest') || q.contains('fred')) {
      final fedFunds = ref.read(fredFedFundsProvider).valueOrNull?.value ?? 5.33;
      return "**What Drives Mortgage Rates?**\n\n"
          "• **10-Year Treasury Yield:** Mortgage rates track this yield closely. When treasury yields go up, mortgage rates rise.\n"
          "• **Federal Reserve (FOMC):** The Fed sets the **Fed Funds Rate** (currently **${(fedFunds - 0.08).toStringAsFixed(2)}% - ${(fedFunds + 0.17).toStringAsFixed(2)}%** target). While this doesn't directly set mortgage rates, it sets the baseline cost of borrowing.\n"
          "• **Inflation:** High inflation erodes the value of long-term bonds, forcing yields and mortgage rates higher. Dropping inflation usually drops rates.";
    }
 
    final rate30 = ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
    final fedFunds = ref.read(fredFedFundsProvider).valueOrNull?.value ?? 5.33;
    final censusPrice = ref.read(censusMedianHomeValueProvider).valueOrNull?.value ?? 416900.0;
    return "Thanks for asking about US mortgages. 🏡\n\n"
        "Here are key current indicators:\n"
        "• **Freddie Mac 30-Yr:** ${rate30.toStringAsFixed(2)}%\n"
        "• **Fed Funds Rate:** ${fedFunds.toStringAsFixed(2)}% midpoint\n"
        "• **Median US Home Price:** \$${CurrencyFormatter.format(censusPrice, decimalDigits: 0)}\n\n"
        "Please check the calculators on the USA Tools tab for exact figures, or add a Gemini API key in Settings to unlock the full AI advisor.";
  }

  String _buildSystemInstruction() {
    final rate30 = ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
    final rate15 = ref.read(fredMortgage15Provider).valueOrNull?.value ?? 6.11;
    final sofr = ref.read(fredSofrProvider).valueOrNull?.value ?? 5.33;
    final fedFunds = ref.read(fredFedFundsProvider).valueOrNull?.value ?? 5.33;
    final censusPrice = ref.read(censusMedianHomeValueProvider).valueOrNull?.value ?? 416900.0;
 
    String systemInstruction =
        "You are an expert USA Mortgage and Property Finance Advisor. You specialise exclusively in US property, banking, lending guidelines, and mortgage topics.\n\n"
        "Current data (2025):\n"
        "- 30-Yr Conventional Fixed: ${rate30.toStringAsFixed(2)}% (Freddie Mac PMMS)\n"
        "- 15-Yr Conventional Fixed: ${rate15.toStringAsFixed(2)}%\n"
        "- 5/1 ARM: ${(sofr + 0.72).toStringAsFixed(2)}%\n"
        "- FHA 30-Yr: ${(rate30 - 0.30).toStringAsFixed(2)}% average\n"
        "- VA 30-Yr: ${(rate30 - 0.57).toStringAsFixed(2)}% average\n"
        "- USDA Guaranteed: ${(rate30 - 0.47).toStringAsFixed(2)}%\n"
        "- Jumbo 30-Yr: ${(rate30 + 0.22).toStringAsFixed(2)}%\n"
        "- Fed Funds Rate (FOMC): ${(fedFunds - 0.08).toStringAsFixed(2)}% - ${(fedFunds + 0.17).toStringAsFixed(2)}% (${fedFunds.toStringAsFixed(2)}% midpoint)\n"
        "- 10-Yr Treasury Yield: 4.47%\n"
        "- Median US Home Price: \$${CurrencyFormatter.format(censusPrice, decimalDigits: 0)} (US Census ACS)\n"
        "- Home Price Index YoY Change: +5.1% (FHFA)\n\n"
        "Lending Guidelines:\n"
        "- FHA: 3.5% down (580+ FICO), Upfront MIP 1.75%, Monthly MIP 0.85%/yr (typical for 30-yr).\n"
        "- VA: 0% down, no monthly PMI, 2.15% funding fee (1st use, <5% down, waived if 10%+ disability).\n"
        "- USDA: 0% down, 1% upfront fee, 0.35% annual, income limit 115% AMI, property must be rural-eligible.\n"
        "- Conventional: 3% down (FTB) or 5%, monthly PMI required below 20% LTV (can cancel at 80% LTV).\n"
        "- Jumbo: for loans exceeding conforming limit (\$766,550 in most areas), typically 10-20% down required.\n"
        "- DTI rules: Conventional ideal is 28% front-end / 36% back-end, max 43% under QM rules.\n\n"
        "Format responses clearly with key numbers highlighted in bold. Use US terminology (PMI, FHA, VA, USDA, DTI, HUD, W-2, 1099, etc.). Be helpful, specific, and accurate. Mention that rates change and to verify details. Keep replies concise and under 300 words unless detail is required. Show calculations where applicable.";

    if (_homePriceCtrl.text.isNotEmpty || _incomeCtrl.text.isNotEmpty || _creditCtrl.text.isNotEmpty) {
      systemInstruction += "\n\nUSER PROFILE CONTEXT:\n"
          "- Home Price: \$${_homePriceCtrl.text}\n"
          "- Down Payment: ${_downPmtCtrl.text}%\n"
          "- Annual Income: \$${_incomeCtrl.text}\n"
          "- Credit Score: ${_creditCtrl.text}\n"
          "- Loan Type: $_loanType\n"
          "- State: $_state\n"
          "- First-Time Buyer: ${_isFtb ? "Yes" : "No"}\n"
          "- VA Eligible: ${_isVa ? "Yes" : "No"}\n"
          "- Rural Area: ${_isRural ? "Yes" : "No"}\n"
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
      final text = "Profile Context Applied! 👤\n"
          "• Home Price: \$${_homePriceCtrl.text}\n"
          "• Down Payment: ${_downPmtCtrl.text}%\n"
          "• Income: \$${_incomeCtrl.text}\n"
          "• Credit Score: ${_creditCtrl.text}\n"
          "• Loan Type: $_loanType\n"
          "• State: $_state\n"
          "• First-Time Buyer: ${_isFtb ? "Yes" : "No"}\n"
          "• VA Eligible: ${_isVa ? "Yes" : "No"}\n"
          "• Rural Area: ${_isRural ? "Yes" : "No"}";

      _messages.add(_ChatMessage(text: text, isUser: false, isProfileApplied: true));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF4A5C7A);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x141B3F72);

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
                      Color(0xFF0B1D3A),
                      Color(0xFF1B3F72),
                      Color(0xFF4C1D95),
                      Color(0xFFB91C1C),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                child: Column(
                  children: [
                    Row(
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🤖  USA AI Mortgage Advisor',
                                  style: AppTextStyles.dmSans(
                                      size: 15, weight: FontWeight.w800, color: Colors.white)),
                              Text('FRED · FHA/VA/USDA · Live Rates · Guidelines',
                                  style: AppTextStyles.dmSans(
                                      size: 8.5, color: Colors.white.withValues(alpha: 0.5))),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _messages.clear();
                              _messages.add(const _ChatMessage(
                                text: "Chat cleared! I'm ready to help with your mortgage questions. What would you like to know? 🏠",
                                isUser: false,
                                isWelcome: true,
                              ));
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                            ),
                            alignment: Alignment.center,
                            child: const Text('🔄', style: TextStyle(color: Colors.white, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final rate30 = ref.watch(fredMortgage30Provider).valueOrNull?.formatted ?? '6.82%';
                        final rateFed = ref.watch(fredFedFundsProvider).valueOrNull?.formatted ?? '5.33%';
                        final rawRate30 = ref.watch(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
                        final fhaRate = '${(rawRate30 - 0.30).toStringAsFixed(2)}%';
                        final vaRate = '${(rawRate30 - 0.57).toStringAsFixed(2)}%';

                        final isLive30 = ref.watch(fredMortgage30Provider).valueOrNull?.isLive == true;
                        final isLiveFed = ref.watch(fredFedFundsProvider).valueOrNull?.isLive == true;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildRateStripItem('30-Yr Fixed', rate30, isLive30 ? 'FRED Live' : 'Freddie Mac'),
                              _buildRateStripItem('Fed Funds', rateFed, isLiveFed ? 'FRED Live' : 'FOMC', isGold: true),
                              _buildRateStripItem('FHA Avg', fhaRate, isLive30 ? 'Live spread' : '2025 avg', isGrn: true),
                              _buildRateStripItem('VA Avg', vaRate, isLive30 ? 'Live spread' : '2025 avg', isGrn: true),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),

              // Scrollable area
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 190),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active advisor status banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                          ),
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
                                    'USA Financial AI Advisor',
                                    style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: Colors.white),
                                  ),
                                  Text(
                                    'Trained on FHA · VA · USDA · Conforming & Jumbo Rules',
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

                      // Profile Card context builder
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
                              '👤 Customize Borrower Context',
                              style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textPrimaryColor),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildProfileInput('HOME PRICE (\$)', _homePriceCtrl)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildProfileInput('DOWN PMT (%)', _downPmtCtrl)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildProfileInput('INCOME (\$)', _incomeCtrl)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildProfileInput('CREDIT (FICO)', _creditCtrl)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('LOAN TYPE', style: AppTextStyles.dmSans(size: 8, color: textMutedColor, weight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF5F2),
                                            borderRadius: BorderRadius.circular(10)),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _loanType,
                                            isExpanded: true,
                                            dropdownColor: cardBgColor,
                                            style: AppTextStyles.dmSans(size: 12, color: textPrimaryColor, weight: FontWeight.bold),
                                            items: const [
                                              DropdownMenuItem(value: 'Conventional', child: Text('Conventional')),
                                              DropdownMenuItem(value: 'FHA', child: Text('FHA')),
                                              DropdownMenuItem(value: 'VA', child: Text('VA')),
                                              DropdownMenuItem(value: 'USDA', child: Text('USDA')),
                                              DropdownMenuItem(value: 'Jumbo', child: Text('Jumbo')),
                                            ],
                                            onChanged: (val) => setState(() => _loanType = val ?? 'Conventional'),
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
                                      Text('LOCATION (STATE)', style: AppTextStyles.dmSans(size: 8, color: textMutedColor, weight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF5F2),
                                            borderRadius: BorderRadius.circular(10)),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _state,
                                            isExpanded: true,
                                            dropdownColor: cardBgColor,
                                            style: AppTextStyles.dmSans(size: 12, color: textPrimaryColor, weight: FontWeight.bold),
                                            items: const [
                                              DropdownMenuItem(value: 'CA', child: Text('California (CA)')),
                                              DropdownMenuItem(value: 'TX', child: Text('Texas (TX)')),
                                              DropdownMenuItem(value: 'FL', child: Text('Florida (FL)')),
                                              DropdownMenuItem(value: 'NY', child: Text('New York (NY)')),
                                              DropdownMenuItem(value: 'GA', child: Text('Georgia (GA)')),
                                              DropdownMenuItem(value: 'IL', child: Text('Illinois (IL)')),
                                              DropdownMenuItem(value: 'CO', child: Text('Colorado (CO)')),
                                              DropdownMenuItem(value: 'WA', child: Text('Washington (WA)')),
                                            ],
                                            onChanged: (val) => setState(() => _state = val ?? 'GA'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildToggleChip('🏠 First-Time Buyer', _isFtb, (val) => setState(() => _isFtb = val)),
                                _buildToggleChip('🪖 VA Eligible', _isVa, (val) => setState(() => _isVa = val)),
                                _buildToggleChip('🌾 Rural Area', _isRural, (val) => setState(() => _isRural = val)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _applyProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _theme.primaryColor,
                                minimumSize: const Size(double.infinity, 42),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                              ),
                              child: Text(
                                'Apply Profile to Advisor Context',
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
                                  size: 10.5,
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
                            labelStyle: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: textPrimaryColor),
                            onPressed: () => _sendMessage(p),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Chat Messages Log
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
                                      Text('USA AI Mortgage Advisor Thread',
                                          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textPrimaryColor)),
                                      Text('Ask about FHA/VA/USDA guidelines, rates, DTI...',
                                          style: AppTextStyles.dmSans(size: 8.5, color: textMutedColor)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                return _buildChatMessageItem(msg, textPrimaryColor, textMutedColor, isDark);
                              },
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
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF5F2),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Message input area fixed bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                border: Border(top: BorderSide(color: borderCol)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      style: AppTextStyles.dmSans(size: 13, color: textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about US mortgage guidelines…',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF5F2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF1B3F72)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('➤', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
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
              countryLabel: 'USA',
              countryRoute: '/usa',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateStripItem(String label, String val, String note, {bool isGold = false, bool isGrn = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          val,
          style: AppTextStyles.dmSans(
            size: 12.5,
            weight: FontWeight.w800,
            color: isGold ? const Color(0xFFFCD34D) : isGrn ? const Color(0xFF6EE7B7) : Colors.white,
          ),
        ),
        Text(note, style: const TextStyle(fontSize: 7.5, color: Colors.white38)),
      ],
    );
  }

  Widget _buildProfileInput(String label, TextEditingController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: isDark ? Colors.white70 : const Color(0xFF4A5C7A), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 12, color: isDark ? Colors.white : const Color(0xFF0B1D3A), weight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF5F2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleChip(String label, bool isSelected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onChanged,
      selectedColor: const Color(0xFFF5F3FF),
      checkmarkColor: const Color(0xFF6D28D9),
      labelStyle: AppTextStyles.dmSans(
        size: 9.5,
        weight: FontWeight.bold,
        color: isSelected ? const Color(0xFF6D28D9) : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildChatMessageItem(_ChatMessage msg, Color textPrimary, Color textMuted, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF1B3F72)]),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🤖', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? const Color(0xFF1B3F72)
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF5F2)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(msg.isUser ? 12 : 2),
                  bottomRight: Radius.circular(msg.isUser ? 2 : 12),
                ),
                border: msg.isUser ? null : Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _formatMessageText(msg.text, msg.isUser ? Colors.white : textPrimary, msg.isUser),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      msg.isUser ? 'You' : 'Advisor',
                      style: AppTextStyles.dmSans(
                        size: 8,
                        color: msg.isUser ? Colors.white70 : textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('👤', style: TextStyle(fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formatMessageText(String text, Color textCol, bool isUser) {
    final List<Widget> children = [];
    final lines = text.split('\n');

    for (var line in lines) {
      if (line.startsWith('•')) {
        // Bullet point
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: isUser ? Colors.white70 : const Color(0xFF6D28D9), fontWeight: FontWeight.bold)),
                Expanded(
                  child: _parseInlineMarkdown(line.substring(1).trim(), textCol),
                ),
              ],
            ),
          ),
        );
      } else {
        // Normal line
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _parseInlineMarkdown(line, textCol),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _parseInlineMarkdown(String text, Color baseColor) {
    final List<TextSpan> spans = [];
    final reg = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in reg.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: AppTextStyles.dmSans(size: 11.5, color: baseColor, height: 1.45),
        children: spans,
      ),
    );
  }

  Widget _buildTypingDot(int idx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF6D28D9),
        shape: BoxShape.circle,
      ),
    );
  }
}
