// ============================================================
// MOCK DATA - Gaming and Zone-focused mock data for Blush
// Focus: Arena of Valor / Liên Quân Mobile & 3-purpose routing
// ============================================================

export const MOCK_USERS = [
  {
    id: 'u1', name: 'Linh Nguyễn', age: 20,
    mbti: 'INFJ', emoji: '🌸',
    interests: ['Liên Quân Mobile', 'Hội Tấu Hài', 'Đường Giữa'],
    lifestyle_en: 'Night Raider (Night)',
    lifestyle_vi: 'Thợ cày đêm (Cú đêm)',
    bio_en: 'Midlane specialist who loves singing in voice chat. Let\'s play casually and have fun! 🎤',
    bio_vi: 'Chuyên đi Mid tấu hài, voice chat hát hò giải stress cực vui. Tìm đồng đội tấu hài cùng! 🎤',
    compatibility: 94, matchColor: '#9D4EDD',
    avatar: '🌸', avatarBg: 'linear-gradient(135deg,#9D4EDD,#00F5FF)',
    isVip: false, reported: false, status: 'active',
    joinDate: '2025-12-01', location_en: 'HCMC Server', location_vi: 'Server TP.HCM',
    exp: 1250, coins: 340, level: 12,
    badges: ['🎤 Top 1 Tấu Hài', '💫 Gacha Collector']
  },
  {
    id: 'u2', name: 'Minh Tú', age: 22,
    mbti: 'ENFP', emoji: '⚔️',
    interests: ['Liên Quân Mobile', 'Chúa Tryhard', 'Đường Rừng'],
    lifestyle_en: 'Flexible Raider',
    lifestyle_vi: 'Giờ chơi tự do',
    bio_en: 'Jungle main carry. Looking for a serious competitive team to climb rank. High stars only! ⚔️',
    bio_vi: 'Rừng gánh team cực mạnh. Cần tìm đồng đội leo rank nghiêm túc, phối hợp chuẩn chỉ. ⚔️',
    compatibility: 87, matchColor: '#00F5FF',
    avatar: '⚔️', avatarBg: 'linear-gradient(135deg,#00F5FF,#7B2CBF)',
    isVip: true, reported: false, status: 'active',
    joinDate: '2025-11-15', location_en: 'Hanoi Server', location_vi: 'Server Hà Nội',
    exp: 4200, coins: 1500, level: 28,
    badges: ['👑 Local MVP', '⚔️ Chúa Tryhard', '⚡ Team Carry']
  },
  {
    id: 'u3', name: 'Khánh An', age: 21,
    mbti: 'INTJ', emoji: '🧙‍♂️',
    interests: ['Liên Quân Mobile', 'Thợ Săn Sự Kiện', 'Trợ Thủ'],
    lifestyle_en: 'Early Grinder (Morning)',
    lifestyle_vi: 'Cày sáng sớm (Chim sớm)',
    bio_en: 'Support main. Need quick team to clear event missions and get free skins then dismiss. 🎁',
    bio_vi: 'Chuyên Trợ Thủ đỡ đòn. Cần lập đội nhanh làm nhiệm vụ sự kiện cày skin rồi giải tán! 🎁',
    compatibility: 79, matchColor: '#00FF9F',
    avatar: '🧙‍♂️', avatarBg: 'linear-gradient(135deg,#00FF9F,#00F5FF)',
    isVip: false, reported: false, status: 'active',
    joinDate: '2026-01-10', location_en: 'Da Nang Server', location_vi: 'Server Đà Nẵng',
    exp: 2800, coins: 650, level: 19,
    badges: ['🧠 Mentor Uy Tín', '🤝 Shotcaller']
  },
  {
    id: 'u4', name: 'Phúc Bảo', age: 23,
    mbti: 'ESFP', emoji: '🏹',
    interests: ['Liên Quân Mobile', 'Chúa Tryhard', 'Xạ Thủ'],
    lifestyle_en: 'Night Raider (Night)',
    lifestyle_vi: 'Thợ cày đêm (Cú đêm)',
    bio_en: 'AD main. Need a solid Support to peel. Serious star climbing, no throwing! 🔫',
    bio_vi: 'Xạ Thủ cần Trợ Thủ cứng bảo kê để bắn cháy máy. Nghiêm túc cày sao, không quăng game! 🔫',
    compatibility: 72, matchColor: '#FF4D6D',
    avatar: '🏹', avatarBg: 'linear-gradient(135deg,#FF4D6D,#9D4EDD)',
    isVip: false, reported: true, status: 'flagged',
    joinDate: '2025-10-20', location_en: 'HCMC Server', location_vi: 'Server TP.HCM',
    exp: 950, coins: 200, level: 8,
    badges: ['🏹 Sniper Ace']
  },
  {
    id: 'u5', name: 'Yến Nhi', age: 20,
    mbti: 'ISFP', emoji: '🌿',
    interests: ['Liên Quân Mobile', 'Hội Tấu Hài', 'Đường Tà Thần'],
    lifestyle_en: 'Flexible Raider',
    lifestyle_vi: 'Giờ chơi tự do',
    bio_en: 'Slayer lane. Let\'s voice chat, chat and sing to relax. Strict no toxic policy! 🎸',
    bio_vi: 'Đi Top tự lo. Vừa solo vừa hát hò tấu hài xả stress, không toxic nha mọi người! 🎸',
    compatibility: 68, matchColor: '#C77DFF',
    avatar: '🌿', avatarBg: 'linear-gradient(135deg,#C77DFF,#7B2CBF)',
    isVip: true, reported: false, status: 'active',
    joinDate: '2026-02-05', location_en: 'HCMC Server', location_vi: 'Server TP.HCM',
    exp: 3100, coins: 880, level: 21,
    badges: ['🌿 Top 1 Tấu Hài', '📷 Photographer']
  },
];

export const MOCK_STAFF = [
  { id: 's1', name: 'Hùng Moderator', role: 'staff', joinDate: '2024-06-01' },
  { id: 's2', name: 'Mai Kiểm Duyệt', role: 'staff', joinDate: '2024-09-15' },
];

export const MOCK_REPORTS = [
  {
    id: 'r1', reportedUserId: 'u4',
    reportedName: 'Phúc Bảo',
    reason: 'Gửi từ ngữ toxic, quấy phá lobby cày rank',
    reportedBy: 'Linh Nguyễn',
    reportDate: '2026-06-15',
    status: 'pending',
    severity: 'high',
  },
  {
    id: 'r2', reportedUserId: 'u2',
    reportedName: 'Minh Tú',
    reason: 'Quảng cáo nạp lậu hoặc hack game trong feed',
    reportedBy: 'Khánh An',
    reportDate: '2026-06-14',
    status: 'pending',
    severity: 'medium',
  },
  {
    id: 'r3', reportedUserId: 'u5',
    reportedName: 'Yến Nhi',
    reason: 'Spam tin nhắn mời vào guild ngoài luồng',
    reportedBy: 'Phúc Bảo',
    reportDate: '2026-06-13',
    status: 'resolved',
    severity: 'low',
  },
];

export const MOCK_ICEBREAKERS = [
  {
    id: 'ib1',
    question_en: 'During a critical match, would you save your teammate or secure the main objective (Dark Slayer/Abyssal Dragon)?',
    question_vi: 'Trong trận đấu quan trọng, bạn thà cứu đồng đội hay chiếm mục tiêu lớn (Tà Thần Caesar/Rồng)?',
    category: 'Strategy',
    active: true,
    options: [
      { icon: '🤝', label_en: 'Save my teammate at all costs', label_vi: 'Cứu đồng đội bằng mọi giá' },
      { icon: '🏆', label_en: 'Secure the objective to win', label_vi: 'Chiếm mục tiêu lớn để chiến thắng' }
    ]
  },
  {
    id: 'ib2',
    question_en: 'What is your preferred voice chat style during gaming sessions?',
    question_vi: 'Bạn thích voice chat theo phong cách nào nhất khi chơi?',
    category: 'Lobby Style',
    active: true,
    options: [
      { icon: '🎙️', label_en: 'Tactical shotcalling and try-harding', label_vi: '🎙️ Bật mic call chiến thuật try-hard' },
      { icon: '🎤', label_en: 'Singing, joking and laughing to relax', label_vi: '🎤 Hát hò tấu hài, pha trò xả stress' }
    ]
  },
  {
    id: 'ib3',
    question_en: 'If you encounter an AFK teammate or thrower, what do you do?',
    question_vi: 'Nếu gặp đồng đội afk hoặc quăng game, bạn sẽ làm gì?',
    category: 'Team Role',
    active: true,
    options: [
      { icon: '⚔️', label_en: 'Try to carry and fight to win', label_vi: '⚔️ Cố gắng gánh team lật kèo' },
      { icon: '🏳️', label_en: 'Vote surrender and play next match', label_vi: '🏳️ Vote đầu hàng nhanh chơi ván mới' }
    ]
  }
];

export const MOCK_CHAT_EN = [
  { id: 'c1', from: 'them', text: 'Hey! I saw you are looking for AoV Comedy Zone too. Want to play casual and voice chat? 🎤', time: '20:15' },
  { id: 'c2', from: 'me',   text: 'Yes! I usually play Mid and love to joke around. Let\'s team up! 💫', time: '20:16' },
  { id: 'c3', from: 'them', text: 'Awesome! I will go Slayer lane and log on voice now. Let\'s play! ✨', time: '20:17' },
];

export const MOCK_CHAT_VI = [
  { id: 'c1', from: 'them', text: 'Hey! Thấy bạn cũng đang ở Zone Liên Quân Tấu Hài. Muốn vào đấu thường voice chat hát hò tí không? 🎤', time: '20:15' },
  { id: 'c2', from: 'me',   text: 'Vào luôn chứ bạn! Mình đi Mid chuyên troll troll pha trò nè. Lập team thôi! 💫', time: '20:16' },
  { id: 'c3', from: 'them', text: 'Quá đã! Mình đi Top tự lo được. Bật voice mic lên chiến nào bạn ơi! ✨', time: '20:17' },
];

export const AI_STARTERS = [
  {
    en: '🎮 Are you looking to climb rank seriously or just looking to joke around and sing in voice chat today?',
    vi: '🎮 Hôm nay bạn muốn leo rank nghiêm túc hay tấu hài ca hát xả stress thế?'
  },
  {
    en: '🎤 Let\'s hop on voice chat and sing some songs! What is your go-to karaoke track?',
    vi: '🎤 Bật voice mic lên ca hát tấu hài tí cho xả stress đi bạn ơi!'
  },
  {
    en: '🎁 The new skin event requires 3 co-op matches. Let\'s clear it quickly and get the reward!',
    vi: '🎁 Sự kiện Liên Quân mới này cày nhanh 3 trận là được skin free rồi, đi lẹ đi!'
  },
  {
    en: '⚔️ Let\'s draft meta heroes and get a win streak in star climbing!',
    vi: '⚔️ Lập team cấm chọn chuẩn chỉ để làm chuỗi thắng leo rank tinh anh nào!'
  }
];

// Analytics charts (mock data for Blush dashboard)
export const MOCK_ANALYTICS = {
  months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
  newUsers:    [150, 240, 310, 480, 690, 950], // active gamers joining
  vipRevenue:  [1.5, 2.9, 3.8, 5.2, 8.4, 12.5], // battle pass revenue (millions)
  matches:     [110, 190, 280, 420, 580, 810], // co-op parties formed
  deadChatSaved:[25, 48, 62, 95, 130, 185], // lobby lobbies revived by AI daily topic trigger
};

// Onboarding Quiz - 3 Second AI Sorting
export const SURVEY_QUESTIONS = [
  {
    id: 'q1',
    text_en: 'Select the game you want to find teammates for today',
    text_vi: 'Chọn tựa game bạn muốn lập tổ đội chơi hôm nay?',
    options: [
      { value: 'aov', label_en: '🎮 Arena of Valor (Liên Quân Mobile) — Primary focus', label_vi: '🎮 Liên Quân Mobile (Trọng tâm)' },
      { value: 'valorant', label_en: '🔫 Valorant — Tactical FPS', label_vi: '🔫 Valorant — Đọ súng chiến thuật' },
      { value: 'lol',  label_en: '🧙‍♂️ League of Legends — Strategy MOBA', label_vi: '🧙‍♂️ League of Legends — MOBA PC' },
    ],
  },
  {
    id: 'q2',
    text_en: 'What is your preferred lane / position?',
    text_vi: 'Đường / Vị trí sở trường của bạn là gì?',
    options: [
      { value: 'mid',    label_en: '🔮 Midlaner — Magic carry', label_vi: '🔮 Đường Giữa (Mid)' },
      { value: 'ad', label_en: '🏹 Dragon Lane / AD Carry', label_vi: '🏹 Đường Rồng / Xạ Thủ (AD)' },
      { value: 'jungle', label_en: '⚡ Jungler — Ganking & Objectives', label_vi: '⚡ Đường Rừng (Jungle)' },
      { value: 'support', label_en: '🛡️ Roamer / Support / Tanker', label_vi: '🛡️ Trợ Thủ / Đỡ Đòn (Support)' },
      { value: 'top', label_en: '⚔️ Slayer Lane / Fighter', label_vi: '⚔️ Đường Tà Thần / Đấu Sĩ (Top)' },
    ],
  },
  {
    id: 'q3',
    text_en: 'What is your matchmaking purpose today?',
    text_vi: 'Mục đích ghép đội chiến game hôm nay của bạn là gì?',
    options: [
      { value: 'tryhard', label_en: '🛡️ Serious Rank Climbing (Chúa Tryhard) - Serious players, meta picks', label_vi: '🛡️ Leo Rank nghiêm túc (Chúa Tryhard) - Hợp tác cày sao' },
      { value: 'comedy', label_en: '🎤 Casual Gaming (Hội Tấu Hài) - Voice chat, singing, having fun', label_vi: '🎤 Chơi game giải trí (Hội Tấu Hài) - Voice mic ca hát' },
      { value: 'event',  label_en: '🎁 Event Hunting (Thợ Săn Sự Kiện) - Fast quest clearing for free skins', label_vi: '🎁 Cày sự kiện lấy skin (Thợ Săn Sự Kiện) - Làm quest nhanh' },
    ],
  },
];
