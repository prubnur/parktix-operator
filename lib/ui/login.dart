import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:international_phone_input/international_phone_input.dart';
import 'package:parktixspaceadmin/services/authservice.dart';
import 'package:parktixspaceadmin/ui/textLogin.dart';
import 'package:parktixspaceadmin/ui/verticalText.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_database/firebase_database.dart';


class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final formKey = new GlobalKey<FormState>();
  String phoneNo, verificationId, smsCode;

  bool codeSent = false;

  final TextEditingController controller = TextEditingController();
  String phoneNumber;
  String phoneIsoCode = '+91';

  String currentText = "";
  TextEditingController textEditingController = TextEditingController();

  String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
//      appBar: AppBar(
//        title: codeSent ? Text("Verification") : Text("ParkTix"),
//        backgroundColor: Colors.blueAccent,
//        centerTitle: true,
//      ),

      body:
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.blue.shade900, Colors.blue.shade700]),
        ),
        child: Form(
          key: formKey,
          child: !codeSent ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(children: <Widget>[
                VerticalText(),
                TextLogin(),
              ]),
              SizedBox(height: 50),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)
                  ),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Container(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.08,
                                right: MediaQuery.of(context).size.width * 0.08,
                                bottom: MediaQuery.of(context).size.height * 0.01,
                                top: MediaQuery.of(context).size.height * 0.03
                            ),
                            child: TextFormField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                labelText: "Name",
                                fillColor: Colors.white,
//                                border: InputBorder.none
                              ),
                              validator: (val) {
                                if (val!=null && val.isNotEmpty) {
                                  return null;
                                }
                                else return "Enter name";
                              },
                              onSaved: (val) {
                                name = val;
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.08, right: MediaQuery.of(context).size.width * 0.08, bottom: MediaQuery.of(context).size.height * 0.01),
                            child: InternationalPhoneInput(
                              onPhoneNumberChange: onPhoneNumberChange,
                              initialPhoneNumber: phoneNumber,
                              initialSelection: phoneIsoCode,
                              enabledCountries: ['+91'],
                              showCountryFlags: true,
                              showCountryCodes: false,
                              labelText: "Phone",
                              hintText: "eg. 9999999999",
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.08,
                              right: MediaQuery.of(context).size.width * 0.08,
                              bottom: MediaQuery.of(context).size.height * 0.02
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: FlatButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40)),
                                child: Center(
                                  child: Text(
                                    "Continue",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if (formKey.currentState.validate()) {
                                    formKey.currentState.save();
                                    //TODO: Check if phone number exists among venue operators before verifying
                                    verifyPhone(phoneNo);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            ],
          ) : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
                child: Row(children: <Widget>[
                  VerticalText(),
                  TextLogin(),
                ]),
              ),
              SizedBox(height: 30),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)
                  ),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 10,
                  child: Container(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("Enter the OTP sent to ", style: TextStyle(fontSize: 18),),
                                Text("${phoneNo}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),)
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1, vertical: MediaQuery.of(context).size.height * 0.05),
                            child: PinCodeTextField(
                              autoFocus: true,
                              backgroundColor: Colors.transparent,
                              textInputType: TextInputType.numberWithOptions(decimal: false),
                              length: 6,
                              obsecureText: true,
                              onChanged: (value) {
                                print(value);
                                setState(() {
                                  smsCode = value;
                                });
                              },
                              onCompleted: (v) {
                                AuthService().signInWithOTP(smsCode, verificationId, name);
                              },
                              animationType: AnimationType.fade,
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.underline,
                                inactiveColor: Colors.grey,
                                activeColor: Colors.blue
                              ),
                              animationDuration: Duration(milliseconds: 300),
                              controller: textEditingController,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("Didn't receive code? "),
                                InkWell(
                                  child: Text("RESEND OTP", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),),
                                  onTap: () {
                                    textEditingController.clear();
                                    verifyPhone(phoneNo);
                                  },
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Spacer()
            ],
          ),
        ),
      ),
    );
  }

  Future<void> verifyPhone(String phoneNo) async {

    final PhoneVerificationCompleted verified = (AuthCredential authResult)  async {
      AuthService().signIn(authResult, name);
    };

    final PhoneVerificationFailed verificationFailed = (AuthException authException) {
      print(authException.message);
    };

    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this.verificationId = verId;
      setState(() {
        codeSent = true;
      });
    };

    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this.verificationId = verId;
    };

    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNo,
        timeout: const Duration(minutes: 1),
        verificationCompleted: verified,
        verificationFailed: verificationFailed,
        codeSent: smsSent,
        codeAutoRetrievalTimeout: autoTimeout
    );
  }

  void onPhoneNumberChange(String number, String internationalizedPhoneNumber, String isoCode) {
    print(number);
    print(internationalizedPhoneNumber);
    phoneNo = internationalizedPhoneNumber;
    setState(() {
      phoneNumber = number;
      phoneIsoCode = isoCode;
    });
  }
}
