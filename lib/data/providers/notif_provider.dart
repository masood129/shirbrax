import '../../core/network/api_client.dart';
import '../models/notif_model.dart';

class NotifProvider {
  final _dio = ApiClient.instance;

  Future<List<NotifModel>> getNotifications() async {
    final response = await _dio.get('/notifications');
    final List data = response.data['data'] as List;
    return data.map((e) {
      final json = e as Map<String, dynamic>;
      final type = switch (json['type']) {
        'comment' => NotifType.comment,
        'follow' => NotifType.follow,
        'mention' => NotifType.mention,
        'follow_request' => NotifType.followRequest,
        'follow_accepted' => NotifType.followAccepted,
        'subscription' => NotifType.subscription,
        _ => NotifType.like,
      };
      return NotifModel(
        id: json['id'].toString(),
        type: type,
        actorName: json['actorName'] as String,
        actorAvatar: json['actorAvatar'] as String?,
        postThumbnail: json['postThumbnail'] as String?,
        postId: json['postId'] as String?,
        message: json['message'] as String,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    }).toList();
  }

  Future<void> markRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/read-all');
  }
}
