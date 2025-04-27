import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'models/discount_provider.dart';
import 'services/auth_service.dart';
import 'components/animated_loading.dart';
import 'utils/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'providers/category_provider.dart';
import 'providers/stores_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hard-coded Contentful credentials for testing
  // You should replace these with your actual Contentful credentials
  // and then load from .env for production
  const String hardcodedSpaceId = 'dm9oug4ckfgv';  // Space ID from logs
  const String hardcodedAccessToken = 'Unp4wnUCiGanzC64e_9TyzucoF53yyFvmQ42sOt68O0';  // Updated access token
  
  // Load environment variables from .env file
  try {
    await dotenv.dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully');
    
    // Check if Contentful credentials are available from .env
    var spaceId = dotenv.dotenv.env['CONTENTFUL_SPACE_ID'];
    var accessToken = dotenv.dotenv.env['CONTENTFUL_ACCESS_TOKEN'];
    
    // If not available from .env, use the hardcoded ones (if provided)
    if (spaceId == null || spaceId.isEmpty) {
      spaceId = hardcodedSpaceId;
      // Add to environment variables so ContentfulService can find them
      if (spaceId.isNotEmpty) {
        dotenv.dotenv.env['CONTENTFUL_SPACE_ID'] = spaceId;
      }
    }
    
    if (accessToken == null || accessToken.isEmpty) {
      accessToken = hardcodedAccessToken;
      // Add to environment variables so ContentfulService can find them
      if (accessToken.isNotEmpty) {
        dotenv.dotenv.env['CONTENTFUL_ACCESS_TOKEN'] = accessToken;
      }
    }
    
    print('Contentful credentials check:');
    print('- Space ID: ${spaceId.isNotEmpty ? "Available" : "MISSING"}');
    print('- Access Token: ${accessToken.isNotEmpty ? "Available" : "MISSING"}');
    
    if (spaceId.isEmpty || accessToken.isEmpty) {
      print('WARNING: Contentful credentials are missing or invalid. The app will not display content.');
    }
  } catch (e) {
    print('Failed to load environment variables: $e');
    
    // If .env loading failed, try to use hardcoded values as fallback
    if (hardcodedSpaceId.isNotEmpty && hardcodedAccessToken.isNotEmpty) {
      print('Using hardcoded Contentful credentials as fallback');
      dotenv.dotenv.env['CONTENTFUL_SPACE_ID'] = hardcodedSpaceId;
      dotenv.dotenv.env['CONTENTFUL_ACCESS_TOKEN'] = hardcodedAccessToken;
    }
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue without Firebase, the app can still show UI
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