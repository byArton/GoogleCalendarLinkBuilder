import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const CalendarLinkGeneratorApp());
}

class CalendarLinkGeneratorApp extends StatelessWidget {
  const CalendarLinkGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カレンダー予定共有',
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansJpTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      home: const CalendarLinkGeneratorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalendarLinkGeneratorScreen extends StatefulWidget {
  const CalendarLinkGeneratorScreen({super.key});

  @override
  _CalendarLinkGeneratorScreenState createState() =>
      _CalendarLinkGeneratorScreenState();
}

class _CalendarLinkGeneratorScreenState
    extends State<CalendarLinkGeneratorScreen> {
  final TextEditingController titleController = TextEditingController(text: "");
  final TextEditingController locationController =
      TextEditingController(text: "");
  final TextEditingController detailsController =
      TextEditingController(text: "");

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);
  String? generatedLink;

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('ja', 'JP'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final DateTime dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(dateTime.toUtc());
  }

  void generateAndCopyLink(BuildContext context) async {
    final String startDateTime = _formatDateTime(selectedDate, startTime);
    final String endDateTime = _formatDateTime(selectedDate, endTime);

    final String baseUrl = "https://calendar.google.com/calendar/render";
    final String action = "TEMPLATE";
    final String title = Uri.encodeComponent(titleController.text);
    final String dates = "$startDateTime/$endDateTime";
    final String location = Uri.encodeComponent(locationController.text);
    final String details = Uri.encodeComponent(detailsController.text);

    final String url =
        "$baseUrl?action=$action&text=$title&dates=$dates&location=$location&details=$details";

    setState(() {
      generatedLink = url;
    });

    await Clipboard.setData(ClipboardData(text: url));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('リンクをクリップボードにコピーしました',
              style: TextStyle(fontFamily: 'Noto Sans JP')),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy年MM月dd日').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("カレンダー予定共有"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "イベント名",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('日付と時間',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text('日付: $formattedDate'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('開始: ${startTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('終了: ${endTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "場所",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: "詳細",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            if (generatedLink != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "生成されたリンク:\n$generatedLink",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => generateAndCopyLink(context),
              icon: const Icon(Icons.copy),
              label: const Text("リンクを生成してコピー"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
