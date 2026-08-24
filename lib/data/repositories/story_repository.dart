import '../providers/story_provider.dart';

class StoryRepository {
  final _provider = StoryProvider();

  Future<List<StoryGroup>> getStories() => _provider.getStories();

  Future<void> createStory({
    required String filePath,
    String? caption,
  }) =>
      _provider.createStory(filePath: filePath, caption: caption);
}
