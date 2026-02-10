import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/cipher_provider.dart';
import '../../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cipher history when returning to home screen
    final cipherProvider = Provider.of<CipherProvider>(context, listen: false);
    cipherProvider.loadCipherHistory();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final responsivePadding = AppResponsivePadding(mediaQuery);
    final isMobile = mediaQuery.isMobile;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.white,
                      size: 18,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Title Text - Shortened
            Flexible(
              child: Text(
                'CRYPTOGRAPHY VISUALIZER',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: responsivePadding.horizontalPadding,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: responsivePadding.horizontalPadding.copyWith(
                top: isMobile ? AppSpacing.xl : AppSpacing.xxl,
                bottom: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(),
                  SizedBox(height: isMobile ? AppSpacing.xxl : AppSpacing.xxxl),

                  // Quick Stats Section
                  _buildStatsSection(),
                  SizedBox(height: isMobile ? AppSpacing.xxl : AppSpacing.xxxl),

                  // Cipher Solutions Header
                  Text(
                    'Cipher Solutions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: isMobile ? 18 : 20,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Caesar Cipher Card
                  _buildCipherCard(
                    context,
                    title: 'Caesar Cipher',
                    description: 'Encrypt and decrypt text using circular shift substitution',
                    icon: Icons.rotate_right_outlined,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pushNamed(context, '/caesar');
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Playfair Cipher Card
                  _buildCipherCard(
                    context,
                    title: 'Playfair Cipher',
                    description: 'Solve digraph encryption with visual 5×5 matrix grid',
                    icon: Icons.grid_3x3_outlined,
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pushNamed(context, '/playfair');
                    },
                  ),
                  SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxl),

                  // Features Section
                  _buildFeaturesSection(context),
                  SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Visualize and learn cryptographic ciphers in real-time',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Consumer<CipherProvider>(
      builder: (context, cipherProvider, child) {
        return Column(
          children: [
            // Debug info
            if (cipherProvider.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('Loading history...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            if (cipherProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Error: ${cipherProvider.error}',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Ciphers Solved',
                    value: cipherProvider.totalCount.toString(),
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    label: 'Caesar',
                    value: cipherProvider.caesarCount.toString(),
                    icon: Icons.rotate_right_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    label: 'Playfair',
                    value: cipherProvider.playfairCount.toString(),
                    icon: Icons.grid_3x3_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            // Manual refresh button for debugging
            SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () {
                print('🔄 Manual refresh requested');
                cipherProvider.loadCipherHistory();
              },
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Refresh Stats', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFFB0B0B0) 
                      : Colors.black87,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCipherCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? const Color(0xFFE0E0E0) 
                                  : Colors.black,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? const Color(0xFFB0B0B0) 
                                  : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Text(
                      'Open Solver',
                      style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Key Features',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFeatureItem('📝 Real-time text encryption & decryption'),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem('🎨 Visual representation of cipher grids'),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem('🔄 Step-by-step transformation display'),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem('⚡ Instant results with clear output'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.greyDark,
            height: 1.5,
          ),
    );
  }
}
