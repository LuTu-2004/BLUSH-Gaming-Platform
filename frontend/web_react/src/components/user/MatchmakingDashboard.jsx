import React, { useState } from 'react';
import { Sparkles, Users, Gamepad2, ArrowRight, Calendar, Clock, Plus, Check } from 'lucide-react';

const INITIAL_ROOMS = [
  {
    id: 1,
    title: 'Tryhard Squad #12',
    game: 'Liên Quân Mobile',
    desc: 'Leo rank nghiêm túc, có mic, biết combo',
    current: 3,
    max: 5,
    rank: 'Kim Cương+',
    tag: 'Leo Rank',
    tagColor: '#FF4D6D',
    avatars: ['🧙‍♂️', '⚔️', '🛡️']
  },
  {
    id: 2,
    title: 'Hội Tấu Hài Đêm',
    game: 'Liên Quân Mobile',
    desc: 'Vừa chơi vừa hát, ai toxic out ngay',
    current: 4,
    max: 5,
    rank: 'Mọi mức rank',
    tag: 'Tấu Hài',
    tagColor: '#9D4EDD',
    avatars: ['🌸', '🎸', '🌿', '☕']
  },
  {
    id: 3,
    title: 'Cày Event Mùa Hè',
    game: 'Liên Quân Mobile',
    desc: 'Farm skin free sự kiện mùa hè, ai cũng được',
    current: 2,
    max: 5,
    rank: 'Mọi mức rank',
    tag: 'Cày Skin',
    tagColor: '#00FF9F',
    avatars: ['🎮', '👾']
  },
  {
    id: 4,
    title: 'Rank Cao Thủ Only',
    game: 'Liên Quân Mobile',
    desc: 'Đã đủ team, sắp vào trận',
    current: 5,
    max: 5,
    rank: 'Cao Thủ+',
    tag: 'Leo Rank',
    tagColor: '#FF4D6D',
    avatars: ['👑', '🏆', '🔫', '🏹', '💫']
  }
];

const INITIAL_SCHEDULED = [
  {
    id: 101,
    title: 'Hẹn cày chuỗi thắng Tinh Anh',
    game: 'Liên Quân Mobile',
    time: '20:30 tối nay',
    desc: 'Cần tìm 1 AD và 1 Rừng cứng đi chung, giao tiếp mic discord rõ ràng, không giận dỗi.',
    current: 3,
    max: 5,
    rank: 'Tinh Anh II+',
    tag: 'Leo Rank',
    tagColor: '#FF4D6D',
    creator: 'Dũng Triều',
    rsvped: false
  },
  {
    id: 102,
    title: 'Lập sảnh karaoke tấu hài',
    game: 'Liên Quân Mobile',
    time: '21:00 tối nay',
    desc: 'Đấu thường tấu hài xả stress cuối ngày, vào hát hò chém gió là chính, thắng thua không quan trọng.',
    current: 2,
    max: 5,
    rank: 'Mọi mức rank',
    tag: 'Tấu Hài',
    tagColor: '#9D4EDD',
    creator: 'Yến Nhi',
    rsvped: false
  },
  {
    id: 103,
    title: 'Gom đội cày sự kiện skin free',
    game: 'Liên Quân Mobile',
    time: '22:00 tối nay',
    desc: 'Chạy nhanh 3 trận coop làm quest ngày nhận hộp quà skin, xong tự động giải tán.',
    current: 1,
    max: 5,
    rank: 'Mọi mức rank',
    tag: 'Cày Skin',
    tagColor: '#00FF9F',
    creator: 'Phúc Bảo',
    rsvped: true
  }
];

export default function MatchmakingDashboard({ onEnterRoom, t, lang, onUpgrade }) {
  const [activeTab, setActiveTab] = useState('live'); // 'live' | 'scheduled'
  const [activeCategory, setActiveCategory] = useState('Tất cả');
  const [rooms, setRooms] = useState(INITIAL_ROOMS);
  const [scheduledLobbies, setScheduledLobbies] = useState(INITIAL_SCHEDULED);
  const [matching, setMatching] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newTime, setNewTime] = useState('');
  const [newDesc, setNewDesc] = useState('');

  const stats = [
    { label: lang === 'en' ? 'Online' : 'Online', value: '2.4K', icon: '👥', color: '#00F5FF' },
    { label: lang === 'en' ? 'Waiting Rooms' : 'Phòng đang chờ', value: '186', icon: '🎮', color: '#9D4EDD' },
    { label: lang === 'en' ? 'Matched Today' : 'Đã ghép hôm nay', value: '1.2K', icon: '⚡', color: '#00FF9F' }
  ];

  const categories = [
    { name: lang === 'en' ? 'All' : 'Tất cả', icon: '🌐' },
    { name: lang === 'en' ? 'Leo Rank' : 'Leo Rank', icon: '🔥' },
    { name: lang === 'en' ? 'Tấu Hài' : 'Tấu Hài', icon: '🎤' },
    { name: lang === 'en' ? 'Cày Skin' : 'Cày Skin', icon: '🎁' }
  ];

  const filteredRooms = activeCategory === 'Tất cả' || activeCategory === 'All'
    ? rooms
    : rooms.filter(r => r.tag === activeCategory);

  const filteredScheduled = activeCategory === 'Tất cả' || activeCategory === 'All'
    ? scheduledLobbies
    : scheduledLobbies.filter(s => s.tag === activeCategory);

  const handleQuickMatch = () => {
    setMatching(true);
    setTimeout(() => {
      setMatching(false);
      const availableRoom = rooms.find(r => r.current < r.max);
      if (availableRoom && onEnterRoom) {
        onEnterRoom(availableRoom);
      }
    }, 2500);
  };

  const handleRsvp = (id) => {
    setScheduledLobbies(prev => prev.map(s => {
      if (s.id === id) {
        const nextRsvped = !s.rsvped;
        return {
          ...s,
          rsvped: nextRsvped,
          current: nextRsvped ? s.current + 1 : s.current - 1
        };
      }
      return s;
    }));
  };

  const handleCreateLobby = (e) => {
    e.preventDefault();
    if (!newTitle.trim() || !newTime.trim()) return;

    const newLobby = {
      id: Date.now(),
      title: newTitle,
      game: 'Liên Quân Mobile',
      time: newTime,
      desc: newDesc || 'Không có mô tả chi tiết.',
      current: 1,
      max: 5,
      rank: 'Mọi mức rank',
      tag: activeCategory === 'Tất cả' || activeCategory === 'All' ? 'Leo Rank' : activeCategory,
      tagColor: activeCategory === 'Tấu Hài' ? '#9D4EDD' : activeCategory === 'Cày Skin' ? '#00FF9F' : '#FF4D6D',
      creator: 'Khánh Linh',
      rsvped: true
    };

    setScheduledLobbies([newLobby, ...scheduledLobbies]);
    setNewTitle('');
    setNewTime('');
    setNewDesc('');
    setShowCreateModal(false);

    alert(lang === 'en' ? 'Scheduled Lobby created successfully!' : 'Đã lên lịch hẹn chơi thành công!');
  };

  return (
    <div style={{ padding: '2rem 1.5rem', maxWidth: '1100px', margin: '0 auto', minHeight: '85vh' }} className="animate-fade-in">
      
      {/* AI Golden Peak Hour Indicator */}
      <div style={{ 
        background: 'linear-gradient(90deg, rgba(0, 245, 255, 0.08) 0%, rgba(157, 78, 221, 0.08) 100%)',
        border: '1px solid rgba(0, 245, 255, 0.2)',
        padding: '0.75rem 1.25rem',
        borderRadius: '12px',
        marginBottom: '1.5rem',
        display: 'flex',
        alignItems: 'center',
        gap: '.65rem',
        fontSize: '.82rem',
        color: 'var(--text-primary)'
      }}>
        <span style={{ animation: 'pulse 1.5s infinite', display: 'inline-block', fontSize: '1.1rem' }}>💡</span>
        <div>
          <span style={{ fontWeight: 800, color: 'var(--cyan)' }}>
            {lang === 'en' ? '⚡ PEAK HOURS ALERT (20:00 - 22:00):' : '⚡ KHUNG GIỜ VÀNG GHÉP ĐỘI (20:00 - 22:00 HẰNG NGÀY):'}
          </span>
          <span style={{ marginLeft: '.4rem', color: 'var(--text-secondary)' }}>
            {lang === 'en' 
              ? 'Join now for 2x faster matchmaking and +50% EXP bonus on all co-op party games!'
              : 'Tham gia sảnh ngay bây giờ để được ghép đội nhanh gấp đôi và cộng thêm +50% EXP thưởng nhiệm vụ!'}
          </span>
        </div>
      </div>

      {/* Welcome & Matching Card */}
      <div className="card-pink" style={{ padding: '2rem', marginBottom: '2rem', position: 'relative', overflow: 'hidden' }}>
        <div style={{
          position: 'absolute', right: '-5%', top: '-15%', width: '300px', height: '300px',
          borderRadius: '50%', background: 'radial-gradient(circle, rgba(0, 245, 255, 0.12) 0%, transparent 70%)',
          pointerEvents: 'none', zIndex: 1
        }} />
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '2rem', position: 'relative', zIndex: 2 }}>
          <div style={{ maxWidth: '600px' }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: '.4rem', background: 'rgba(0, 245, 255, 0.1)', border: '1px solid rgba(0, 245, 255, 0.25)', borderRadius: 99, padding: '.3rem .8rem', marginBottom: '1rem' }}>
              <Sparkles size={12} style={{ color: '#00F5FF' }} />
              <span style={{ fontSize: '.75rem', fontWeight: 700, color: '#00F5FF' }}>
                {lang === 'en' ? 'AI PEAK HOUR GRAPHS ACTIVE' : 'AI SORTING & MATCHMAKING ĐANG HOẠT ĐỘNG'}
              </span>
            </div>
            <h1 style={{ fontSize: '2.2rem', fontWeight: 900, marginBottom: '.75rem', color: '#FFF', letterSpacing: '-.02em' }}>
              Tìm đồng đội <span style={{ color: 'var(--cyan)' }}>cùng tần số</span>
            </h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: '.95rem', lineHeight: 1.6 }}>
              {lang === 'en'
                ? 'AI sorts and recommends teammates based on playstyle, rank, and purpose. No mismatch, no toxicity.'
                : 'AI phân tích lối chơi, xếp hạng và mục đích để ghép bạn với đồng đội phù hợp nhất. Không lệch pha, không toxic.'}
            </p>
          </div>
          
          <div>
            <button 
              onClick={handleQuickMatch}
              disabled={matching}
              className="btn btn-primary btn-lg" 
              style={{ 
                gap: '.75rem', 
                padding: '1rem 2.2rem',
                fontSize: '1rem',
                boxShadow: '0 0 20px rgba(0, 245, 255, 0.4)',
                background: 'linear-gradient(135deg, #9D4EDD 0%, #00F5FF 100%)',
                borderColor: '#00F5FF'
              }}
            >
              {matching ? (
                <>
                  <div style={{ width: 18, height: 18, border: '2px solid rgba(255,255,255,0.2)', borderTopColor: '#FFF', borderRadius: '50%', animation: 'spin .8s linear infinite' }} />
                  {lang === 'en' ? 'Searching Party...' : 'Đang tìm tổ đội...'}
                </>
              ) : (
                <>
                  <span>⚡</span>
                  {lang === 'en' ? 'Start AI Matchmaking' : 'Bắt đầu ghép đội'}
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Mini-Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', marginBottom: '2rem' }} className="responsive-profile">
        {stats.map(s => (
          <div key={s.label} className="card" style={{ padding: '1.25rem', display: 'flex', alignItems: 'center', gap: '1rem', border: '1px solid var(--border-soft)' }}>
            <div style={{ width: 44, height: 44, borderRadius: '12px', background: `${s.color}15`, border: `1px solid ${s.color}30`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.3rem' }}>
              {s.icon}
            </div>
            <div>
              <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#FFF', lineHeight: 1.1 }}>{s.value}</div>
              <div style={{ fontSize: '.78rem', color: 'var(--text-secondary)', marginTop: '.15rem' }}>{s.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Main Experience Tab Selector (Live vs Scheduled) */}
      <div style={{ display: 'flex', borderBottom: '1px solid var(--border-soft)', paddingBottom: '.5rem', marginBottom: '1.5rem', gap: '1.5rem' }}>
        <button 
          onClick={() => setActiveTab('live')}
          style={{
            background: 'none', border: 'none', color: activeTab === 'live' ? 'var(--cyan)' : 'var(--text-secondary)',
            fontSize: '1.05rem', fontWeight: 800, paddingBottom: '.5rem', cursor: 'pointer',
            borderBottom: activeTab === 'live' ? '3px solid var(--cyan)' : '3px solid transparent',
            transition: 'var(--tr)', display: 'flex', alignItems: 'center', gap: '.4rem'
          }}
        >
          <span>🎮</span> {lang === 'en' ? 'Live Waiting Lobbies' : 'Sảnh Chờ Trực Tuyến'}
        </button>
        <button 
          onClick={() => setActiveTab('scheduled')}
          style={{
            background: 'none', border: 'none', color: activeTab === 'scheduled' ? 'var(--cyan)' : 'var(--text-secondary)',
            fontSize: '1.05rem', fontWeight: 800, paddingBottom: '.5rem', cursor: 'pointer',
            borderBottom: activeTab === 'scheduled' ? '3px solid var(--cyan)' : '3px solid transparent',
            transition: 'var(--tr)', display: 'flex', alignItems: 'center', gap: '.4rem'
          }}
        >
          <span>📅</span> {lang === 'en' ? 'Scheduled Lobbies (No Empty App)' : 'Lịch Hẹn Chơi Trước (Chống Trống App)'}
        </button>
      </div>

      {/* Categories filter bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
        <div style={{ display: 'flex', gap: '.5rem', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--border-soft)', padding: '.25rem', borderRadius: '99px' }}>
          {categories.map(c => {
            const isActive = activeCategory === c.name;
            return (
              <button
                key={c.name}
                onClick={() => setActiveCategory(c.name)}
                style={{
                  display: 'flex', alignItems: 'center', gap: '.4rem',
                  padding: '.5rem 1.1rem', borderRadius: '99px',
                  fontSize: '.82rem', fontWeight: 700, cursor: 'pointer',
                  transition: 'var(--tr)',
                  background: isActive ? 'rgba(0, 245, 255, 0.12)' : 'transparent',
                  color: isActive ? '#00F5FF' : 'var(--text-secondary)',
                  border: `1px solid ${isActive ? 'rgba(0,245,255,.2)' : 'transparent'}`
                }}
              >
                <span>{c.icon}</span>
                {c.name}
              </button>
            );
          })}
        </div>
        
        {activeTab === 'live' ? (
          <div style={{ fontSize: '.88rem', color: 'var(--text-secondary)' }}>
            {lang === 'en' ? `Waiting rooms (${filteredRooms.length})` : `Phòng đang chờ (${filteredRooms.length})`}
          </div>
        ) : (
          <button 
            onClick={() => setShowCreateModal(true)}
            className="btn btn-outline btn-sm" 
            style={{ borderColor: 'var(--success)', color: 'var(--success)', gap: '.3rem' }}
          >
            <Plus size={14} /> {lang === 'en' ? 'Schedule a Lobby' : 'Lên lịch hẹn chơi mới'}
          </button>
        )}
      </div>

      {/* Modal for creating a scheduled lobby */}
      {showCreateModal && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 100, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem', backdropFilter: 'blur(4px)' }}>
          <div className="card" style={{ padding: '2rem', maxWidth: '480px', width: '100%', border: '1px solid var(--border-soft)', position: 'relative' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#FFF', marginBottom: '1.25rem' }}>📅 Lên lịch sảnh chơi hẹn trước</h3>
            <form onSubmit={handleCreateLobby} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '.8rem', color: 'var(--text-secondary)', marginBottom: '.35rem', fontWeight: 700 }}>Tiêu đề cuộc hẹn</label>
                <input 
                  type="text" 
                  value={newTitle} 
                  onChange={e => setNewTitle(e.target.value)}
                  placeholder="Ví dụ: Cày chuỗi thắng Tinh Anh..." 
                  className="input" 
                  required 
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '.8rem', color: 'var(--text-secondary)', marginBottom: '.35rem', fontWeight: 700 }}>Thời gian hẹn</label>
                <input 
                  type="text" 
                  value={newTime} 
                  onChange={e => setNewTime(e.target.value)}
                  placeholder="Ví dụ: 20:30 tối nay / Chiều mai 15:00..." 
                  className="input" 
                  required 
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '.8rem', color: 'var(--text-secondary)', marginBottom: '.35rem', fontWeight: 700 }}>Mô tả yêu cầu</label>
                <textarea 
                  value={newDesc} 
                  onChange={e => setNewDesc(e.target.value)}
                  placeholder="Cần tìm đường đi nào, rank gì, có mic không..." 
                  className="input" 
                  style={{ height: '80px', resize: 'none' }}
                />
              </div>
              
              <div style={{ display: 'flex', gap: '.75rem', marginTop: '.5rem', justifyContent: 'flex-end' }}>
                <button type="button" onClick={() => setShowCreateModal(false)} className="btn btn-outline btn-sm">Hủy</button>
                <button type="submit" className="btn btn-primary btn-sm" style={{ background: 'var(--success)', color: '#0A0516' }}>Xác nhận tạo</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Render TAB 1: Live waiting rooms */}
      {activeTab === 'live' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.25rem' }}>
          {filteredRooms.map(room => {
            const isFull = room.current >= room.max;
            return (
              <div 
                key={room.id} 
                className="card" 
                style={{ 
                  padding: '1.5rem', 
                  border: '1px solid var(--border-soft)', 
                  display: 'flex', 
                  flexDirection: 'column', 
                  justifyContent: 'space-between',
                  minHeight: '210px',
                  transition: 'var(--tr)',
                  background: 'var(--surface)'
                }}
                onMouseEnter={e => { e.currentTarget.style.borderColor = 'rgba(157,78,221,0.3)'; e.currentTarget.style.transform = 'translateY(-2px)'; }}
                onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--border-soft)'; e.currentTarget.style.transform = 'none'; }}
              >
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '.75rem' }}>
                    <div>
                      <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#FFF' }}>{room.title}</h3>
                      <div style={{ fontSize: '.78rem', color: 'var(--text-muted)', marginTop: '.15rem' }}>{room.game}</div>
                    </div>
                    
                    <span style={{ 
                      fontSize: '.7rem', fontWeight: 700, padding: '.25rem .65rem', borderRadius: '6px',
                      background: `${room.tagColor}15`, color: room.tagColor, border: `1px solid ${room.tagColor}30` 
                    }}>
                      {room.tag}
                    </span>
                  </div>

                  <p style={{ color: 'var(--text-secondary)', fontSize: '.84rem', lineHeight: 1.45, marginBottom: '1.25rem' }}>
                    {room.desc}
                  </p>
                </div>

                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid rgba(255,255,255,0.04)', paddingTop: '1rem' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '.25rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '.35rem', fontSize: '.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
                        <span>👥</span> {room.current}/{room.max}
                        {room.rank && <span style={{ color: 'var(--text-muted)' }}>| {room.rank}</span>}
                      </div>
                      <div style={{ display: 'flex', gap: '.15rem', marginTop: '.25rem' }}>
                        {room.avatars.map((av, idx) => (
                          <div key={idx} style={{ 
                            width: 22, height: 22, borderRadius: '50%', background: 'rgba(255,255,255,0.06)', 
                            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.8rem',
                            border: '1px solid var(--border-soft)', marginLeft: idx > 0 ? '-6px' : 0
                          }}>
                            {av}
                          </div>
                        ))}
                      </div>
                    </div>

                    <button 
                      onClick={() => !isFull && onEnterRoom && onEnterRoom(room)}
                      disabled={isFull}
                      className="btn btn-sm"
                      style={{
                        background: isFull ? 'rgba(255,255,255,0.05)' : 'var(--success)',
                        color: isFull ? 'var(--text-muted)' : '#0A0516',
                        fontWeight: 800,
                        cursor: isFull ? 'not-allowed' : 'pointer',
                        border: 'none',
                        padding: '.45rem 1.1rem',
                        borderRadius: '8px'
                      }}
                    >
                      {isFull ? (lang === 'en' ? 'Full' : 'Đã đầy') : (lang === 'en' ? 'Join' : 'Vào phòng')}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Render TAB 2: Scheduled lobbies (Cold-Start Solution) */}
      {activeTab === 'scheduled' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {filteredScheduled.map(lobby => {
            const isFull = lobby.current >= lobby.max;
            return (
              <div 
                key={lobby.id}
                className="card"
                style={{ 
                  padding: '1.5rem', 
                  border: lobby.rsvped ? '1px solid rgba(0, 245, 255, 0.3)' : '1px solid var(--border-soft)',
                  background: lobby.rsvped ? 'linear-gradient(145deg, #140E28 0%, rgba(0, 245, 255, 0.02) 100%)' : 'var(--surface)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  flexWrap: 'wrap',
                  gap: '1.5rem'
                }}
              >
                <div style={{ display: 'flex', gap: '1.25rem', alignItems: 'flex-start', flex: 1, minWidth: '300px' }}>
                  <div style={{ 
                    width: 50, height: 50, borderRadius: '12px', background: 'rgba(255,255,255,0.03)',
                    border: '1px solid var(--border-soft)', display: 'flex', flexDirection: 'column',
                    alignItems: 'center', justifyContent: 'center', color: 'var(--cyan)', flexShrink: 0
                  }}>
                    <Calendar size={20} />
                  </div>

                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem', flexWrap: 'wrap' }}>
                      <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#FFF' }}>{lobby.title}</h3>
                      <span className="badge" style={{ background: 'rgba(255,255,255,0.05)', color: 'var(--text-secondary)', fontSize: '.68rem' }}>{lobby.game}</span>
                      <span style={{ 
                        fontSize: '.65rem', fontWeight: 700, padding: '.15rem .5rem', borderRadius: '4px',
                        background: `${lobby.tagColor}15`, color: lobby.tagColor, border: `1px solid ${lobby.tagColor}30` 
                      }}>{lobby.tag}</span>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem', fontSize: '.8rem', color: 'var(--warning)', fontWeight: 700, marginTop: '.35rem' }}>
                      <Clock size={12} />
                      <span>{lobby.time}</span>
                      <span style={{ color: 'var(--text-muted)' }}>• Người tạo: {lobby.creator}</span>
                    </div>

                    <p style={{ color: 'var(--text-secondary)', fontSize: '.82rem', marginTop: '.5rem', lineHeight: 1.4 }}>
                      {lobby.desc}
                    </p>
                  </div>
                </div>

                {/* Right columns: Members count & RSVP action */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '2rem', flexWrap: 'wrap' }}>
                  <div>
                    <div style={{ fontSize: '.72rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '.05em', marginBottom: '.15rem' }}>
                      Thành viên đã hẹn
                    </div>
                    <div style={{ fontSize: '1.15rem', fontWeight: 800, color: '#FFF', display: 'flex', alignItems: 'center', gap: '.35rem' }}>
                      <span>👥</span> {lobby.current}/{lobby.max}
                      <span style={{ fontSize: '.72rem', color: 'var(--text-muted)', fontWeight: 500 }}>| {lobby.rank}</span>
                    </div>
                  </div>

                  <button
                    onClick={() => handleRsvp(lobby.id)}
                    disabled={isFull && !lobby.rsvped}
                    className="btn btn-sm"
                    style={{
                      background: lobby.rsvped 
                        ? 'rgba(0, 245, 255, 0.12)' 
                        : 'rgba(255,255,255,0.05)',
                      color: lobby.rsvped ? 'var(--cyan)' : '#FFF',
                      border: lobby.rsvped ? '1px solid rgba(0, 245, 255, 0.25)' : '1px solid var(--border-soft)',
                      fontWeight: 800,
                      cursor: (isFull && !lobby.rsvped) ? 'not-allowed' : 'pointer',
                      padding: '.5rem 1.25rem',
                      borderRadius: '8px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '.3rem'
                    }}
                  >
                    {lobby.rsvped ? (
                      <>
                        <Check size={14} />
                        <span>Đã đặt chỗ ✓</span>
                      </>
                    ) : (
                      <span>Đặt chỗ chơi trước</span>
                    )}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

    </div>
  );
}
