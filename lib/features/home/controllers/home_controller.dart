import 'package:get/get.dart';
import 'package:shirbrax/data/models/post_model.dart';
import 'package:shirbrax/data/repositories/post_repository.dart';

class HomeController extends GetxController {
  final _repo = PostRepository();

  final _posts = <PostModel>[].obs;
  final _isLoading = false.obs;
  final _isRefreshing = false.obs;
  final _page = 1.obs;
  final _hasMore = true.obs;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get hasMore => _hasMore.value;

  @override
  void onInit() {
    super.onInit();
    loadFeed();
  }

  Future<void> loadFeed() async {
    _isLoading.value = true;
    try {
      final newPosts = await _repo.getFeed(page: 1);
      _posts.assignAll(newPosts);
      _page.value = 1;
      _hasMore.value = newPosts.length >= 10;
    } catch (_) {
      // Use mock data when backend is not available
      _posts.assignAll(PostModel.mockFeed);
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    _isRefreshing.value = true;
    await loadFeed();
    _isRefreshing.value = false;
  }

  Future<void> loadMore() async {
    if (!_hasMore.value || _isLoading.value) return;
    _page.value++;
    try {
      final more = await _repo.getFeed(page: _page.value);
      _posts.addAll(more);
      _hasMore.value = more.length >= 10;
    } catch (_) {
      _page.value--;
    }
  }

  void toggleLike(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = _posts[idx];
    _posts[idx] = post.copyWith(
      isLiked: !post.isLiked,
      likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
  }
}
