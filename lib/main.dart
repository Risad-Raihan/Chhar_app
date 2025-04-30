import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/contentful_service.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'models/discount_provider.dart';
import 'services/auth_service.dart';
import 'components/animated_loading.dart';
import 'utils/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'providers/category_provider.dart';
import 'providers/stores_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");
  } catch (e) {
    print("Error loading environment variables: $e");
  }
  
  // Hard-coded Contentful credentials for testing
  const String hardcodedSpaceId = 'dm9oug4ckfgv';  // Space ID from logs
  const String hardcodedAccessToken = 'Unp4wnUCiGanzC64e_9TyzucoF53yyFvmQ42sOt68O0';  // Updated access token
  
  // Check if Contentful credentials are available from .env
  final spaceId = dotenv.env['CONTENTFUL_SPACE_ID'] ?? '';
  final accessToken = dotenv.env['CONTENTFUL_ACCESS_TOKEN'] ?? '';
  
  // If .env loading failed, use hardcoded values as fallback
  if (spaceId.isEmpty || accessToken.isEmpty) {
    print('WARNING: Contentful credentials are missing or invalid. Using hardcoded values.');
    dotenv.env['CONTENTFUL_SPACE_ID'] = hardcodedSpaceId;
    dotenv.env['CONTENTFUL_ACCESS_TOKEN'] = hardcodedAccessToken;
  }
  
  // Initialize ContentfulService early to ensure it's properly set up
  // for use in all parts of the app, including background compute functions
  final contentfulService = ContentfulService.instance;
  print('Pre-initialized ContentfulService singleton with Space ID: ${contentfulService.spaceId}');
  
  // Initialize Firebase if using Firebase services
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DiscountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => StoresProvider()),
      ],
      child: SplashScreen(
        child: MaterialApp(
          title: 'Chhar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/main': (context) => const MainScreen(),
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Provider.of<AuthService>(context).authStateChanges,
      builder: (context, snapshot) {
        // If Firebase or auth service throws an error, still show the login screen
        if (snapshot.hasError) {
          print('Auth stream error: ${snapshot.error}');
          return const LoginScreen();
        }
        
        // Show loading animation while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.accentTeal,
                          AppColors.accentMagenta,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      size: 64,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Loading animation
                  const AnimatedLoading(
                    animationType: 'loading',
                    size: 60,
                    color: AppColors.accentTeal,
                    message: 'Loading Discount Hub...',
                  ),
                ],
              ),
            ),
          );
        }
        
        // Check if user is signed in
        if (snapshot.hasData) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// Custom theme settings for the app
class AppTheme {
  static ThemeData get darkTheme {
    // Print debug info for image loading
    debugPrint('Initializing app theme with image configuration');
    
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.backgroundColor,
      cardColor: AppColors.cardColor,
      primaryColor: AppColors.primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: AppColors.surfaceColor,
        error: AppColors.errorColor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        fontFamily: 'Outfit',
        fontFamilyFallback: ['NotoSansBengali'],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          textStyle: const TextStyle(
            color: AppColors.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Add SplashScreen class definition at the end of the file (before the last closing brace)
class SplashScreen extends StatefulWidget {
  final Widget child;
  const SplashScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller with longer duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Create animations
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Pulse animation that starts after the initial scale
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.linear),
      ),
    );

    // Text fade in animation with delay
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Start the animation and loading sequence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      
      // Increased minimum display time to 2.5 seconds
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
        ? Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              backgroundColor: AppColors.backgroundColor,
              body: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo container
                        Opacity(
                          opacity: _fadeInAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value * _pulseAnimation.value,
                            child: Container(
                              width: 300,  // Increased size
                              height: 180,  // Adjusted for aspect ratio
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: SvgPicture.asset(
                                'assets/images/logo.svg',
                                fit: BoxFit.contain,
                                // Add color override to ensure visibility
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF69BF69), // Your brand color
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Animated text container
                        Opacity(
                          opacity: _textFadeAnimation.value,
                          child: Column(
                            children: [
                              // App title with styled text
                              Text(
                                'Chhar',
                                style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ).animate()
                                .slideY(
                                  begin: 0.3,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                ),
                              const SizedBox(height: 12),
                              Text(
                                'Find discounts near you',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ).animate()
                                .slideY(
                                  begin: 0.3,
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 100),
                                  curve: Curves.easeOut,
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          )
        : widget.child;
  }
} 