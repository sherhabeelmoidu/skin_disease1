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
import 'package:skin_disease1/chatbot_widget.dart';
import 'package:skin_disease1/chat_list.dart';
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
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analyzing...')),
                );
                try {
                  final res = await analyzeImage(
                    file: _pickedFile != null ? File(_pickedFile!.path) : null,
                    bytes: _webImageBytes,
                  );
                  
                  if (!mounted) return;
                  
                  // Save scan to history
                  await FirebaseFirestore.instance
                      .collection('user')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('scan_history')
                      .add({
                    'label': res['label'],
                    'confidence': res['confidence'],
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  _showResultDialog(res['label'], res['confidence']);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Analysis failed: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B9AE1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Analyze'),
            ),
          ],
        );
      },
    );
  }

  void _showResultDialog(String label, double confidence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Image.asset(
              'assets/icon/logo.png',
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            const Text('Scan Result', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: confidence > 0.7 ? Colors.green : Colors.orange, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'We recommend consulting a dermatologist for a professional diagnosis and treatment plan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF7F8C8D))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B9AE1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Find Doctors', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      backgroundColor: Color(0xFFF5F7FA),
      drawer: UserDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/icon/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            Text(
              'DermaSense',
              style: GoogleFonts.poppins(
                color: Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Color(0xFF2C3E50)),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Color(0xFF2C3E50)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatList()));
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Color(0xFF2C3E50)),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Camera Preview
              if (_isCameraInitialized && _controller != null)
                Container(
                  height: 250,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CameraPreview(_controller!),
                        Positioned(
                          bottom: 10,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            child: Text('Live Detection Ready', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_cameraError != null)
                 Container(
                  height: 150,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)),
                  child: Center(child: Text(_cameraError!, style: TextStyle(color: Colors.red))),
                ),

              // Welcome Title
              Text(
                'Welcome to DermaSense',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 16),
              // Greeting Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name from Firebase
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
                        return Text(
                          'Hello, $userName,',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF2C3E50),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    // Scan Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _pickImageAndScan,
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        label: Text(
                          'Scan Your Skin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B9AE1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              // Recent Scans Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Scans',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // View all
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF3B9AE1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Recent Scans List - Real Firebase Data
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('user')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('scan_history')
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading scan history'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: Color(0xFFBDC3C7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No scan history yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start by scanning your skin condition',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF95A5A6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final scanData = doc.data() as Map<String, dynamic>;
                      final confidence = scanData['confidence'] ?? 0.0;
                      final label = scanData['label'] ?? 'Unknown';
                      final timestamp = scanData['timestamp'] as Timestamp?;

                      // Determine confidence color
                      Color confidenceColor;
                      String confidenceText;
                      if (confidence >= 0.8) {
                        confidenceColor = Colors.green;
                        confidenceText = 'High';
                      } else if (confidence >= 0.6) {
                        confidenceColor = Colors.orange;
                        confidenceText = 'Moderate';
                      } else {
                        confidenceColor = Colors.red;
                        confidenceText = 'Low';
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Condition Icon
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: confidenceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.medical_services_outlined,
                                color: confidenceColor,
                              ),
                            ),
                            SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Confidence: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF7F8C8D),
                                        ),
                                      ),
                                      Text(
                                        confidenceText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: confidenceColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Time
                            Text(
                              timestamp != null ? _formatTimeAgo(timestamp.toDate()) : 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF95A5A6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),

          // Chatbot Widget
          ChatbotWidget(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF3B9AE1),
          unselectedItemColor: Color(0xFF95A5A6),
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'Doctors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
