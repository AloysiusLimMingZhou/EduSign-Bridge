import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:ai_voice_to_hand_signs_project/features/auth/repositories/auth.repositories.dart';
import 'package:ai_voice_to_hand_signs_project/features/sign_to_voice/screens/sign_to_voice_screen.dart';
import 'package:ai_voice_to_hand_signs_project/features/voice_to_text/screens/voice_to_text_screen.dart';
import 'package:ai_voice_to_hand_signs_project/util/constants/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: TColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              AuthRepositories.instance.logout();
            },
            icon: const Icon(Iconsax.logout, color: TColors.white),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildHomeContent() : _buildProfileContent(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: TColors.darkContainer,
        indicatorColor: TColors.primary.withAlpha(20),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            // Navigate to Sign-to-Voice screen
            Get.to(() => const SignToVoiceScreen());
          } else {
            setState(() => _selectedIndex = index == 2 ? 1 : 0);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.home, color: TColors.textSecondary),
            selectedIcon: Icon(Iconsax.home, color: TColors.primary),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Iconsax.camera, color: TColors.textSecondary),
            selectedIcon: Icon(Iconsax.camera, color: TColors.primary),
            label: "Sign",
          ),
          NavigationDestination(
            icon: Icon(Iconsax.user, color: TColors.textSecondary),
            selectedIcon: Icon(Iconsax.user, color: TColors.primary),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome to the Future\nof Learning",
            style: TextStyle(
              color: TColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Break language barriers with AI",
            style: TextStyle(color: TColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Sign to Voice Card
          _buildFeatureCard(
            icon: Iconsax.video,
            title: "Sign to Voice",
            description: "Convert hand signs to speech in real-time",
            gradientColors: [const Color(0xFF6C63FF), const Color(0xFF9D50BB)],
            onTap: () => Get.to(() => const SignToVoiceScreen()),
          ),
          const SizedBox(height: 16),

          // Voice to Text Card
          _buildFeatureCard(
            icon: Iconsax.microphone,
            title: "Voice to Text",
            description: "Convert speech to text for deaf users",
            gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
            onTap: () => Get.to(() => const VoiceToTextScreen()),
          ),
          const SizedBox(height: 32),

          // Quick Stats
          const Text(
            "Quick Stats",
            style: TextStyle(
              color: TColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.language_circle,
                  value: "1",
                  label: "Languages",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.text,
                  value: "24",
                  label: "Signs",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColors.darkContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColors.grey.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: TColors.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: TColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: TColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return const Center(
      child: Text(
        "Profile - Coming Soon",
        style: TextStyle(color: TColors.textSecondary),
      ),
    );
  }
}
