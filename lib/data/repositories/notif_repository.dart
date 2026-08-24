import '../models/notif_model.dart';
import '../providers/notif_provider.dart';

class NotifRepository {
  final _provider = NotifProvider();

  Future<List<NotifModel>> getNotifications() => _provider.getNotifications();

  Future<void> markRead(String id) => _provider.markRead(id);

  Future<void> markAllRead() => _provider.markAllRead();
}
