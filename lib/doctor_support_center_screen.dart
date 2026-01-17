import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorSupportCenterScreen extends StatelessWidget {
  const DoctorSupportCenterScreen({Key? key}) : super(key: key);

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@dermasense.com',
      query: 'subject=Doctor Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1234567890');
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Support Center',
          style: GoogleFonts.outfit(color: const Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B9AE1), Color(0xFF2C3E50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is here to assist you',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact Options
            Text(
              'Contact Us',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 16),

            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@dermasense.com',
              description: 'Get a response within 24 hours',
              onTap: _launchEmail,
            ),
            const SizedBox(height: 12),

            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+1 (234) 567-890',
              description: 'Mon-Fri, 9 AM - 6 PM',
              onTap: _launchPhone,
            ),
            const SizedBox(height: 12),

            _buildContactCard(
              icon: Icons.chat_bubble_outline,
              title: 'Live Chat',
              subtitle: 'Chat with our team',
              description: 'Available during business hours',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live chat coming soon!')),
                );
              },
            ),

            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 16),

            _buildFAQCard(
              question: 'How do I manage my appointment slots?',
              answer: 'Go to Settings > Working Hours to add, edit, or remove your available time slots.',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'How do I update my professional details?',
              answer: 'Navigate to Settings > Professional Details to edit your profile, qualifications, and contact information.',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'How do patients book appointments with me?',
              answer: 'Patients can view your profile, check available slots, and book appointments directly through the app. You\'ll receive notifications for new bookings.',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'Can I cancel or reschedule appointments?',
              answer: 'Yes, you can manage appointments from the Bookings tab. Patients will be notified automatically of any changes.',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'How do I change my password?',
              answer: 'Go to Settings > Change Password to update your account password securely.',
            ),

            const SizedBox(height: 32),

            // Additional Resources
            Text(
              'Additional Resources',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 16),

            _buildResourceCard(
              icon: Icons.book_outlined,
              title: 'User Guide',
              description: 'Learn how to use all features',
            ),
            const SizedBox(height: 12),

            _buildResourceCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              description: 'How we protect your data',
            ),
            const SizedBox(height: 12),

            _buildResourceCard(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              description: 'Platform usage guidelines',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B9AE1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF3B9AE1), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF3B9AE1), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7F8C8D)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard({required String question, required String answer}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            question,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50)),
          ),
          children: [
            Text(
              answer,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard({required IconData icon, required String title, required String description}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B9AE1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF3B9AE1), size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50)),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF7F8C8D)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
        onTap: () {
          // Navigate to respective resource pages
        },
      ),
    );
  }
}
