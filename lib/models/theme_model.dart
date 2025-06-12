import 'collection_model.dart';

class ThemeModel {
  final String name;
  final String assetPath;
  final List<CollectionCard> cards;

  ThemeModel({
    required this.name,
    required this.assetPath,
    required this.cards,
  });
}

// 卡牌中文名称映射
final Map<String, String> cardChineseNames = {
  'afternoon_tea.png': '英式下午茶',
  'bagpiper.png': '苏格兰风笛手',
  'bookstore.png': '古典书店',
  'double_decker.png': '红色双层巴士',
  'epl_ticket.png': '英超球票',
  'london_eye.png': '伦敦眼',
  'newsboy.png': '报童',
  'red_guard.png': '皇家卫兵',
  'royal_musician.png': '皇家乐手',
};

// 卡牌描述信息
final Map<String, String> cardDescriptions = {
  'afternoon_tea.png': '英式下午茶是英国传统文化的重要组成部分，通常在下午3-4点享用，包括精致的茶点、司康饼和三层点心架。这一传统始于19世纪维多利亚时代，体现了英国人对优雅生活的追求。',
  'bagpiper.png': '苏格兰风笛手是苏格兰文化的象征，身着传统格子裙，演奏悠扬的风笛乐曲。风笛声常在重要仪式和庆典中响起，承载着苏格兰民族的历史记忆和文化传承。',
  'bookstore.png': '英国的古典书店承载着深厚的文学传统，从莎士比亚到狄更斯，无数文学巨匠的作品在这里流传。这些书店不仅是知识的宝库，更是英国文化底蕴的体现。',
  'double_decker.png': '红色双层巴士是伦敦最具标志性的交通工具，自1956年起服务于伦敦街头。它不仅是实用的公共交通，更成为了英国文化的象征，出现在无数明信片和电影中。',
  'epl_ticket.png': '英超联赛是世界上最受欢迎的足球联赛之一，汇聚了全球顶尖球星。一张英超球票不仅是观赛的门票，更是体验英国足球文化和激情的珍贵机会。',
  'london_eye.png': '伦敦眼是泰晤士河畔的巨型摩天轮，高135米，是伦敦天际线的重要组成部分。从这里可以俯瞰整个伦敦城，感受这座古老城市的现代魅力。',
  'newsboy.png': '传统的英国报童是维多利亚时代街头的常见身影，他们穿着整洁的制服，在街头巷尾叫卖报纸。这一形象代表了英国新闻业的历史传统和社会变迁。',
  'red_guard.png': '英国皇家卫兵以其标志性的红色制服和高帽闻名世界，他们守卫着白金汉宫等皇室重要场所。换岗仪式是伦敦最受欢迎的旅游景点之一，展现了英国皇室的庄严传统。',
  'royal_musician.png': '皇家乐手是英国宫廷音乐传统的传承者，他们在重要的国事活动和庆典中演奏。精湛的音乐技艺和华丽的制服体现了英国皇室文化的优雅与庄重。',
};

String _nameFromPath(String path) {
  return cardChineseNames[path] ?? path
      .split('.')[0] // remove .png
      .replaceAll('_', ' ') // replace underscores
      .split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

final Map<String, ThemeModel> themes = {
  'uk': ThemeModel(
    name: 'UK Collection',
    assetPath: 'UK', // Case-sensitive to match directory
    cards: [
      'afternoon_tea.png', 'bagpiper.png', 'bookstore.png', 'double_decker.png',
      'epl_ticket.png', 'london_eye.png', 'newsboy.png', 'red_guard.png', 'royal_musician.png'
    ].map((file) => CollectionCard(name: _nameFromPath(file), imagePath: file)).toList(),
  ),
  'japan': ThemeModel(
    name: 'Japan Collection',
    assetPath: 'Japan', // Case-sensitive to match directory
    cards: [
      'japanese_garden.png', 'japanese_maiko.png', 'japanese_summer_festival.png', 'japanese_tea_ceremony.png',
      'japan_cherry_blossom_samurai.png', 'kabuki_performance.png', 'kinkaku.png', 'mt_fuji_village.png', 'sumo_wrestler.png'
    ].map((file) => CollectionCard(name: _nameFromPath(file), imagePath: file)).toList(),
  ),
}; 