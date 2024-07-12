// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:deep_link_client/src/model/podcast_share_link.dart';
import 'package:deep_link_client/src/model/session_link.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

final _log = Logger("DeepLinkClient");

class DeepLinkClient {
  final StreamController<String> _linksNotificationsController = BehaviorSubject<String>();
  Stream<String> get linksNotifications => _linksNotificationsController.stream;

  FirebaseDynamicLinks? _dynamicLinks;

  DeepLinkClient() {
    _dynamicLinks = FirebaseDynamicLinks.instance;
    Timer(const Duration(seconds: 2), listen);
  }

  void listen() async {
    var data = await FirebaseDynamicLinks.instance.getInitialLink();
    if (data != null) {
      publishLink(data);
    }

    _dynamicLinks!.onLink.listen((data) {
      publishLink(data);
    }).onError((err) {
      _log.severe("Failed to fetch dynamic link $err", err);
      return Future.value(null);
    });
  }

  publishLink(PendingDynamicLinkData data) async {
    final Uri uri = data.link;
    _linksNotificationsController.add(uri.toString());
  }

  SessionLink parseSessionInviteLink(String link) {
    return SessionLink.fromLinkQuery(Uri.parse(link).query);
  }

  Future<String> generateSessionInviteLink(SessionLink link) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: "https://breez.page.link",
      link: Uri.parse('https://breez.technology?${link.toLinkQuery()}'),
      androidParameters: const AndroidParameters(packageName: "com.breez.liquid.l_breez"),
      iosParameters: const IOSParameters(bundleId: "com.breez.liquid.lBreez"),
    );
    final ShortDynamicLink shortLink = await _dynamicLinks!.buildShortLink(parameters);

    return shortLink.shortUrl.toString();
  }

  PodcastShareLink parsePodcastShareLink(String link) {
    return PodcastShareLink.fromLinkQuery(Uri.parse(link).query);
  }

  Future<String> generatePodcastShareLink(PodcastShareLink link) async {
    return 'https://breez.link/p?${link.toLinkQuery()}';
  }
}
