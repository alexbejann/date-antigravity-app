import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/date_invitation_data.dart';
import 'utils/file_downloader.dart';
import 'widgets/date_ticket_card.dart';
import 'widgets/floating_hearts_background.dart';

void main() {
  runApp(const RomanticDateApp());
}

class RomanticDateApp extends StatelessWidget {
  final DateInvitationData? initialData;

  const RomanticDateApp({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '💌 Urgent Romantic Dispatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF2A6D),
          primary: const Color(0xFFFF2A6D),
          secondary: const Color(0xFFC9184A),
          surface: Colors.white,
        ),
        fontFamily: 'Georgia',
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFF590D22),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      ),
      home: DateInvitationHomePage(initialData: initialData),
    );
  }
}

class DateInvitationHomePage extends StatefulWidget {
  final DateInvitationData? initialData;

  const DateInvitationHomePage({super.key, this.initialData});

  @override
  State<DateInvitationHomePage> createState() => _DateInvitationHomePageState();
}

class _DateInvitationHomePageState extends State<DateInvitationHomePage>
    with SingleTickerProviderStateMixin {
  DateInvitationData? _data;
  String? _loadError;

  // Step 0: Proposal, Step 1: Pick Date, Step 2: Pick Restaurant + Perks, Step 3: Final Ticket
  int _currentStep = 0;

  // Runaway "No" button state
  int _noAttempts = 0;
  Alignment _noButtonAlignment = const Alignment(0.45, 0.0);
  final math.Random _rng = math.Random();
  String? _funnyAlertBanner;

  // Rigged date & restaurant banners
  String? _dateRiggedBanner;
  String? _restaurantRiggedBanner;

  // User selections
  DateOption? _selectedDate;
  RestaurantOption? _selectedRestaurant;
  final Set<String> _selectedExtraIds = {};
  final TextEditingController _customNoteController = TextEditingController();
  final ScrollController _mainScrollController = ScrollController();

  // Confetti trigger counter
  int _confettiTrigger = 0;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    if (widget.initialData != null) {
      _initializeWithData(widget.initialData!);
    } else {
      _loadJsonData();
    }
  }

  void _initializeWithData(DateInvitationData loaded) {
    setState(() {
      _data = loaded;
      if (loaded.dates.isNotEmpty) {
        _selectedDate = loaded.destinedDate;
      }
      if (loaded.restaurants.isNotEmpty) {
        _selectedRestaurant = loaded.destinedRestaurant;
      }
      if (loaded.extras.isNotEmpty) {
        for (final extra in loaded.extras.take(3)) {
          _selectedExtraIds.add(extra.id);
        }
      }
    });
  }

  Future<void> _loadJsonData() async {
    try {
      final rawJson = await rootBundle.loadString('assets/date_options.json');
      final parsed = DateInvitationData.fromJsonString(rawJson);
      if (!mounted) return;
      _initializeWithData(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'Could not load assets/date_options.json ($e). Check that valid JSON is formatted properly!';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _customNoteController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _currentStep = step;
    });
    if (_mainScrollController.hasClients) {
      _mainScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _triggerConfetti() {
    setState(() {
      _confettiTrigger++;
    });
  }

  void _evadeNoButton() {
    final data = _data;
    if (data == null) return;

    double nextX;
    double nextY;
    int guard = 0;
    do {
      nextX = (_rng.nextDouble() * 1.8) - 0.9;
      nextY = (_rng.nextDouble() * 1.6) - 0.8;
      guard++;
    } while ((((nextX - _noButtonAlignment.x).abs() < 0.45 &&
                (nextY - _noButtonAlignment.y).abs() < 0.45) ||
            (nextX.abs() < 0.45 && nextY.abs() < 0.45)) &&
        guard < 25);

    final messages = data.hero.noButtonPleadingMessages;
    final msg = messages.isEmpty
        ? 'Nice try! That button is strictly decorative 💕'
        : messages[_noAttempts % messages.length];

    setState(() {
      _noAttempts++;
      _noButtonAlignment = Alignment(nextX, nextY);
      _funnyAlertBanner = msg;
    });
  }

  void _onYesClicked() {
    _triggerConfetti();
    setState(() {
      _funnyAlertBanner = null;
    });
    _goToStep(1);
  }

  void _onDateOptionTapped(DateInvitationData data, DateOption option) {
    if (option.isDestined) {
      setState(() {
        _selectedDate = option;
        _dateRiggedBanner =
            '💖 Excellent choice! Saturday at 17:45 is officially locked in!';
      });
      return;
    }

    // Rigged date behavior: show funny excuse and snap back to Saturday @ 17:45!
    final destined = data.destinedDate;
    final excuse = option.riggedExcuse.isNotEmpty
        ? option.riggedExcuse
        : '🚨 Schedule Override: Only ${destined.dayLabel} is allowed! Switching you back 💕';

    setState(() {
      _selectedDate = destined;
      _dateRiggedBanner = excuse;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC9184A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            excuse,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _onRestaurantOptionTapped(
    DateInvitationData data,
    RestaurantOption rest,
  ) {
    if (rest.isDestined) {
      setState(() {
        _selectedRestaurant = rest;
        _restaurantRiggedBanner =
            '🇮🇩💖 Best decision ever! Lestari Indonesisch Restaurant is ready for us!';
      });
      return;
    }

    // Rigged restaurant behavior: show funny excuse and snap back to Lestari!
    final destined = data.destinedRestaurant;
    final excuse = rest.riggedExcuse.isNotEmpty
        ? rest.riggedExcuse
        : '🚨 Chef Override: Switching you back to ${destined.name}! 💕';

    setState(() {
      _selectedRestaurant = destined;
      _restaurantRiggedBanner = excuse;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC9184A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            excuse,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _pickRandomRestaurant() {
    final data = _data;
    if (data == null || data.restaurants.isEmpty) return;
    final picked = data.destinedRestaurant;
    setState(() {
      _selectedRestaurant = picked;
      _restaurantRiggedBanner =
          '🎲 Totally 100% Unrigged Randomizer Result: ${picked.emoji} ${picked.name} at 17:45! What a crazy coincidence! 😉💖';
    });
    _triggerConfetti();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC9184A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            '🎲 Destiny has spoken: ${picked.emoji} ${picked.name}!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showLoveDiagnosticsDialog() {
    final inviter = _data?.inviterName ?? 'Alex';
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: const Color(0xFFFFF8FA),
          title: const Row(
            children: [
              Text('🩺', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'System Love Diagnostics',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF590D22),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiagnosticRow(
                label: 'Chance of $inviter being obsessed with you:',
                value: '1,000,000%',
              ),
              const SizedBox(height: 10),
              const _DiagnosticRow(
                label: '"No" Button Status:',
                value: 'Broken on purpose 🛠️',
              ),
              const SizedBox(height: 10),
              const _DiagnosticRow(
                label: 'Locked Date & Time:',
                value: 'Saturday @ 17:45 🌅',
              ),
              const SizedBox(height: 10),
              const _DiagnosticRow(
                label: 'Locked Restaurant:',
                value: 'Lestari 🇮🇩',
              ),
              const SizedBox(height: 10),
              _DiagnosticRow(
                label: 'Refusal Attempts Logged:',
                value: '$_noAttempts attempt(s)',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Verdict: Zero bugs found. Free will is temporarily suspended until after our Indonesian Rijsttafel on Saturday at 17:45.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF800F2F),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF2A6D),
              ),
              child: const Text('Fair enough 💖'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _loadError!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2A6D)),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FloatingHeartsBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(data),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        controller: _mainScrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 740),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.05),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCurrentStepContent(data),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CelebrationConfettiOverlay(
              triggerCount: _confettiTrigger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(DateInvitationData data) {
    final steps = [
      '💌 The Question',
      '📅 Pick Time',
      '🇮🇩 Pick Feast',
      '🎟️ Date Ticket',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(steps.length, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                return GestureDetector(
                  onTap: isCompleted ? () => _goToStep(index) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFF2A6D)
                          : (isCompleted
                              ? const Color(0xFFFFCCD5)
                              : Colors.white.withOpacity(0.75)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFFF2A6D)
                            : const Color(0xFFFFB3C1),
                      ),
                    ),
                    child: Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color:
                            isActive ? Colors.white : const Color(0xFF800F2F),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Tooltip(
            message: 'Having trouble clicking "No"? Run system diagnostics!',
            child: TextButton.icon(
              onPressed: _showLoveDiagnosticsDialog,
              icon: const Icon(
                Icons.bug_report_outlined,
                size: 17,
                color: Color(0xFFA4133C),
              ),
              label: const Text(
                'Report a Bug',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA4133C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(DateInvitationData data) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Proposal(data);
      case 1:
        return _buildStep2PickDate(data);
      case 2:
        return _buildStep3PickRestaurant(data);
      case 3:
      default:
        final chosenDate = _selectedDate ?? data.destinedDate;
        final chosenRestaurant = _selectedRestaurant ?? data.destinedRestaurant;
        final chosenExtras = data.extras
            .where((e) => _selectedExtraIds.contains(e.id))
            .toList();

        return DateTicketCard(
          key: const ValueKey('step_4_ticket'),
          data: data,
          selectedDate: chosenDate,
          selectedRestaurant: chosenRestaurant,
          selectedExtras: chosenExtras,
          customRequestNote: _customNoteController.text,
          noAttemptsCount: _noAttempts,
          onCelebrateAgain: _triggerConfetti,
          onStartOver: () => _goToStep(1),
        );
    }
  }

  // ===========================================================================
  // STEP 1: THE PROPOSAL (WITH RUNAWAY "NO" BUTTON)
  // ===========================================================================
  Widget _buildStep1Proposal(DateInvitationData data) {
    final yesScale = (1.0 + (_noAttempts * 0.08)).clamp(1.0, 1.55);
    final noScale = (1.0 - (_noAttempts * 0.06)).clamp(0.55, 1.0);
    final messages = data.hero.noButtonPleadingMessages;
    final currentNoLabel = _noAttempts == 0 || messages.isEmpty
        ? data.hero.noButtonInitialText
        : messages[(_noAttempts - 1) % messages.length];

    return Container(
      key: const ValueKey('step_1_proposal'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFCCD5), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2A6D).withOpacity(0.14),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.hero.badge,
              style: const TextStyle(
                color: Color(0xFFC9184A),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.08).animate(
              CurvedAnimation(
                parent: _pulseController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2A6D), Color(0xFFFF758F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2A6D).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                '💌',
                style: TextStyle(fontSize: 42),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data.hero.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF590D22),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.hero.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF800F2F),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _funnyAlertBanner == null
                ? const SizedBox(height: 8)
                : Container(
                    key: ValueKey(_funnyAlertBanner),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF4D79),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🚨', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _funnyAlertBanner!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFC9184A),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8FA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFE5EC)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Runaway & Shrinking NO Button (underneath so YES always dominates)
                AnimatedAlign(
                  alignment: _noButtonAlignment,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: MouseRegion(
                    onEnter: (_) => _evadeNoButton(),
                    child: GestureDetector(
                      onTapDown: (_) => _evadeNoButton(),
                      child: AnimatedScale(
                        scale: noScale,
                        duration: const Duration(milliseconds: 200),
                        child: OutlinedButton(
                          key: const Key('no_button'),
                          onPressed: _evadeNoButton,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF800F2F),
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFFFB3C1),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            currentNoLabel,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // The Growing YES Button (Always on top!)
                Align(
                  alignment: _noAttempts == 0
                      ? const Alignment(-0.38, 0.0)
                      : const Alignment(0.0, 0.0),
                  child: AnimatedScale(
                    scale: yesScale,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.elasticOut,
                    child: Tooltip(
                      message: 'Best decision of your week, guaranteed ✨',
                      child: ElevatedButton(
                        key: const Key('yes_button'),
                        onPressed: _onYesClicked,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF2A6D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
                          ),
                          elevation: 8,
                          shadowColor:
                              const Color(0xFFFF2A6D).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          data.hero.yesButtonText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_noAttempts > 0) ...[
            const SizedBox(height: 12),
            Text(
              '📊 Stubbornness Telemetry: $_noAttempts failed attempt(s) to resist ${data.inviterName}\'s charm.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA4133C),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            data.hero.termsDisclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF590D22).withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 2: PICK A DATE & TIME (RIGGED FOR SATURDAY @ 17:45)
  // ===========================================================================
  Widget _buildStep2PickDate(DateInvitationData data) {
    return Container(
      key: const ValueKey('step_2_pick_date'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFCCD5), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2A6D).withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'YAY! SHE SAID YES! 🎉💖',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFF2A6D),
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Step 1: When Should I Pick You Up?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF590D22),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You have complete freedom to pick any date below (as long as it\'s Saturday at 17:45 😉).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: Color(0xFF800F2F),
            ),
          ),
          const SizedBox(height: 16),

          if (_dateRiggedBanner != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF2A6D), width: 1.5),
              ),
              child: Text(
                _dateRiggedBanner!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC9184A),
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],

          // Date Option Cards
          ...data.dates.map((option) {
            final isSelected = _selectedDate?.id == option.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Tooltip(
                message: option.tooltip,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _onDateOptionTapped(data, option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF0F5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF2A6D)
                            : const Color(0xFFFFCCD5),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFFFF2A6D).withOpacity(0.16),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF2A6D)
                                : const Color(0xFFFFE5EC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            option.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    option.dayLabel,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF590D22),
                                    ),
                                  ),
                                  if (option.isDestined)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF2A6D),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '🌟 DESTINY\'S PICK',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE5EC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      option.vibe,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFC9184A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${option.dateText} • ${option.timeText}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFA4133C),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                option.funnyNote,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF590D22),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? const Color(0xFFFF2A6D)
                              : const Color(0xFFFFB3C1),
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              TextButton.icon(
                onPressed: () => _goToStep(0),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
              ElevatedButton.icon(
                key: const Key('to_restaurants_button'),
                onPressed: () => _goToStep(2),
                icon: const Icon(Icons.restaurant_rounded),
                label: const Text('Next: Pick Our Restaurant 🇮🇩'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2A6D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3: PICK A RESTAURANT & VIP PERKS (RIGGED FOR LESTARI ARNHEM)
  // ===========================================================================
  Widget _buildStep3PickRestaurant(DateInvitationData data) {
    return Container(
      key: const ValueKey('step_3_pick_restaurant'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFCCD5), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2A6D).withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'THE MOST IMPORTANT QUESTION 🍽️',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFF2A6D),
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Step 2: What Are We Craving?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF590D22),
            ),
          ),
          const SizedBox(height: 10),

          // Indecisive Girlfriend Randomizer Button (Rigged to pick Lestari!)
          Center(
            child: Tooltip(
              message:
                  'Click this if your answer is "I don\'t know, wherever you want!"',
              child: OutlinedButton.icon(
                onPressed: _pickRandomRestaurant,
                icon: const Text('🎲'),
                label: const Text(
                  '"I Can\'t Decide, Pick For Me!" Button',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC9184A),
                  side: const BorderSide(color: Color(0xFFFF758F)),
                  backgroundColor: const Color(0xFFFFF0F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_restaurantRiggedBanner != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF2A6D), width: 1.5),
              ),
              child: Text(
                _restaurantRiggedBanner!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC9184A),
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],

          // Restaurant Cards
          ...data.restaurants.map((rest) {
            final isSelected = _selectedRestaurant?.id == rest.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _onRestaurantOptionTapped(data, rest),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFFFFF0F5) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF2A6D)
                          : const Color(0xFFFFCCD5),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF2A6D).withOpacity(0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF2A6D)
                                  : const Color(0xFFFFE5EC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              rest.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      rest.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF590D22),
                                      ),
                                    ),
                                    if (rest.isDestined)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF2A6D),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          '🌟 RESERVED FOR US @ 17:45',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE5EC),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${rest.priceLevel} • ${rest.vibeTag}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFC9184A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${rest.cuisine} • 📍 ${rest.address}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFA4133C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isSelected
                                ? const Color(0xFFFF2A6D)
                                : const Color(0xFFFFB3C1),
                            size: 26,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rest.description,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF590D22),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCCD5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✨ Signature Dish: ${rest.specialDish}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF800F2F),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '😂 Bonus Perk: ${rest.funnyPerk}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF590D22),
                              ),
                            ),
                            if (rest.isDestined) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => openBrowserUrl(rest.mapsUrl),
                                  icon: const Icon(
                                    Icons.map_rounded,
                                    size: 16,
                                    color: Color(0xFFFF2A6D),
                                  ),
                                  label: const Text(
                                    'See Lestari on Google Maps 📍',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF2A6D),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFFFCCD5)),
          const SizedBox(height: 12),

          // VIP Princess Add-ons
          const Text(
            '👑 Select Your Complimentary Princess Add-ons:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF590D22),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select as many as you want (hover for fine print):',
            style: TextStyle(fontSize: 13, color: Color(0xFF800F2F)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: data.extras.map((extra) {
              final selected = _selectedExtraIds.contains(extra.id);
              return Tooltip(
                message: extra.tooltip,
                child: FilterChip(
                  selected: selected,
                  label: Text(extra.label),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF590D22),
                  ),
                  selectedColor: const Color(0xFFFF2A6D),
                  checkmarkColor: Colors.white,
                  backgroundColor: const Color(0xFFFFF0F5),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFFFF2A6D)
                        : const Color(0xFFFFB3C1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedExtraIds.add(extra.id);
                      } else {
                        _selectedExtraIds.remove(extra.id);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          TextField(
            controller: _customNoteController,
            decoration: InputDecoration(
              labelText: 'Any special requests, cravings, or demands? 💬',
              hintText: 'e.g., "Extra saté sauce" or "Wear that shirt I like"',
              filled: true,
              fillColor: const Color(0xFFFFF8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFFCCD5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFFCCD5)),
              ),
            ),
          ),

          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              TextButton.icon(
                onPressed: () => _goToStep(1),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Dates'),
              ),
              ElevatedButton.icon(
                key: const Key('generate_ticket_button'),
                onPressed: () {
                  _triggerConfetti();
                  _goToStep(3);
                },
                icon: const Icon(Icons.confirmation_number_rounded),
                label: const Text('Lock In Our Date Ticket! 🎟️💖'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2A6D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagnosticRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF590D22),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFFC9184A),
          ),
        ),
      ],
    );
  }
}
