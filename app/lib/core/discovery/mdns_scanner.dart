import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

class DiscoveredRobot {
  final String host;
  final int port;
  final String name;
  const DiscoveredRobot({required this.host, required this.port, required this.name});
}

/// Quét mDNS tìm robot broadcast service `_rosbridge._tcp`.
class MdnsScanner {
  Future<List<DiscoveredRobot>> scan({Duration timeout = const Duration(seconds: 3)}) async {
    final client = MDnsClient(rawDatagramSocketFactory: (dynamic host, int port,
            {bool reuseAddress = true, bool reusePort = false, int ttl = 255}) =>
        RawDatagramSocket.bind(host, port, reuseAddress: reuseAddress, ttl: ttl));

    final found = <DiscoveredRobot>[];
    try {
      await client.start();
      const name = '_rosbridge._tcp.local';
      final ptrs = await client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))
          .timeout(timeout, onTimeout: (sink) => sink.close())
          .toList();

      for (final ptr in ptrs) {
        final srvs = await client
            .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName))
            .toList();
        for (final srv in srvs) {
          final ips = await client
              .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target))
              .toList();
          for (final ip in ips) {
            found.add(DiscoveredRobot(
              host: ip.address.address,
              port: srv.port,
              name: ptr.domainName,
            ));
          }
        }
      }
    } on TimeoutException {
      // ignore - return what we have
    } catch (_) {
      // ignore errors, return empty
    } finally {
      client.stop();
    }
    return found;
  }
}
