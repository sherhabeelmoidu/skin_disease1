import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skin_disease1/inference.dart';

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

  // Mock data for recent scans
  final List<Map<String, dynamic>> recentScans = [
    {
      'name': 'Psoriasis',
      'confidence': 'Moderate',
      'time': 'Today',
      'confidenceColor': Colors.orange,
    },
    {
      'name': 'Dermatitis',
      'confidence': 'Low',
      'time': 'Today',
      'confidenceColor': Colors.green,
    },
    {
      'name': 'Eczema',
      'confidence': 'Moderate',
      'time': 'Today',
      'confidenceColor': Colors.orange,
    },
  ];

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
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.camera,
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
                : (_pickedFile != null
                    ? Image.file(File(_pickedFile!.path), fit: BoxFit.contain)
                    : const SizedBox()),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Result: ${res['label']} (${(res['confidence'] as double).toStringAsFixed(2)})',
                      ),
                    ),
                  );
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

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Color(0xFF2C3E50)),
          onPressed: () {
            // Menu action
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Color(0xFF2C3E50)),
            onPressed: () {
              // Notifications
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              // Recent Scans List
              ...recentScans.map((scan) {
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
                      // Thumbnail
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xFFFFC0C0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          color: Colors.red.shade300,
                        ),
                      ),
                      SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scan['name'],
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
                                  scan['confidence'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: scan['confidenceColor'],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Time
                      Text(
                        scan['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF95A5A6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
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
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info),
              label: 'About',
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
