import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hadith_premium/controllers/theme_controller.dart';
import '../controllers/settings_controller.dart';
import 'hadith_list_screen.dart';

class SharedHadithDetailScreen extends StatelessWidget {
  final Map<String, dynamic> share;

  const SharedHadithDetailScreen({super.key, required this.share});

  @override
  Widget build(BuildContext context) {
    String _processArabicText(String text, BuildContext context) {
      if (text.isEmpty) return "";
      String processed = text;
      final colorScheme = Theme.of(context).colorScheme;
      final narratorColor =
          '#${colorScheme.primary.value.toRadixString(16).substring(2)}';

      processed = processed.replaceAllMapped(
        RegExp(r'\[narrator.*?\](.*?)\[/narrator\]'),
        (match) =>
            '<span style="color: $narratorColor; font-weight: 600;">${match.group(1)}</span>',
      );
      processed = processed.replaceAll(
        '[prematn]',
        '<div style="margin-bottom: 8px; opacity: 0.8;">',
      );
      processed = processed.replaceAll('[/prematn]', '</div>');
      processed = processed.replaceAll(
        '[matn]',
        '<div style="font-weight: bold; margin-top: 8px;">',
      );
      processed = processed.replaceAll('[/matn]', '</div>');

      return processed;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final SettingsController _settingsController =
        Get.find<SettingsController>();
    final ThemeController _themeController = Get.find<ThemeController>();


    return Scaffold(
      appBar: AppBar(title: const Text("Shared Hadith"), backgroundColor: theme.scaffoldBackgroundColor,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender info
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _themeController.isDarkMode ? Colors.black : Colors.white,
                border: Border.all(width: 1, color: _themeController.isDarkMode ? Colors.white : Colors.black),
                borderRadius: BorderRadius.circular(21)
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(share['sender']['username'][0].toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share['sender']['username'],
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        "shared this with you",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Shared info
            if (share['comment'] != null && share['comment'].isNotEmpty) ...[
              Text(
                "Comment:",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  share['comment'],
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (share['annotation'] != null &&
                share['annotation'].isNotEmpty) ...[
              Text(
                "Annotation:",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  share['annotation'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Hadith Context
            Text(
              "${share['book_name']} - Hadith #${share['hadith_number']}",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Arabic Text
            if (share['text_ar'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HtmlWidget(
                  _processArabicText(share['text_ar'], context),
                  textStyle: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'qalammajeed3',
                    fontSize: _settingsController.fontSize.value * 1.5,
                    height: 1.8,
                    color: colorScheme.onSurface,
                    wordSpacing: 2.2,
                  ),
                  customStylesBuilder: (element) {
                    if (element.localName == 'p' ||
                        element.localName == 'div') {
                      return {'text-align': 'right', 'direction': 'rtl'};
                    }
                    return null;
                  },
                ),
              ),

            const SizedBox(height: 16),

            // English Text
            if (share['text_en'] != null)
              HtmlWidget(
                share['text_en'],
                textStyle: theme.textTheme.bodyMedium,
              ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Get.to(
                  () => HadithListScreen(
                    bookId: share['book_id'],
                    bookName: share['book_name'],
                    collectionId: share['collection_id'],
                    targetHadithNumber: share['hadith_number'],
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text("View in Full Hadith Context"),
            ),
          ],
        ),
      ),
    );
  }
}
