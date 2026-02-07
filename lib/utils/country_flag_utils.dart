/// Utility class to convert country names to flag emojis
class CountryFlagUtils {
  /// Map of country names to flag emojis
  static const Map<String, String> _countryToFlag = {
    'Pakistan': '🇵🇰',
    'Albania': '🇦🇱',
    'United States': '🇺🇸',
    'USA': '🇺🇸',
    'United Kingdom': '🇬🇧',
    'UK': '🇬🇧',
    'India': '🇮🇳',
    'Bangladesh': '🇧🇩',
    'Afghanistan': '🇦🇫',
    'China': '🇨🇳',
    'Japan': '🇯🇵',
    'South Korea': '🇰🇷',
    'Germany': '🇩🇪',
    'France': '🇫🇷',
    'Italy': '🇮🇹',
    'Spain': '🇪🇸',
    'Canada': '🇨🇦',
    'Australia': '🇦🇺',
    'Brazil': '🇧🇷',
    'Mexico': '🇲🇽',
    'Russia': '🇷🇺',
    'Turkey': '🇹🇷',
    'Saudi Arabia': '🇸🇦',
    'UAE': '🇦🇪',
    'United Arab Emirates': '🇦🇪',
    'Egypt': '🇪🇬',
    'Iran': '🇮🇷',
    'Iraq': '🇮🇶',
    'Jordan': '🇯🇴',
    'Lebanon': '🇱🇧',
    'Syria': '🇸🇾',
    'Yemen': '🇾🇪',
    'Oman': '🇴🇲',
    'Kuwait': '🇰🇼',
    'Qatar': '🇶🇦',
    'Bahrain': '🇧🇭',
    'Indonesia': '🇮🇩',
    'Malaysia': '🇲🇾',
    'Singapore': '🇸🇬',
    'Thailand': '🇹🇭',
    'Philippines': '🇵🇭',
    'Vietnam': '🇻🇳',
    'Nepal': '🇳🇵',
    'Sri Lanka': '🇱🇰',
    'Myanmar': '🇲🇲',
    'Cambodia': '🇰🇭',
    'Laos': '🇱🇦',
    'Maldives': '🇲🇻',
    'Bhutan': '🇧🇹',
    'Mongolia': '🇲🇳',
    'Kazakhstan': '🇰🇿',
    'Uzbekistan': '🇺🇿',
    'Kyrgyzstan': '🇰🇬',
    'Tajikistan': '🇹🇯',
    'Turkmenistan': '🇹🇲',
    'Azerbaijan': '🇦🇿',
    'Armenia': '🇦🇲',
    'Georgia': '🇬🇪',
    'Ukraine': '🇺🇦',
    'Poland': '🇵🇱',
    'Romania': '🇷🇴',
    'Bulgaria': '🇧🇬',
    'Greece': '🇬🇷',
    'Portugal': '🇵🇹',
    'Netherlands': '🇳🇱',
    'Belgium': '🇧🇪',
    'Switzerland': '🇨🇭',
    'Austria': '🇦🇹',
    'Sweden': '🇸🇪',
    'Norway': '🇳🇴',
    'Denmark': '🇩🇰',
    'Finland': '🇫🇮',
    'Ireland': '🇮🇪',
    'New Zealand': '🇳🇿',
    'South Africa': '🇿🇦',
    'Nigeria': '🇳🇬',
    'Kenya': '🇰🇪',
    'Ghana': '🇬🇭',
    'Ethiopia': '🇪🇹',
    'Tanzania': '🇹🇿',
    'Uganda': '🇺🇬',
    'Morocco': '🇲🇦',
    'Algeria': '🇩🇿',
    'Tunisia': '🇹🇳',
    'Libya': '🇱🇾',
    'Sudan': '🇸🇩',
    'Somalia': '🇸🇴',
    'Djibouti': '🇩🇯',
    'Eritrea': '🇪🇷',
    'Chad': '🇹🇩',
    'Niger': '🇳🇪',
    'Mali': '🇲🇱',
    'Burkina Faso': '🇧🇫',
    'Senegal': '🇸🇳',
    'Guinea': '🇬🇳',
    'Sierra Leone': '🇸🇱',
    'Liberia': '🇱🇷',
    'Ivory Coast': '🇨🇮',
    'Gambia': '🇬🇲',
    'Guinea-Bissau': '🇬🇼',
    'Cape Verde': '🇨🇻',
    'Mauritania': '🇲🇷',
    'Argentina': '🇦🇷',
    'Chile': '🇨🇱',
    'Peru': '🇵🇪',
    'Colombia': '🇨🇴',
    'Venezuela': '🇻🇪',
    'Ecuador': '🇪🇨',
    'Bolivia': '🇧🇴',
    'Paraguay': '🇵🇾',
    'Uruguay': '🇺🇾',
    'Andorra': '🇦🇩',
  };

  /// Convert country name to flag emoji
  /// Returns the flag emoji if found, otherwise returns default flag (🇵🇰)
  static String getFlagEmoji(String? countryName) {
    if (countryName == null || countryName.isEmpty) {
      return '🇵🇰'; // Default flag
    }

    // Try exact match first
    final normalizedName = countryName.trim();
    if (_countryToFlag.containsKey(normalizedName)) {
      return _countryToFlag[normalizedName]!;
    }

    // Try case-insensitive match
    for (var entry in _countryToFlag.entries) {
      if (entry.key.toLowerCase() == normalizedName.toLowerCase()) {
        return entry.value;
      }
    }

    // Default fallback
    return '🇵🇰';
  }
}

