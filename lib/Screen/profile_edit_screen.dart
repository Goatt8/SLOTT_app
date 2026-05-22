import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Service/firestore_service.dart';

class ProfileEditScreen extends StatefulWidget {
  // ★ 이제 무거운 AppUser 대신, 깔끔하게 유저 ID(String)만 받습니다!
  final String currentUserId;

  const ProfileEditScreen({super.key, required this.currentUserId});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FireStoreService _firestoreService = FireStoreService();

  File? _pickedImageFile;
  String? _currentProfileUrl;
  String _selectedTheme = "블랙";
  String _selectedFont = "기본체";

  bool _isLoading = true; // 서버에서 내 데이터를 받아오는 중인지 체크하는 변수

  @override
  void initState() {
    super.initState();
    _loadUserData(); // 화면이 켜지자마자 넘겨받은 id로 서버 조회 시작!
  }

  // ★ 네가 보여준 getUser 메서드를 활용해 기존 이름과 사진을 채워넣는 핵심 함수
  Future<void> _loadUserData() async {
    try {
      AppUser? user = await _firestoreService.getUser(widget.currentUserId);
      if (user != null) {
        setState(() {
          _nameController.text = user.name;
          _currentProfileUrl = user.profileUrl;
          _isLoading = false; // 로딩 완료!
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('유저 정보를 불러오지 못했습니다: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 1. 프로필 이미지 섹션
  Widget _buildProfileImage() {
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
              maxWidth: 300, // 가벼운 해상도로 조절 (렉 방지)
              maxHeight: 300,
              imageQuality: 70, // 압축률 설정 (용량 다이어트)
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

  // 2. 입력 필드 섹션
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

  // 3. 테마/폰트 선택 섹션 (인스타 스타일)
  Widget _buildSelectionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(
            color: Colors.white.withOpacity(0.05),
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
          _buildStatButton("폰트", _selectedFont, () {
            _showSelectionSheet("폰트 선택", [
              "기본체",
              "나눔고딕",
              "프리텐다드",
            ], (val) => setState(() => _selectedFont = val));
          }),
        ],
      ),
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

  void _showSelectionSheet(
    String title,
    List<String> options,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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
              // TODO: 저장 로직 실행
            },
          ),
        ],
      ),
      // ★ 데이터를 가져오는 중일 때는 한가운데에 로딩바를 띄우고, 완료되면 UI를 그립니다.
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 10),
                  _buildTextField(),
                  _buildSelectionButtons(),
                ],
              ),
            ),
    );
  }
}
