import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyAFjxY8d3CNnkQSCFUpgb1-WwGRhA-MxgY",
      authDomain: "blalg-chat.firebaseapp.com",
      projectId: "blalg-chat",
      storageBucket: "blalg-chat.firebasestorage.app",
      messagingSenderId: "391864604410",
      appId: "1:391864604410:web:4a10c270ad4c6639629b43",
      measurementId: "G-TLHHSPBRLL",
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PremiumChatApp());
}

class PremiumChatApp extends StatelessWidget {
  const PremiumChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLALG Workspace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19), 
        primaryColor: const Color(0xFF38BDF8), 
        cardColor: const Color(0xFF1E293B), 
        hintColor: const Color(0xFF64748B),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
          );
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String _errorMessage = '';

  void _submit() async {
    if (_isLoading) return;
    
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();

    if (email.isEmpty || password.isEmpty || (_isSignUp && username.isEmpty)) {
      setState(() {
        _errorMessage = 'Please populate all active form fields.';
        _isLoading = false;
      });
      return;
    }

    try {
      if (_isSignUp) {
        final usernameCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();

        if (usernameCheck.docs.isNotEmpty) {
          setState(() {
            _errorMessage = 'This username is already taken.';
            _isLoading = false;
          });
          return;
        }

        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'This email address is already registered.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'The email address format is invalid.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'The password must be at least 6 characters.';
        } else {
          _errorMessage = e.message ?? 'An authentication error occurred.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Database sync error. Check your Firebase settings.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(40.0),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSignUp ? 'Create BLALG Identity' : 'BLALG Secure Access',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_isSignUp) ...[
                  TextField(
                    controller: _usernameController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_\-]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Unique Username',
                      hintText: 'letters, numbers, _ or - only',
                      prefixText: '@ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Account Password', border: OutlineInputBorder()),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isSignUp ? 'REGISTER PROFILE' : 'SECURE SIGN IN', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() {
                    _isSignUp = !_isSignUp;
                    _errorMessage = '';
                    _usernameController.clear();
                  }),
                  child: Text(
                    _isSignUp ? 'Already registered? Access Sign In' : 'Need an account? Create Identity Profile',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF38BDF8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String? _selectedRoomId;
  String _selectedRoomName = '';
  String _currentProfileUsername = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUsername();
  }

  void _fetchCurrentUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentProfileUsername = doc.data()?['username'] ?? 'unknown';
        });
      }
    }
  }

  void _createNewGroupChannel() {
    final controller = TextEditingController();
    String dialogError = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Invite-Only Channel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'e.g., Secret Project, Private Squad',
                  labelText: 'Channel Name',
                ),
              ),
              if (dialogError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(dialogError, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final groupName = controller.text.trim();
                if (groupName.isEmpty) {
                  setDialogState(() => dialogError = 'Channel name cannot be empty.');
                  return;
                }

                if (_currentProfileUsername.isEmpty || _currentProfileUsername == 'loading...') return;

                final docRef = await FirebaseFirestore.instance.collection('rooms').add({
                  'name': groupName,
                  'createdBy': _currentProfileUsername,
                  'members': [_currentProfileUsername],
                  'createdAt': FieldValue.serverTimestamp(),
                });

                setState(() {
                  _selectedRoomId = docRef.id;
                  _selectedRoomName = groupName;
                });
                
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Launch Channel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentProfileUsername.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))));
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(right: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MY CHANNELS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
                      IconButton(
                        icon: const Icon(Icons.add_box_outlined, size: 20, color: Color(0xFF38BDF8)),
                        onPressed: _createNewGroupChannel,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .where('members', arrayContains: _currentProfileUsername)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final isSelected = docs[index].id == _selectedRoomId;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF1E293B),
                            leading: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF38BDF8)),
                            title: Text(
                              data['name'] ?? '',
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedRoomId = docs[index].id;
                                _selectedRoomName = data['name'] ?? 'Group Chat';
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(color: Color(0xFF1E293B), height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0EA5E9),
                    radius: 16,
                    child: Text(
                      _currentProfileUsername.isNotEmpty ? _currentProfileUsername[0].toUpperCase() : 'B', 
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: Text('@$_currentProfileUsername', style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold)),
                  subtitle: Text(FirebaseAuth.instance.currentUser?.email ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.power_settings_new, size: 18, color: Color(0xFFEF4444)),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: _selectedRoomId == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_person_outlined, size: 48, color: Color(0xFF334155)),
                        SizedBox(height: 16),
                        Text('Select or create a secure, private room thread.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                      ],
                    ),
                  )
                : ChatArea(
                    key: Key(_selectedRoomId!), 
                    roomId: _selectedRoomId!, 
                    roomName: _selectedRoomName, 
                    currentUsername: _currentProfileUsername,
                    onRoomExited: () {
                      setState(() {
                        _selectedRoomId = null;
                        _selectedRoomName = '';
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChatArea extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String currentUsername;
  final VoidCallback onRoomExited;
  const ChatArea({required this.roomId, required this.roomName, required this.currentUsername, required this.onRoomExited, super.key});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final _messageController = TextEditingController();
  bool _useCustomFont = false;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('messages').add({
      'text': text,
      'senderUsername': widget.currentUsername,
      'senderId': user?.uid ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'useCustomFont': _useCustomFont,
    });
  }

  void _openInviteDialog() {
    final inviteController = TextEditingController();
    String inviteError = '';
    bool isSuccess = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite Member to Channel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSuccess) ...[
                TextField(
                  controller: inviteController,
                  decoration: const InputDecoration(
                    hintText: 'Enter exact username',
                    prefixText: '@ ',
                  ),
                ),
              ] else ...[
                const Text('User successfully added to this room profile.', style: TextStyle(color: Colors.greenAccent)),
              ],
              if (inviteError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(inviteError, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(isSuccess ? 'Close' : 'Cancel')),
            if (!isSuccess)
              TextButton(
                onPressed: () async {
                  final targetUser = inviteController.text.trim().toLowerCase();
                  if (targetUser.isEmpty) return;

                  final userCheck = await FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: targetUser)
                      .get();

                  if (userCheck.docs.isEmpty) {
                    setDialogState(() => inviteError = 'Username profile not found.');
                    return;
                  }

                  await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
                    'members': FieldValue.arrayUnion([targetUser])
                  });

                  setDialogState(() {
                    inviteError = '';
                    isSuccess = true;
                  });
                },
                child: const Text('Add User'),
              ),
          ],
        ),
      ),
    );
  }

  void _leaveChannel() async {
    widget.onRoomExited();
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'members': FieldValue.arrayRemove([widget.currentUsername])
    });
  }

  void _deleteChannel() async {
    widget.onRoomExited();
    
    // Clean up internal messages sub-collection first
    final messages = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .get();
        
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    
    // Remove actual root document
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).delete();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, roomSnapshot) {
        if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Loading active workspace parameters...')));
        }

        final roomData = roomSnapshot.data!.data() as Map<String, dynamic>;
        final createdBy = roomData['createdBy'] ?? '';
        final isOwner = createdBy == widget.currentUsername;
        final memberCount = (roomData['members'] as List? ?? []).length;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.roomName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                Text('$memberCount active profile members', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF38BDF8), size: 20),
                tooltip: 'Invite User',
                onPressed: _openInviteDialog,
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444), size: 20),
                  tooltip: 'Delete Channel Entirely',
                  onPressed: _deleteChannel,
                )
              else
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFF59E0B), size: 20),
                  tooltip: 'Leave Group Workspace',
                  onPressed: _leaveChannel,
                ),
              const SizedBox(width: 12),
            ],
          ),
          backgroundColor: const Color(0xFF0B0F19),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == currentUser?.uid;
                        final messageUsesCustomFont = data['useCustomFont'] ?? false;
                        
                        // Compute message localized clock value dynamically
                        String timeString = '';
                        final Timestamp? ts = data['timestamp'] as Timestamp?;
                        if (ts != null) {
                          timeString = DateFormat('h:mm a').format(ts.toDate());
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                                      child: Text('@${data['senderUsername'] ?? 'user'}', style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600)),
                                    ),
                                  Container(
                                    constraints: const BoxConstraints(maxWidth: 400),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          data['text'] ?? '',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: messageUsesCustomFont ? 'BlalgCustom' : null,
                                          ),
                                        ),
                                        if (timeString.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            timeString,
                                            style: const TextStyle(fontSize: 9, color: Colors.white60),
                                          )
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                color: const Color(0xFF0B0F19),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Send a message to ${widget.roomName}...',
                          hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFF111827),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2937))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _useCustomFont ? "BLALG FONT" : "STANDARD",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _useCustomFont ? const Color(0xFF38BDF8) : const Color(0xFF475569)),
                                ),
                                IconButton(
                                  icon: Icon(_useCustomFont ? Icons.toggle_on : Icons.toggle_off, color: _useCustomFont ? const Color(0xFF38BDF8) : const Color(0xFF475569)),
                                  onPressed: () => setState(() => _useCustomFont = !_useCustomFont),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(8)),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}