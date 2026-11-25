import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/viewmodels/auth_viewmodel.dart';
import 'package:mobile/viewmodels/notes_viewmodel.dart';
import 'package:mobile/viewmodels/scheduler_viewmodel.dart';
import 'package:mobile/viewmodels/tasks_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('XiaomiNotesApp mounts cleanly with MVVM providers', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => NotesViewModel()),
          ChangeNotifierProvider(create: (_) => TasksViewModel()),
          ChangeNotifierProvider(create: (_) => SchedulerViewModel()),
        ],
        child: const XiaomiNotesApp(),
      ),
    );
    expect(find.byType(XiaomiNotesApp), findsOneWidget);
  });
}
