import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class CallRecorder {
  static const platform = MethodChannel('call_recorder/channel');
  String? currentRecordingPath;

  Future<void> initialize() async {
    print("Qo'ng'iroq holatini kuzatish boshlanmoqda...");

    platform.setMethodCallHandler((call) async {
      print("Qo'ng'iroq holati: ${call.arguments}");
      if (call.method == "getCallState") {
        String state = call.arguments ?? "idle";
        print("Qo'ng'iroq holati: $state");
        if (state == "offhook") {
          await startRecording();
        } else if (state == "idle") {
          await stopRecording();
        }
      }
    });
  }

  Future<void> startRecording() async {
    currentRecordingPath = 'call_${DateTime.now().millisecondsSinceEpoch}.aac';
    print('Yozib olish boshlandi: $currentRecordingPath');
    // Yozish kodini bu yerga qo'shing
  }

  Future<void> stopRecording() async {
    print('Yozib olish tugadi: $currentRecordingPath');
    if (currentRecordingPath != null) {
      final isOnline = await checkInternetConnection();
      if (isOnline) {
        await sendToBackend(currentRecordingPath!);
      } else {
        print("Internet yo'q, yozuv saqlanmoqda.");
      }
    }
  }

  Future<void> sendToBackend(String filePath) async {
    try {
      print('Fayl yuklanmoqda: $filePath');
      final response = await Dio().post(
        'https://your-backend.com/upload',
        data: FormData.fromMap({
          'file':
              await MultipartFile.fromFile(filePath, filename: 'recording.aac'),
        }),
      );
      print('Fayl yuklandi: ${response.statusCode}');
    } catch (e) {
      print('Fayl yuklashda xatolik: $e');
    }
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CallRecorder callRecorder = CallRecorder();

  @override
  void initState() {
    super.initState();
    requestPermissions();
    callRecorder.initialize();
  }

  Future<void> requestPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.microphone,
      Permission.storage, // Oddiy saqlash uchun
      Permission.manageExternalStorage, // Kengaytirilgan saqlash uchun
    ];

    for (var permission in permissions) {
      if (await permission.isDenied || await permission.isPermanentlyDenied) {
        await permission.request();
      }
    }

    // Rad etilgan ruxsatlarni tekshirish
    final deniedPermissions =
        await Future.wait(permissions.map((p) => p.status));
    print("Rad etilgan ruxsatlar: $deniedPermissions");
    if (deniedPermissions.any((status) => status.isDenied)) {
      print("Quyidagi ruxsatlar berilmadi: $deniedPermissions");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ruxsat kerak'),
          content: const Text(
            'Ilova to\'g\'ri ishlashi uchun barcha ruxsatlarni taqdim etishingiz kerak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Recorder'),
      ),
      body: const Center(
        child: Text('Call recording is active.'),
      ),
    );
  }
}
