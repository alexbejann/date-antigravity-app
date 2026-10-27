import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/date_invitation_data.dart';
import '../utils/file_downloader.dart';

class DateTicketCard extends StatelessWidget {
  final DateInvitationData data;
  final DateOption selectedDate;
  final RestaurantOption selectedRestaurant;
  final List<ExtraPerk> selectedExtras;
  final String customRequestNote;
  final int noAttemptsCount;
  final VoidCallback onCelebrateAgain;
  final VoidCallback onStartOver;

  const DateTicketCard({
    super.key,
    required this.data,
    required this.selectedDate,
    required this.selectedRestaurant,
    required this.selectedExtras,
    required this.customRequestNote,
    required this.noAttemptsCount,
    required this.onCelebrateAgain,
    required this.onStartOver,
  });

  String _buildShareableMessage() {
    final extrasStr = selectedExtras.isEmpty
        ? 'Just your handsome company 💕'
        : selectedExtras.map((e) => '• ${e.label}').join('\n');
    final noteLine = customRequestNote.trim().isEmpty
        ? ''
        : '\n📝 Special Demand: "${customRequestNote.trim()}"\n';
    final stubbornLine = noAttemptsCount == 0
        ? '😇 I clicked YES on the very first try (0 hesitation!).'
        : '😂 I tried to click "No" $noAttemptsCount time(s) before surrendering to your charm.';

    return '''
💌 OFFICIAL DATE NIGHT CONFIRMATION TICKET 💌
━━━━━━━━━━━━━━━━━━━━━━
🎟️ Ticket Holder: ${data.partnerName}
🤵 Lucky Chauffeur & Date: ${data.inviterName}

📅 When: ${selectedDate.dayLabel} (${selectedDate.dateText} @ ${selectedDate.timeText})
✨ Vibe: ${selectedDate.vibe}

${selectedRestaurant.emoji} Where: ${selectedRestaurant.name}
🍽️ Cuisine: ${selectedRestaurant.cuisine} (${selectedRestaurant.priceLevel})
📍 Address: ${selectedRestaurant.address}
🗺️ Google Maps: ${selectedRestaurant.mapsUrl}
👗 Dress Code: ${selectedRestaurant.dressCode}

🎁 VIP Princess Add-ons:
$extrasStr
$noteLine
$stubbornLine
━━━━━━━━━━━━━━━━━━━━━━
Confirmation Code: LUV-1745-LESTARI 💖
''';
  }

  String _buildIcsCalendarContent() {
    final nowLocal = DateTime.now();
    // Find upcoming Saturday
    final daysUntilSaturday = (DateTime.saturday - nowLocal.weekday) % 7;
    final targetSaturday = nowLocal.add(
      Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday),
    );
    // Saturday at 17:45 local time
    final startLocal = DateTime(
      targetSaturday.year,
      targetSaturday.month,
      targetSaturday.day,
      17,
      45,
    );
    final startUtc = startLocal.toUtc();
    final endUtc = startUtc.add(const Duration(hours: 3));
    final nowUtc = nowLocal.toUtc();

    String fmt(DateTime dt) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}${two(dt.month)}${two(dt.day)}T${two(dt.hour)}${two(dt.minute)}00Z';
    }

    final extrasText = selectedExtras.isEmpty
        ? 'Unlimited compliments'
        : selectedExtras.map((e) => e.label).join(', ');

    final description =
        'Romantic Date with ${data.inviterName}!\\n'
        'When: ${selectedDate.dayLabel} (${selectedDate.dateText} at ${selectedDate.timeText})\\n'
        'Restaurant: ${selectedRestaurant.name} (${selectedRestaurant.cuisine})\\n'
        'Google Maps: ${selectedRestaurant.mapsUrl}\\n'
        'Special Dish: ${selectedRestaurant.specialDish}\\n'
        'Dress Code: ${selectedRestaurant.dressCode}\\n'
        'VIP Perks: $extrasText';

    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//RomanticDateDispatch//EN',
      'BEGIN:VEVENT',
      'UID:date-invite-${nowUtc.millisecondsSinceEpoch}@loveticket.app',
      'DTSTAMP:${fmt(nowUtc)}',
      'DTSTART:${fmt(startUtc)}',
      'DTEND:${fmt(endUtc)}',
      'SUMMARY:💖 Date Night: ${selectedRestaurant.name} with ${data.inviterName}',
      'LOCATION:${selectedRestaurant.name}, ${selectedRestaurant.address} (${selectedRestaurant.mapsUrl})',
      'DESCRIPTION:$description',
      'URL:${selectedRestaurant.mapsUrl}',
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\r\n');
  }

  Future<void> _copyMessage(BuildContext context) async {
    final msg = _buildShareableMessage();
    await Clipboard.setData(ClipboardData(text: msg));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFD81B60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          '💌 Copied! Now paste & send it to ${data.inviterName}!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
    onCelebrateAgain();
  }

  void _openGoogleMaps(BuildContext context) {
    final opened = openBrowserUrl(selectedRestaurant.mapsUrl);
    if (!opened) {
      Clipboard.setData(ClipboardData(text: selectedRestaurant.mapsUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC9184A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            '📍 Google Maps link copied: ${selectedRestaurant.mapsUrl}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _downloadCalendarInvite(BuildContext context) {
    final ics = _buildIcsCalendarContent();
    final downloaded = triggerBrowserDownload(
      filename: 'saturday_1745_lestari_date.ics',
      content: ics,
      mimeType: 'text/calendar;charset=utf-8',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF7B2CBF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          downloaded
              ? '📅 Calendar invite for Saturday @ 17:45 downloaded!'
              : '📅 Calendar invite ready! Use "Copy Receipt" to share.',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
    onCelebrateAgain();
  }

  void _downloadTicketReceipt(BuildContext context) {
    final txt = _buildShareableMessage();
    final downloaded = triggerBrowserDownload(
      filename: 'official_date_ticket.txt',
      content: txt,
      mimeType: 'text/plain;charset=utf-8',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2B9348),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          downloaded
              ? '🎟️ Official Date Ticket downloaded!'
              : '🎟️ Ticket copied to clipboard!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
    onCelebrateAgain();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top celebratory banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF2A6D).withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'SATURDAY @ 17:45 LOCKED IN! NO TAKE-BACKS ALLOWED!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC9184A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 12.5,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text('🥂', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Perforated Boarding Pass / VIP Ticket Card
        ClipPath(
          clipper: _TicketClipper(holeRadius: 16, splitRatio: 0.70),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2A6D).withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ticket Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF2A6D), Color(0xFFFF758F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '🎟️',
                          style: TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VIP ROMANTIC BOARDING PASS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data.inviterName} × ${data.partnerName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'SAT 17:45 💖',
                          style: TextStyle(
                            color: Color(0xFFC9184A),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Ticket Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Time Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _TicketField(
                              label: 'WHEN WE\'RE GOING',
                              value:
                                  '${selectedDate.emoji} ${selectedDate.dayLabel}',
                              subvalue:
                                  '${selectedDate.dateText} • ${selectedDate.timeText} sharp',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TicketField(
                              label: 'MOOD / VIBE',
                              value: selectedDate.vibe,
                              subvalue: 'Chauffeur: ${data.inviterName}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: Color(0xFFFFE5EC)),
                      const SizedBox(height: 18),

                      // Restaurant Section
                      _TicketField(
                        label: 'DESTINATION RESTAURANT',
                        value:
                            '${selectedRestaurant.emoji} ${selectedRestaurant.name}',
                        subvalue:
                            '${selectedRestaurant.cuisine} • ${selectedRestaurant.priceLevel} • ${selectedRestaurant.vibeTag}',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFCCD5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_rounded,
                                  size: 16,
                                  color: Color(0xFFC9184A),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    selectedRestaurant.address,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: Color(0xFF590D22),
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _openGoogleMaps(context),
                                  icon: const Icon(
                                    Icons.map_rounded,
                                    size: 16,
                                    color: Color(0xFFFF2A6D),
                                  ),
                                  label: const Text(
                                    'Open Maps 📍',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                      color: Color(0xFFFF2A6D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 16,
                                  color: Color(0xFFC9184A),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Must-try: ${selectedRestaurant.specialDish}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF800F2F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.checkroom_rounded,
                                  size: 16,
                                  color: Color(0xFFC9184A),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Dress Code: ${selectedRestaurant.dressCode}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF800F2F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (selectedExtras.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'INCLUDED PRINCESS PERKS & DEMANDS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Color(0xFFA4133C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedExtras.map((perk) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE5EC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                perk.label,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF800F2F),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (customRequestNote.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFD166),
                            ),
                          ),
                          child: Text(
                            '📝 Special Note: "${customRequestNote.trim()}"',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B4E00),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Perforated Dashed Divider
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: CustomPaint(
                    size: const Size(double.infinity, 2),
                    painter: _DashedLinePainter(),
                  ),
                ),

                // Ticket Stub / Barcode Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      Text(
                        noAttemptsCount == 0
                            ? '😇 Fun Fact: You clicked YES with 0 attempts to click No. True love verified!'
                            : '😂 Fun Fact: You tried to click "No" $noAttemptsCount time(s) before admitting you\'re obsessed with me.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF800F2F),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Faux Barcode
                      SizedBox(
                        height: 38,
                        width: 240,
                        child: CustomPaint(
                          painter: _BarcodePainter(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'AUTH CODE: LUV-1745-LESTARI • NON-REFUNDABLE KISSES',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Action Buttons (Copy to Send, Open Google Maps, Download Calendar, Download Ticket)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _copyMessage(context),
              icon: const Icon(Icons.copy_rounded),
              label: Text('Copy Receipt to Send to ${data.inviterName} 💌'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2A6D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _openGoogleMaps(context),
              icon: const Icon(Icons.location_on_rounded),
              label: const Text('View Lestari on Google Maps 🇮🇩'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC9184A),
                side: const BorderSide(color: Color(0xFFFF2A6D), width: 2),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadCalendarInvite(context),
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Download Calendar Invite (.ics)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC9184A),
                side: const BorderSide(color: Color(0xFFFF4D79), width: 2),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadTicketReceipt(context),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Save Ticket (.txt)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF590D22),
                side: const BorderSide(color: Color(0xFFFFB3C1), width: 1.5),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onCelebrateAgain,
              icon: const Text('🎊'),
              label: const Text(
                'Shower More Hearts!',
                style: TextStyle(
                  color: Color(0xFFC9184A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onStartOver,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Replay Steps',
                style: TextStyle(
                  color: Color(0xFF800F2F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TicketField extends StatelessWidget {
  final String label;
  final String value;
  final String subvalue;

  const _TicketField({
    required this.label,
    required this.value,
    required this.subvalue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Color(0xFFA4133C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF590D22),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subvalue,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF800F2F),
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB3C1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF590D22)
      ..style = PaintingStyle.fill;

    final widths = [
      3.0, 1.5, 4.0, 2.0, 1.5, 5.0, 2.0, 1.5, 3.5, 2.0, 1.5, 4.5, 2.0, 3.0,
      1.5, 2.5, 4.0, 1.5, 3.0, 2.0, 5.0, 1.5, 2.0, 3.5, 1.5, 4.0, 2.0, 3.0
    ];
    double x = 0;
    for (int i = 0; i < widths.length; i++) {
      final w = widths[i];
      if (x + w > size.width) break;
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      }
      x += w + 2.2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TicketClipper extends CustomClipper<Path> {
  final double holeRadius;
  final double splitRatio;

  _TicketClipper({
    required this.holeRadius,
    required this.splitRatio,
  });

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holeY = size.height * splitRatio;

    final notches = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(0, holeY), radius: holeRadius),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(size.width, holeY), radius: holeRadius),
      );

    return Path.combine(PathOperation.difference, path, notches);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
