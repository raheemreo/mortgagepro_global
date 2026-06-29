// lib/features/australia/tools/au_ai_advisor.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../shared/widgets/bottom_nav.dart';

class AUAIAdvisorScreen extends ConsumerStatefulWidget {
  const AUAIAdvisorScreen({super.key});

  @override
  ConsumerState<AUAIAdvisorScreen> createState() => _AUAIAdvisorScreenState();
}

class _AUAIAdvisorScreenState extends ConsumerState<AUAIAdvisorScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  late AnimationController _pulseController;
  int _selectedTopicIndex = 0;

  static const _theme = CountryThemes.australia;

  // Hardcoded key fallback
  static const _hardcodedKey = String.fromEnvironment('GEMINI_API_KEY_AU', defaultValue: String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''));

  final List<String> _topics = [
    'All',
    'RBA',
    'LMI',
    'First Home',
    'Refinance',
    'Offset',
    'Stamp Duty'
  ];

  static final Map<String, List<String>> _topicPrompts = {
    'All': [
      '📊 RBA Outlook',
      '🛡️ LMI Explained',
      '🏦 Offset Account',
      '🏡 FHOG Guide',
      '🔑 FHBG',
      '💰 Borrowing Power'
    ],
    'RBA': [
      'When will RBA cut rates?',
      'How many cuts in 2025?',
      'RBA meeting dates 2025'
    ],
    'LMI': [
      'How much is LMI?',
      'Can I avoid LMI without 20%?',
      'Is LMI tax deductible?'
    ],
    'First Home': [
      'FHOG by state',
      'First Home Guarantee explained',
      'FHSS — how does it work?'
    ],
    'Refinance': [
      'When should I refinance?',
      'How to switch lenders?',
      'Break costs on fixed rate'
    ],
    'Offset': [
      'How much does offset save?',
      '100% vs partial offset?',
      'Offset vs redraw'
    ],
    'Stamp Duty': [
      'Stamp duty NSW on \$800K',
      'VIC stamp duty concession',
      'Cheapest stamp duty state'
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
      text: "G'day! I'm your Australian Mortgage Advisor. 🇦🇺\n\n"
          "I specialise in Australian property finance — RBA cash rate decisions, LMI calculations, stamp duty by state, First Home Owner Grants, offset accounts, and APRA lending rules.\n\n"
          "Current cash rate: 4.35% (Nov 2023). Variable home loans avg ~6.09%.\n\n"
          "What would you like to know about buying or refinancing in Australia?",
      isUser: false,
      isWelcome: true,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    if (q.contains('rba') || q.contains('outlook') || q.contains('cash rate')) {
      return "**RBA Cash Rate Outlook**\n\n"
          "• **Current Rate:** 4.35% (last changed November 2023)\n"
          "• **Historical Context:** 13 consecutive holds by the Reserve Bank of Australia.\n"
          "• **Forecasts:** Most Big 4 banks forecast 2-4 interest rate cuts in late 2025, potentially bringing the cash rate down to ~3.10% - 3.35%.\n"
          "• **Next Meetings:** Feb 17-18, Apr 1, May 20, Jul 8, Aug 5, Sep 23, Nov 4, Dec 9, 2025.\n\n"
          "Use the **RBA Rate History** tool in the State & Resources section to view complete historical charts and project repayment impacts.";
    }
    if (q.contains('lmi') || q.contains('lenders mortgage')) {
      return "**Lenders Mortgage Insurance (LMI)**\n\n"
          "• Required on home loans in Australia if your **LVR (Loan-to-Value Ratio) is above 80%** (i.e. deposit is under 20%).\n"
          "• Protects the lender, not the borrower, in case of default.\n"
          "• **Tiers (approximate):**\n"
          "  - LVR 80-85%: ~0.60% - 0.90% of loan amount\n"
          "  - LVR 85-90%: ~1.20% - 1.80% of loan amount\n"
          "  - LVR 90-95%: ~2.00% - 3.20% of loan amount\n"
          "• LMI can usually be **capitalised** (added) to the loan balance.\n\n"
          "Try the **LMI Calculator** to calculate exact premiums by state and LVR.";
    }
    if (q.contains('offset') || q.contains('redraw')) {
      return "**Offset Accounts vs Redraw Facilities**\n\n"
          "• **Offset Account:** A transaction account linked directly to your home loan. Every dollar in it reduces the interest-bearing balance. E.g., a \$600K loan with a \$50K offset means you only pay interest on \$550K.\n"
          "• **Redraw Facility:** Allows you to withdraw extra repayments you've made directly into your home loan. Not a separate transaction account.\n"
          "• **Key Benefits:** Offsets offer maximum flexibility and liquidity while saving thousands in lifetime interest.\n\n"
          "Use the **Offset Account** calculator to map out your exact interest and term savings trajectory.";
    }
    if (q.contains('fhog') || q.contains('grant') || q.contains('first home owner')) {
      return "**First Home Owner Grant (FHOG) & Schemes (2024-25)**\n\n"
          "• **NSW:** \$10,000 for new homes ≤\$600K.\n"
          "• **VIC:** \$10,000 for new homes.\n"
          "• **QLD:** \$30,000 boosted for new builds ≤\$750K (until June 2025).\n"
          "• **WA:** \$10,000 for new builds ≤\$750K (or \$1M north of 26th parallel).\n"
          "• **SA:** \$15,000 for new builds ≤\$650K.\n"
          "• **TAS:** \$30,000 boosted for new builds until June 2025.\n"
          "• **Federal Schemes:**\n"
          "  - **First Home Guarantee (FHBG):** Buy with a 5% deposit, no LMI (35,000 places).\n"
          "  - **Family Home Guarantee:** Single parents can buy with a 2% deposit.\n\n"
          "Open the **First Home Owner Grant** resource tool for detailed checklists and eligibility tables.";
    }
    if (q.contains('stamp') || q.contains('duty') || q.contains('concession')) {
      return "**Stamp Duty & Concessions**\n\n"
          "Stamp duty is a state government tax on property purchases. It varies heavily by state:\n\n"
          "• **NSW:** First home buyers pay \$0 duty below \$650K, concessions up to \$800K.\n"
          "• **VIC:** Full exemption below \$600K for first home buyers, concessions up to \$750K.\n"
          "• **QLD:** First home buyers pay zero duty up to \$700K.\n\n"
          "Use the **Stamp Duty (AUS)** tool to calculate duty by buyer type, state, and property value.";
    }
    if (q.contains('borrow') || q.contains('capacity') || q.contains('dti')) {
      return "**Borrowing Capacity & DTI Ratio**\n\n"
          "• **DTI (Debt-to-Income):** APRA guidelines consider DTIs above **6x** total gross income as high risk.\n"
          "• **Lending Buffer:** Australian banks assess serviceability at the current contract rate + **3.0% APRA buffer**.\n"
          "• E.g., if you apply for a variable loan at 6.1%, the bank tests your capacity to repay at 9.1%.\n\n"
          "Verify your limits with the **DTI Ratio** and **Affordability** tools.";
    }

    return "Great question about Australian mortgages! 🏠\n\n"
        "Here are the current core indicators:\n"
        "• **RBA Cash Rate:** 4.35%\n"
        "• **Standard Variable Rate:** ~6.09% (Avg)\n"
        "• **LMI Threshold:** 80% LVR (20% deposit)\n\n"
        "Please use the specific calculators in the Australia Tools tab for precise numbers. Add a Gemini API key in Settings to get full AI-powered advice.";
  }

  String _buildSystemInstruction() {
    return "You are an expert Australian Mortgage and Property Finance Advisor. You specialise exclusively in Australian property, finance, and mortgage topics.\n\n"
        "Current data (as at late 2024 / 2025):\n"
        "- RBA Cash Rate: 4.35% (last changed November 2023, 13 consecutive holds)\n"
        "- Average variable home loan rate: ~6.09% (Big 4 banks)\n"
        "- 2-year fixed rate average: ~6.29%\n"
        "- 3-year fixed rate (Big 4): ~6.15%\n"
        "- Upcoming RBA meetings: Feb 17-18 2025, Apr 1, May 20, Jul 8, Aug 5, Sep 23, Nov 4, Dec 9 2025\n"
        "- Market forecast: 2-4 rate cuts in 2025, cash rate ending ~3.10-3.35%\n\n"
        "Australian Mortgage Rules:\n"
        "- LMI (Lenders Mortgage Insurance) required when LVR > 80% (deposit < 20%)\n"
        "- First Home Guarantee: 5% deposit, no LMI, 35,000 places 2024-25\n"
        "- Family Home Guarantee: 2% deposit, single parents\n"
        "- Regional First Home Buyer Guarantee: 10,000 places\n"
        "- APRA buffer: banks must assess at rate + 3% (serviceability buffer)\n"
        "- Max DTI ratio typically 6x income (APRA guidance)\n"
        "- First Home Super Saver (FHSS): up to \$50,000 (\$15K/yr) via super\n\n"
        "State FHOG (2024-25):\n"
        "- NSW: \$10,000 (new homes ≤\$600K)\n"
        "- VIC: \$10,000 (\$20K regional, new homes)\n"
        "- QLD: \$30,000 boosted until Jun 2025 (new homes ≤\$750K)\n"
        "- WA: \$10,000 (new homes ≤\$750K)\n"
        "- SA: \$15,000 (new homes ≤\$650K)\n"
        "- TAS: \$30,000 boosted until Jun 2025\n"
        "- ACT: Abolished FHOG, stamp duty concession instead\n"
        "- NT: \$10,000 (new & established ≤\$700K)\n\n"
        "Stamp Duty:\n"
        "- NSW: Exempt below \$650K FHB, concession up to \$800K\n"
        "- ACT: Home Buyer Concession — no duty below \$1M for eligible FHB\n"
        "- VIC: Full exemption below \$600K, concession up to \$750K\n\n"
        "Offset accounts: Every dollar in offset reduces interest-bearing balance. E.g., \$600K loan with \$50K offset = interest on \$550K only.\n\n"
        "Format responses clearly with key figures highlighted. Use Australian terminology (LVR, FHOG, APRA, RBA, fortnight, etc.). Be helpful, specific, and accurate. Mention that rates and policies change and to verify with lenders. Keep responses conversational but informative. If a calculation is possible, show your working.";
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

    // Add current question if not in message list yet
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
    final bgColor = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFFFF8F0);
    final cardBgColor = isDark ? const Color(0xFF141C33) : Colors.white;
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF1A0A00);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF7A3A1A);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x147C2D12);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Header Gradient matching au_ai_advisor.html
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A0A00),
                      Color(0xFF7C2D12),
                      Color(0xFF002868),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
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
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '←',
                                  style: AppTextStyles.dmSans(
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Column(
                              children: [
                                Text(
                                  '🤖  AI Mortgage Advisor',
                                  style: AppTextStyles.playfair(
                                    size: 18,
                                    weight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Australia · RBA · LMI · Offset · FHOG',
                                  style: AppTextStyles.dmSans(
                                    size: 10,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '🔔',
                                style: AppTextStyles.dmSans(
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Status Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pulsing Green Indicator
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF4ADE80),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4ADE80).withValues(
                                            alpha: 0.4 * (1.0 - _pulseController.value),
                                          ),
                                          blurRadius: 6.0 * _pulseController.value,
                                          spreadRadius: 4.0 * _pulseController.value,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Australian Mortgage Expert · Powered by Gemini AI · RBA 4.35% · 2024–25 data',
                                  style: AppTextStyles.dmSans(
                                    size: 9,
                                    weight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                          color: isSelected
                              ? const Color(0xFF002868)
                              : bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF002868)
                                : const Color(0x2B7C2D12),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _topics[index],
                          style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF7C2D12),
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
                            color: const Color(0x3B7C2D12),
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
                            color: const Color(0xFF7C2D12),
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
            ],
          ),
          // Input bar & Disclaimer docked at bottom above bottom nav
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF7C2D12).withValues(alpha: 0.1),
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
                              color: const Color(0x3B7C2D12),
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
                              hintText: 'Ask about mortgages, LMI, RBA, stamp duty…',
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
                              colors: [Color(0xFF7C2D12), Color(0xFF002868)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C2D12).withValues(alpha: 0.3),
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
                    '⚠️ General information only. Not financial advice. Consult a licensed mortgage broker for personal advice.',
                    style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: isDark ? Colors.white54 : const Color(0xFF92400E).withValues(alpha: 0.7),
                      weight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: 1,
              activeColor: _theme.primaryColor,
              countryIcon: _theme.flag,
              countryLabel: 'Australia',
              countryRoute: '/australia',
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
                    colors: [Color(0xFF7C2D12), Color(0xFF002868)],
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
      // AI Message bubble
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C2D12), Color(0xFF002868)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                '🦘',
                style: TextStyle(fontSize: 16),
              ),
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
                      border: Border.all(
                        color: const Color(0x2B7C2D12),
                        width: 1.2,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildParsedText(message.text, textPrimaryColor, textMutedColor),
                        if (message.isWelcome) ...[
                          const SizedBox(height: 12),
                          _buildWelcomeCard(),
                        ]
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: Text(
                      'Just now',
                      style: AppTextStyles.dmSans(
                        size: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFDBA74).withValues(alpha: 0.5),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📊',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                'Live Market Snapshot',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: const Color(0xFF7C2D12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildWelcomeCardRow('RBA Cash Rate', '4.35%'),
          _buildWelcomeCardRow('Avg Variable Rate', '6.09%'),
          _buildWelcomeCardRow('3-Yr Fixed (Big 4)', '6.15%'),
          _buildWelcomeCardRow('Median Sydney Price', '\$1.17M'),
          _buildWelcomeCardRow('Median Melbourne', '\$795K'),
        ],
      ),
    );
  }

  Widget _buildWelcomeCardRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w500,
              color: const Color(0xFF92400E),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              color: const Color(0xFF1A0A00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedText(String text, Color primaryColor, Color mutedColor) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');

    for (int l = 0; l < lines.length; l++) {
      final line = lines[l];
      if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
        // Bullet point line
        final content = line.trim().substring(1).trim();
        spans.add(
          const TextSpan(
            text: '• ',
            style: TextStyle(
              color: Color(0xFF7C2D12),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        _parseInlineFormatting(content, spans, primaryColor);
      } else {
        _parseInlineFormatting(line, spans, primaryColor);
      }

      if (l < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: AppTextStyles.dmSans(
        size: 13,
        color: primaryColor,
        height: 1.45,
      ),
    );
  }

  void _parseInlineFormatting(String text, List<TextSpan> spans, Color primaryColor) {
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;
    final matches = regExp.allMatches(text);

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
  }

  Widget _buildTypingBubble(Color borderCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C2D12), Color(0xFF002868)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              '🦘',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
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

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final double opacity = ((_controller.value * 3 - i) % 3) / 3.0;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C2D12).withValues(alpha: opacity.clamp(0.2, 1.0)),
            ),
          );
        }),
      ),
    );
  }
}
