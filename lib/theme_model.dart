import 'package:flutter/foundation.dart';

@immutable
class GameTheme {
  final String name; // 主题名称，如 "伦敦印象"
  final String assetPath; // 资源路径，如 "cards" 或 "japan"
  final List<String> cardPool; // 卡池
  final Map<String, String> cardPics; // 卡片名称到图片文件的映射
  final Map<String, String> cardDescriptions; // 卡片描述

  const GameTheme({
    required this.name,
    required this.assetPath,
    required this.cardPool,
    required this.cardPics,
    required this.cardDescriptions,
  });
}

// 主题数据中心
class Themes {
  static final GameTheme londonTheme = GameTheme(
    name: '伦敦印象',
    assetPath: 'cards/uk',
    cardPool: const [
      '红衣哨兵', '下午茶三层盘', '伦敦眼门票',
      '查令十字街书店卡', '皇家乐手', '英超球票',
      '风笛手', '地铁报童', '双层巴士'
    ],
    cardPics: const {
      '红衣哨兵': 'red_guard.png',
      '下午茶三层盘': 'afternoon_tea.png',
      '伦敦眼门票': 'london_eye.png',
      '查令十字街书店卡': 'bookstore.png',
      '皇家乐手': 'royal_musician.png',
      '英超球票': 'epl_ticket.png',
      '风笛手': 'bagpiper.png',
      '地铁报童': 'newsboy.png',
      '双层巴士': 'double_decker.png',
    },
    cardDescriptions: const {
      '双层巴士': '伦敦街头的红色流动风景线 🚌。坐上上层的第一排，整个城市的脉搏仿佛都在你的脚下。下一站，是未知的惊喜还是熟悉的街角？ #LondonVibes',
      '皇家乐手': '高高的熊皮帽，庄严的红色制服 💂‍♂️。他们不只是仪仗队的守护者，更是日不落帝国历史的回响。嘘...仔细听，空气中仿佛还回荡着他们的鼓点与号角。 #RoyalGuard',
      '风笛手': '苏格兰高地的灵魂之声 🎶。那悠远苍凉的乐声，是山川的低语，是民族的骄傲。闭上眼，仿佛能看到穿着格子裙的乐手，在风中独自矗立。 #ScottishPride',
      '红衣哨兵': '他们是白金汉宫最忠诚的卫士，以纹丝不动和冷峻表情闻名于世。但别被外表骗了，这身鲜红的制服下，是一颗为女王跳动的心 ❤️。 #BuckinghamPalace',
      '伦敦眼门票': '一张通往天际的门票 🎡。在泰晤士河畔缓缓升起，将整个伦敦的壮丽景色尽收眼底。从国会大厦到圣保罗大教堂，每一个地标都变成了你眼中的星辰。 #LondonEye',
      '下午茶三层盘': '这不只是一顿点心，这是英伦生活的仪式感 🍰☕。司康、三明治、小蛋糕，从咸到甜，一层层品味时光的优雅。别忘了，小指要翘起来哦！ #AfternoonTea',
      '英超球票': '周末的呐喊，绿茵场的狂热 ⚽🔥！这张票是通往梦想剧场的凭证，是与成千上万球迷共享激情与心跳的约定。进球的瞬间，整个世界都为你沸腾！ #FootballIsLife',
      '查令十字街书店卡': '致敬所有爱书人的圣地 📖。在这里，时光放慢了脚步，每一本书都承载着一个世界。或许，你也能在这里找到那封寄往84号的信。 #CharingCrossRoad',
      '地铁报童': '"Mind the gap!" 🚇 在繁忙的伦敦地下铁，他们是流动的资讯站。一份报纸，连接着地上与地下的世界，也见证着无数行色匆匆的伦敦故事。 #TubeLife'
    },
  );

  static final GameTheme japanTheme = GameTheme(
    name: '和风之旅',
    assetPath: 'cards/japan',
    cardPool: const [
      '樱落武士', '静谧庭院', '和服少女',
      '歌舞伎', '晨曦富士', '茶道',
      '相扑力士', '金阁寺', '夏日祭'
    ],
    cardPics: const {
      '樱落武士': 'japan_cherry_blossom_samurai.png',
      '静谧庭院': 'japanese_garden.png',
      '和服少女': 'japanese_maiko.png',
      '歌舞伎': 'kabuki_performance.png',
      '晨曦富士': 'mt_fuji_village.png',
      '茶道': 'japanese_tea_ceremony.png',
      '相扑力士': 'sumo_wrestler.png',
      '金阁寺': 'kinkaku.png',
      '夏日祭': 'japanese_summer_festival.png',
    },
    cardDescriptions: const {
      '樱落武士': '樱花飘落背景下的日本传统武士，手持长刀，身姿挺拔。',
      '静谧庭院': '宁静的日式庭院，有石灯笼、潺潺流水和翠绿的苔藓。',
      '和服少女': '穿着和服的日本少女，手持折扇，面带微笑。',
      '歌舞伎': '日本传统的歌舞伎表演场景，演员妆容夸张，服饰华丽。',
      '晨曦富士': '富士山在清晨阳光照耀下，山顶覆盖着白雪，山下是错落的村庄。',
      '茶道': '日本茶道场景，一位茶艺师正在进行优雅的泡茶动作。',
      '相扑力士': '展示日本相扑选手在赛场上准备比赛的瞬间。',
      '金阁寺': '日本金阁寺，在湖水中倒映出金色的光芒。',
      '夏日祭': '色彩斑斓的日本夏日祭典，人们穿着浴衣，手持烟花。',
    },
  );

  static final List<GameTheme> allThemes = [londonTheme, japanTheme];
} 