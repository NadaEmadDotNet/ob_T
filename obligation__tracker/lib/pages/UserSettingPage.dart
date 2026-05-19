import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obligation__tracker/pages/AboutPage.dart';
import 'package:obligation__tracker/pages/ChangePasswordPage.dart';
import 'package:obligation__tracker/pages/FeedbackPage.dart';
import 'package:obligation__tracker/pages/HelpSupportPage.dart';
import 'package:obligation__tracker/pages/HomePage.dart';
import 'package:obligation__tracker/services/api_service.dart';

class UserSettingsPage extends StatefulWidget {
  final bool embedded;

  const UserSettingsPage({super.key, this.embedded = false});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final Color gradientTop = const Color(0xFFAEECE2); 
  final Color gradientBottom = const Color(0xFFF9F7E8); 
  final Color primaryTextColor = const Color(0xFF4B4532); 

  String _userName = ''; 
  String? _imageUrl;
  bool _isUploading = false;

  String _normalizeAvatarUrl(String url) {
    if (url.isEmpty) return url;
    if (url.contains('supabase.co')) return '';
    return url;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _userName = data['username'] ?? 'No Name';
        final imageUrl = data['profileImageUrl']?.toString() ?? '';
        _imageUrl = imageUrl.isNotEmpty ? _normalizeAvatarUrl(imageUrl) : null;
      });
    } catch (e) { debugPrint("Error loading data: $e"); }
  }

  Future<void> _uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 400, 
      maxHeight: 400, 
      imageQuality: 70
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final publicUrl = await ApiService.uploadProfileAvatar(
        bytes: bytes,
        fileName: image.name,
      );

      if (!mounted) return;
      setState(() { 
        _imageUrl = publicUrl; 
        _isUploading = false; 
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile image updated!')));
    } catch (e) { 
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildWideCard({required Widget child}) {
    return Container(
      width: double.infinity, 
      margin: const EdgeInsets.only(bottom: 20), 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: widget.embedded ? null : AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor)), 
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      body: Container(
        width: double.infinity, 
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, 
            end: Alignment.bottomCenter, 
            colors: [gradientTop, gradientBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 18 : 120, 16, widget.embedded ? 100 : 16),
          child: Column(
            children: [
              _buildWideCard(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _uploadProfileImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 70, 
                            backgroundColor: Colors.white.withOpacity(0.4),
                            key: ValueKey(_imageUrl),
                            backgroundImage: (_imageUrl != null && _imageUrl!.isNotEmpty) 
                                ? NetworkImage(_imageUrl!) 
                                : null,
                            child: (_imageUrl == null || _imageUrl!.isEmpty) && !_isUploading 
                                ? Icon(Icons.person, size: 60, color: primaryTextColor.withOpacity(0.3)) 
                                : null,
                          ),
                          if (_isUploading) const CircularProgressIndicator(),
                          if (!_isUploading) 
                            Positioned(
                              bottom: 5, 
                              right: 5, 
                              child: CircleAvatar(
                                radius: 18, 
                                backgroundColor: const Color(0xFF81D4FA), 
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(_userName.isEmpty ? "mariam bahgat" : _userName, 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: Icon(Icons.edit, size: 16, color: primaryTextColor),
                      label: Text('Edit Profile', style: TextStyle(color: primaryTextColor)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: primaryTextColor.withOpacity(0.1))),
                      onPressed: () {
                        String newName = _userName;
                        showDialog(context: context, builder: (context) => AlertDialog(
                          backgroundColor: gradientBottom, 
                          title: const Text('Edit Name'),
                          content: TextField(
                            onChanged: (val) => newName = val, 
                            controller: TextEditingController(text: _userName),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                if (newName.isNotEmpty) {
                                  await ApiService.updateProfile(username: newName);
                                  if (!context.mounted) return;
                                  setState(() => _userName = newName);
                                }
                                if (context.mounted) Navigator.pop(context);
                              }, 
                              child: Text('Save', style: TextStyle(color: primaryTextColor)),
                            ),
                          ],
                        ));
                      },
                    ),
                  ],
                ),
              ),

              _buildWideCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.vpn_key_outlined, color: primaryTextColor), 
                      title: Text('Change Password', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)), 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage())),
                    ),
                    Divider(color: primaryTextColor.withOpacity(0.1), indent: 15, endIndent: 15),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: primaryTextColor), 
                      title: Text('About', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)), 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
                    ),
                    Divider(color: primaryTextColor.withOpacity(0.1), indent: 15, endIndent: 15),
                    ListTile(
                      leading: Icon(Icons.help_outline, color: primaryTextColor), 
                      title: Text('Help & Support', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)), 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportPage())),
                    ),
                  ],
                ),
              ),

            
              _buildWideCard(
                child: ListTile(
                  leading: Icon(Icons.feedback_outlined, color: primaryTextColor),
                  title: Text('Feedback & Suggestions', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: primaryTextColor.withOpacity(0.5)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedbackPage ()),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text('App Version 1.0.0', style: TextStyle(color: primaryTextColor.withOpacity(0.5), fontSize: 14)),
                    Text('Obligation Tracker 2025', style: TextStyle(color: primaryTextColor.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              TextButton.icon(
                onPressed: () async {
                  await ApiService.clearToken();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (r) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}