import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parktixspaceadmin/ui/home.dart';
import 'package:parktixspaceadmin/ui/login.dart';

class AuthService {
  handleAuth() {
    return StreamBuilder(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return Home();
        }
        else {
          return Login();
        }
      },
    );
  }

  signOut() {
    FirebaseAuth.instance.signOut();
  }

  signIn(AuthCredential authCreds, String name) async {
    var creds = await FirebaseAuth.instance.signInWithCredential(authCreds);
    UserUpdateInfo updateInfo = UserUpdateInfo();
    updateInfo.displayName = name;
    creds.user.updateProfile(updateInfo);
  }

  signInWithOTP(String smsCode, String verId, name) {
    AuthCredential authCreds = PhoneAuthProvider.getCredential(
        verificationId: verId,
        smsCode: smsCode
    );
    signIn(authCreds, name);
  }
}