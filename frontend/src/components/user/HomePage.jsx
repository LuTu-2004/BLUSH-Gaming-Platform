import React, { useState } from 'react';
import { ArrowRight, Sparkles, Heart, Zap, Eye, MessageCircle, Star, ChevronRight, Crown, CheckCircle, Gift, Award } from 'lucide-react';
import BlushLogo from '../BlushLogo';

const FEATURES = [
  {
    icon: '🎮',
    title_en: 'Pre-made Game Hubs',
    title_vi: 'Sảnh Game Có Sẵn',
    desc_en: 'No need to set up servers. Each game has its own active, ready-made group where players join, chat, and invite each other instantly.',
    desc_vi: 'Không cần tự thiết lập server. Mỗi tựa game có sẵn một phân khu hoạt động để người chơi vào giao lưu, nhắn tin và rủ nhau co-op tức thì.',
    color: '#00F5FF',
    bg: 'rgba(0, 245, 255, 0.08)',
  },
  {
    icon: '🤖',
    title_en: 'AI Daily Prompts',
    title_vi: 'Trigger chủ đề hàng ngày',
    desc_en: 'AI scans active keywords to auto-generate engaging discussion triggers, keeping groups active without manual work.',
    desc_vi: 'AI quét từ khóa hot để tự động tạo câu hỏi thảo luận ghim đầu phân khu, chống dead group hiệu quả.',
    color: '#9D4EDD',
    bg: 'rgba(157, 78, 221, 0.08)',
  },
  {
    icon: '🏆',
    title_en: 'PBL Gamification',
    title_vi: 'Vòng lặp Gamification PBL',
    desc_en: 'Earn EXP and Coins by contributing strategies or helping rookies. Claim levels, unique badges, and local leaderboards.',
    desc_vi: 'Tích lũy EXP/Coins từ việc đăng bài chiến thuật hoặc giúp tân thủ để leo top bảng xếp hạng phân khu.',
    color: '#00FF9F',
    bg: 'rgba(0, 255, 159, 0.08)',
  },
  {
    icon: '💬',
    title_en: 'AI Party Starters',
    title_vi: 'AI gợi ý giao tiếp 1-1',
    desc_en: 'Simulate private voice and text party matching. Get custom opening lines based on your shared zone comments.',
    desc_vi: 'Tự động tạo câu mở đầu thân thiện dựa trên lịch sử tương tác chung để dễ dàng mở lời rủ party.',
    color: '#00F5FF',
    bg: 'rgba(0, 245, 255, 0.08)',
  },
  {
    icon: '🤝',
    title_en: 'B2B Brand Challenges',
    title_vi: 'Nhiệm vụ Tài trợ Brand',
    desc_en: 'Complete weekly challenges sponsored by hardware and gear brands to earn real rewards and gaming gear.',
    desc_vi: 'Các nhãn hàng tài trợ nhiệm vụ tuần giúp bạn có cơ hội nhận quà hiện vật tự nhiên không rác quảng cáo.',
    color: '#FFB703',
    bg: 'rgba(255, 183, 3, 0.08)',
  },
  {
    icon: '👑',
    title_en: 'BLUSH Pass Premium',
    title_vi: 'Thẻ BLUSH Pass Cao Cấp',
    desc_en: 'Access closed Pro-player zones, premium glowing dynamic avatar frames, chat bubbles, and priority matching.',
    desc_vi: 'Truy cập sảnh kín của Pro-player/Mentor, khung avatar phát sáng, bong bóng chat, và ưu tiên ghép sảnh.',
    color: '#FF4D6D',
    bg: 'rgba(255, 77, 109, 0.08)',
  },
];

const TESTIMONIALS = [
  { name: 'Xian_Gamer', mbti: 'INFJ', text_en: 'Finally, a gaming group that is not chaotic! Found my core Genshin co-op group in just a day.', text_vi: 'Cuối cùng cũng có một group game không bị loãng. Mình tìm được team cày Genshin cực ăn ý chỉ sau 1 ngày.', stars: 5, avatar: '🌸' },
  { name: 'Tuan_Valorant', mbti: 'ENFP', text_en: 'Love the Daily Challenges. Earning EXP to unlock premium badges feels like a real RPG guild.', text_vi: 'Cực thích hệ thống nhiệm vụ ngày. Tích EXP đổi huy hiệu giống hệt như đang chơi bang hội RPG thực sự.', stars: 5, avatar: '🎮' },
  { name: 'Kai_LoL', mbti: 'INTJ', text_en: 'The AI Starter helped me invite a top-tier midlaner without feeling awkward. We are 10-0 in duo rank!', text_vi: 'AI Starter đã giúp mình bắt chuyện rủ solo lane cực kỳ tự nhiên. Tụi mình đã thắng thông 10 trận hạng!', stars: 5, avatar: '🧙‍♂️' },
];

const HOW_IT_WORKS = [
  { step: '01', title_en: 'AI Sorting Quiz', title_vi: 'Khảo sát Phân khu', desc_en: 'Fill in your favorite game titles, play style, and available session hours.', desc_vi: 'Điền tựa game cày, lối chơi try-hard hay casual, và khung giờ online rảnh.', icon: '🧠' },
  { step: '02', title_en: 'Get Sorted', title_vi: 'AI Xếp vào Zone', desc_en: 'AI immediately recommends 1-3 active Zones matching your exact frequency.', desc_vi: 'AI đề xuất ngay 1-3 Phân khu hoạt động sôi nổi đúng tần số của bạn.', icon: '⚡' },
  { step: '03', title_en: 'Solve Quests', title_vi: 'Làm Nhiệm Vụ Guild', desc_en: 'Participate in Daily AI discussions or Co-op challenges to harvest EXP and Coins.', desc_vi: 'Bình luận chủ đề AI hàng ngày hoặc làm co-op quest để gom EXP và Coins.', icon: '🎯' },
  { step: '04', title_en: 'Lobby Party Chat', title_vi: 'Lập Party Voice', desc_en: 'Open 1-1 party chats with AI conversation assistance based on shared comments.', desc_vi: 'Mở chat voice 1-1 với đồng đội cùng chí hướng nhờ AI gợi ý mở đầu.', icon: '💬' },
];

export default function HomePage({ onLogin, onRegister, loggedIn, onNavigate, t, lang, myProfile, onSaveProfile }) {
  const [dailyClaimed, setDailyClaimed] = useState(false);
  const [claiming, setClaiming] = useState(false);
  const [activeGame, setActiveGame] = useState('all');

  const GAMES = [
    { id: 'all', name_en: 'All Games', name_vi: 'Tất cả Game', icon: '🌐', bg: 'linear-gradient(135deg, #9D4EDD, #00F5FF)' },
    { id: 'aov', name_en: 'Arena of Valor', name_vi: 'Liên Quân Mobile', icon: '🎮', bg: 'linear-gradient(135deg, #005F73, #0A9396)' },
    { id: 'valorant', name_en: 'Valorant', name_vi: 'Valorant', icon: '🔫', bg: 'linear-gradient(135deg, #9B2226, #AE2012)' },
    { id: 'lol', name_en: 'League of Legends', name_vi: 'LMHT', icon: '🧙‍♂️', bg: 'linear-gradient(135deg, #1A4301, #3F7D20)' },
    { id: 'tft', name_en: 'Teamfight Tactics', name_vi: 'Đấu Trường Chân Lý', icon: '👑', bg: 'linear-gradient(135deg, #CA6702, #EE9B00)' },
  ];

  const ZONES = [
    { id: 'aov_comedy', gameId: 'aov', name: 'Zone Liên Quân - Hội Tấu Hài', game: 'Arena of Valor / Liên Quân Mobile', icon: '🎤', active: 512, logoBg: 'linear-gradient(135deg, #00F5FF, #7B2CBF)', desc: lang === 'en' ? 'Voice chat, joke around, sing karaoke, and play casually to relieve stress.' : 'Phòng voice chat tấu hài, ca hát giao lưu và đấu thường xả stress cực vui.' },
    { id: 'aov_tryhard', gameId: 'aov', name: 'Zone Liên Quân - Chúa Tryhard', game: 'Arena of Valor / Liên Quân Mobile', icon: '⚔️', active: 384, logoBg: 'linear-gradient(135deg, #FF4D6D, #9D4EDD)', desc: lang === 'en' ? 'Serious star climbing, meta pick/ban strategies, and pro shotcalling comms.' : 'Cày rank nghiêm túc, cấm chọn theo meta, call team phối hợp chuẩn chỉ.' },
    { id: 'aov_event', gameId: 'aov', name: 'Zone Liên Quân - Thợ Săn Sự Kiện', game: 'Arena of Valor / Liên Quân Mobile', icon: '🎁', active: 246, logoBg: 'linear-gradient(135deg, #00FF9F, #00F5FF)', desc: lang === 'en' ? 'Quick team up for weekly event quest clearing to earn free skins then dismiss.' : 'Gom đội siêu tốc làm nhiệm vụ sự kiện, cày skin miễn phí rồi giải tán.' },
    
    { id: 'val_tryhard', gameId: 'valorant', name: 'Zone Valorant - Biệt Đội Hủy Diệt', game: 'Valorant', icon: '🎯', active: 412, logoBg: 'linear-gradient(135deg, #FF4D6D, #AE2012)', desc: lang === 'en' ? 'Tactical round execution, precise aimers, climbing immortal/radiant ranks.' : 'Call chiến thuật bắn bom, luyện aim cứng cáp, cùng cày rank Kim Cương/Bất Tử.' },
    { id: 'val_custom', gameId: 'valorant', name: 'Zone Valorant - Phòng Custom Vui Vẻ', game: 'Valorant', icon: '🎤', active: 289, logoBg: 'linear-gradient(135deg, #00F5FF, #9D4EDD)', desc: lang === 'en' ? 'Custom lobbies, knife fights, casual games with friends.' : 'Lập phòng custom giải trí, đấu dao, giao lưu kết bạn không áp lực thắng thua.' },
    
    { id: 'lol_aram', gameId: 'lol', name: 'Zone LMHT - Vực Gió Hú ARAM', game: 'League of Legends / LMHT', icon: '🍻', active: 356, logoBg: 'linear-gradient(135deg, #00FF9F, #1A4301)', desc: lang === 'en' ? 'Fun ARAM rooms, high roll, trolling builds and casual voice comms.' : 'Sảnh ARAM vui vẻ, cày xả stress, thử nghiệm giáo án lạ và voice chat chém gió.' },
    { id: 'lol_rank', gameId: 'lol', name: 'Zone LMHT - Leo Hạng Kỳ Cựu', game: 'League of Legends / LMHT', icon: '⚔️', active: 210, logoBg: 'linear-gradient(135deg, #7B2CBF, #0A9396)', desc: lang === 'en' ? 'Serious draft picks, lane coordination, climbing to Diamond+ ranks.' : 'Cấm chọn nghiêm túc, phối hợp gank đường chuẩn chỉ, leo rank Bạch Kim/Kim Cương+.' },
    
    { id: 'tft_normal', gameId: 'tft', name: 'Zone ĐTCL - Hội Cờ Thủ Nhân Phẩm', game: 'Teamfight Tactics / ĐTCL', icon: '🎲', active: 180, logoBg: 'linear-gradient(135deg, #FFB703, #EE9B00)', desc: lang === 'en' ? 'Shared lobby for roll down, flex board theory crafting, and playing double-up.' : 'Phòng ghép cờ thủ cùng roll bài, trao đổi giáo án leo top và chơi chế độ Cặp Đôi.' }
  ];

  const filteredZones = activeGame === 'all' 
    ? ZONES 
    : ZONES.filter(z => z.gameId === activeGame);

  const NAV_LINKS = lang === 'en'
    ? ['Features', 'How it Works', 'VIP Store', 'Partnerships']
    : ['Tính năng', 'Quy trình', 'Cửa hàng VIP', 'Nhãn hàng'];

  const handleClaimDaily = () => {
    if (dailyClaimed || claiming || !myProfile || !onSaveProfile) return;
    setClaiming(true);
    setTimeout(() => {
      onSaveProfile({
        ...myProfile,
        exp: myProfile.exp + 50,
        coins: myProfile.coins + 15,
      });
      setDailyClaimed(true);
      setClaiming(false);
    }, 1000);
  };

  if (loggedIn && myProfile) {
    // Gamer Dashboard View
    return (
      <div style={{ padding: '2rem 1.5rem', maxWidth: '1100px', margin: '0 auto' }}>
        
        {/* Welcome Hero Panel */}
        <div className="card-pink animate-fade-in" style={{ padding: '2rem', marginBottom: '2rem', position: 'relative', overflow: 'hidden' }}>
          {/* Subtle background glow */}
          <div style={{
            position: 'absolute', right: '-10%', top: '-20%', width: '350px', height: '350px',
            borderRadius: '50%', background: 'radial-gradient(circle, rgba(0, 245, 255, 0.15) 0%, transparent 70%)',
            pointerEvents: 'none', zIndex: 1
          }} />
          
          <div style={{ display: 'flex', gap: '2rem', alignItems: 'center', position: 'relative', zIndex: 2, flexWrap: 'wrap' }}>
            
            {/* Left Content Column */}
            <div style={{ flex: '1 1 500px' }}>
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '.4rem', background: 'rgba(0, 245, 255, 0.1)', border: '1px solid rgba(0, 245, 255, 0.25)', borderRadius: 99, padding: '.3rem .8rem', marginBottom: '1rem' }}>
                <Sparkles size={12} style={{ color: '#00F5FF' }} />
                <span style={{ fontSize: '.75rem', fontWeight: 700, color: '#00F5FF' }}>
                  {lang === 'en' ? 'Gamer Lobby Status: ONLINE' : 'Trạng thái Sảnh chờ: ĐANG ONLINE'}
                </span>
              </div>
              
              <h1 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '.5rem', color: '#FFF' }}>
                {lang === 'en' ? `Welcome back, Commander ${myProfile.name}! 👋` : `Chào mừng trở lại, Chỉ huy ${myProfile.name}! 👋`}
              </h1>
              <p style={{ color: 'var(--text-secondary)', fontSize: '.95rem', marginBottom: '1.5rem', lineHeight: 1.5 }}>
                {lang === 'en' 
                  ? 'Check your active gaming zones below, claim your daily check-in reward coins, and team up with fellow guild members.'
                  : 'Truy cập phân khu game của bạn bên dưới, điểm danh nhận coin hàng ngày và bắt đầu lập party chiến game cùng bang hội.'}
              </p>
              
              {/* Quick Action Info Grid */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem' }}>
                <div style={{ background: 'rgba(0,0,0,0.25)', padding: '1rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.05)', backdropFilter: 'blur(4px)' }}>
                  <div style={{ fontSize: '.75rem', color: 'var(--text-muted)', marginBottom: '.25rem' }}>
                    {lang === 'en' ? 'GUILD LEVEL' : 'CẤP ĐỘ GUILD'}
                  </div>
                  <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#00F5FF' }}>Lvl {myProfile.level}</div>
                  <div style={{ fontSize: '.7rem', color: 'var(--text-secondary)', marginTop: '.25rem' }}>
                    {myProfile.exp} EXP total
                  </div>
                </div>
                <div style={{ background: 'rgba(0,0,0,0.25)', padding: '1rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.05)', backdropFilter: 'blur(4px)' }}>
                  <div style={{ fontSize: '.75rem', color: 'var(--text-muted)', marginBottom: '.25rem' }}>
                    {lang === 'en' ? 'ACTIVE GUILD COINS' : 'COIN GUILD TÍCH LŨY'}
                  </div>
                  <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#FFB703' }}>🪙 {myProfile.coins}</div>
                  <div style={{ fontSize: '.7rem', color: 'var(--text-secondary)', marginTop: '.25rem' }}>
                    {lang === 'en' ? 'Use in BLUSH Pass Store' : 'Dùng mua sắm trong BLUSH Store'}
                  </div>
                </div>
                <div style={{ background: 'rgba(0,0,0,0.25)', padding: '1rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.05)', backdropFilter: 'blur(4px)' }}>
                  <div style={{ fontSize: '.75rem', color: 'var(--text-muted)', marginBottom: '.25rem' }}>
                    {lang === 'en' ? 'ACTIVE ZONES' : 'PHÂN KHU ĐÃ GIA NHẬP'}
                  </div>
                  <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#9D4EDD' }}>
                    {myProfile.joinedZones ? myProfile.joinedZones.length : 1} Zones
                  </div>
                  <div style={{ fontSize: '.7rem', color: 'var(--text-secondary)', marginTop: '.25rem' }}>
                    {lang === 'en' ? 'Customized Sorting active' : 'Đã so khớp bằng AI Sorting'}
                  </div>
                </div>
              </div>
            </div>

            {/* Right 3D Visual Column */}
            <div style={{ 
              flex: '1 1 200px', display: 'flex', justifyContent: 'center', alignItems: 'center', 
              position: 'relative', minHeight: '180px' 
            }}>
              {/* Spinning tech circle behind image */}
              <div className="animate-spin" style={{
                position: 'absolute', width: '160px', height: '160px',
                border: '2px dashed rgba(0, 245, 255, 0.3)',
                borderRadius: '50%', pointerEvents: 'none', zIndex: 1
              }} />
              <div style={{
                position: 'absolute', width: '190px', height: '190px',
                border: '1px solid rgba(157, 78, 221, 0.2)',
                borderRadius: '50%', pointerEvents: 'none', zIndex: 1
              }} />
              
              {/* Glowing 3D controller image */}
              <img 
                src="/gaming_3d_mascot.png" 
                alt="Blush 3D Mascot"
                className="animate-float"
                style={{
                  width: '180px', height: 'auto',
                  objectFit: 'contain', zIndex: 2,
                  filter: 'drop-shadow(0 0 25px rgba(0, 245, 255, 0.6)) drop-shadow(0 0 40px rgba(157, 78, 221, 0.45))'
                }}
              />
            </div>
            
          </div>
        </div>

        {/* Dashboard Main Grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '2rem' }}>
          
          {/* Main Column: Joined Zones & Quests */}
          <div>
            {/* Lita-like Find Zones by Game Selector */}
            <div className="section-header" style={{ marginBottom: '1rem' }}>
              <h2 className="section-title">🎯 {lang === 'en' ? 'Find Zones by Game' : 'Tìm Phân Khu Theo Game'}</h2>
            </div>
            
            <div style={{
              display: 'flex', gap: '0.75rem', overflowX: 'auto', paddingBottom: '0.75rem',
              marginBottom: '1.5rem', scrollbarWidth: 'none', msOverflowStyle: 'none'
            }} className="no-scrollbar">
              {GAMES.map(game => {
                const gName = lang === 'en' ? game.name_en : game.name_vi;
                const isActive = activeGame === game.id;
                return (
                  <div
                    key={game.id}
                    onClick={() => setActiveGame(game.id)}
                    style={{
                      flex: '0 0 130px', height: '90px', borderRadius: '16px',
                      background: game.bg, padding: '0.85rem', display: 'flex',
                      flexDirection: 'column', justifyItems: 'center', justifyContent: 'space-between',
                      cursor: 'pointer', transition: 'var(--tr)', position: 'relative',
                      overflow: 'hidden', border: `2.5px solid ${isActive ? 'var(--cyan)' : 'transparent'}`,
                      boxShadow: isActive ? '0 0 12px rgba(0, 245, 255, 0.4)' : 'var(--shadow-sm)',
                      transform: isActive ? 'scale(1.03)' : 'none'
                    }}
                    onMouseEnter={e => { if(!isActive) e.currentTarget.style.transform = 'translateY(-3px)'; }}
                    onMouseLeave={e => { if(!isActive) e.currentTarget.style.transform = 'none'; }}
                  >
                    <span style={{
                      position: 'absolute', right: '-8px', bottom: '-12px', fontSize: '3.8rem',
                      opacity: 0.12, pointerEvents: 'none'
                    }}>{game.icon}</span>
                    
                    <span style={{ fontSize: '1.25rem', zIndex: 2 }}>{game.icon}</span>
                    <span style={{ fontSize: '.75rem', fontWeight: 800, color: '#FFF', zIndex: 2, textShadow: '0 1px 3px rgba(0,0,0,0.6)' }}>
                      {gName}
                    </span>
                  </div>
                );
              })}
            </div>

            <div className="section-header">
              <h2 className="section-title">🎮 {lang === 'en' ? 'Recommended Lobbies' : 'Sảnh Game Gợi Ý'}</h2>
              <button onClick={() => onNavigate('feed')} className="btn btn-ghost btn-sm" style={{ color: 'var(--cyan)' }}>
                {lang === 'en' ? 'Browse All Zones' : 'Khám phá tất cả Zone'} <ArrowRight size={14} />
              </button>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '2.5rem' }}>
              {filteredZones.map((zone, idx) => (
                <div key={idx} className="card animate-fade-in-up" style={{ padding: '1.25rem', border: '1px solid var(--border-soft)', display: 'flex', gap: '1rem', alignItems: 'center' }}>
                  <div style={{ width: 56, height: 56, borderRadius: '14px', background: zone.logoBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.5rem', flexShrink: 0, fontWeight: 'bold', color: '#FFF' }}>
                    {zone.icon}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', flexWrap: 'wrap' }}>
                      <h4 style={{ fontWeight: 800, fontSize: '1rem' }}>{zone.name}</h4>
                      <span className="badge" style={{ background: 'rgba(255,255,255,0.05)', color: 'var(--text-secondary)', fontSize: '.68rem' }}>{zone.game}</span>
                    </div>
                    <p style={{ fontSize: '.8rem', color: 'var(--text-secondary)', margin: '.3rem 0 .5rem', lineHeight: 1.4 }}>{zone.desc}</p>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', fontSize: '.75rem', color: 'var(--text-muted)' }}>
                      <span>🟢 <strong>{zone.active}</strong> {lang === 'en' ? 'gamers online' : 'game thủ online'}</span>
                      <span>•</span>
                      <span>🎁 +50 EXP / {lang === 'en' ? 'comment' : 'bình luận'}</span>
                    </div>
                  </div>
                  <button onClick={() => onNavigate('feed')} className="btn btn-outline btn-sm" style={{ borderColor: 'var(--pink)', color: 'var(--pink)' }}>
                    {lang === 'en' ? 'Enter' : 'Vào Zone'}
                  </button>
                </div>
              ))}
              {filteredZones.length === 0 && (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                  {lang === 'en' ? 'No active zones found for this game.' : 'Không tìm thấy phân khu hoạt động cho game này.'}
                </div>
              )}
            </div>

            {/* Daily & Weekly Quest PBL Section */}
            <div className="section-header">
              <h2 className="section-title">🛡️ {lang === 'en' ? 'Daily & Weekly Quests' : 'Nhiệm vụ & Chiến dịch'}</h2>
              <span className="badge badge-purple">PBL Engine</span>
            </div>

            <div className="card" style={{ padding: '1.25rem', marginBottom: '2rem' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                
                {/* Quest 1 */}
                <div style={{ display: 'flex', justifyItems: 'center', justifyContent: 'space-between', paddingBottom: '1rem', borderBottom: '1px solid var(--border-soft)' }}>
                  <div style={{ display: 'flex', gap: '.85rem' }}>
                    <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'rgba(0, 255, 159, 0.1)', border: '1px solid rgba(0, 255, 159, 0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <CheckCircle size={18} color="#00FF9F" />
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '.9rem' }}>
                        {lang === 'en' ? 'Daily check-in' : 'Điểm danh hàng ngày'}
                      </div>
                      <div style={{ fontSize: '.75rem', color: 'var(--text-secondary)' }}>
                        {lang === 'en' ? 'Logs in and claim reward once a day' : 'Đăng nhập và điểm danh mỗi ngày một lần'}
                      </div>
                      <div style={{ display: 'flex', gap: '.5rem', marginTop: '.25rem' }}>
                        <span className="badge" style={{ background: 'rgba(0, 255, 159, 0.1)', color: '#00FF9F', fontSize: '.65rem' }}>+50 EXP</span>
                        <span className="badge" style={{ background: 'rgba(255, 183, 3, 0.1)', color: '#FFB703', fontSize: '.65rem' }}>+15 Coins</span>
                      </div>
                    </div>
                  </div>
                  <div>
                    <button 
                      onClick={handleClaimDaily} 
                      disabled={dailyClaimed || claiming} 
                      className={`btn btn-sm ${dailyClaimed ? 'btn-outline' : 'btn-primary'}`}
                      style={{ fontSize: '.75rem' }}
                    >
                      {claiming ? (t('checkout.connecting')) : dailyClaimed ? (lang === 'en' ? 'Claimed ✓' : 'Đã nhận ✓') : (lang === 'en' ? 'Claim Rewards' : 'Nhận Thưởng')}
                    </button>
                  </div>
                </div>

                {/* Quest 2 */}
                <div style={{ display: 'flex', justifyItems: 'center', justifyContent: 'space-between' }}>
                  <div style={{ display: 'flex', gap: '.85rem' }}>
                    <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'rgba(0, 245, 255, 0.1)', border: '1px solid rgba(0, 245, 255, 0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <Zap size={18} color="#00F5FF" />
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '.9rem' }}>
                        {lang === 'en' ? 'AI discussion starter' : 'Thảo luận chủ đề AI'}
                      </div>
                      <div style={{ fontSize: '.75rem', color: 'var(--text-secondary)' }}>
                        {lang === 'en' ? 'Comment in the pinned AI daily topic thread' : 'Để lại bình luận trong bài viết thảo luận AI ghim đầu Zone'}
                      </div>
                      <div style={{ display: 'flex', gap: '.5rem', marginTop: '.25rem' }}>
                        <span className="badge" style={{ background: 'rgba(0, 255, 159, 0.1)', color: '#00FF9F', fontSize: '.65rem' }}>+100 EXP</span>
                      </div>
                    </div>
                  </div>
                  <div>
                    <button onClick={() => onNavigate('feed')} className="btn btn-outline btn-sm" style={{ fontSize: '.75rem' }}>
                      {lang === 'en' ? 'Go to Thread' : 'Tới bài viết'}
                    </button>
                  </div>
                </div>

              </div>
            </div>
          </div>

        </div>

      </div>
    );
  }

  // Marketing Landing page for logged-out users
  return (
    <div style={{ minHeight: '100vh' }}>

      {/* ── NAVBAR ── */}
      {!loggedIn && (
        <nav style={{
          position: 'fixed', top: 0, left: 0, right: 0, zIndex: 50,
          height: 64, display: 'flex', alignItems: 'center',
          padding: '0 2.5rem', gap: '2rem',
          background: 'rgba(10,5,22,.88)', backdropFilter: 'blur(16px)',
          borderBottom: '1px solid rgba(157,78,221,.25)',
        }}>
          {/* Logo */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem', marginRight: 'auto' }}>
            <BlushLogo size={34} />
            <span style={{ fontSize: '1.15rem', fontWeight: 900, letterSpacing: '-.02em' }} className="gradient-text">Blush</span>
            <span style={{ fontSize: '.58rem', fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '.1em', textTransform: 'uppercase', marginTop: '.15rem' }} className="topnav-logout-text">AI Gaming Zones</span>
          </div>

          {/* Nav links */}
          <div style={{ display: 'flex', gap: '1.75rem' }} className="topnav-logout-text">
            {NAV_LINKS.map(l => (
              <a key={l} href="#" style={{ fontSize: '.88rem', fontWeight: 500, color: 'var(--text-secondary)', transition: 'var(--tr)' }}
                onMouseEnter={e => e.target.style.color = 'var(--cyan)'}
                onMouseLeave={e => e.target.style.color = 'var(--text-secondary)'}
              >{l}</a>
            ))}
          </div>

          {/* Auth buttons */}
          <div style={{ display: 'flex', gap: '.6rem', alignItems: 'center' }}>
            <button className="btn btn-ghost btn-sm" onClick={onLogin}>{t('home.login')}</button>
            <button className="btn btn-primary btn-sm" onClick={onRegister} style={{ gap: '.4rem' }}>
              {t('home.freeStart')} <ArrowRight size={14}/>
            </button>
          </div>
        </nav>
      )}

      {/* ── HERO SECTION ── */}
      <section style={{ paddingTop: 130, paddingBottom: 80, padding: '130px 2rem 80px', position: 'relative' }}>
        {/* Floating decorations */}
        {['🎮','🔫','🧙‍♂️','💫','🏆','⚔️'].map((e, i) => (
          <div key={i} style={{
            position: 'absolute', fontSize: `${1 + (i % 3) * .3}rem`,
            top: `${15 + (i * 13) % 70}%`, left: `${4 + (i * 17) % 88}%`,
            opacity: .18, animation: `float ${3 + i * .4}s ease-in-out infinite`,
            animationDelay: `${i * .25}s`, pointerEvents: 'none',
          }}>{e}</div>
        ))}

        {/* 2-Column Responsive Layout */}
        <div style={{ maxWidth: '1100px', margin: '0 auto', display: 'flex', gap: '3rem', alignItems: 'center', flexWrap: 'wrap', textAlign: 'left' }} className="responsive-profile">
          
          {/* Left Column: Text & CTA */}
          <div className="animate-fade-in" style={{ flex: '1.2 1 480px' }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: '.5rem', background: 'var(--pink-soft)', border: '1px solid rgba(157,78,221,.25)', borderRadius: 99, padding: '.35rem 1rem', marginBottom: '1.5rem' }}>
              <Sparkles size={13} style={{ color: 'var(--cyan)' }}/>
              <span style={{ fontSize: '.78rem', fontWeight: 700, color: 'var(--cyan)' }}>AI Matchmaking + Gamified PBL Guilds</span>
            </div>

            <h1 style={{ fontSize: 'clamp(2.2rem, 5.5vw, 3.8rem)', fontWeight: 900, lineHeight: 1.1, marginBottom: '1.5rem', letterSpacing: '-.03em', color: '#FFF' }}>
              {lang === 'en' ? (
                <>
                  Level up your gaming circles<br/>
                  <span className="gradient-text">by your playstyle</span>
                </>
              ) : (
                <>
                  Tìm tổ đội cày game hợp ý<br/>
                  <span className="gradient-text">bằng phong cách của bạn</span>
                </>
              )}
            </h1>

            <p style={{ fontSize: '1.05rem', color: 'var(--text-secondary)', lineHeight: 1.7, marginBottom: '2.5rem', maxWidth: '580px' }}>
              {t('home.heroSubtitle')}
            </p>

            <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', marginBottom: '1rem' }}>
              <button className="btn btn-primary btn-lg" onClick={onRegister} style={{ gap: '.75rem' }}>
                <Heart size={18}/> {t('home.freeStart')}
              </button>
              <button className="btn btn-outline btn-lg" onClick={onLogin} style={{ gap: '.5rem' }}>
                {t('home.login')} <ChevronRight size={16}/>
              </button>
            </div>

            <p style={{ fontSize: '.78rem', color: 'var(--text-muted)' }}>
              {lang === 'en' ? 'Free basic access · Gamified leveling · Takes 2 minutes to start' : 'Vào bang hội miễn phí · Tích EXP thăng cấp · Chỉ mất 2 phút khởi đầu'}
            </p>
          </div>

          {/* Right Column: 3D Visual Hub */}
          <div style={{
            flex: '0.8 1 320px', display: 'flex', justifyContent: 'center', alignItems: 'center',
            position: 'relative', minHeight: '320px'
          }}>
            {/* Hologram/Spinning Rings behind */}
            <div className="animate-spin" style={{
              position: 'absolute', width: '220px', height: '220px',
              border: '2px dashed rgba(0, 245, 255, 0.2)',
              borderRadius: '50%', pointerEvents: 'none', zIndex: 1
            }} />
            <div style={{
              position: 'absolute', width: '260px', height: '260px',
              border: '1.5px solid rgba(157, 78, 221, 0.15)',
              borderRadius: '50%', pointerEvents: 'none', zIndex: 1
            }} />
            
            {/* Glowing 3D diverse hub asset */}
            <img
              src="/gaming_3d_hub.png"
              alt="Blush Gaming Hub 3D"
              className="animate-float"
              style={{
                width: '260px', height: 'auto',
                objectFit: 'contain', zIndex: 2,
                filter: 'drop-shadow(0 0 30px rgba(0, 245, 255, 0.55)) drop-shadow(0 0 50px rgba(157, 78, 221, 0.4))'
              }}
            />
          </div>

        </div>

        {/* Stats bar */}
        <div className="animate-fade-in-up stagger-3" style={{ display: 'flex', gap: '4rem', justifyContent: 'center', marginTop: '5rem', flexWrap: 'wrap', borderTop: '1px solid var(--border-soft)', paddingTop: '2.5rem', maxWidth: '960px', margin: '5rem auto 0' }}>
          {[
            { val: '12,500+', label: lang === 'en' ? 'Active Gamers' : 'Game thủ hoạt động' },
            { val: '94%',     label: lang === 'en' ? 'Co-op Satisfaction' : 'Độ hài lòng co-op' },
            { val: '8,100+',  label: lang === 'en' ? 'Parties Formed' : 'Tổ đội được thành lập' },
            { val: '185+',    label: lang === 'en' ? 'Lobbies Saved by AI' : 'Dead group được hồi sinh' },
          ].map((s, i) => (
            <div key={i} style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '2rem', fontWeight: 900, letterSpacing: '-.02em' }} className="gradient-text">{s.val}</div>
              <div style={{ fontSize: '.8rem', color: 'var(--text-muted)', marginTop: '.2rem' }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Supported Games Diverse Row */}
        <div style={{ marginTop: '4rem', textAlign: 'center' }}>
          <div style={{ fontSize: '.75rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '.12em', marginBottom: '1.25rem' }}>
            {lang === 'en' ? 'Form Parties Across Your Favorite Titles' : 'Hỗ trợ lập tổ đội kết nối đa tựa game'}
          </div>
          <div style={{ display: 'flex', gap: '0.85rem', justifyContent: 'center', flexWrap: 'wrap', opacity: 0.85 }}>
            {[
              { name: 'Liên Quân Mobile', icon: '🎮', color: '#00F5FF' },
              { name: 'Valorant', icon: '🔫', color: '#FF4D6D' },
              { name: 'Liên Minh Huyền Thoại', icon: '🧙‍♂️', color: '#00FF9F' },
              { name: 'Đấu Trường Chân Lý', icon: '👑', color: '#FFB703' },
              { name: 'PUBG Mobile', icon: '🪂', color: '#E29500' },
              { name: 'Free Fire', icon: '🔥', color: '#FF5F57' }
            ].map((game, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: '.4rem',
                background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.05)',
                borderRadius: '99px', padding: '.45rem 1.1rem', fontSize: '.8rem', fontWeight: 600,
                color: '#FFF', transition: 'var(--tr)', cursor: 'default'
              }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = game.color; e.currentTarget.style.boxShadow = `0 0 12px ${game.color}30`; }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.05)'; e.currentTarget.style.boxShadow = 'none'; }}
              >
                <span>{game.icon}</span>
                <span>{game.name}</span>
              </div>
            ))}
          </div>
        </div>

      </section>

      {/* ── PREVIEW MOCKUP ── */}
      <section style={{ padding: '0 2rem 80px', display: 'flex', justifyContent: 'center' }}>
        <div style={{ maxWidth: 860, width: '100%', position: 'relative' }}>
          <div className="card" style={{ overflow: 'hidden', boxShadow: '0 24px 80px rgba(157,78,221,.25)' }}>
            <div style={{ padding: '.75rem 1.25rem', background: 'var(--surface-2)', borderBottom: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', gap: '.5rem' }}>
              <div style={{ display: 'flex', gap: '.35rem' }}>
                {['#FF5F57','#FFBD2E','#28CA41'].map((c,i) => <div key={i} style={{ width: 11, height: 11, borderRadius: '50%', background: c }}/>)}
              </div>
              <div style={{ flex: 1, display: 'flex', justifyContent: 'center' }}>
                <div style={{ background: 'var(--surface)', borderRadius: 99, padding: '.25rem 1.5rem', fontSize: '.78rem', color: 'var(--text-muted)', border: '1px solid var(--border-soft)' }}>
                  🔒 blush.app/zone-hub
                </div>
              </div>
            </div>
            {/* App preview in gaming look */}
            <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', minHeight: 380, background: 'linear-gradient(160deg,#0A0516,#140E28)' }} className="responsive-grid-2">
              
              {/* Left Column - Lobby Chat Preview */}
              <div style={{ padding: '1.25rem', borderRight: '1px solid rgba(157,78,221,.15)', display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '1rem', color: '#FFF' }}>💬 # {lang === 'en' ? 'AOV - Comedy Zone' : 'Sảnh Liên Quân - Hội Tấu Hài'}</div>
                    <div style={{ fontSize: '.68rem', color: 'var(--cyan)', fontWeight: 600 }}>🟢 512 {lang === 'en' ? 'gamers active' : 'game thủ đang hoạt động'}</div>
                  </div>
                  <span style={{ fontSize: '.62rem', background: 'rgba(0,245,255,0.1)', border: '1px solid rgba(0,245,255,0.25)', borderRadius: '4px', padding: '.15rem .4rem', color: 'var(--cyan)' }}>AI ACTIVE</span>
                </div>
                
                {/* Mock Message list */}
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.75rem', background: 'rgba(0,0,0,0.2)', padding: '0.85rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.03)' }}>
                  
                  {/* Msg 1 */}
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-start' }}>
                    <div style={{ width: 26, height: 26, borderRadius: '50%', background: 'linear-gradient(135deg,#00F5FF,#7B2CBF)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.8rem' }}>⚔️</div>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                        <span style={{ fontSize: '.75rem', fontWeight: 800, color: 'var(--cyan)' }}>Minh Tú</span>
                        <span style={{ fontSize: '.6rem', color: 'var(--text-muted)' }}>20:15</span>
                      </div>
                      <p style={{ fontSize: '.76rem', color: 'var(--text-secondary)', marginTop: '.15rem', lineHeight: 1.3 }}>
                        {lang === 'en' ? "Need 1 pro Jungler for star climbing in Diamond rank now! ⚔️" : "Ai lập team leo rank Tinh Anh không? Thiếu 1 Rừng cày sao gấp! ⚔️"}
                      </p>
                    </div>
                  </div>

                  {/* Msg 2 */}
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-start' }}>
                    <div style={{ width: 26, height: 26, borderRadius: '50%', background: 'linear-gradient(135deg,#00FF9F,#00F5FF)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.8rem' }}>🧙‍♂️</div>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                        <span style={{ fontSize: '.75rem', fontWeight: 800, color: 'var(--success)' }}>Khánh An</span>
                        <span style={{ fontSize: '.6rem', color: 'var(--text-muted)' }}>20:16</span>
                      </div>
                      <p style={{ fontSize: '.76rem', color: 'var(--text-secondary)', marginTop: '.15rem', lineHeight: 1.3 }}>
                        {lang === 'en' ? "Join voice chat room for some karaoke and gaming, chill only 🎤" : "Vào làm trận đấu thường tấu hài đi mọi người, mic on chém gió ca hát 🎤"}
                      </p>
                    </div>
                  </div>

                  {/* Msg 3 (AI discussion starter trigger) */}
                  <div style={{ background: 'rgba(157,78,221,0.08)', border: '1px solid rgba(157,78,221,0.15)', borderRadius: '8px', padding: '0.5rem 0.65rem' }}>
                    <div style={{ fontSize: '.62rem', fontWeight: 700, color: 'var(--pink)', display: 'flex', alignItems: 'center', gap: '0.25rem', marginBottom: '.15rem' }}>
                      <span>🤖</span> {lang === 'en' ? "AI DAILY DISCUSSION TOPIC" : "AI TRIGGER CHỦ ĐỀ HÀNG NGÀY"}
                    </div>
                    <p style={{ fontSize: '.72rem', color: '#FFF', fontWeight: 600 }}>
                      {lang === 'en' ? "What is your best hero pick to counter Nakroth this season? Reply to claim +50 EXP!" : "Lối chơi Nakroth lên full tank mùa này thế nào? Bình luận để nhận ngay +50 EXP!"}
                    </p>
                  </div>

                </div>

                {/* Input box */}
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <div style={{ flex: 1, background: 'rgba(0,0,0,0.25)', border: '1px solid rgba(255,255,255,0.05)', borderRadius: '20px', padding: '.45rem .85rem', fontSize: '.75rem', color: 'var(--text-muted)' }}>
                    {lang === 'en' ? "Message # Sảnh Tấu Hài..." : "Nhắn tin vào sảnh chờ..."}
                  </div>
                  <button className="btn btn-primary btn-sm" style={{ padding: '0 .85rem', borderRadius: '20px', fontSize: '.72rem' }}>
                    {lang === 'en' ? "Send" : "Gửi"}
                  </button>
                </div>

              </div>

              {/* Right Column - Online Gamers & Quick Party */}
              <div style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                <div style={{ fontWeight: 800, fontSize: '0.9rem', color: '#FFF' }}>🟢 {lang === 'en' ? 'Online Gamers (3)' : 'Đang Online (3)'}</div>
                
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', flex: 1 }}>
                  {[
                    { name: 'Minh Tú', level: 28, tag: lang === 'en' ? 'Tryhard Jungle Main' : 'Chúa Tryhard Main Rừng', bg: 'linear-gradient(135deg,#00F5FF,#7B2CBF)' },
                    { name: 'Khánh An', level: 19, tag: lang === 'en' ? 'Event Hunter' : 'Thợ Săn Sự Kiện', bg: 'linear-gradient(135deg,#00FF9F,#00F5FF)' },
                    { name: 'Yến Nhi', level: 21, tag: lang === 'en' ? 'Comedy Club' : 'Hội Tấu Hài', bg: 'linear-gradient(135deg,#C77DFF,#7B2CBF)' }
                  ].map((gamer, idx) => (
                    <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'rgba(255,255,255,0.02)', padding: '0.5rem', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.03)' }}>
                      <div style={{ width: 28, height: 28, borderRadius: '50%', background: gamer.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.75rem', fontWeight: 'bold' }}>👤</div>
                      <div style={{ flex: 1 }}>
                        <div style={{ display: 'flex', alignItems: 'center', justifyItems: 'center', justifyContent: 'space-between' }}>
                          <span style={{ fontSize: '.76rem', fontWeight: 700, color: '#FFF' }}>{gamer.name}</span>
                          <span style={{ fontSize: '.62rem', color: 'var(--cyan)' }}>Lvl {gamer.level}</span>
                        </div>
                        <div style={{ fontSize: '.62rem', color: 'var(--text-muted)', marginTop: '.1rem' }}>{gamer.tag}</div>
                      </div>
                    </div>
                  ))}
                </div>

                <div style={{ background: 'var(--pink-soft)', border: '1px solid rgba(157,78,221,0.2)', borderRadius: '10px', padding: '0.6rem', textAlign: 'center', fontSize: '.68rem', color: 'var(--text-secondary)' }}>
                  ⚡ {lang === 'en' ? "AI so khớp & Ghép đội tức thì" : "AI so khớp & Ghép đội tức thì"}
                </div>
              </div>

            </div>
          </div>
        </div>
      </section>

      {/* ── HOW IT WORKS ── */}
      <section style={{ padding: '60px 2rem', background: 'rgba(20,14,40,.6)', backdropFilter: 'blur(10px)' }}>
        <div style={{ maxWidth: 860, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
            <h2 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '.5rem' }}>{t('home.howItWorks')}</h2>
            <p style={{ color: 'var(--text-secondary)' }}>{t('home.howItWorksSub')}</p>
          </div>
          <div className="responsive-grid-4">
            {HOW_IT_WORKS.map((h, i) => {
              const hTitle = lang === 'en' ? h.title_en : h.title_vi;
              const hDesc = lang === 'en' ? h.desc_en : h.desc_vi;
              return (
                <div key={i} className="animate-fade-in-up" style={{ textAlign: 'center', animationDelay: `${i*.1}s` }}>
                  <div style={{ width: 60, height: 60, borderRadius: '50%', background: i % 2 === 0 ? 'rgba(0,245,255,0.08)' : 'rgba(157,78,221,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.5rem', margin: '0 auto 1rem', border: `2px solid ${i % 2 === 0 ? 'var(--cyan)' : 'var(--pink)'}` }}>{h.icon}</div>
                  <div style={{ fontSize: '.65rem', fontWeight: 800, letterSpacing: '.1em', color: i%2===0?'var(--cyan)':'var(--pink)', textTransform: 'uppercase', marginBottom: '.35rem' }}>
                    {lang === 'en' ? `Quest ${h.step}` : `Bước ${h.step}`}
                  </div>
                  <div style={{ fontWeight: 700, marginBottom: '.4rem' }}>{hTitle}</div>
                  <div style={{ fontSize: '.82rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>{hDesc}</div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ── FEATURES ── */}
      <section style={{ padding: '80px 2rem' }}>
        <div style={{ maxWidth: 960, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
            <h2 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '.5rem' }}>{t('home.features')}</h2>
            <p style={{ color: 'var(--text-secondary)' }}>{t('home.featuresSub')}</p>
          </div>
          <div className="responsive-grid-3">
            {FEATURES.map((f, i) => {
              const fTitle = lang === 'en' ? f.title_en : f.title_vi;
              const fDesc = lang === 'en' ? f.desc_en : f.desc_vi;
              return (
                <div key={i} className="card animate-fade-in-up" style={{ padding: '1.75rem', animationDelay: `${i*.08}s`, transition: 'var(--tr)', border: '1px solid var(--border-soft)' }}
                  onMouseEnter={e => { e.currentTarget.style.transform='translateY(-4px)'; e.currentTarget.style.borderColor=f.color; e.currentTarget.style.boxShadow=`0 8px 24px ${f.color}15`; }}
                  onMouseLeave={e => { e.currentTarget.style.transform='none'; e.currentTarget.style.borderColor=''; e.currentTarget.style.boxShadow=''; }}
                >
                  <div style={{ width: 52, height: 52, borderRadius: 'var(--radius-md)', background: f.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.4rem', marginBottom: '1.1rem', border: `1.5px solid ${f.color}35` }}>
                    {f.icon}
                  </div>
                  <h3 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '.5rem' }}>{fTitle}</h3>
                  <p style={{ fontSize: '.85rem', color: 'var(--text-secondary)', lineHeight: 1.6 }}>{fDesc}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ── TESTIMONIALS ── */}
      <section style={{ padding: '60px 2rem', background: 'rgba(20,14,40,.4)' }}>
        <div style={{ maxWidth: 860, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: '2.5rem' }}>
            <h2 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '.5rem' }}>{t('home.testimonials')}</h2>
          </div>
          <div className="responsive-grid-3">
            {TESTIMONIALS.map((tItem, i) => {
              const tText = lang === 'en' ? tItem.text_en : tItem.text_vi;
              return (
                <div key={i} className="card animate-fade-in-up" style={{ padding: '1.5rem', animationDelay: `${i*.1}s`, border: '1px solid var(--border-soft)' }}>
                  <div style={{ display: 'flex', gap: '.3rem', marginBottom: '.85rem' }}>
                    {Array(tItem.stars).fill(0).map((_,j) => <Star key={j} size={14} fill="#FFB703" style={{ color: '#FFB703' }}/>)}
                  </div>
                  <p style={{ fontSize: '.88rem', color: 'var(--text-secondary)', lineHeight: 1.6, marginBottom: '1rem', fontStyle: 'italic' }}>"{tText}"</p>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '.75rem' }}>
                    <div style={{ width: 38, height: 38, borderRadius: '50%', background: 'rgba(157,78,221,.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.1rem', border: '2px solid rgba(157,78,221,.25)' }}>{tItem.avatar}</div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '.88rem' }}>{tItem.name}</div>
                      <span className="badge badge-purple" style={{ fontSize: '.65rem' }}>{tItem.mbti}</span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ── PRICING TEASER ── */}
      <section style={{ padding: '80px 2rem' }}>
        <div style={{ maxWidth: 600, margin: '0 auto', textAlign: 'center' }}>
          <h2 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '.75rem' }}>{t('home.ctaTitle')}</h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '2rem', lineHeight: 1.6 }}>
            {t('home.ctaSub')}
          </p>
          <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center', flexWrap: 'wrap' }}>
            <button className="btn btn-primary btn-lg" onClick={onRegister} style={{ gap: '.6rem' }}>
              <Sparkles size={18}/> {t('home.freeStart')}
            </button>
            <button className="btn btn-outline btn-lg" onClick={onLogin} style={{ gap: '.6rem' }}>
              <Crown size={18} style={{ color: '#FFB703' }}/> {t('home.login')}
            </button>
          </div>
          <div style={{ display: 'flex', gap: '1.5rem', justifyContent: 'center', marginTop: '1.5rem', flexWrap: 'wrap' }}>
            {[t('home.freeForever'), t('home.noCredit'), t('home.cancelAnytime')].map((textItem, i) => (
              <span key={i} style={{ fontSize: '.78rem', color: 'var(--text-muted)' }}>{textItem}</span>
            ))}
          </div>
        </div>
      </section>

      {/* ── FOOTER ── */}
      <footer style={{ borderTop: '1px solid rgba(157,78,221,.25)', padding: '2.5rem 2rem', background: 'rgba(10,5,22,.6)' }}>
        <div style={{ maxWidth: 960, margin: '0 auto', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem' }}>
            <BlushLogo size={28} />
            <span style={{ fontWeight: 900, letterSpacing: '-.02em' }} className="gradient-text">Blush</span>
          </div>
          <div style={{ display: 'flex', gap: '1.5rem' }}>
            {[t('home.footerTerms'), t('home.footerPrivacy'), t('home.footerContact'), t('home.footerFaq')].map(l => (
              <a key={l} href="#" style={{ fontSize: '.8rem', color: 'var(--text-muted)' }}>{l}</a>
            ))}
          </div>
          <div style={{ fontSize: '.78rem', color: 'var(--text-muted)' }}>© 2026 Blush. {t('home.footerDesc')}</div>
        </div>
      </footer>

    </div>
  );
}
