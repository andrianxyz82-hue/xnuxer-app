import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NicknameGeneratorTab extends StatefulWidget {
  const NicknameGeneratorTab({Key? key}) : super(key: key);

  @override
  State<NicknameGeneratorTab> createState() => _NicknameGeneratorTabState();
}

class _NicknameGeneratorTabState extends State<NicknameGeneratorTab>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  String _generatedNickname = '';
  bool _isGenerating = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _selectedCategory = 'Cool';

  final List<String> _categories = ['Cool', 'Funny', 'Pro Player'];

  final List<String> _coolPrefixes = [
    'Dark',
    'Shadow',
    'Fire',
    'Ice',
    'Storm',
    'Thunder',
    'Blade',
    'Ghost',
    'Venom',
    'Savage',
    'Elite',
    'Alpha',
    'Phoenix',
    'Dragon',
    'Wolf',
    'Hawk'
  ];

  final List<String> _coolSuffixes = [
    'Hunter',
    'Killer',
    'Master',
    'Lord',
    'King',
    'Warrior',
    'Slayer',
    'Beast',
    'Demon',
    'Legend',
    'Hero',
    'Champion',
    'Destroyer',
    'Reaper',
    'Sniper',
    'Assassin'
  ];

  final List<String> _funnyPrefixes = [
    'Crazy',
    'Silly',
    'Funny',
    'Wacky',
    'Goofy',
    'Dizzy',
    'Bouncy',
    'Giggly',
    'Tickle',
    'Bubble',
    'Fluffy',
    'Squishy',
    'Wiggly',
    'Jolly',
    'Peppy',
    'Zippy'
  ];

  final List<String> _funnySuffixes = [
    'Banana',
    'Pickle',
    'Noodle',
    'Muffin',
    'Cookie',
    'Pancake',
    'Waffle',
    'Donut',
    'Taco',
    'Pizza',
    'Burger',
    'Chicken',
    'Potato',
    'Cheese',
    'Bacon',
    'Sandwich'
  ];

  final List<String> _proPrefixes = [
    'Pro',
    'Ace',
    'Elite',
    'Master',
    'Expert',
    'Skilled',
    'Tactical',
    'Strategic',
    'Precision',
    'Sharp',
    'Quick',
    'Swift',
    'Rapid',
    'Flash',
    'Bullet',
    'Rocket'
  ];

  final List<String> _proSuffixes = [
    'Gamer',
    'Player',
    'Shooter',
    'Sniper',
    'Tactician',
    'Strategist',
    'Champion',
    'Winner',
    'Victor',
    'Conqueror',
    'Dominator',
    'Crusher',
    'Breaker',
    'Striker',
    'Fighter',
    'Warrior'
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _generateNickname() {
    List<String> prefixes;
    List<String> suffixes;

    switch (_selectedCategory) {
      case 'Funny':
        prefixes = _funnyPrefixes;
        suffixes = _funnySuffixes;
        break;
      case 'Pro Player':
        prefixes = _proPrefixes;
        suffixes = _proSuffixes;
        break;
      default:
        prefixes = _coolPrefixes;
        suffixes = _coolSuffixes;
    }

    final random = DateTime.now().millisecondsSinceEpoch;
    final prefix = prefixes[random % prefixes.length];
    final suffix = suffixes[(random ~/ 1000) % suffixes.length];

    if (_nameController.text.trim().isNotEmpty) {
      final variations = [
        '${prefix}_${_nameController.text.trim()}',
        '${_nameController.text.trim()}_$suffix',
        '${prefix}${_nameController.text.trim()}$suffix',
        '${_nameController.text.trim()}${(random % 999) + 1}',
        '${prefix}_${_nameController.text.trim()}_$suffix',
      ];
      return variations[random % variations.length];
    } else {
      return '${prefix}_$suffix';
    }
  }

  Future<void> _onGeneratePressed() async {
    if (_isGenerating) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isGenerating = true;
    });

    // Simulate generation delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _generatedNickname = _generateNickname();
      _isGenerating = false;
    });
  }

  Future<void> _copyToClipboard() async {
    if (_generatedNickname.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _generatedNickname));
      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nickname disalin ke clipboard!',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Selection
          SizedBox(height: 2.h),
          Text(
            'Pilih Kategori',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 6.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Container(
                  margin: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(
                      category,
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.lightTheme.colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        HapticFeedback.selectionClick();
                      }
                    },
                    selectedColor: AppTheme.lightTheme.colorScheme.tertiary,
                    backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.outline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 3.h),

          // Name Input Field
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.tertiary
                    .withValues(alpha: 0.3),
                width: 2,
              ),
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.colorScheme.surface,
                  AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: TextField(
              controller: _nameController,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Masukkan nama kamu (opsional)',
                hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 2.h,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'person',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    size: 6.w,
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onGeneratePressed(),
            ),
          ),

          SizedBox(height: 4.h),

          // Generate Button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  height: 7.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.lightTheme.colorScheme.tertiary,
                        AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _onGeneratePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isGenerating
                        ? SizedBox(
                            width: 6.w,
                            height: 6.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'auto_awesome',
                                color: Colors.white,
                                size: 6.w,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Generate Nickname',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 4.h),

          // Generated Nickname Display
          if (_generatedNickname.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.lightTheme.colorScheme.primaryContainer,
                    AppTheme.lightTheme.colorScheme.primaryContainer
                        .withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Nickname Kamu:',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  SelectableText(
                    _generatedNickname,
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Copy Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: CustomIconWidget(
                            iconName: 'content_copy',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 5.w,
                          ),
                          label: Text(
                            'Salin',
                            style: AppTheme.lightTheme.textTheme.labelLarge
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // Regenerate Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onGeneratePressed,
                          icon: CustomIconWidget(
                            iconName: 'refresh',
                            color: Colors.white,
                            size: 5.w,
                          ),
                          label: Text(
                            'Generate Lagi',
                            style: AppTheme.lightTheme.textTheme.labelLarge
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.tertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),
          ],

          // Random Generation Suggestions
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Tips:',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '• Kosongkan nama untuk nickname random\n• Pilih kategori sesuai style bermain\n• Tekan generate berkali-kali untuk variasi',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    height: 1.4,
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
