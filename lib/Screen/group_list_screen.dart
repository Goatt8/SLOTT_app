import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bababam_app/Model/group.dart';
import 'package:bababam_app/Model/mock_data.dart';
import 'package:bababam_app/Service/auth_service.dart';
import 'package:bababam_app/Screen/create_group_screen.dart';
import 'package:bababam_app/Screen/social_group_screen.dart';
import 'package:bababam_app/Widget/group_list_cell.dart';
import 'package:bababam_app/Widget/glass_popup_menu.dart';
import 'package:bababam_app/Widget/confirm_dialog.dart';
import 'package:bababam_app/Widget/code_input_dialog.dart';
import 'package:bababam_app/Helper/warning_snackbar.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final AuthService _authService = AuthService();

  void _navigateAndAddGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    );

    if (result != null && result is Group) {
      setState(() {
        testGroups.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //MARK: Top title
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Bababam'),
        titleTextStyle: GoogleFonts.londrinaSolid(
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        actions: [
          //MARK: Add Button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showGlassMenu(
                context,
                alignment: const Alignment(0.5, -0.75),
                menu: GlassPopupMenu(
                  items: [
                    GlassMenuItem(
                      title: '그룹 만들기',
                      icon: Icons.add_circle_outline,
                      onTap: _navigateAndAddGroup,
                    ),
                    GlassMenuItem(
                      title: '그룹 참여하기',
                      icon: Icons.group_add_outlined,
                      onTap: () async {
                        final String? code = await showDialog<String>(
                          context: context,
                          builder: (context) => const CodeInputDialog(),
                        );

                        if (code != null && code.isNotEmpty) {
                          print('서버로 보낼 그룹 코드: $code');
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              _showGlassMenu(
                context,
                alignment: const Alignment(0.9, -0.75),
                menu: GlassPopupMenu(
                  width: 180,
                  items: [
                    //MARK: Profile Button
                    GlassMenuItem(
                      title: '내 프로필',
                      icon: Icons.account_circle_outlined,
                      onTap: () => print('프로필 이동'),
                    ),
                    //MARK: Logout Button
                    GlassMenuItem(
                      title: '로그아웃',
                      icon: Icons.logout,
                      onTap: () async {
                        final bool? isConfirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => const ConfirmDialog(
                            title: '로그아웃',
                            message: '정말 로그아웃 하시겠습니까?',
                          ),
                        );
                        if (isConfirmed == true) {
                          try {
                            await _authService.signOut();
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              WarningSnackBar.showWarning(
                                context,
                                "로그아웃에 실패했습니다.",
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: testGroups.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final group = testGroups[index];
          return Dismissible(
            key: Key(
              group.id.isNotEmpty ? group.id : group.title + index.toString(),
            ),
            // MARK: - Group Delete slide
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (context) => ConfirmDialog(
                      title: '그룹 삭제',
                      message: '${group.title} 그룹을 삭제하시겠습니까?',
                    ),
                  ) ??
                  false;
            },
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              setState(() {
                testGroups.removeAt(index);
              });
              WarningSnackBar.showWarning(context, "그룹삭제에 실패했습니다.");
            },
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocialGroupScreen(group: group),
                  ),
                );
              },
              child: GroupListCell(group: group),
            ),
          );
        },
      ),
    );
  }

  void _showGlassMenu(
    BuildContext context, {
    required Alignment alignment,
    required Widget menu,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(alignment: alignment, child: menu);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          alignment: alignment + const Alignment(0, -0.1),
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}
