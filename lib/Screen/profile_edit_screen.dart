import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Service/auth_service.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/firestorage_service.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Widget/code_input_dialog.dart';
import 'package:bababam_app/Widget/post_text_style_picker_dialog.dart';
import 'package:bababam_app/Widget/confirm_dialog.dart';

class ProfileEditScreen extends StatefulWidget {
  final String currentUserId;

  const ProfileEditScreen({super.key, required this.currentUserId});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final FireStoreService _firestoreService = FireStoreService();
  final FireStorageService _firestorageService = FireStorageService();

  File? _pickedImageFile;
  String? _currentProfileUrl;
  String _selectedTheme = "블랙";
  PostTextStyleSelection _selectedTextStyle =
      AppTypography.defaultPostTextStyleSelection;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      AppUser? user = await _firestoreService.getUser(widget.currentUserId);
      if (!mounted) return;
      setState(() {
        if (user != null) {
          _nameController.text = user.name;
          _currentProfileUrl = user.profileUrl;
          _selectedTextStyle = AppTypography.postTextStyleSelection(
            fontId: user.fontId,
            colorId: user.colorId,
            hourFontId: user.hourFontId,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      WarningSnackBar.showWarning(context, '유저 정보를 불러오지 못했습니다.');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _changeProfileImage() {
    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.grey[800],
          backgroundImage: _pickedImageFile != null
              ? FileImage(_pickedImageFile!)
              : (_currentProfileUrl != null
                        ? NetworkImage(_currentProfileUrl!)
                        : null)
                    as ImageProvider?,
        ),
        TextButton(
          onPressed: () async {
            final XFile? pickedFile = await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 300,
              maxHeight: 300,
              imageQuality: 70,
            );
            if (pickedFile != null) {
              setState(() {
                _pickedImageFile = File(pickedFile.path);
              });
            }
          },
          child: const Text(
            '프로필 사진 수정',
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  //MARK: TextField
  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "이름",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white10),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //MARK: Select Section
  Widget _buildSelectionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatButton("테마", _selectedTheme, () {
            _showSelectionSheet("테마 선택", [
              "화이트",
              "블랙",
            ], (val) => setState(() => _selectedTheme = val));
          }),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildStatButton(
            "폰트",
            '${AppTypography.postFontLabel(_selectedTextStyle.fontId)} · ${AppTypography.hourFontLabel(_selectedTextStyle.hourFontId)} · ${AppTypography.postColorLabel(_selectedTextStyle.colorId)}',
            () {
              _showFontPicker();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showFontPicker() async {
    final selection = await showDialog<PostTextStyleSelection>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.08),
      builder: (context) {
        return PostTextStylePickerDialog(initialSelection: _selectedTextStyle);
      },
    );

    if (!mounted || selection == null) return;

    setState(() {
      _selectedTextStyle = selection;
    });
  }

  //MARK: Bottom Sheet
  void _showSelectionSheet(
    String title,
    List<String> options,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Divider(color: Colors.white10),
              ...options.map(
                (opt) => ListTile(
                  title: Text(
                    opt,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatButton(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  //MARK: SaveProfile Button
  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      WarningSnackBar.showWarning(context, '프로필 명을 변경해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? newProfileUrl;

      if (_pickedImageFile != null) {
        newProfileUrl = await _firestorageService.uploadProfileImage(
          uid: widget.currentUserId,
          imageFile: _pickedImageFile!,
        );

        if (newProfileUrl == null) {
          if (!mounted) return;
          WarningSnackBar.showWarning(context, '이미지 업로드에 실패했습니다.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await _firestoreService.updateUser(
        userId: widget.currentUserId,
        newName: newName,
        profileUrl: newProfileUrl,
        fontId: _selectedTextStyle.fontId,
        colorId: _selectedTextStyle.colorId,
        hourFontId: _selectedTextStyle.hourFontId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("프로필이 변경되었습니다.")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        WarningSnackBar.showWarning(context, '포로필 저장 실패.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //MARK: Delete Account
  Future<T> _runDeleteStep<T>(
    String stepName,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (error) {
      debugPrint('회원탈퇴 오류[$stepName]: $error');
      rethrow;
    }
  }

  Future<void> _tryCleanupStep(
    String stepName,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      debugPrint('회원탈퇴 정리 실패[$stepName], 계속 진행: $error');
    }
  }

  //MARK: Re Auth For Delete
  Future<bool> _reauthenticateForAccountDeletion() async {
    await _authService.sendReauthCode((_) {});

    if (!mounted) return false;

    final smsCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CodeInputDialog(
        title: '회원탈퇴 본인 확인',
        hintText: '인증번호 6자리',
        confirmText: '확인',
        prefixText: null,
      ),
    );

    if (smsCode == null || smsCode.isEmpty) {
      return false;
    }

    await _authService.reauthenticateWithCode(smsCode);
    return true;
  }

  Future<void> _executeDeleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;

      if (userId == null) {
        throw Exception("유저 정보를 찾을 수 없습니다.");
      }

      final didReauthenticate = await _runDeleteStep(
        'Firebase Auth 재인증',
        _reauthenticateForAccountDeletion,
      );

      if (!didReauthenticate) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });
        return;
      }

      var postVideoUrls = <String>[];

      await _tryCleanupStep('Firestore 작성 게시물 삭제', () async {
        postVideoUrls = await _firestoreService.deletePostsByAuthor(userId);
      });
      await _tryCleanupStep(
        'Storage 게시물 영상 삭제',
        () => _firestorageService.deleteVideosByUrls(postVideoUrls),
      );
      await _tryCleanupStep(
        'Storage 프로필 이미지 삭제',
        () => _firestorageService.deleteProfileImage(uid: userId),
      );
      await _runDeleteStep(
        'Firestore 유저 익명화',
        () => _firestoreService.anonymizeDeletedUser(userId),
      );
      await _runDeleteStep('Firebase Auth 계정 삭제', _authService.deleteAccount);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("회원탈퇴가 완료되었습니다. 이용해 주셔서 감사합니다.")),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on FirebaseAuthException catch (error) {
      debugPrint('회원탈퇴 Auth 오류: ${error.code} ${error.message}');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      WarningSnackBar.showWarning(context, '회원탈퇴 중 오류가 발생하였습니다.');
    } catch (error) {
      debugPrint('회원탈퇴 오류: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      WarningSnackBar.showWarning(context, '회원탈퇴 중 오류가 발생하였습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "프로필 편집",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blueAccent),
            onPressed: () {
              _saveProfile();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _changeProfileImage(),
                  const SizedBox(height: 10),
                  _buildTextField(),
                  _buildSelectionButtons(),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: () async {
                bool? isConfirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const ConfirmDialog(
                    title: "정말 탈퇴하시겠습니까?",
                    message: "계정 정보와 작성한 게시물이 삭제되며\n프로필은 탈퇴한 사용자로 표시됩니다.",
                    isDangerous: true,
                    confirmText: "탈퇴",
                  ),
                );

                if (isConfirmed == true) {
                  _executeDeleteAccount();
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "회원탈퇴",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
