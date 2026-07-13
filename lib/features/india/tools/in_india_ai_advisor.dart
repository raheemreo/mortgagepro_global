// lib/features/india/tools/in_india_ai_advisor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../../services/ai_service.dart';

class INIndiaAIAdvisor extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INIndiaAIAdvisor({super.key, required this.theme});

  @override
  ConsumerState<INIndiaAIAdvisor> createState() => _INIndiaAIAdvisorState();
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

class _INIndiaAIAdvisorState extends ConsumerState<INIndiaAIAdvisor> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  late AnimationController _pulseController;
  int _selectedTopicIndex = 0;



  final List<String> _topics = [
    'All',
    'Repo Rate',
    'PMAY Subsidy',
    'GST on Property',
    'Tax Benefits',
    'Stamp Duty',
    'CIBIL Score',
    'LAP Guide',
    'RERA Check'
  ];

  static final Map<String, List<String>> _topicPrompts = {
    'All': [
      'What is the current RBI repo rate and how does it affect home loans in 2025?',
      'How to check PMAY eligibility and what subsidy can I get in 2025?',
      'What is GST on under-construction property in India 2025?',
      'What are Section 80C and 24(b) deductions on home loan in India?',
      'What are stamp duty charges in Maharashtra, Delhi and Karnataka in 2025?',
      'How does CIBIL score affect home loan interest rate in India?',
      'What is Loan Against Property (LAP) — eligibility and rates in India 2025?',
      'How to check if a property builder is RERA registered?',
    ],
    'Repo Rate': [
      'What is the current RBI repo rate and how does it affect home loans in 2025?',
      'RBI repo rate history and future interest rate cuts in India',
      'Difference between MCLR and Repo Rate Linked Lending Rate (RLLR)'
    ],
    'PMAY Subsidy': [
      'How to check PMAY eligibility and what subsidy can I get in 2025?',
      'PMAY Urban 2.0 eligibility limits for EWS, LIG and MIG categories',
      'What documents are needed to apply for PMAY interest subsidy?'
    ],
    'GST on Property': [
      'What is GST on under-construction property in India 2025?',
      'Is there GST on ready-to-move-in property in India?',
      'GST rate difference between affordable and luxury housing segments'
    ],
    'Tax Benefits': [
      'What are Section 80C and 24(b) deductions on home loan in India?',
      'Can co-borrowers claim separate home loan tax deductions in India?',
      'Section 80EE & 80EEA additional tax benefits for first-time buyers'
    ],
    'Stamp Duty': [
      'What are stamp duty charges in Maharashtra, Delhi and Karnataka in 2025?',
      'Are there stamp duty concessions for women buyers in India?',
      'How is stamp duty calculated on resale properties in India?'
    ],
    'CIBIL Score': [
      'How does CIBIL score affect home loan interest rate in India?',
      'What is the minimum CIBIL score required for a home loan in India?',
      'How to improve CIBIL score quickly to get a cheaper home loan'
    ],
    'LAP Guide': [
      'What is Loan Against Property (LAP) — eligibility and rates in India 2025?',
      'Difference between home loan and loan against property (LAP) in India',
      'Maximum LTV (Loan-to-Value) ratio for Loan Against Property in India'
    ],
    'RERA Check': [
      'How to check if a property builder is RERA registered?',
      'What are RERA rules for delayed property possession in India?',
      'How to file a complaint against a builder in state RERA portal'
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

    // Initial welcome message matching in_india_ai_advisor.html
    _messages.add(const _ChatMessage(
      text: "Namaste! 🙏 I'm your **India Home Finance AI** — ask me anything about:\n\n"
          "RBI Repo Rate · Home Loan EMI · PMAY Eligibility · GST on Property · Stamp Duty · Section 80C / 24(b) · RERA · LAP · CIBIL Score · NHB Residex · TDS on Property · Capital Gains Tax",
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

    String reply;
    try {
      reply = await AIService.instance.sendMessage(
        question: text,
        systemInstruction: _buildSystemInstruction(),
        history: _messages
            .where((m) => !m.isWelcome)
            .map((m) => AIChatMessage(text: m.text, isUser: m.isUser))
            .toList(),
        countryCode: 'in',
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

    if (q.contains('repo') || q.contains('rbi') || q.contains('mclr') || q.contains('rllr')) {
      return "**RBI Repo Rate & Monetary Policy (2025 Rules)**\n\n"
          "• **Current Repo Rate:** **6.25%** in 2025 after recent policy cuts (down from 6.50% peak).\n"
          "• **Impact on Home Loans:** Most banks link retail home loans to the **Repo Linked Lending Rate (RLLR)**. When the RBI cuts or hikes rates, home loan interest rates adjust within 30 days.\n"
          "• **Typical Home Loan Rates (2025):**\n"
          "  - **SBI:** ~8.50% indicative EBLR\n"
          "  - **HDFC Bank:** ~8.70% floating\n"
          "  - **ICICI Bank / Axis Bank:** ~8.75% floating\n"
          "  - **LIC Housing Finance:** ~8.65% HFC benchmark\n"
          "• **MCLR vs EBLR/RLLR:** Old loans linked to MCLR reset quarterly or annually. New loans linked to EBLR reset immediately after RBI decisions.";
    }

    if (q.contains('pmay') || q.contains('subsidy') || q.contains('awas')) {
      return "**PMAY (Pradhan Mantri Awas Yojana) Urban 2.0 (2025 Rules)**\n\n"
          "• **Scheme Period:** Launched to subsidise interest rates on home loans for urban families.\n"
          "• **Max Subsidy Amount:** Up to **₹2.67 Lakh** credited directly to the loan principal account.\n"
          "• **Eligibility Income Slabs:**\n"
          "  - **EWS (Economically Weaker Section):** Annual household income up to **₹3 Lakh**.\n"
          "  - **LIG (Low Income Group):** Annual household income between **₹3 Lakh and ₹6 Lakh**.\n"
          "  - **MIG (Middle Income Group):** Annual household income between **₹6 Lakh and ₹18 Lakh**.\n"
          "• **Property Condition:** The beneficiary family must not own a pucca house in any part of India in the name of any member.";
    }

    if (q.contains('gst') || q.contains('affordable') || q.contains('under-construction')) {
      return "**GST on Property Purchases in India (2025)**\n\n"
          "• **Ready-to-Move Properties (Nil GST):** No GST is applicable if the builder has received the Completion Certificate (CC) or First Occupancy Certificate.\n"
          "• **Under-Construction Properties:**\n"
          "  - **Affordable Housing (1% GST):** Homes costing up to **₹45 Lakh** in metro/non-metro areas, with carpet area up to 60 sqm (metros) or 90 sqm (non-metros).\n"
          "  - **Non-Affordable / Luxury (5% GST):** Properties costing over ₹45 Lakh or exceeding area limits. No Input Tax Credit (ITC) benefits can be claimed by builders under the current regime.";
    }

    if (q.contains('tax') || q.contains('80c') || q.contains('24(b)') || q.contains('24b') || q.contains('deduction')) {
      return "**Income Tax Benefits on Home Loans (India)**\n\n"
          "You can claim tax deductions under the Old Income Tax Regime:\n\n"
          "• **Section 24(b) (Interest Repayment):**\n"
          "  - Deduct up to **₹2 Lakh** per year on home loan interest for a self-occupied property.\n"
          "  - No cap on rented/let-out properties (subject to loss set-off limits of ₹2L under house property).\n\n"
          "• **Section 80C (Principal Repayment):**\n"
          "  - Deduct up to **₹1.5 Lakh** per year on principal repayment, registration fees, and stamp duty charges.\n"
          "  - *Caution: If you sell the property within 5 years of possession, claimed Section 80C deductions will be added back to your taxable income.*\n\n"
          "• **Section 80EE / 80EEA (First-Time Buyers):**\n"
          "  - Additional ₹50,000 (80EE) or ₹1.5 Lakh (80EEA) deduction for eligible loans approved in specific periods.";
    }

    if (q.contains('stamp') || q.contains('duty') || q.contains('registration') || q.contains('maharashtra') || q.contains('delhi') || q.contains('karnataka')) {
      return "**Stamp Duty & Registration Charges in India (2025)**\n\n"
          "Stamp duty is a state government tax paid on the transaction value of property. Key states in 2025:\n\n"
          "• **Maharashtra:** **5% to 6%** (depending on municipal corporation limits) + 1% Metro Cess in Mumbai/Pune + ₹30,000 Registration fee.\n"
          "• **Delhi:** **4%** for women buyers, **6%** for men buyers, and **5%** for joint purchases + 1% Registration fee.\n"
          "• **Karnataka:** **5%** stamp duty + 1% Registration fee.\n"
          "• **Tamil Nadu:** **7%** stamp duty + 4% Registration fee (total 11% transfer fee).\n"
          "• **Telangana:** **4%** stamp duty + 0.5% Registration fee + 1.5% transfer duty (total 6%).\n\n"
          "💡 *Tip: Many states offer a 1-2% discount on stamp duty if the primary buyer is a woman.*";
    }

    if (q.contains('cibil') || q.contains('credit score') || q.contains('score')) {
      return "**CIBIL Score Impact on Home Loans**\n\n"
          "• **Ideal Score:** A CIBIL score of **750 or above** is preferred by major lenders (SBI, HDFC, ICICI).\n"
          "• **Interest Rate Difference:** Lenders offer their best interest rates (e.g. 8.50%) to buyers with scores above 750. A score between 700-750 may attract a risk premium of **0.25% to 0.50% extra**.\n"
          "• **Rejection Risk:** If your score is below 650, your loan application might be rejected, or you may need to apply to Non-Banking Financial Companies (NBFCs) at much higher rates (10.5%+).\n"
          "• **Fast Improvement Tips:** Avoid late payments, clear outstanding credit card dues, maintain credit utilization below 30%, and do not apply for multiple credit cards/loans concurrently.";
    }

    if (q.contains('lap') || q.contains('loan against property') || q.contains('collateral')) {
      return "**Loan Against Property (LAP) Guidelines (2025)**\n\n"
          "• **What it is:** A secured loan where you pledge a residential, commercial, or industrial property as collateral.\n"
          "• **Interest Rates (2025):** Typically higher than home loans, ranging between **9.25% and 10.50%**.\n"
          "• **LTV (Loan-to-Value) Ratio:** Lenders fund up to **60% to 70%** of the property's current market valuation.\n"
          "• **Tenure:** Max tenure is usually capped at **15 years** (unlike 30 years for home loans).\n"
          "• **End Use:** Unlike a home loan, LAP funds can be used for business expansion, child education, medical expenses, or personal needs.";
    }

    if (q.contains('rera') || q.contains('builder') || q.contains('compliance')) {
      return "**RERA (Real Estate Regulatory Authority) Guide**\n\n"
          "• **RERA Registration:** It is legally mandatory for all commercial and residential projects with land area >500 sqm or exceeding 8 apartments to register under RERA.\n"
          "• **How to Verify:** Visit your state RERA portal (e.g., MahaRERA, Karnataka RERA, Delhi RERA) and search for the project using the registration code. Check builder financials, project layout, and official completion date.\n"
          "• **Delayed Possession:** Builders are legally bound to pay interest (compounded at RBI SBI MCLR + 2%) to buyers for every month of delay.\n"
          "• **Escrow Account:** Builders must deposit **70%** of project receipts from buyers in a separate bank account to cover land and construction costs.";
    }

    if (q.contains('price') || q.contains('mumbai') || q.contains('delhi') || q.contains('bengaluru') || q.contains('hyderabad') || q.contains('city')) {
      return "**City Property Prices & NHB Residex (2025 average values)**\n\n"
          "Average property rates in major Indian metro segments:\n\n"
          "• **Mumbai:** **₹22,400/sqft** average. (Premium suburbs are significantly higher).\n"
          "• **Delhi NCR:** **₹12,800/sqft** average. (Gurugram / Noida prime sectors see high absorption).\n"
          "• **Bengaluru:** **₹11,500/sqft** average. (IT corridors like Outer Ring Road, Whitefield are higher).\n"
          "• **Hyderabad:** **₹9,100/sqft** average. (Gachibowli / Hitec City segments lead price growth).\n"
          "• **Pune:** **₹8,600/sqft** average.\n"
          "• **Chennai:** **₹8,200/sqft** average.\n\n"
          "📋 *Resource:* Use the **NHB Residex** city tracking tool under India Resources to monitor quarterly housing price indices.";
    }

    return "Thank you for asking! 🙏\n\n"
        "Here are the current core Indian home finance indicators:\n"
        "• **RBI Repo Rate:** 6.25%\n"
        "• **Avg Home Loan Rate:** 8.50% - 8.75%\n"
        "• **PMAY Max Subsidy:** ₹2.67 Lakh\n"
        "• **GST Under-Construction:** 1% (Affordable) or 5% (Luxury)\n\n"
        "Please use the calculators in the India tab for specific calculations. Configure your Gemini API key in Settings to unlock deep, personalized AI chats.";
  }

  String _buildSystemInstruction() {
    return "You are an expert India home finance and real estate advisor for the app MortgagePro India. You have deep, up-to-date knowledge of:\n"
        "- RBI Repo Rate and monetary policy (current rate 6.25% in 2025 after cuts)\n"
        "- Home loan rates from SBI (8.50%), HDFC (8.70%), ICICI (8.75%), Axis (8.75%), Bajaj HFL (8.55%), LIC HFL (8.65%), PNB Housing (8.99%)\n"
        "- PMAY (Pradhan Mantri Awas Yojana) Urban 2.0 launched 2024 — EWS (income up to ₹3L), LIG (₹3L-₹6L), MIG (₹6L-₹18L) categories, subsidy up to ₹2.67 Lakh\n"
        "- GST on property: Under-construction = 5% (affordable: 1%); Ready-possession = Nil GST\n"
        "- Stamp duty: Maharashtra 5-6%, Delhi 4% women/6% men, Karnataka 5%, Tamil Nadu 7%, Telangana 4%\n"
      'Section 80C (principal deduction up to ₹1.5L), Section 24(b) (interest deduction up to ₹2L for self-occupied), Section 80EE (first-time buyers ₹50K extra)\n'
        '- RERA compliance, CIBIL score requirements (750+ ideal), TDS on property >₹50L (1%), Capital Gains Tax\n'
        '- LAP (Loan Against Property) rates: 9.25-10.5%, max LTV 60-70%\n'
        '- City property prices (2025): Mumbai ₹22,400/sqft, Delhi NCR ₹12,800/sqft, Bengaluru ₹11,500/sqft, Hyderabad ₹9,100/sqft, Pune ₹8,600/sqft, Chennai ₹8,200/sqft\n'
        '- NHB Residex city-level property price index\n\n'
        'Always give practical, actionable advice with specific Indian rupee amounts, percentages, and real institution names. Format responses clearly with line breaks and bullet points. Use ₹ symbol. Keep answers concise and focused. When quoting rates, note they are indicative and may vary. Respond in English with occasional Hindi terms where natural (like \'Namaste\', \'crore\', \'lakh\'). Always recommend consulting RBI, official PMAY portal, or a SEBI-registered advisor for final decisions. Highlight key terms with double asterisks (**).';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFFFF8F0);
    final cardBgColor = isDark ? const Color(0xFF141C33) : Colors.white;
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF0B1F48);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF7A5C3A);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x1AFF6B00);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1F48),
                  Color(0xFF1A3A8F),
                  Color(0xFFFF6B00),
                  Color(0xFFE05A00),
                ],
                stops: [0.0, 0.40, 0.82, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -10,
                      child: Text(
                        '☸',
                        style: TextStyle(
                          fontSize: 120,
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                        ),
                      ),
                    ),
                    Column(
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
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'India ',
                                        style: AppTextStyles.playfair(
                                          size: 18,
                                          weight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'AI Advisor',
                                        style: AppTextStyles.playfair(
                                          size: 18,
                                          weight: FontWeight.w800,
                                          color: const Color(0xFFFFDEA0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'RBI · PMAY · Stamp Duty · GST · 80C · RERA',
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
                              child: const Text(
                                '🔔',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                                  'AI Powered · India Finance Expert · RBI 6.25% · 2025 data',
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
                  ],
                ),
              ),
            ),
          ),
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
                          ? const Color(0xFF0B1F48)
                          : (isDark ? const Color(0xFF141C33) : const Color(0x14FF6B00)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0B1F48)
                            : const Color(0x3BFF6B00),
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
                            : (isDark ? Colors.white70 : const Color(0xFF0B1F48)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
                        color: const Color(0x3BFF6B00),
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
                      prompt.length > 25 ? '${prompt.substring(0, 24)}…' : prompt,
                      style: AppTextStyles.dmSans(
                        size: 10,
                        weight: FontWeight.w700,
                        color: const Color(0xFFFF6B00),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFFFF8F0),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _messages.length) {
                    return _buildTypingBubble(borderCol);
                  }
                  final message = _messages[index];
                  if (message.isWelcome) {
                    return _buildWelcomeCard(message, cardBgColor, borderCol);
                  }
                  return _buildMessageBubble(message, cardBgColor, textPrimaryColor, borderCol, textMutedColor);
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
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
                          color: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFFFF3E8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
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
                            hintText: 'Ask about home loans, PMAY, GST, stamp duty…',
                            hintStyle: AppTextStyles.dmSans(
                              size: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF7A5C3A).withValues(alpha: 0.5),
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B00), Color(0xFFE05A00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
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
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'AI responses are informational only. Always verify with official sources (RBI.org.in, PMAY, state SRO).',
                  style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: isDark ? Colors.white54 : const Color(0xFF7A5C3A),
                    weight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        activeIndex: 1,
        activeColor: widget.theme.primaryColor,
        countryIcon: widget.theme.flag,
        countryLabel: 'India',
        countryRoute: '/india',
      ),
    );
  }

  Widget _buildWelcomeCard(_ChatMessage message, Color cardBg, Color borderCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F48).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(
              '🤖',
              style: TextStyle(
                fontSize: 50,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🇮🇳 India AI Financial Advisor · Powered by Gemini',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Namaste! 🙏 I\'m your ',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    TextSpan(
                      text: 'India Home Finance AI',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: const Color(0xFFFFDEA0),
                        height: 1.5,
                      ),
                    ),
                    TextSpan(
                      text: ' — ask me anything about:',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'RBI Repo Rate · Home Loan EMI · PMAY Eligibility · GST on Property · Stamp Duty · Section 80C / 24(b) · RERA · LAP · CIBIL Score · NHB Residex · TDS on Property · Capital Gains Tax',
                style: AppTextStyles.dmSans(
                  size: 10,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _welcomePill('🏠 First Home Buyer', 'What is the best home loan option in India for a first-time buyer in 2025?'),
                  _welcomePill('🏦 Compare Banks', 'Compare SBI vs HDFC home loan rates and features in 2025'),
                  _welcomePill('🏙️ City Prices', 'What are property prices in Mumbai, Delhi, Bengaluru and Hyderabad in 2025?'),
                  _welcomePill('📄 Documents', 'What documents are needed for a home loan in India?'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _welcomePill(String label, String prompt) {
    return GestureDetector(
      onTap: () => _sendMessage(prompt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
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
                colors: [Color(0xFFFF6B00), Color(0xFFE05A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('☸', style: TextStyle(fontSize: 16, color: Colors.white)),
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
                    color: Color(0xFFFF6B00),
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
                    colors: [Color(0xFFFF6B00), Color(0xFFE05A00)],
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
      final nowStr = TimeOfDay.now().format(context);
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
                  colors: [Color(0xFFFF6B00), Color(0xFFE05A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('☸', style: TextStyle(fontSize: 16, color: Colors.white)),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Bubble Header matching HTML
                        Row(
                          children: [
                            const Text('🤖', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 5),
                            Text(
                              'India AI Advisor',
                              style: AppTextStyles.dmSans(
                                size: 10,
                                weight: FontWeight.w800,
                                color: const Color(0xFFFF6B00),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              nowStr,
                              style: AppTextStyles.dmSans(
                                size: 9,
                                color: textMutedColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Divider(height: 1, thickness: 0.5, color: Color(0x2BFF6B00)),
                        const SizedBox(height: 8),
                        _buildRichMessage(message.text, textPrimaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'India AI Advisor · Just now',
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
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // Check if it's a bullet point
      final isBullet = trimmed.startsWith('•') || trimmed.startsWith('-') || trimmed.startsWith('*');
      String cleanLine = line;
      if (isBullet) {
        cleanLine = trimmed.replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
      }

      final List<TextSpan> spans = [];
      final RegExp regExp = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*');
      int lastIndex = 0;

      for (final match in regExp.allMatches(cleanLine)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(
            text: cleanLine.substring(lastIndex, match.start),
            style: AppTextStyles.dmSans(size: 13, color: textColor, height: 1.45),
          ));
        }

        if (match.group(1) != null) {
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

      if (lastIndex < cleanLine.length) {
        spans.add(TextSpan(
          text: cleanLine.substring(lastIndex),
          style: AppTextStyles.dmSans(size: 13, color: textColor, height: 1.45),
        ));
      }

      if (isBullet) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: const Color(0xFFFF6B00))),
                Expanded(
                  child: RichText(
                    text: TextSpan(children: spans),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: RichText(
              text: TextSpan(children: spans),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
