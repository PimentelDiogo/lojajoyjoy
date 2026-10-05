import 'package:joyjoy/core/services/browser_info.dart';

BrowserInfo currentBrowserInfo() =>
    BrowserInfo(url: Uri.base, userAgent: '', referrer: '');
