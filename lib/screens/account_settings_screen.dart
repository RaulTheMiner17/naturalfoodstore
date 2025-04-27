import 'dart:io'; // Required for File type

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Image picker
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase

import '../main.dart'; // Access supabase client

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(); // To display current email

  bool _isLoading = false;
  bool _isUploading = false;
  String? _avatarUrl;
  XFile? _pickedImage; // Store the picked image file

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        _emailController.text = user.email ?? 'No Email';
        // Load name and avatar URL from user metadata
        final name = user.userMetadata?['full_name'] as String?;
        _avatarUrl = user.userMetadata?['avatar_url'] as String?;
        if (name != null) {
          _nameController.text = name;
        }
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load user data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600, // Optional: Resize image
        maxHeight: 600,
        imageQuality: 85, // Optional: Compress image
      );
      if (image != null && mounted) {
        setState(() {
          _pickedImage = image;
        });
        // Immediately attempt upload after picking
        await _uploadAvatar();
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _uploadAvatar() async {
    if (_pickedImage == null) return;

    setState(() => _isUploading = true);
    final imageFile = File(_pickedImage!.path);
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackbar('Not logged in.');
      setState(() => _isUploading = false);
      return;
    }

    // Generate a unique file path
    final imageExtension = _pickedImage!.path.split('.').last.toLowerCase();
    final filePath = '${user.id}/profile.$imageExtension';
    final storage = supabase.storage.from('avatars'); // <<< YOUR BUCKET NAME HERE

    try {
      // 1. Upload image to Supabase Storage
      await storage.upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // 2. Get the public URL
      final imageUrl = storage.getPublicUrl(filePath);

      // 3. Update user metadata
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'avatar_url': imageUrl, // Save URL in metadata
          },
        ),
      );

      if (mounted) {
        setState(() {
          _avatarUrl = imageUrl; // Update local URL for display
          _pickedImage = null; // Clear picked image
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } on StorageException catch (e) {
      _showErrorSnackbar('Storage Error: ${e.message}');
      print('Storage Error: ${e.statusCode} ${e.error}');
    } on AuthException catch (e) {
      _showErrorSnackbar('Auth Error updating metadata: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred during upload: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Don't proceed if validation fails
    }

    setState(() => _isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackbar('Not logged in.');
      setState(() => _isLoading = false);
      return;
    }

    final newName = _nameController.text.trim();
    // final newEmail = _emailController.text.trim(); // Keep for potential future use

    try {
      // --- Update Name ---
      // Only update if the name has actually changed
      if (newName != (user.userMetadata?['full_name'] as String? ?? '')) {
        await supabase.auth.updateUser(UserAttributes(
          data: {
            'full_name': newName, // Save name in metadata
          },
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Name updated successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Name is unchanged.')),
          );
        }
      }

      // --- Update Email (Example - Requires Verification usually) ---
      // Uncomment and adapt if implementing email change.
      // Be aware Supabase often requires email verification for changes.
      /*
      final currentEmail = user.email;
      if (newEmail != currentEmail && newEmail.isNotEmpty) {
        await supabase.auth.updateUser(UserAttributes(email: newEmail));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email update initiated. Please check your email for verification.')),
          );
          // Optionally update the UI email field or navigate away
        }
      }
      */

    } on AuthException catch (e) {
      _showErrorSnackbar('Failed to update profile: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        leading: IconButton( // Explicit back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // --- Profile Picture Section ---
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? NetworkImage(_avatarUrl!)
                        : null) as ImageProvider?,
                    child: _pickedImage == null && (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? const Icon(Icons.person_outline, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Theme.of(context).primaryColor,
                      shape: const CircleBorder(),
                      elevation: 2.0,
                      child: InkWell(
                        onTap: _isUploading ? null : _pickImage,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _isUploading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 30),

              // --- Name Field ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              // --- Email Field (Display Only) ---
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  // Make it look disabled
                  filled: true,
                  fillColor: Color.fromARGB(255, 235, 235, 235),
                ),
                readOnly: true, // Make email read-only
                // validator: (value) { // Add validator if making editable
                //   if (value == null || value.isEmpty || !value.contains('@')) {
                //     return 'Please enter a valid email';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email address cannot be changed here. Contact support if needed.', // Inform user
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),

              // TODO: Add Change Password section/button here if needed
              // const SizedBox(height: 20),
              // TextButton(
              //   onPressed: () { /* Navigate to Change Password Screen */ },
              //   child: const Text('Change Password'),
              // ),

              const SizedBox(height: 40),

              // --- Update Button ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Make wider
                ),
                onPressed: _isLoading || _isUploading ? null : _updateProfile,
                child: (_isLoading)
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}