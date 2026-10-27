import 'dart:convert';

class DateInvitationData {
  final String inviterName;
  final String partnerName;
  final HeroConfig hero;
  final List<DateOption> dates;
  final List<RestaurantOption> restaurants;
  final List<ExtraPerk> extras;

  const DateInvitationData({
    required this.inviterName,
    required this.partnerName,
    required this.hero,
    required this.dates,
    required this.restaurants,
    required this.extras,
  });

  factory DateInvitationData.fromJsonString(String jsonStr) {
    final Map<String, dynamic> map = json.decode(jsonStr) as Map<String, dynamic>;
    return DateInvitationData.fromJson(map);
  }

  factory DateInvitationData.fromJson(Map<String, dynamic> json) {
    return DateInvitationData(
      inviterName: json['inviterName'] as String? ?? 'Your Favorite Person',
      partnerName: json['partnerName'] as String? ?? 'Cutie',
      hero: HeroConfig.fromJson(json['hero'] as Map<String, dynamic>? ?? {}),
      dates: (json['dates'] as List<dynamic>? ?? [])
          .map((e) => DateOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      restaurants: (json['restaurants'] as List<dynamic>? ?? [])
          .map((e) => RestaurantOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      extras: (json['extras'] as List<dynamic>? ?? [])
          .map((e) => ExtraPerk.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  DateOption get destinedDate =>
      dates.firstWhere((d) => d.isDestined, orElse: () => dates.first);

  RestaurantOption get destinedRestaurant => restaurants.firstWhere(
        (r) => r.isDestined,
        orElse: () => restaurants.first,
      );
}

class HeroConfig {
  final String badge;
  final String title;
  final String subtitle;
  final String yesButtonText;
  final String noButtonInitialText;
  final List<String> noButtonPleadingMessages;
  final String termsDisclaimer;

  const HeroConfig({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.yesButtonText,
    required this.noButtonInitialText,
    required this.noButtonPleadingMessages,
    required this.termsDisclaimer,
  });

  factory HeroConfig.fromJson(Map<String, dynamic> json) {
    return HeroConfig(
      badge: json['badge'] as String? ?? 'URGENT ROMANTIC DISPATCH 💌',
      title: json['title'] as String? ?? 'Will You Go On a Date With Me?',
      subtitle: json['subtitle'] as String? ??
          'Warning: Saying yes includes complimentary butterflies and great food.',
      yesButtonText: json['yesButtonText'] as String? ?? 'YES! 💖',
      noButtonInitialText: json['noButtonInitialText'] as String? ?? 'No thanks',
      noButtonPleadingMessages:
          (json['noButtonPleadingMessages'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      termsDisclaimer: json['termsDisclaimer'] as String? ?? '',
    );
  }
}

class DateOption {
  final String id;
  final String dayLabel;
  final String dateText;
  final String timeText;
  final String vibe;
  final String emoji;
  final String funnyNote;
  final String tooltip;
  final bool isDestined;
  final String riggedExcuse;

  const DateOption({
    required this.id,
    required this.dayLabel,
    required this.dateText,
    required this.timeText,
    required this.vibe,
    required this.emoji,
    required this.funnyNote,
    required this.tooltip,
    required this.isDestined,
    required this.riggedExcuse,
  });

  factory DateOption.fromJson(Map<String, dynamic> json) {
    return DateOption(
      id: json['id'] as String? ?? '',
      dayLabel: json['dayLabel'] as String? ?? '',
      dateText: json['dateText'] as String? ?? '',
      timeText: json['timeText'] as String? ?? '',
      vibe: json['vibe'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📅',
      funnyNote: json['funnyNote'] as String? ?? '',
      tooltip: json['tooltip'] as String? ?? '',
      isDestined: json['isDestined'] as bool? ?? true,
      riggedExcuse: json['riggedExcuse'] as String? ?? '',
    );
  }
}

class RestaurantOption {
  final String id;
  final String name;
  final String cuisine;
  final String emoji;
  final String priceLevel;
  final String vibeTag;
  final String address;
  final String mapsUrl;
  final String description;
  final String funnyPerk;
  final String specialDish;
  final String dressCode;
  final bool isDestined;
  final String riggedExcuse;

  const RestaurantOption({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.emoji,
    required this.priceLevel,
    required this.vibeTag,
    required this.address,
    required this.mapsUrl,
    required this.description,
    required this.funnyPerk,
    required this.specialDish,
    required this.dressCode,
    required this.isDestined,
    required this.riggedExcuse,
  });

  factory RestaurantOption.fromJson(Map<String, dynamic> json) {
    return RestaurantOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🍽️',
      priceLevel: json['priceLevel'] as String? ?? r'$$',
      vibeTag: json['vibeTag'] as String? ?? '',
      address: json['address'] as String? ?? '',
      mapsUrl: json['mapsUrl'] as String? ??
          'https://maps.app.goo.gl/5w67QseydzxbkMb66',
      description: json['description'] as String? ?? '',
      funnyPerk: json['funnyPerk'] as String? ?? '',
      specialDish: json['specialDish'] as String? ?? '',
      dressCode: json['dressCode'] as String? ?? '',
      isDestined: json['isDestined'] as bool? ?? true,
      riggedExcuse: json['riggedExcuse'] as String? ?? '',
    );
  }
}

class ExtraPerk {
  final String id;
  final String label;
  final String tooltip;

  const ExtraPerk({
    required this.id,
    required this.label,
    required this.tooltip,
  });

  factory ExtraPerk.fromJson(Map<String, dynamic> json) {
    return ExtraPerk(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      tooltip: json['tooltip'] as String? ?? '',
    );
  }
}
