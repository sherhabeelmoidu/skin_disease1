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
import 'package:google_fonts/google_fonts.dart';

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
    // Show options for camera or gallery
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF3B9AE1)),
                title: Text('Camera'),
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
                leading: Icon(Icons.photo_library, color: Color(0xFF3B9AE1)),
                title: Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    if (kIsWeb) {
                      final bytes = await file.readAsBytes();
                      setState(() {
                        _webImageBytes = bytes;
                        _pickedFile = null;
                      });
                    } else {
                      setState(() {
                        _pickedFile = file;
                        _webImageBytes = null;
                      });
                    }
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
              onPressed: () async {
                setState(() => _isAnalyzing = true);
                try {
                  // Upload to Cloudinary first
                  String? imageUrl;
                  if (_pickedFile != null) {
                    final response = await cloudinary.uploadFile(
                      CloudinaryFile.fromFile(_pickedFile!.path, resourceType: CloudinaryResourceType.Image),
                    );
                    imageUrl = response.secureUrl;
                  } else if (_webImageBytes != null) {
                    // Cloudinary support for bytes or use a different method if needed
                    // For now, let's assume mobile focus or handle web bytes if possible
                  }

                  final res = await analyzeImage(
                    file: _pickedFile != null ? File(_pickedFile!.path) : null,
                    bytes: _webImageBytes,
                  );
                  
                  if (!mounted) return;

                  setState(() {
                    _lastUploadedImageUrl = imageUrl;
                    _isAnalyzing = false;
                  });
                  
                  // Save scan to history
                  await FirebaseFirestore.instance
                      .collection('user')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('scan_history')
                      .add({
                    'disease_name': res['label'], // Changed key to match dashboard expectation
                    'confidence': (res['confidence'] * 100).toInt(),
                    'image_url': imageUrl,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  _showResultPage(res['label'], res['confidence']);
                } catch (e) {
                  setState(() => _isAnalyzing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Analysis failed: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B9AE1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isAnalyzing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Analyze'),
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
    if (index == 2) {
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
      drawer: UserDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B9AE1), Color(0xFF2C3E50)],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DermaSense AI',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.chat_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatList())),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildBody(),
          ),
        ],
      ),
    
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: const Color(0xFF3B9AE1),
        unselectedItemColor: const Color(0xFF94A3B8),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting Header
            StreamBuilder<DocumentSnapshot>(
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
                      'Hello, $userName 👋',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to check your skin health today?',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Analysis Pulse Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B9AE1), Color(0xFF2C3E50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B9AE1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    'Instant AI Analysis',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan or upload a photo to identify skin conditions with high accuracy.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pickImageAndScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2C3E50),
                      ),
                      child: const Text('Start New Scan'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Recent Activity Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scan History List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('scan_history')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _buildHistoryCard(data);
                  },
                );
              },
            ),
          ],
        ),
      );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null 
        ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}' 
        : 'Recent';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            image: data['image_url'] != null 
                ? DecorationImage(image: NetworkImage(data['image_url']), fit: BoxFit.cover)
                : null,
          ),
          child: data['image_url'] == null ? const Icon(Icons.image, color: Color(0xFF94A3B8)) : null,
        ),
        title: Text(
          data['disease_name'] ?? 'Analysis',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
        ),
        subtitle: Text(
          'Date: $dateStr • ${data['confidence'] ?? 'N/A'}% match',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => InferenceResultPage(
            imagePath: '', 
            result: data['disease_name'] ?? 'Unknown',
            confidence: (data['confidence'] ?? 0).toDouble(),
            imageUrl: data['image_url'],
          )));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_outlined, size: 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            'No Scans Yet',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your skin analysis history will appear here once you perform your first scan.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
