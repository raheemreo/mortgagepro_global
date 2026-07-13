// lib/features/newzealand/tools/nz_ai_advisor.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../../providers/nz_rates_provider.dart';
import '../../../services/remote_config_service.dart';
import '../../../services/ai_service.dart';

class NZAIAdvisorScreen extends ConsumerStatefulWidget {
  const NZAIAdvisorScreen({super.key});

  @override
  ConsumerState<NZAIAdvisorScreen> createState() => _NZAIAdvisorScreenState();
}

class _NZAIAdvisorScreenState extends ConsumerState<NZAIAdvisorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  int _selectedTopicIndex = 0;

  static const _theme = CountryThemes.newZealand;

  // Hardcoded key fallback


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

    // Initial welcome message
    _messages.add(const _ChatMessage(
      text: "",
      isUser: false,
      isWelcome: true,
    ));
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

    String reply;
    try {
      reply = await AIService.instance.sendMessage(
        question: text,
        systemInstruction: _buildSystemInstruction(),
        history: _messages
            .where((m) => !m.isWelcome)
            .map((m) => AIChatMessage(text: m.text, isUser: m.isUser))
            .toList(),
        countryCode: 'nz',
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

    return systemInstruction;
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
      body: Column(
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
      bottomNavigationBar: BottomNav(
        activeIndex: 1,
        activeColor: _theme.primaryColor,
        countryIcon: _theme.flag,
        countryLabel: 'NZ',
        countryRoute: '/newzealand',
      ),
    );
  }

  Widget _buildChatMessageItem(_ChatMessage msg) {
    const theme = _theme;
    final isUser = msg.isUser;



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

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isWelcome = false,
  });
}
