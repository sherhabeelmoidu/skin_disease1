import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skin_disease1/inference.dart';
import 'package:skin_disease1/profile_screen.dart';
import 'package:skin_disease1/doctors_screen.dart';
import 'package:skin_disease1/user_drawer.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:skin_disease1/chatbot_widget.dart';
import 'package:skin_disease1/chat_list.dart';
import 'package:skin_disease1/notifications_screen.dart';
import 'package:skin_disease1/inference_result_page.dart';
import 'package:skin_disease1/scan_history_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_disease1/doctors_map_screen.dart';
import 'package:geolocator/geolocator.dart';

class CameraGalleryPage extends StatefulWidget {
  const CameraGalleryPage({Key? key}) : super(key: key);

  @override
  State<CameraGalleryPage> createState() => _CameraGalleryPageState();
}

class _CameraGalleryPageState extends State<CameraGalleryPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  XFile? _pickedFile;
  Uint8List? _webImageBytes;
  bool _isCameraInitialized = false;
  String? _cameraError;
  int _selectedIndex = 0;
  String? _lastUploadedImageUrl;
  bool _isAnalyzing = false;

  final cloudinary = CloudinaryPublic('dgn6dvfzm', 'skindisease_images', cache: false);

  final ImagePicker _picker = ImagePicker();

  // Real scan history from Firebase
  // TODO: Implement scan history collection in Firebase

  @override
  void initState() {
    super.initState();
    _initPermissionsAndCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initPermissionsAndCamera() async {
    _cameraError = null;
    if (kIsWeb) {
      setState(() {
        _cameraError = 'Camera preview is not supported on web. Use gallery upload instead.';
        _isCameraInitialized = false;
      });
      return;
    }

    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraError = 'Camera permission denied. Grant permission in app settings.';
        });
        return;
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraIndex = 0;
        await _initializeControllerFor(_cameraIndex);
      } else {
        setState(() {
          _cameraError = 'No cameras found on this device.';
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      setState(() {
        _cameraError = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _initializeControllerFor(int index) async {
    try {
      final cam = _cameras![index];
      final old = _controller;
      _controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      try {
        await _controller!.setFlashMode(_flashMode);
      } catch (_) {}
      await old?.dispose();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _cameraIndex = index;
        _cameraError = null;
      });
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
      setState(() {
        _cameraError = 'Error initializing camera: $e';
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _pickImageAndScan() async {
    if (kIsWeb) {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _pickedFile = null;
        });
        await _startInstantAnalysis();
      }
      return;
    }

    // Show options for camera or gallery on mobile
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF3B9AE1)),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  if (_controller != null && _controller!.value.isInitialized) {
                    final XFile file = await _controller!.takePicture();
                    setState(() {
                      _pickedFile = file;
                      _webImageBytes = null;
                    });
                    await _showConfirmDialog();
                  } else {
                    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
                    if (file != null) {
                      setState(() {
                        _pickedFile = file;
                        _webImageBytes = null;
                      });
                      await _showConfirmDialog();
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF3B9AE1)),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    setState(() {
                      _pickedFile = file;
                      _webImageBytes = null;
                    });
                    await _showConfirmDialog();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startInstantAnalysis() async {
    setState(() => _isAnalyzing = true);
    
    // Show a loading overlay for web
    if (kIsWeb) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      String? imageUrl;
      if (_webImageBytes != null) {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromByteData(
            ByteData.view(_webImageBytes!.buffer),
            identifier: 'web_scan_${DateTime.now().millisecondsSinceEpoch}',
            resourceType: CloudinaryResourceType.Image,
            folder: 'scans',
          ),
        );
        imageUrl = response.secureUrl;
      } else if (_pickedFile != null) {
         final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _pickedFile!.path, 
            resourceType: CloudinaryResourceType.Image,
            folder: 'scans',
          ),
        );
        imageUrl = response.secureUrl;
      }

      final res = await analyzeImage(
        file: _pickedFile != null ? File(_pickedFile!.path) : null,
        bytes: _webImageBytes,
      );
      
      if (!mounted) return;
      if (kIsWeb) Navigator.pop(context); // Close loading overlay

      setState(() {
        _lastUploadedImageUrl = imageUrl;
        _isAnalyzing = false;
      });
      
      await FirebaseFirestore.instance
          .collection('user')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('scan_history')
          .add({
        'disease_name': res['label'],
        'confidence': (res['confidence'] * 100).toInt(),
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showResultPage(res['label'], res['confidence']);
    } catch (e) {
      if (kIsWeb && mounted) Navigator.pop(context);
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    }
  }

  Future<void> _showConfirmDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm Image', style: TextStyle(color: Color(0xFF2C3E50))),
          content: SizedBox(
            width: double.maxFinite,
            child: _webImageBytes != null
                ? Image.memory(_webImageBytes!, fit: BoxFit.contain)
                : (_pickedFile != null && !kIsWeb
                    ? Image.file(File(_pickedFile!.path), fit: BoxFit.contain)
                    : (_pickedFile != null && kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: _pickedFile!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(snapshot.data!, fit: BoxFit.contain);
                              }
                              return CircularProgressIndicator();
                            },
                          )
                        : const SizedBox())),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _pickedFile = null;
                  _webImageBytes = null;
                });
                Navigator.of(context).pop();
              },
              child: Text('Retake', style: TextStyle(color: Color(0xFF7F8C8D))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startInstantAnalysis();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B9AE1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Analyze', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showResultPage(String label, double confidence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InferenceResultPage(
          imagePath: '',
          result: label,
          confidence: confidence,
          imageUrl: _lastUploadedImageUrl, // We should ensure this is set
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      // Navigate to History screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanHistoryScreen()),
      );
    } else if (index == 2) {
      // Navigate to Doctors screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DoctorsScreen()),
      );
    } else if (index == 3) {
      // Navigate to Profile screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: UserDrawer(),
      body: Stack(
        children: [
          // Background Gradient Decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B9AE1), Color(0xFF2C3E50)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildBody(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), 
                  sliver: _buildHistoryList(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          selectedItemColor: const Color(0xFF3B9AE1),
          unselectedItemColor: const Color(0xFF94A3B8),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Doctors'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80,
      floating: false,
      pinned: false,
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      actions: [
        _buildAppBarAction(Icons.notifications_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
        _buildAppBarAction(Icons.chat_bubble_outline, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatList()))),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Center(
          child: Text(
            'DermaSense',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Greeting Section with Fade Animation
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String userName = 'User';
              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                userName = data?['name'] ?? 'User';
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $userName! 👋',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'How is your skin feeling today?',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Main Scan Card with Scale Animation
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.9, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B9AE1).withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B9AE1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner_outlined, color: Color(0xFF3B9AE1), size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'AI Skin Analysis',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Take a photo or upload from gallery to get instant insights about your skin condition.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _pickImageAndScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B9AE1),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF3B9AE1).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined),
                        const SizedBox(width: 12),
                        Text(
                          'Start Assessment',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Map Integration Card
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(value * 0, (1 - value) * 20),
                child: child,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF3B9AE1).withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_outlined, color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Medical Centers',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find clinics and specialists near your location.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorsMapScreen())),
                  icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Recent Activity Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent History',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanHistoryScreen()));
              },
              child: Text(
                'View All',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF3B9AE1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('scan_history')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildHistoryCard(data, index);
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }


  Widget _buildHistoryCard(Map<String, dynamic> data, int index) {
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null 
        ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}' 
        : 'Recent';
        
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuad,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF94A3B8).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => InferenceResultPage(
                imagePath: '', 
                result: data['disease_name'] ?? 'Unknown',
                confidence: (data['confidence'] ?? 0).toDouble(),
                imageUrl: data['image_url'],
              )));
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Hero(
                    tag: 'history_img_${timestamp?.microsecondsSinceEpoch ?? index}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        image: data['image_url'] != null 
                            ? DecorationImage(image: NetworkImage(data['image_url']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: data['image_url'] == null 
                          ? const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)) 
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['disease_name'] ?? 'Analysis Result',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: const Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B9AE1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${data['confidence'] ?? 0}%',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B9AE1),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_edu_outlined, size: 40, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          Text(
            'No History Yet',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your recent scans will appear here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
