// lib/features/ai_advisor/ai_advisor_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../app/theme/country_themes.dart';
import '../../app/theme/text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_service.dart';

class AIAdvisorScreen extends ConsumerStatefulWidget {
  final String country;

  const AIAdvisorScreen({super.key, required this.country});

  @override
  ConsumerState<AIAdvisorScreen> createState() => _AIAdvisorScreenState();
}

class _AIAdvisorScreenState extends ConsumerState<AIAdvisorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  CountryTheme get _theme => CountryThemes.fromCode(widget.country);

  static final Map<String, List<String>> _suggestions = {
    'usa': [
      'What\'s the best loan for first-time buyers?',
      'How does PMI work?',
      'Explain the 28/36 rule',
      'FHA vs Conventional?'
    ],
    'uk': [
      'What is SDLT and how much will I pay?',
      'Explain Help to Buy',
      'Fixed vs tracker mortgage?',
      'How much can I borrow?'
    ],
    'au': [
      'What is LMI and when do I need it?',
      'How does an offset account work?',
      'First Home Owner Grant explained',
      'Variable vs fixed AU'
    ],
    'ca': [
      'How does the CMHC stress test work?',
      'What is CMHC insurance?',
      'Explain GDS/TDS ratio',
      'RRSP Home Buyers\' Plan'
    ],
    'eu': [
      'How do Euribor mortgages work?',
      'Germany vs Spain mortgage rates?',
      'ECB rate impact on mortgages',
      'Fixed vs variable EU'
    ],
    'in': [
      'What is home loan EMI?',
      'Section 24B tax benefit explained',
      'SBI vs HDFC home loan',
      'PMAY scheme eligibility'
    ],
    'nz': [
      'What are LVR restrictions?',
      'KiwiSaver HomeStart Grant',
      'Fixed vs floating NZ',
      'RBNZ OCR impact on mortgages'
    ],
  };

  List<String> get _chips {
    final key = widget.country.toLowerCase();
    return _suggestions[key] ?? _suggestions['usa']!;
  }



  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text:
          '👋 Hi! I\'m your ${_theme.name} AI Advisor.\n\nI can help you understand ${_theme.currencyCode} mortgage rates, local regulations, and calculate scenarios.\n\nWhat would you like to know?',
      isUser: false,
    ));
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    await Future.delayed(const Duration(milliseconds: 150));
    _scrollToBottom();

    String reply;
    try {
      reply = await AIService.instance.sendMessage(
        question: text,
        systemInstruction: _buildSystemPrompt(),
        history: _messages
            .skip(1)
            .map((m) => AIChatMessage(text: m.text, isUser: m.isUser))
            .toList(),
        countryCode: widget.country.toLowerCase(),
      );
    } catch (_) {
      reply = _fallbackResponse(text);
    }
    if (reply.isEmpty) reply = _fallbackResponse(text);

    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isLoading = false;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  String _fallbackResponse(String question) {
    final q = question.toLowerCase();
    final country = widget.country.toLowerCase();

    if (q.contains('lmi') || q.contains('lenders mortgage')) {
      return '**Lenders Mortgage Insurance (LMI)** is required in Australia when your deposit is below 20% of the property value.\n\n**LMI Tiers:**\n• LVR 80–85%: ~0.62% of loan\n• LVR 85–90%: ~1.45% of loan\n• LVR 90–95%: ~2.23% of loan\n\nLMI can often be capitalized into your loan amount. Use the LMI Calculator in the Australia Tools section to get an exact figure.';
    }
    if (q.contains('stress test') || q.contains('cmhc')) {
      return '**Canadian Mortgage Stress Test**\n\nYou must qualify at the higher of:\n• Your contract rate + 2%\n• 5.25% (government floor)\n\n**Example:** Contract rate of 4.99% → qualify at 6.99%\n\nGDS ratio must be ≤ 39%, TDS ≤ 44%.\n\nUse the Stress Test Calculator in Canada Tools for your scenario.';
    }
    if (q.contains('sdlt') || q.contains('stamp duty')) {
      return '**UK Stamp Duty Land Tax (SDLT)**\n\n**Standard rates:**\n• Up to £250K: 0%\n• £250K–£925K: 5%\n• £925K–£1.5M: 10%\n• Over £1.5M: 12%\n\n**First-Time Buyer Relief:**\n• Up to £425K: 0%\n• £425K–£625K: 5%\n\nAdditional properties attract a 3% surcharge. Use the SDLT Calculator for exact figures.';
    }
    if (q.contains('pmi')) {
      return '**Private Mortgage Insurance (PMI)**\n\nPMI is required in the USA when your down payment is less than 20% of the home price.\n\n**Typical rates by LTV:**\n• LTV 80–85%: 0.20–0.30%/yr\n• LTV 85–90%: 0.40–0.60%/yr\n• LTV 90–95%: 0.60–0.90%/yr\n\nPMI can be cancelled when your loan balance reaches 80% of the original value. Use the PMI Calculator for your monthly cost.';
    }
    if (q.contains('emi')) {
      return '**EMI (Equated Monthly Installment)**\n\nEMI = P × r × (1+r)^n / ((1+r)^n - 1)\n\nWhere:\n• P = Principal loan amount\n• r = Monthly interest rate\n• n = Loan tenure in months\n\n**Tax Benefits:**\n• Section 24B: Up to ₹2L deduction on interest\n• Section 80C: Up to ₹1.5L on principal\n\nUse the EMI Calculator for your exact monthly installment.';
    }

    return 'Great question about ${_theme.name} mortgages! 🏠\n\nFor ${_theme.currencyCode} mortgage calculations, I recommend:\n\n1. **Use the calculators** in the ${_theme.flag} ${_theme.name} section for precise numbers\n2. **Check live rates** — currently ${country == "usa" ? "6.82%" : country == "au" ? "6.09%" : country == "uk" ? "4.75%" : "varies"} for standard mortgages\n3. **Consult a local broker** for personalized advice\n\nTry asking me a specific question about rates, loan types, or eligibility.';
  }



  // ── Country-aware system prompt ──────────────────────────────────
  String _buildSystemPrompt() {
    final country = widget.country.toUpperCase();
    const countryContext = {
      'USA':
          'US mortgage market: PITI, PMI, FHA/VA/USDA/Jumbo loans, DTI 28/36 rule, conforming limit \$766,550, Freddie Mac/Fannie Mae, FRED data, 30-yr & 15-yr fixed, ARM, all 50-state property taxes, FICO bands.',
      'UK':
          'UK mortgage market: SDLT, Help to Buy, shared ownership, LTV bands, FCA regulations, Bank of England base rate, 2-yr & 5-yr fixed deals, tracker mortgages, buy-to-let, income multiples (4–4.5x salary).',
      'AU':
          'Australian mortgage market: LMI, offset accounts, redraw, RBA cash rate, APRA 3% buffer, First Home Owner Grant, stamp duty by state (NSW/VIC/QLD/WA/SA), LVR tiers, variable vs fixed.',
      'CA':
          'Canadian mortgage market: CMHC insurance (premium tiers), stress test (contract+2% or 7%), GDS/TDS ratios (39%/44%), BoC rate, RRSP HBP, First-Time Home Buyer Incentive, 25-yr max amortization.',
      'EU':
          'European mortgage markets: ECB deposit rate, Euribor (3m/6m/12m), German Baufinanzierung (10–20yr fixed, Grunderwerbsteuer), French prêt immobilier (notaire fees ~8%), Spanish hipoteca (Euribor variable), non-resident rules.',
      'IN':
          'Indian home loan market: RBI repo rate, MCLR vs repo-linked rates, EMI formula, FOIR, PMAY subsidy, Section 24B (₹2L interest) & 80C (₹1.5L principal), GST on under-construction (5%), CIBIL score, balance transfer.',
      'NZ':
          'New Zealand home loan market: RBNZ OCR, LVR restrictions (owner-occ 20% min, investor 35%), KiwiSaver HomeStart Grant, bright-line test (10yr), Kainga Ora First Home Partner, 1yr/2yr/5yr fixed refixing.',
    };
    final ctx = countryContext[country] ?? countryContext['USA']!;

    return 'You are MortgagePro AI — an expert mortgage and real estate finance advisor for the $country market.\n\n'
        'CONTEXT: $ctx\n\n'
        'GUIDELINES:\n'
        '- Be concise, accurate, and friendly. Use **bold** headers and bullet points.\n'
        '- Quote specific numbers, rates, and thresholds whenever relevant.\n'
        '- For calculations, show the formula and a worked example.\n'
        '- End relevant answers by suggesting which MortgagePro tool the user can use.\n'
        '- Always use ${_theme.currencySymbol} (${_theme.currencyCode}) for monetary values.\n'
        '- Do NOT provide personalised financial advice; recommend a licensed broker for individual decisions.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(gradient: _theme.headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
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
                                color: Colors.white.withValues(alpha: 0.20))),
                        alignment: Alignment.center,
                        child: Text('←',
                            style: AppTextStyles.dmSans(
                                size: 18, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_theme.flag}  AI Mortgage Advisor',
                            style: AppTextStyles.playfair(
                                size: 16, color: Colors.white)),
                        Text('Powered by Gemini AI',
                            style: AppTextStyles.dmSans(
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.50))),
                      ],
                    ),
                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.40))),
                      child: Row(children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E))),
                        const SizedBox(width: 4),
                        Text('Live',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w700,
                                color: const Color(0xFF22C55E))),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isLoading && i == _messages.length) {
                  return _TypingBubble(theme: _theme);
                }
                return _MessageBubble(message: _messages[i], theme: _theme);
              },
            ),
          ),
          // Suggestion chips
          if (_messages.length <= 2)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendMessage(_chips[i]),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _theme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _theme.primaryColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(_chips[i],
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w600,
                            color: _theme.primaryColor)),
                  ),
                ),
              ),
            ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(
                      color: _theme.primaryColor.withValues(alpha: 0.08))),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTextStyles.dmSans(
                          size: 14, color: const Color(0xFF061528)),
                      decoration: InputDecoration(
                        hintText: 'Ask about ${_theme.name}…',
                        hintStyle: AppTextStyles.dmSans(
                            size: 14, color: const Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: _theme.backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          gradient: _theme.heroGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    _theme.primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]),
                      alignment: Alignment.center,
                      child: const Text('↑',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final CountryTheme theme;

  const _MessageBubble({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  gradient: theme.heroGradient,
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Text('🤖', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? theme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: theme.borderColor),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: AppTextStyles.dmSans(
                      size: 13,
                      color: message.isUser ? Colors.white : theme.textColor,
                      height: 1.45),
                  strong: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.bold,
                      color: message.isUser ? Colors.white : theme.textColor,
                      height: 1.45),
                  listBullet: AppTextStyles.dmSans(
                      size: 13,
                      color: message.isUser ? Colors.white : theme.textColor,
                      height: 1.45),
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final CountryTheme theme;

  const _TypingBubble({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                gradient: theme.heroGradient,
                borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 14)),
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
                    bottomLeft: Radius.circular(4)),
                border: Border.all(color: theme.borderColor),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ]),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
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
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9CA3AF).withValues(
                    alpha: ((_controller.value * 3 - i).clamp(0.0, 1.0)))),
          );
        }),
      ),
    );
  }
}
