// 扩展的收集卡牌类，支持道具
class CollectionCard {
  final String name;
  final String imagePath;
  final bool isProp; // 新增：是否为道具
  int progress; // 0 to 4，道具不使用此字段

  bool get isCollected => !isProp && progress >= 4;

  CollectionCard({
    required this.name,
    required this.imagePath,
    this.progress = 0,
    this.isProp = false, // 默认为卡牌
  });

  CollectionCard clone() {
    return CollectionCard(
      name: name,
      imagePath: imagePath,
      progress: progress,
      isProp: isProp,
    );
  }
}

class ThemeModel {
  final String name;
  final String assetPath;
  final List<CollectionCard> cards; // 包含卡牌和道具

  ThemeModel({
    required this.name,
    required this.assetPath,
    required this.cards,
  });
}

// 道具中文名称映射
final Map<String, String> propChineseNames = {
  'Crystal Dice.png': '水晶骰子',
};

// 道具描述信息
final Map<String, String> propDescriptions = {
  'Crystal Dice.png': '神秘的水晶骰子，蕴含着古老的魔法力量。当它在老虎机中连续出现时，会为你增加宝贵的转动次数。2连可获得25次转动，3连可获得100次转动！',
};

// 卡牌中文名称映射
final Map<String, String> cardChineseNames = {
  // 英国主题
  'afternoon_tea.png': '英式下午茶',
  'bagpiper.png': '苏格兰风笛手',
  'bookstore.png': '古典书店',
  'double_decker.png': '红色双层巴士',
  'epl_ticket.png': '英超球票',
  'london_eye.png': '伦敦眼',
  'newsboy.png': '报童',
  'red_guard.png': '皇家卫兵',
  'royal_musician.png': '皇家乐手',
  
  // 日本主题
  'japanese_garden.png': '日式庭院',
  'japanese_maiko.png': '艺伎',
  'japanese_summer_festival.png': '夏日祭典',
  'japanese_tea_ceremony.png': '茶道表演',
  'japan_cherry_blossom_samurai.png': '樱花武士',
  'kabuki_performance.png': '歌舞伎表演',
  'kinkaku.png': '金阁寺',
  'mt_fuji_village.png': '富士山村落',
  'sumo_wrestler.png': '相扑选手',
};

// 卡牌描述信息
final Map<String, String> cardDescriptions = {
  // 英国主题描述
  'afternoon_tea.png': '英式下午茶是英国传统文化的重要组成部分，通常在下午3-4点享用，包括精致的茶点、司康饼和三层点心架。这一传统始于19世纪维多利亚时代，体现了英国人对优雅生活的追求。',
  'bagpiper.png': '苏格兰风笛手是苏格兰文化的象征，身着传统格子裙，演奏悠扬的风笛乐曲。风笛声常在重要仪式和庆典中响起，承载着苏格兰民族的历史记忆和文化传承。',
  'bookstore.png': '英国的古典书店承载着深厚的文学传统，从莎士比亚到狄更斯，无数文学巨匠的作品在这里流传。这些书店不仅是知识的宝库，更是英国文化底蕴的体现。',
  'double_decker.png': '红色双层巴士是伦敦最具标志性的交通工具，自1956年起服务于伦敦街头。它不仅是实用的公共交通，更成为了英国文化的象征，出现在无数明信片和电影中。',
  'epl_ticket.png': '英超联赛是世界上最受欢迎的足球联赛之一，汇聚了全球顶尖球星。一张英超球票不仅是观赛的门票，更是体验英国足球文化和激情的珍贵机会。',
  'london_eye.png': '伦敦眼是泰晤士河畔的巨型摩天轮，高135米，是伦敦天际线的重要组成部分。从这里可以俯瞰整个伦敦城，感受这座古老城市的现代魅力。',
  'newsboy.png': '传统的英国报童是维多利亚时代街头的常见身影，他们穿着整洁的制服，在街头巷尾叫卖报纸。这一形象代表了英国新闻业的历史传统和社会变迁。',
  'red_guard.png': '英国皇家卫兵以其标志性的红色制服和高帽闻名世界，他们守卫着白金汉宫等皇室重要场所。换岗仪式是伦敦最受欢迎的旅游景点之一，展现了英国皇室的庄严传统。',
  'royal_musician.png': '皇家乐手是英国宫廷音乐传统的传承者，他们在重要的国事活动和庆典中演奏。精湛的音乐技艺和华丽的制服体现了英国皇室文化的优雅与庄重。',
  
  // 日本主题描述
  'japanese_garden.png': '日式庭院体现了日本人对自然和谐的追求，通过精心布置的石头、水景和植物，创造出宁静致远的禅意空间。每一个细节都蕴含着深厚的文化内涵和美学理念。',
  'japanese_maiko.png': '艺伎是日本传统文化的瑰宝，她们精通茶道、花道、音乐和舞蹈等多种艺术。华美的和服、精致的妆容和优雅的举止，展现了日本女性文化的极致之美。',
  'japanese_summer_festival.png': '夏日祭典是日本最具特色的传统节庆，人们身着浴衣，在夜市中品尝小食、观看烟花。这是连接传统与现代、老少共享的美好时光。',
  'japanese_tea_ceremony.png': '茶道不仅是饮茶的艺术，更是修身养性的精神修炼。通过繁复而优雅的仪式，体现了日本文化中的"和敬清寂"精神，追求内心的平静与和谐。',
  'japan_cherry_blossom_samurai.png': '樱花与武士是日本文化的经典象征，樱花的短暂绚烂象征着武士道的生死观念。在樱花飞舞的季节，武士的勇气和美学得到了最完美的诠释。',
  'kabuki_performance.png': '歌舞伎是日本传统戏剧的瑰宝，以其夸张的表演、华丽的服装和独特的化妆艺术著称。这种艺术形式承载着数百年的历史传统和民族文化精髓。',
  'kinkaku.png': '金阁寺是京都最著名的禅宗寺庙，整座建筑外层贴金，在阳光下金光闪闪。它不仅是建筑艺术的杰作，更体现了日本禅宗文化的深邃意境。',
  'mt_fuji_village.png': '富士山下的传统村落保持着古朴的生活方式，茅草屋顶、木制建筑与雄伟的富士山形成了完美的和谐画面，展现了日本乡村文化的纯真魅力。',
  'sumo_wrestler.png': '相扑是日本的国技，承载着深厚的神道教传统和民族精神。相扑选手通过严格的训练和仪式，展现了力量、技巧与精神修养的完美结合。',
};

// 主题中文名称映射
final Map<String, String> themeChineseNames = {
  'UK Collection': '英国印象',
  'Japan Collection': '日本风情',
};

String _nameFromPath(String path) {
  return cardChineseNames[path] ?? path
      .split('.')[0] // remove .png
      .replaceAll('_', ' ') // replace underscores
      .split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String _propNameFromPath(String path) {
  return propChineseNames[path] ?? path
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
      // 普通卡牌
      ...['afternoon_tea.png', 'bagpiper.png', 'bookstore.png', 'double_decker.png',
          'epl_ticket.png', 'london_eye.png', 'newsboy.png', 'red_guard.png', 'royal_musician.png']
        .map((file) => CollectionCard(name: _nameFromPath(file), imagePath: file)),
      // 道具
      ...['Crystal Dice.png']
        .map((file) => CollectionCard(name: _propNameFromPath(file), imagePath: file, isProp: true)),
    ],
  ),
  'japan': ThemeModel(
    name: 'Japan Collection',
    assetPath: 'Japan', // Case-sensitive to match directory
    cards: [
      // 普通卡牌
      ...['japanese_garden.png', 'japanese_maiko.png', 'japanese_summer_festival.png', 'japanese_tea_ceremony.png',
          'japan_cherry_blossom_samurai.png', 'kabuki_performance.png', 'kinkaku.png', 'mt_fuji_village.png', 'sumo_wrestler.png']
        .map((file) => CollectionCard(name: _nameFromPath(file), imagePath: file)),
      // 道具
      ...['Crystal Dice.png']
        .map((file) => CollectionCard(name: _propNameFromPath(file), imagePath: file, isProp: true)),
    ],
  ),
}; 