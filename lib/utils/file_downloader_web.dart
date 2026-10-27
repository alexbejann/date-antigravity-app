// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

bool triggerBrowserDownload({
  required String filename,
  required String content,
  String mimeType = 'text/plain;charset=utf-8',
}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}

bool openBrowserUrl(String url) {
  html.window.open(url, '_blank');
  return true;
}

Future<String?> fetchFreshAssetString(String assetPath) async {
  try {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    return await html.HttpRequest.getString(
      'assets/$assetPath?v=$cacheBuster',
    );
  } catch (_) {
    return null;
  }
}
