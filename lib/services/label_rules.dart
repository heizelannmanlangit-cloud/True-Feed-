import '../models/article.dart';

// Websites we treat as trusted. Add or remove sites here.
const List<String> trustedSources = [
  'rappler.com',
  'inquirer.net',
  'philstar.com',
  'gmanetwork.com',
  'abs-cbn.com',
  'cnnphilippines.com',
  'pna.gov.ph',
  'mb.com.ph',
  'manilatimes.net',
  'sunstar.com.ph',
  'verafiles.org',
  'pcij.org',
  'bbc.com',
  'bbc.co.uk',
  'reuters.com',
  'apnews.com',
  'aljazeera.com',
  'theguardian.com',
  'nytimes.com',
];

// Is this website in our trusted list?
bool isTrustedSource(String host) {
  final name = host.toLowerCase().replaceFirst('www.', '');
  for (final site in trustedSources) {
    if (name == site || name.endsWith('.$site')) {
      return true;
    }
  }
  return false;
}

// The label rules: source rating + match score decide the label
//   match under 40            -> Unverified
//   trusted source, 70+       -> Verified
//   trusted source, 40 to 69  -> Caution
//   unknown source, 70+       -> Caution
//   unknown source, 40 to 69  -> Unverified
Credibility decideLabel(String host, int matchPercent) {
  final trusted = isTrustedSource(host);

  if (matchPercent < 40) {
    return Credibility.unverified;
  }
  if (trusted && matchPercent >= 70) {
    return Credibility.verified;
  }
  if (trusted || matchPercent >= 70) {
    return Credibility.caution;
  }
  return Credibility.unverified;
}
