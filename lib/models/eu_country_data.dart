// lib/models/eu_country_data.dart
// Immutable data model for per-country display strings consumed by the
// Europe screen (rate strip, hero card, resource list, tool navigation).
// Do NOT embed mortgage math here — rates live in the Euribor provider.

class EuCountryData {
  final String code;          // 'DE', 'FR', 'ES', 'IT', 'NL', 'PT'
  final String flag;          // emoji flag
  final String name;          // English name
  final String accentWord;    // hero card accent word (native language)
  final String heroLine2;     // hero card second line
  final double typicalRate;   // indicative mortgage rate (display only)
  final String rateType;      // 'Fixed 10yr', 'Variable', etc.
  final String resourceTitle; // title for the Countries & Resources card
  final String resourceSub;   // subtitle for that card
  final String transferTaxName; // localised transfer-tax name

  const EuCountryData({
    required this.code,
    required this.flag,
    required this.name,
    required this.accentWord,
    required this.heroLine2,
    required this.typicalRate,
    required this.rateType,
    required this.resourceTitle,
    required this.resourceSub,
    required this.transferTaxName,
  });

  // --- Static catalogue ---------------------------------------------------
  static const all = [
    EuCountryData(
      code: 'DE',
      flag: '🇩🇪',
      name: 'Germany',
      accentWord: 'Baufinanzierung',
      heroLine2: 'payment in EUR',
      typicalRate: 3.85,
      rateType: 'Fixed 10yr',
      resourceTitle: 'Germany – Baufinanzierung',
      resourceSub: '10yr fixed · Grunderwerbsteuer',
      transferTaxName: 'Grunderwerbsteuer',
    ),
    EuCountryData(
      code: 'FR',
      flag: '🇫🇷',
      name: 'France',
      accentWord: 'Prêt Immobilier',
      heroLine2: 'payment in EUR',
      typicalRate: 3.60,
      rateType: 'Fixed 20yr',
      resourceTitle: 'France – Prêt Immobilier',
      resourceSub: '20yr fixed · Frais de notaire',
      transferTaxName: 'Droits de Mutation',
    ),
    EuCountryData(
      code: 'ES',
      flag: '🇪🇸',
      name: 'Spain',
      accentWord: 'Hipoteca',
      heroLine2: 'payment in EUR',
      typicalRate: 4.10,
      rateType: 'Variable',
      resourceTitle: 'Spain – Hipoteca',
      resourceSub: 'Euribor variable · ITP/AJD tax',
      transferTaxName: 'ITP / AJD',
    ),
    EuCountryData(
      code: 'IT',
      flag: '🇮🇹',
      name: 'Italy',
      accentWord: 'Mutuo Ipotecario',
      heroLine2: 'payment in EUR',
      typicalRate: 4.20,
      rateType: 'Variable',
      resourceTitle: 'Italy – Mutuo Ipotecario',
      resourceSub: 'Variable rate · Imposta Registro',
      transferTaxName: 'Imposta Registro',
    ),
    EuCountryData(
      code: 'NL',
      flag: '🇳🇱',
      name: 'Netherlands',
      accentWord: 'Hypotheek',
      heroLine2: 'payment in EUR',
      typicalRate: 3.95,
      rateType: 'Fixed 10yr',
      resourceTitle: 'Netherlands – Hypotheek',
      resourceSub: '10yr fixed · Overdrachtsbelasting 2%',
      transferTaxName: 'Overdrachtsbelasting',
    ),
    EuCountryData(
      code: 'PT',
      flag: '🇵🇹',
      name: 'Portugal',
      accentWord: 'Crédito Habitação',
      heroLine2: 'payment in EUR',
      typicalRate: 4.30,
      rateType: 'Variable',
      resourceTitle: 'Portugal – Crédito Habitação',
      resourceSub: 'Variable rate · IMT tax',
      transferTaxName: 'IMT Tax',
    ),
  ];

  /// Look up by two-letter country code. Falls back to Germany if unknown.
  static EuCountryData byCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => all.first,
    );
  }
}
