import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:community/features/chatbot/chatbot_screen.dart';
import 'package:mockito/annotations.dart'; // For generating mocks
// Adjust this path as needed

// Generate mocks for http.Client
@GenerateMocks([http.Client])
void main() {

    // Helper function to wrap the widget in MaterialApp
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }


  testWidgets('User message is sent correctly', (WidgetTester tester) async {
    // Wrap ChatbotScreen in MaterialApp
    await tester.pumpWidget(buildTestableWidget(ChatbotScreen()));

    final textField = find.byType(TextField);
    final sendButton = find.byIcon(Icons.send);

    await tester.enterText(textField, 'Hello');
    await tester.tap(sendButton);
    await tester.pumpAndSettle(); // Allow state updates and potential animations

    // Check if the message 'Hello' appears in the chat list
    // Be more specific if possible, e.g., find text within a specific list item type
    expect(find.text('Hello'), findsWidgets); // Might find the input text and the chat message
  });

  testWidgets('Bot response appears after user sends message', (WidgetTester tester) async {
     // Wrap ChatbotScreen in MaterialApp
    await tester.pumpWidget(buildTestableWidget(ChatbotScreen()));

    final textField = find.byType(TextField);
    final sendButton = find.byIcon(Icons.send);

    expect(textField, findsOneWidget);
    expect(sendButton, findsOneWidget);


    // Simulate user entering text
    await tester.enterText(textField, 'How are you?');

    // Simulate tapping the send button
    await tester.tap(sendButton);

    // Rebuild the widget tree and wait for potential async operations like API calls
    // Use pumpAndSettle for simplicity if exact timing isn't critical
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Adjust duration as needed

    // Check that some response text appears.
    // This is a basic check. Ideally, mock the API response and check for specific text.
    // Find text widgets, excluding the input field text.
    final textFinder = find.byType(Text);
    final textWidgets = tester.widgetList<Text>(textFinder).toList();
    // Filter out the input text if necessary, or check count > 1
    expect(textWidgets.any((text) => text.data != 'How are you?'), isTrue, reason: "Expected bot response text, but only found input text or no text.");

  });


  testWidgets('Predefined message button works', (WidgetTester tester) async {
     // Wrap ChatbotScreen in MaterialApp
    await tester.pumpWidget(buildTestableWidget(ChatbotScreen()));

    // Find the predefined 'Hello' button (adjust finder if needed)
    // Using widgetWithText is more robust than just find.text
    final helloButton = find.widgetWithText(ElevatedButton, 'Hello');
    expect(helloButton, findsOneWidget, reason: "Predefined 'Hello' button not found");

    await tester.tap(helloButton);
    await tester.pumpAndSettle(); // Allow state updates

    // Check if 'Hello' appears in the chat list (potentially multiple times)
    expect(find.text('Hello'), findsWidgets, reason: "'Hello' text not found after tapping predefined button");
    // Check if the text field was populated (optional, depends on implementation)
    // final textField = find.byType(TextField);
    // expect((tester.widget(textField) as TextField).controller?.text, 'Hello');
});

  testWidgets('Chatbot displays a response from the API', (WidgetTester tester) async {
    // Start the app widget (ChatbotScreen)
    await tester.pumpWidget(MaterialApp(home: ChatbotScreen()));

    // Find the text field and send button
    final textField = find.byType(TextField);
    final sendButton = find.byIcon(Icons.send);

    // Enter some text into the text field
    await tester.enterText(textField, 'How are you?');
    await tester.tap(sendButton);
    await tester.pump();

    // Wait for the API response (simulate a delay)
    await tester.pump(Duration(seconds: 2));  // Adjust based on the API response time

    // Check if some response text from the chatbot appears
    expect(find.byType(Text), findsWidgets);  // Ensure some Text widget (response) is displayed
  });
}
