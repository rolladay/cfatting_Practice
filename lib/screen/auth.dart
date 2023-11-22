import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:mychatapp/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  // FORM 밸리데이셔넹 쓰는?
  bool _isLogIn = true;
  //로그인인지 사인인이지 구분하기 위해
  String enteredEmail = '';
  String enteredPassword = '';
  String username = '';
  File? selectedImage;
  bool isUthenticating = false;

  void _submit() async {


    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogIn && selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong'),
        ),
      );
      return;
    }

    setState(() {
      isUthenticating = true;
    });

    _formKey.currentState!.save();
    // 각각의 폼필드에 onSaved 함수가 있어서 이게 실행되는거임
    print(enteredEmail);
    print(enteredPassword);

    try {
      if (_isLogIn) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
        print(userCredentials);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
        print(userCredentials);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        //ref는 파베의 스토리지 링크를 의미함 그리고 child로 그 안에 folder를 만들고 그 안에 파일을 넣는 작업
        //즉, 여기서의 storageRef는 파일의 경로를 나타내는 값임.
        await storageRef.putFile(selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'userName': username,
          'email': enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication Failed'),
          ),
        );
        // print(error.code);
      }
      setState(() {
        isUthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30.0,
                  bottom: 20.0,
                  left: 20.0,
                  right: 20.0,
                ),
                width: 200.0,
                child: Image.asset('assets/images/tiger.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      // 하나의 form에 하나의 global Key만 쓰여야하네?
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogIn)
                            UserImagePicker(onPickedImage: (img) {
                              selectedImage = img;
                              //여기서 함수바디가 img를 받아서 selectedImage에 img 넣는게 함수바디고,
                              //UserImagePicker에서는 함수가 뭔지는 몰라... 맞지?
                            }),
                          TextFormField(
                            decoration: const InputDecoration(
                              label: Text('email'),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please Enter Valid Email';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              enteredEmail = value!;
                            },
                          ),
                          if (!_isLogIn)
                            TextFormField(
                              enableSuggestions: false,
                              //이거 자동완성 기능... 이멜 로그인시 무조건 꺼
                              decoration: const InputDecoration(
                                labelText: 'UserName',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.length <= 4) {
                                  return 'Make your username more than 4';
                                }
                                return null;
                              },

                              onSaved: (value) {
                                username = value!;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              label: Text('passWord'),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length < 7) {
                                return 'Too short to use password';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              enteredPassword = value!;
                            },
                          ),
                          if (isUthenticating)
                            const CircularProgressIndicator(),
                          const SizedBox(
                            height: 12.0,
                          ),
                          if (!isUthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                              child: Text(
                                _isLogIn ? 'LogIn' : 'Sign Up',
                              ),
                            ),
                          if (!isUthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogIn = !_isLogIn;

                                });
                              },
                              child: Text(_isLogIn
                                  ? 'Create an Account'
                                  : 'I have one. LogIn'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
