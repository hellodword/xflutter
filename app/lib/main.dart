import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as CryptoPack;
import 'package:encrypt/encrypt.dart' as EncryptPack;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String mText = '';

  void setText(String text, s) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      mText = '$text: $s';
    });
  }

  void certChainChecking() async {
    setText("default cert chain checking", "waiting");
    var text = '';
    try {
      var httpClient = new HttpClient();
      HttpClientRequest request = await httpClient
          .getUrl(Uri.parse("https://dl.google.com/robots.txt"));
      HttpClientResponse response = await request.close();
      // text = await response.transform(utf8.decoder).join();
      text = '${response.statusCode}';
      httpClient.close();
    } catch (e) {
      text = 'failed'; //'$e';
    } finally {
      setText("default cert chain checking", text);
    }
  }

  SecurityContext createSecurityContext() {
    var crtPem = """Bag Attributes
    localKeyID: A9 F6 F8 5C 72 B2 50 4A 17 20 54 FD 64 CC C2 02 93 70 F8 1B 
    friendlyName: a9f6f85c72b2504a172054fd64ccc2029370f81b
subject=C = CN, ST = Shanghai, O = soul, OU = tech, L = Shanghai, CN = soulapp.cn, emailAddress = soultech_devops@soulapp.cn

issuer=C = CN, ST = Shanghai, L = Shanghai, O = soul, OU = tech, CN = soulapp.cn, emailAddress = soultech_devops@soulapp.cn

-----BEGIN CERTIFICATE-----
MIIDmDCCAoACAQAwDQYJKoZIhvcNAQENBQAwgZExCzAJBgNVBAYTAkNOMREwDwYD
VQQIDAhTaGFuZ2hhaTERMA8GA1UEBwwIU2hhbmdoYWkxDTALBgNVBAoMBHNvdWwx
DTALBgNVBAsMBHRlY2gxEzARBgNVBAMMCnNvdWxhcHAuY24xKTAnBgkqhkiG9w0B
CQEWGnNvdWx0ZWNoX2Rldm9wc0Bzb3VsYXBwLmNuMB4XDTE5MTAyMTEyNDI0OVoX
DTI5MTAxODEyNDI0OVowgZExCzAJBgNVBAYTAkNOMREwDwYDVQQIDAhTaGFuZ2hh
aTENMAsGA1UECgwEc291bDENMAsGA1UECwwEdGVjaDERMA8GA1UEBwwIU2hhbmdo
YWkxEzARBgNVBAMMCnNvdWxhcHAuY24xKTAnBgkqhkiG9w0BCQEWGnNvdWx0ZWNo
X2Rldm9wc0Bzb3VsYXBwLmNuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
AQEA8plSeX5GsJJR13JIdziuC9Vj8t9Ik7dOqs/jlIx/CoIjYGzz5b1oyS1GAuiQ
lpuybk/0eGA64mJqvMb9i6LIIbLRR2MIh3CdfAiBDbvFvvo2poZ5/lp6CsxYxmoO
udng/4bQuyMyGDt4JnqTk3H/6Gy8yOvhsnYK4eyArt+frRUXbOHvr4hNnWOOIzBu
BL6EF81dB0SqYc5+s9OH5wZCQRgCXI4yZq2Di87BxkmbawqObZc1XoMxdMoYQQqV
x9hJsxPE8lSznZFCzV7D5GkiA5W+RZdcWAMKFpr/WQRjmg8wZKJjtXpw3dW2JJRl
B/TiiXeUu2iGtMDrn4VGRXPzsQIDAQABMA0GCSqGSIb3DQEBDQUAA4IBAQBkM4m6
3L56SFs1A3tF00qLyzOnakdBBUKfC4TlP3KOKxYtjIejVPZt7yV7snHo9GpaGPAC
16ShB05BrfO4aS6SehXZbNfghIZj802xMPvLsAmNmEZRJHYtYjS/ZiOROevD4+wZ
6DYICG3lQNmYuVkX/ic+ZH369AjW8vpeO2vXH/gd9as9y5eRWs/eGlyuX/htU9fr
sOqFfg3ufSaQ/rIMCLYYy6vm0aiddVHAuC7bKbQCTcTDYLrP1CdYWR1uwwntwM5O
t4TJuSdPJc+2kWmaIDm0NQljZdaeFTEm0euwBmPU29qEyxbmlTtO6zT0hHhJ/cbY
eUIfTDWSaLUJK1Rb
-----END CERTIFICATE-----
""";

    var keyPem = """Bag Attributes
    localKeyID: A9 F6 F8 5C 72 B2 50 4A 17 20 54 FD 64 CC C2 02 93 70 F8 1B 
    friendlyName: a9f6f85c72b2504a172054fd64ccc2029370f81b
Key Attributes: <No Attributes>
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDymVJ5fkawklHX
ckh3OK4L1WPy30iTt06qz+OUjH8KgiNgbPPlvWjJLUYC6JCWm7JuT/R4YDriYmq8
xv2LosghstFHYwiHcJ18CIENu8W++jamhnn+WnoKzFjGag652eD/htC7IzIYO3gm
epOTcf/obLzI6+Gydgrh7ICu35+tFRds4e+viE2dY44jMG4EvoQXzV0HRKphzn6z
04fnBkJBGAJcjjJmrYOLzsHGSZtrCo5tlzVegzF0yhhBCpXH2EmzE8TyVLOdkULN
XsPkaSIDlb5Fl1xYAwoWmv9ZBGOaDzBkomO1enDd1bYklGUH9OKJd5S7aIa0wOuf
hUZFc/OxAgMBAAECggEAElWmFwqFGykjyE2ZznDZLonFEQDxAkDzUBOAFqT7oPau
58W0NSO4fKPQS73513gS5yVhy4sySBO6D2RWmywFRg62pFeGuH25WTtnTXtoeYN9
h95X7/I0kQZamzw+uqsNxyIQOmRxj8VG0lmnN5iBB7bYGbNCDnO/ZM2z+ANslO8C
dgr59iIESNtvIPIfVFxDdZar8dG36XgfM+CMN+3gfht1nAVnsi5/acYe+lSLM5tD
sKVYpLBedyPWtr2WcA2A78UGPkuBG4fzVDtNVnYWc5ylNWHPP+cpq4n/qFDszvFD
2HAmsu/80VDx6tfT0oZlt7HfZo67kQMld5Ju36tf1QKBgQD+QUROGxBdxn2nS7Qj
mmG+FSMR+Dg9WPP+MzDs4GLRwdqP+vV7HrRjhxtAdSfYU6/+iZZtX5u37tuX3IHz
i6N7gw7lGYFhuGtdfOyBjSRZb9dhKZF9sWGfELlL3lh1vcjG0T0/iT04sCQtzjRQ
9oU13uzG9xE98O4TgXY4Ot9sUwKBgQD0Q5NLNQ68DobM7XBjgoVN86tnGUy8rDsR
bf1PLZrJPhEQNHlbdO4IlzP1EeSkVJPQjeR+fyLakBkZJWjjsCQCEOf7OVYDOjhN
m1ux1ukmJN9ZO0q7/AvCBpIYQBTYUHYGqhXZHtEoMR31GGrLbmhfzffbIaCERL4y
YB5UsMn/awKBgH6GMhyAIUvZK8xlwtX4zG0QDayyjiIRMxIrnUwzeVmSk1YU97X2
GKRypmAULOjc9HbBNydkbZRBe+t9Yvm0Yn1jQbVGVPkxEdSrBvKNLyqGmnKSggE/
lSnX463ajsDA2bn+g/ErNVkRZl+Y/rXPh4jAT6nPZzggvgjc4tymh2pbAoGBALP6
irBSkt3MElUy6qnXxSNP1M6tnJY0jX1lPs01fCSl/+qhz32s5ascxiLgIUlYLGXx
9xeh0+uZW3Tk1KlX4uBG1reMYq0UG+JLA8BA6x+48X0NLB7hM0SulL0bkoBkoOJ+
NoT5qQFlV359lEr6uhtFZ0hmOaDcCgySOCcM8HmrAoGBAMsKa1KbbrbtvTcaNceb
P/aSidbXkLaCgnUisoMhgJ12IpkxnumWwPOS0hr9Km7Hr/2/8qhUF5adC7VvNcnr
cTW6JzbBJMtwWhVqTt1HX9jWeV3m/LgUIXNqrPfeZ5vmCnHb6X0+qJCT7bP5eSt/
vgGLYodIntkOxpGwmZB1rE+o
-----END PRIVATE KEY-----
""";

    return SecurityContext()
      ..useCertificateChainBytes(crtPem.codeUnits)
      ..usePrivateKeyBytes(keyPem.codeUnits);
  }

  void certificatePinning() async {
    setText("certificate pinning", "waiting");

    var text = '';
    try {
      var httpClient = new HttpClient(context: createSecurityContext())
        ..badCertificateCallback = (cert, host, port) {
          return true;
        };
      HttpClientRequest request =
          await httpClient.getUrl(Uri.parse("https://api-a.soulapp.cn"));
      HttpClientResponse response = await request.close();
      text = await response.transform(utf8.decoder).join();
      httpClient.close();
    } catch (e) {
      text = 'failed'; //'$e';
    } finally {
      setText("certificate pinning", text);
    }
  }

  void certificatePinningPlus() async {
    setText("certificate pinning plus", "waiting");

    var text = '';
    try {
      var httpClient = new HttpClient(context: createSecurityContext())
        ..badCertificateCallback = (cert, host, port) {
          // abcb7101356f9e4e7a449988e4300bd03b321f95
          return cert.sha1[0] == 0xab &&
              cert.sha1[2] == 0x71 &&
              cert.sha1[5] == 0x6f &&
              cert.sha1[8] == 0x7a &&
              cert.sha1[12] == 0xe4 &&
              cert.sha1[17] == 0x32;
        };
      HttpClientRequest request =
          await httpClient.getUrl(Uri.parse("https://api-a.soulapp.cn"));
      HttpClientResponse response = await request.close();
      text = await response.transform(utf8.decoder).join();
      httpClient.close();
    } catch (e) {
      text = 'failed'; //'$e';
    } finally {
      setText("certificate pinning plus", text);
    }
  }

  void aesEncrypt() async {
    setText("aes('123456','0-9a-f')", "waiting");

    var data = '123456';
    var key = '0123456789abcdef';
    var iv = '0123456789abcdef';

    EncryptPack.IV ivObj = EncryptPack.IV.fromUtf8(iv);
    EncryptPack.Key keyObj = EncryptPack.Key.fromUtf8(key);
    final encrypter = EncryptPack.Encrypter(
        EncryptPack.AES(keyObj, mode: EncryptPack.AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: ivObj);

    setText("aes('123456','0-9a-f')", encrypted.base64);
  }

  void hmacSha1() {
    setText("hmac_sha1('123456','0-9a-f')", "waiting");
    var data = '123456';
    var key = '0123456789abcdef';

    var hmac = CryptoPack.Hmac(CryptoPack.sha1, key.codeUnits);

    setText("hmac_sha1('123456','0-9a-f')",
        hex.encode(hmac.convert(data.codeUnits).bytes));
  }

  void xorEncrypt() {
    setText("xor('123456','0-9a-f')", "waiting");
    var data = '123456';
    var key = '0123456789abcdef';

    List<int> x = utf8.encode(data);
    List<int> y = utf8.encode(key);

    for (var i = 0; i < x.length; i++) {
      x[i] ^= y[i];
    }

    setText("xor('123456','0-9a-f')", hex.encode(x));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Text(
            //   'You have pushed the button this many times:',
            // ),
            Text(
              mText,
            ),
            FractionallySizedBox(
              widthFactor: 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ElevatedButton.icon(
                    label: Text(
                      "default cert chain checking",
                    ),
                    onPressed: () => certChainChecking(),
                    icon: Icon(Icons.looks_one),
                  ),
                  ElevatedButton.icon(
                    label: Text(
                      "certificate pinning",
                    ),
                    onPressed: () => certificatePinning(),
                    icon: Icon(Icons.looks_two),
                  ),
                  ElevatedButton.icon(
                    label: Text(
                      "certificate pinning plus",
                    ),
                    onPressed: () => certificatePinningPlus(),
                    icon: Icon(Icons.looks_3),
                  ),
                  ElevatedButton.icon(
                    label: Text(
                      "aes('123456','0-9a-f')",
                    ),
                    onPressed: () => aesEncrypt(),
                    icon: Icon(Icons.looks_4),
                  ),
                  ElevatedButton.icon(
                    label: Text(
                      "hmac_sha1('123456','0-9a-f')",
                    ),
                    onPressed: () => hmacSha1(),
                    icon: Icon(Icons.looks_5),
                  ),
                  ElevatedButton.icon(
                    label: Text(
                      "xor('123456','0-9a-f')",
                    ),
                    onPressed: () => xorEncrypt(),
                    icon: Icon(Icons.looks_6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
