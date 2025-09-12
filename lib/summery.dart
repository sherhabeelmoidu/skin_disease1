import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkinDiseaseSummaryPage extends StatefulWidget {
  @override
  State<SkinDiseaseSummaryPage> createState() => _SkinDiseaseSummaryPageState();
}

class _SkinDiseaseSummaryPageState extends State<SkinDiseaseSummaryPage> {
    final List<String> imagePaths = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
    "assets/image4.jpg"];
    int myCurrentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: GoogleFonts.pacifico(fontSize: 18)),
        backgroundColor: Colors.teal[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              autoPlay: true,
              enlargeCenterPage: true,
            ),
            items: imagePaths.map((path) {
              return Builder(
                builder: (BuildContext context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      path,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                },
              );
            }).toList(),),
            Text(
              '🧴 Summary: Skin Diseases',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Skin diseases are medical conditions affecting the skin — the body\'s largest organ. These conditions can be mild or severe, temporary or chronic, and some may even be life-threatening.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '🔬 Common Types of Skin Diseases:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _bullet('Eczema (Atopic Dermatitis) – Red, itchy, inflamed skin.'),
            _bullet('Psoriasis – Thick, scaly patches caused by autoimmunity.'),
            _bullet('Acne – Blocked pores and inflammation.'),
            _bullet('Fungal Infections – Like Ringworm or Athlete’s Foot.'),
            _bullet('Bacterial Infections – Such as Impetigo or Cellulitis.'),
            _bullet('Viral Infections – Warts, Herpes, etc.'),
            _bullet('Skin Cancer – Especially Melanoma due to sun exposure.'),
            _bullet('Vitiligo – White patches from pigment loss.'),

            SizedBox(height: 20),
            Text(
              '🧠 Causes of Skin Diseases:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            _bullet('Infections (bacteria, viruses, fungi)'),
            _bullet('Allergies and autoimmune reactions'),
            _bullet('Genetics and hormonal changes'),
            _bullet('Environmental exposure and poor hygiene'),

            SizedBox(height: 20),
            Text(
              '🩺 Symptoms:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            _bullet('Rashes, redness, or swelling'),
            _bullet('Itching, pain, or burning'),
            _bullet('Dry, scaly, or peeling skin'),
            _bullet('Pigment loss or dark patches'),

            SizedBox(height: 20),
            Text(
              '⚕ Diagnosis & Treatment:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Diagnosis may involve visual checks, biopsy, or AI tools. Treatments include topical or oral medication, phototherapy, and sometimes surgery.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: GoogleFonts.poppins(fontSize: 16)),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 16))),
        ],
      ),
    );
  }
}
