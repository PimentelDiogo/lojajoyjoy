import 'package:joyjoy/core/services/browser_info.dart';
import 'package:web/web.dart' as web;

BrowserInfo currentBrowserInfo() => BrowserInfo(
  url: Uri.base,
  userAgent: web.window.navigator.userAgent,
  referrer: web.document.referrer,
);
