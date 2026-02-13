import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_disease1/doctors_screen.dart';
import 'package:skin_disease1/doctors_map_screen.dart';

class InferenceResultPage extends StatelessWidget {
  final String? imagePath;
  final String? result;
  final double? confidence;
  final int? percentageChange;
  final String? imageUrl;
  final bool isError;
  final String? errorMessage;
  final Map<String, dynamic>? backendDetails;

  const InferenceResultPage({
    this.imagePath,
    this.result,
    this.confidence,
    this.percentageChange,
    this.imageUrl,
    this.isError = false,
    this.errorMessage,
    this.backendDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'scan_image',
                child: imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFF1E293B),
                        child: const Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.white24,
                        ),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isError) ...[
                    _buildErrorState(),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analysis Result',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3B9AE1),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (result ?? 'Unmatched').toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildChangeIndicator(),
                        const SizedBox(width: 12),
                        _buildConfidenceIndicator(),
                      ],
                    ),
                    _buildConditionDetails(),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorsScreen(),
                          ),
                        );
                      },
                      child: const Text('Find Specialist Near You'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorsMapScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined),
                          SizedBox(width: 12),
                          Text('View Nearby Clinics on Map'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Home'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Failed',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'We encountered an issue',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error Details',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ??
                    'An unexpected error occurred while communicating with the analysis server. Please check your internet connection and try again.',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangeIndicator() {
    if (percentageChange == null) return const SizedBox.shrink();

    final isImprovement = percentageChange! < 0;
    final absChange = percentageChange!.abs();
    final color = isImprovement
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final icon = isImprovement ? Icons.trending_down : Icons.trending_up;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '$absChange%',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            isImprovement ? 'Improvement' : 'Spread',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final color = (confidence ?? 0) > 0.7
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${((confidence ?? 0) * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'Confidence',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'opacity':
        return Icons.opacity;
      case 'wash':
        return Icons.wash;
      case 'science':
        return Icons.science;
      case 'restaurant':
        return Icons.restaurant;
      case 'touch_app':
        return Icons.touch_app;
      case 'medical_services':
        return Icons.medical_services;
      case 'medical_information':
        return Icons.medical_information;
      case 'content_cut':
        return Icons.content_cut;
      case 'search':
        return Icons.search;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'medication':
        return Icons.medication;
      case 'water_drop':
        return Icons.water_drop;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'shield':
        return Icons.shield;
      case 'do_not_disturb_on':
        return Icons.do_not_disturb_on;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildConditionDetails() {
    final currentResult = result ?? 'Unknown';

    if (currentResult == "Invalid Image (Not Skin)") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildSectionHeader('Image Not Recognized'),
          const SizedBox(height: 12),
          Text(
            'Our system could not detect skin in the provided image. Please ensure the photo is clear, well-lit, and focuses on the area of concern.',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _buildStepItem(
            Icons.lightbulb_outline,
            'Good Lighting',
            'Take the photo in natural daylight or a well-lit room.',
          ),
          _buildStepItem(
            Icons.center_focus_strong_outlined,
            'Stay Focused',
            'Ensure the skin condition is in the center and in focus.',
          ),
        ],
      );
    }

    if (currentResult == "Uncertain Prediction") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildSectionHeader('Low Confidence Analysis'),
          const SizedBox(height: 12),
          Text(
            'The AI model is uncertain about this specific image. This can happen if the image is blurry, has poor lighting, or if the condition is not well-represented in our database.',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _buildWarningCard(),
          const SizedBox(height: 40),
          _buildSectionHeader('Next Steps'),
          const SizedBox(height: 16),
          _buildStepItem(
            Icons.camera_alt_outlined,
            'Retake Photo',
            'Try taking another photo with better lighting and focus.',
          ),
          _buildStepItem(
            Icons.medical_services_outlined,
            'Consult a Professional',
            'Since the automated analysis is uncertain, we highly recommend speaking with a dermatologist.',
          ),
        ],
      );
    }

    // Use backend details if provided, otherwise fallback to local map
    final details = backendDetails ?? _localDiseaseDetails[currentResult];

    final description =
        details?['description'] ??
        'Our AI model has detected signals consistent with $currentResult. This is a preliminary assessment based on visual characteristics.';
    final steps = details?['steps'] as List?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _buildSectionHeader('Understanding the Condition'),
        const SizedBox(height: 12),
        Text(
          description,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: const Color(0xFF64748B),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _buildWarningCard(),
        const SizedBox(height: 40),
        _buildSectionHeader('Recommended Next Steps'),
        const SizedBox(height: 16),
        if (steps != null)
          ...steps.map((step) {
            return _buildStepItem(
              _getIconData(step['icon']),
              step['title'] ?? 'Recommendation',
              step['description'] ?? '',
            );
          }),
        _buildStepItem(
          Icons.medical_services_outlined,
          'Clinical Consultation',
          'Speak with a verified specialist for a professional medical evaluation.',
        ),
        _buildStepItem(
          Icons.history_edu_outlined,
          'Continuous Monitoring',
          'Track the area for any changes over the coming weeks.',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Disclaimer',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This tool is for educational purposes. Do not use it for self-diagnosis or to replace professional medical advice.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF3B9AE1), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, Map<String, dynamic>> _localDiseaseDetails = {
    'Acne': {
      'description': 'Acne is caused by clogged pores and oil buildup.',
      'steps': [
        {
          'title': 'Gentle Cleansing',
          'description': 'Wash face twice daily.',
          'icon': 'wash',
        },
        {
          'title': 'Topical Treatment',
          'description': 'Use salicylic acid products.',
          'icon': 'science',
        },
        {
          'title': 'Avoid Touching',
          'description': 'Do not pick pimples.',
          'icon': 'do_not_disturb_on',
        },
      ],
    },
    'Hairloss': {
      'description': 'Hair loss due to genetics or nutrition.',
      'steps': [
        {
          'title': 'Nutrition',
          'description': 'Increase iron and biotin.',
          'icon': 'restaurant',
        },
        {
          'title': 'Massage',
          'description': 'Improve blood circulation.',
          'icon': 'touch_app',
        },
        {
          'title': 'Consult Doctor',
          'description': 'Visit dermatologist.',
          'icon': 'medical_services',
        },
      ],
    },
    'Nail Fungus': {
      'description': 'Fungal infection affecting nails.',
      'steps': [
        {
          'title': 'Keep Dry',
          'description': 'Avoid moisture.',
          'icon': 'opacity',
        },
        {
          'title': 'Antifungal Cream',
          'description': 'Apply medication.',
          'icon': 'medical_information',
        },
        {
          'title': 'Trim Nails',
          'description': 'Keep nails short.',
          'icon': 'content_cut',
        },
      ],
    },
    'Skin Allergy': {
      'description': 'Skin reaction to allergens.',
      'steps': [
        {
          'title': 'Identify Trigger',
          'description': 'Find allergen.',
          'icon': 'search',
        },
        {
          'title': 'Cool Compress',
          'description': 'Reduce irritation.',
          'icon': 'ac_unit',
        },
        {
          'title': 'Medication',
          'description': 'Use antihistamines.',
          'icon': 'medication',
        },
      ],
    },
    'Normal': {
      'description': 'Skin appears healthy.',
      'steps': [
        {
          'title': 'Hydrate',
          'description': 'Drink water.',
          'icon': 'water_drop',
        },
        {
          'title': 'Sun Protection',
          'description': 'Use sunscreen.',
          'icon': 'wb_sunny',
        },
        {
          'title': 'Maintain Routine',
          'description': 'Continue skincare.',
          'icon': 'shield',
        },
      ],
    },
  };
}
