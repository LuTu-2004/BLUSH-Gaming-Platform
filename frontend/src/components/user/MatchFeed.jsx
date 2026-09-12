import React, { useState, useEffect, useRef } from 'react';
import { Heart, X, Eye, Lock, Crown, Sparkles, ChevronRight, Users, RefreshCw, MessageSquare, Award, MessageCircle, Send, Plus, Image, ThumbsUp } from 'lucide-react';
import { MOCK_USERS, MOCK_ICEBREAKERS } from '../../data/mockData';

/* ── Silhouette SVG ── */
function SilhouetteSVG({ color1 = '#9D4EDD', color2 = '#00F5FF' }) {
  return (
    <svg width="120" height="150" viewBox="0 0 180 220" fill="none" xmlns="http://www.w3.org/2000/svg" className="silhouette-svg" style={{ opacity: 0.6 }}>
      <defs>
        <linearGradient id="sil-grad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={color1} stopOpacity=".75"/>
          <stop offset="100%" stopColor={color2} stopOpacity=".55"/>
        </linearGradient>
      </defs>
      <ellipse cx="90" cy="60" rx="38" ry="42" fill="url(#sil-grad)"/>
      <rect x="76" y="98" width="28" height="20" rx="8" fill="url(#sil-grad)"/>
      <path d="M20 200 Q30 130 90 118 Q150 130 160 200 Z" fill="url(#sil-grad)"/>
      <ellipse cx="90" cy="32" rx="36" ry="22" fill="url(#sil-grad)" opacity=".6"/>
      <ellipse cx="58" cy="55" rx="12" ry="30" fill="url(#sil-grad)" opacity=".4"/>
      <ellipse cx="122" cy="55" rx="12" ry="30" fill="url(#sil-grad)" opacity=".4"/>
    </svg>
  );
}

/* ── Mission Room Panel (Co-op Strategist Challenge) ── */
function MissionRoom({ match, onMissionComplete, t, lang, onCancel }) {
  const [round, setRound] = useState(1); // 1, 2, 3
  const [userAnswers, setUserAnswers] = useState([null, null, null]);
  const [step, setStep] = useState('play'); // 'play' | 'processing' | 'results'
  const [partnerAnswers] = useState([0, 1, 0]); // Simulated choices from partner

  // Get current question based on round
  const q = MOCK_ICEBREAKERS[round - 1] || MOCK_ICEBREAKERS[0];
  const questionText = lang === 'en' ? q.question_en : q.question_vi;
  const options = q.options;

  function selectOption(optIndex) {
    const nextAnswers = [...userAnswers];
    nextAnswers[round - 1] = optIndex;
    setUserAnswers(nextAnswers);

    if (round < 3) {
      setTimeout(() => {
        setRound(r => r + 1);
      }, 400);
    }
  }

  function submitAnswers() {
    setStep('processing');
    setTimeout(() => {
      setStep('results');
    }, 1800);
  }

  if (step === 'processing') {
    return (
      <div className="mission-card" style={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '4rem 2rem', textAlign: 'center', border: '1px solid var(--border)', background: 'var(--surface)' }}>
        <div style={{ width: 50, height: 50, border: '4px solid rgba(0,245,255,.15)', borderTopColor: 'var(--cyan)', borderRadius: '50%', animation: 'spin .8s linear infinite', marginBottom: '1.5rem' }}/>
        <h3 style={{ fontWeight: 800, fontSize: '1.1rem', marginBottom: '.5rem' }} className="gradient-text">{t('feed.roundProcessing')}</h3>
        <p style={{ color: 'var(--text-secondary)', fontSize: '.84rem' }}>{t('feed.roundProcessingSub')}</p>
      </div>
    );
  }

  if (step === 'results') {
    let matchCount = 0;
    const resultsSummary = userAnswers.map((ans, idx) => {
      const isMatch = ans === partnerAnswers[idx];
      if (isMatch) matchCount++;
      const question = MOCK_ICEBREAKERS[idx];
      const qText = lang === 'en' ? question.question_en : question.question_vi;
      const userVal = lang === 'en' ? question.options[ans]?.label_en : question.options[ans]?.label_vi;
      const partnerVal = lang === 'en' ? question.options[partnerAnswers[idx]]?.label_en : question.options[partnerAnswers[idx]]?.label_vi;
      return {
        question: qText,
        userVal: userVal || '',
        partnerVal: partnerVal || '',
        isMatch
      };
    });

    const matchPercent = Math.round((matchCount / 3) * 100);

    return (
      <div className="mission-card" style={{ height: '100%', border: '1px solid var(--border)', background: 'var(--surface)' }}>
        {/* Header */}
        <div className="mission-header" style={{ justifyContent: 'center', padding: '1rem' }}>
          <span className="badge badge-purple" style={{ fontSize: '.78rem', display: 'flex', alignItems: 'center', gap: '.3rem' }}>
            {t('feed.roundCompleted')}
          </span>
        </div>

        <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.25rem', textAlign: 'center' }}>
          <div>
            <div style={{ fontSize: '3rem', marginBottom: '.4rem', animation: 'heartbeat 1.5s infinite' }}>🛡️</div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 900 }} className="gradient-text">{t('feed.roundResultTitle')}</h2>
            <div style={{ fontSize: '1.6rem', fontWeight: 900, color: 'var(--cyan)', margin: '.5rem 0' }}>
              {matchCount}/3 {t('feed.roundResultMatch')} ({matchPercent}%)
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '.8rem', maxWidth: 280, margin: '0 auto' }}>
              {t('feed.roundResultDesc')}
            </p>
          </div>

          {/* Results list */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '.6rem', textAlign: 'left' }}>
            {resultsSummary.map((res, i) => (
              <div key={i} style={{ padding: '.75rem', borderRadius: 'var(--radius-md)', background: 'var(--surface-2)', border: `1px solid ${res.isMatch ? 'rgba(0,245,255,.2)' : 'var(--border-soft)'}`, fontSize: '.76rem' }}>
                <div style={{ fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '.3rem' }}>Q{i+1}: {res.question}</div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div>{lang === 'en' ? 'You:' : 'Bạn:'} <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{res.userVal}</span></div>
                    <div>{match.name.split(' ')[0]}: <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{res.partnerVal}</span></div>
                  </div>
                  <span style={{ fontSize: '.82rem', fontWeight: 800, color: res.isMatch ? 'var(--cyan)' : 'var(--text-muted)' }}>
                    {res.isMatch ? `✅ ${t('feed.roundResultMatch').toUpperCase()}` : `✕ ${t('feed.roundResultDiff').toUpperCase()}`}
                  </span>
                </div>
              </div>
            ))}
          </div>

          <button className="btn btn-primary btn-w" onClick={onMissionComplete} style={{ gap: '.5rem', justifyContent: 'center' }}>
            {t('feed.roundResultBtn')}
          </button>
        </div>
      </div>
    );
  }

  const currentPicked = userAnswers[round - 1];

  return (
    <div className="card animate-scale-in" style={{ padding: '1.5rem', border: '1.5px solid var(--border)', background: 'var(--surface)' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border-soft)', paddingBottom: '.75rem', marginBottom: '1.25rem' }}>
        <h3 style={{ fontSize: '1rem', fontWeight: 800 }}>⚔️ {lang === 'en' ? 'Co-op Matchmaker Challenge' : 'Thử thách Ghép đội Co-op'}</h3>
        <button onClick={onCancel} className="btn btn-ghost btn-sm" style={{ padding: '.25rem' }}><X size={16}/></button>
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '.5rem', marginBottom: '1.25rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem' }}>
          <div style={{ width: 28, height: 28, borderRadius: '50%', background: 'var(--grad-brand)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.75rem', color: '#fff', fontWeight: 700, border: '1.5px solid #fff' }}>Y</div>
          <div style={{ fontSize: '.68rem' }}>
            <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{lang === 'en' ? 'You' : 'Bạn'}</div>
            <div style={{ color: 'var(--text-muted)' }}>{t('feed.playerOne')}</div>
          </div>
        </div>

        {/* Round indicators */}
        <div style={{ display: 'flex', gap: '.25rem', alignItems: 'center' }}>
          {[1, 2, 3].map(r => {
            const active = round === r;
            const answered = userAnswers[r - 1] !== null;
            return (
              <div key={r} style={{
                padding: '.15rem .45rem', borderRadius: 99, fontSize: '.62rem', fontWeight: 700,
                background: active ? 'rgba(0,245,255,0.1)' : (answered ? 'var(--pink-soft)' : 'var(--surface-3)'),
                color: active ? 'var(--cyan)' : (answered ? 'var(--pink)' : 'var(--text-muted)'),
                border: active ? '1px solid rgba(0,245,255,.3)' : 'none',
                cursor: 'pointer', transition: 'var(--tr)'
              }}
              onClick={() => answered && setRound(r)}
              >
                R{r}
              </div>
            );
          })}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem' }}>
          <div style={{ fontSize: '.68rem', textAlign: 'right' }}>
            <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{match.name.split(' ')[0]}</div>
            <div style={{ color: 'var(--text-muted)' }}>{t('feed.playerTwo')}</div>
          </div>
          <div style={{ width: 28, height: 28, borderRadius: '50%', background: match.avatarBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.75rem', border: '1.5px solid #fff' }}>{match.avatar}</div>
        </div>
      </div>

      <div style={{ padding: '1rem', background: 'var(--surface-2)', borderRadius: 'var(--radius-lg)', marginBottom: '1.25rem' }}>
        <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
          <span style={{ fontSize: '.65rem', fontWeight: 700, letterSpacing: '.1em', textTransform: 'uppercase', color: 'var(--cyan)' }}>{t('feed.roundTitle')}</span>
          <p style={{ fontWeight: 800, fontSize: '.95rem', color: 'var(--text-primary)', lineHeight: 1.4, marginTop: '.25rem' }}>
            "{questionText}"
          </p>
        </div>

        {/* Options */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '.5rem' }}>
          {options.map((opt, i) => {
            const optLabel = lang === 'en' ? opt.label_en : opt.label_vi;
            return (
              <button
                key={i}
                className={`survey-option ${currentPicked === i ? 'selected' : ''}`}
                onClick={() => selectOption(i)}
                style={{
                  padding: '.6rem .75rem',
                  fontSize: '.8rem',
                  border: currentPicked === i ? '1.5px solid var(--cyan)' : '1.5px solid var(--border-soft)',
                  background: currentPicked === i ? 'rgba(0,245,255,0.08)' : 'var(--surface)',
                  color: currentPicked === i ? 'var(--cyan)' : 'var(--text-secondary)'
                }}
              >
                <span style={{ marginRight: '.4rem' }}>{opt.icon}</span>
                {optLabel}
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ textAlign: 'center' }}>
        {userAnswers.includes(null) ? (
          <p style={{ fontSize: '.72rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '.3rem' }}>
            <Eye size={12}/> {t('feed.roundFooter')}
          </p>
        ) : (
          <button className="btn btn-primary btn-sm btn-w" onClick={submitAnswers} style={{ gap: '.4rem', background: 'var(--grad-brand)', border: 'none', color: '#0A0516' }}>
            <Heart size={14}/> {lang === 'en' ? 'Sync & Find Match' : 'Đồng bộ & Kết nối'}
          </button>
        )}
      </div>
    </div>
  );
}

/* ── Main ZoneHub ── */
export default function MatchFeed({ isVip, onChat, onUpgrade, t, lang }) {
  const [activeTab, setActiveTab] = useState('chat'); // 'chat' | 'feed'
  const [targetMatch, setTargetMatch] = useState(null); // specific user to match with
  const [showMission, setShowMission] = useState(false);
  
  // Community Chat state
  const [chatMessages, setChatMessages] = useState([
    { id: 1, user: 'Minh Tú', role: '⚔️ Chúa Tryhard', avatar: '⚔️', text: 'Cần Trợ Thủ cứng bảo kê, đang tinh anh 3 cày chuỗi thắng ⚔️', time: '16:01', system: false, recruitment: true, userId: 'u2' },
    { id: 2, user: 'Khánh An', role: '🧠 Mentor Uy Tín', avatar: '🧙‍♂️', text: 'Có ai cày chung sự kiện lấy skin free hôm nay không? Lập team làm quest nhanh 🎁', time: '16:02', system: false, recruitment: true, userId: 'u3' },
    { id: 3, user: 'Yến Nhi', role: '🎤 Top 1 Tấu Hài', avatar: '🌿', text: 'Hội tấu hài ca hát bật voice lên đi mọi người ơi, vừa chơi vừa hát xả stress cực đỉnh 🎤', time: '16:04', system: false, recruitment: false, userId: 'u5' },
    { id: 4, user: 'Phúc Bảo', role: '🏹 Sniper Ace', avatar: '🏹', text: 'AD gánh team tìm Rừng/Top ăn ý leo rank nghiêm túc, tỉ lệ thắng 65%.', time: '16:05', system: false, recruitment: true, userId: 'u4' }
  ]);
  const [chatInput, setChatInput] = useState('');
  
  // Social Feed state
  const [posts, setPosts] = useState([
    {
      id: 'p1',
      author: 'Minh Tú',
      role: '⚔️ Chúa Tryhard',
      avatar: '⚔️',
      avatarBg: 'linear-gradient(135deg,#00F5FF,#7B2CBF)',
      text: 'Highlights Nakroth đi rừng gánh team 20 trận thắng thông ⚡ Giáo án di chuyển và cướp rừng cực đỉnh cho anh em leo rank Tinh Anh / Cao Thủ nhé!',
      likes: 42,
      comments: [
        { name: 'Phúc Bảo', text: 'Giáo án Nakroth này khét quá bro, hôm nào kéo tui đi chung nha!' },
        { name: 'Khánh An', text: 'Chuỗi thắng 20 trận nể thiệt, macro đỉnh cao.' }
      ],
      liked: false,
      newComment: '',
      hasImg: true
    },
    {
      id: 'p2',
      author: 'Yến Nhi',
      role: '🎤 Top 1 Tấu Hài',
      avatar: '🌿',
      avatarBg: 'linear-gradient(135deg,#C77DFF,#7B2CBF)',
      text: 'Hôm nay vừa thắng rank vừa hát hò tấu hài xả stress vui xỉu. Đúng kiểu vừa chơi vừa voice chat ca hát xả stress. Cám ơn team nha 🎤 Mọi người vào sảnh tấu hài đi!',
      likes: 28,
      comments: [
        { name: 'Linh Nguyễn', text: 'Hôm nay nghe Yến Nhi hát trực tiếp trên voice chat vui lắm luôn á!' }
      ],
      liked: false,
      newComment: '',
      hasImg: false
    }
  ]);
  const [postInput, setPostInput] = useState('');

  const chatEndRef = useRef(null);

  // Auto scroll chat
  useEffect(() => {
    if (chatEndRef.current) {
      chatEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [chatMessages, activeTab]);

  function handleSendChatMessage(e) {
    e.preventDefault();
    if (!chatInput.trim()) return;

    const newMessage = {
      id: Date.now(),
      user: 'Khánh Linh',
      role: '🎤 Top 1 Tấu Hài',
      avatar: '🌸',
      text: chatInput,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      system: false,
      recruitment: false,
      userId: 'u1'
    };

    setChatMessages(prev => [...prev, newMessage]);
    setChatInput('');

    // Reward feedback
    setTimeout(() => {
      alert(lang === 'en' 
        ? 'Message sent! You earned +50 EXP and +5 Coins for active contribution!'
        : 'Đã gửi tin nhắn! Bạn nhận được +50 EXP và +5 Coins vì tích cực tương tác!');
    }, 300);
  }

  function handleCreatePost(e) {
    e.preventDefault();
    if (!postInput.trim()) return;

    const newPostObj = {
      id: `p_${Date.now()}`,
      author: 'Khánh Linh',
      role: '🎤 Top 1 Tấu Hài',
      avatar: '🌸',
      avatarBg: 'linear-gradient(135deg,#9D4EDD,#00F5FF)',
      text: postInput,
      likes: 0,
      comments: [],
      liked: false,
      newComment: '',
      hasImg: false
    };

    setPosts(prev => [newPostObj, ...prev]);
    setPostInput('');

    alert(lang === 'en'
      ? 'Post created! AI reviewed strategy: +100 EXP and +10 Coins!'
      : 'Đăng bài thành công! AI duyệt bài đăng chiến thuật: +100 EXP và +10 Coins!');
  }

  function handleLikePost(postId) {
    setPosts(prev => prev.map(p => {
      if (p.id === postId) {
        return {
          ...p,
          liked: !p.liked,
          likes: p.liked ? p.likes - 1 : p.likes + 1
        };
      }
      return p;
    }));
  }

  function handleAddComment(e, postId) {
    e.preventDefault();
    setPosts(prev => prev.map(p => {
      if (p.id === postId) {
        if (!p.newComment.trim()) return p;
        const updatedComments = [...p.comments, { name: 'Khánh Linh', text: p.newComment }];
        setTimeout(() => {
          alert(lang === 'en' 
            ? 'Comment posted! You earned +50 EXP and +5 Coins.'
            : 'Đã đăng bình luận! Bạn nhận được +50 EXP và +5 Coins.');
        }, 100);
        return {
          ...p,
          comments: updatedComments,
          newComment: ''
        };
      }
      return p;
    }));
  }

  function handleCommentInputChange(postId, val) {
    setPosts(prev => prev.map(p => {
      if (p.id === postId) {
        return { ...p, newComment: val };
      }
      return p;
    }));
  }

  // Trigger matching challenge
  function triggerInvite(userId) {
    const foundUser = MOCK_USERS.find(u => u.id === userId);
    if (!foundUser) return;
    setTargetMatch(foundUser);
    setShowMission(true);
  }

  return (
    <div style={{ padding: '1.5rem 1.5rem', maxWidth: 1100, margin: '0 auto', minHeight: '85vh' }}>

      {/* Page Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.5rem' }} className="animate-fade-in">
        <div>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, letterSpacing: '-.02em' }}>
            {lang === 'en' ? 'Blush Gaming Hub' : 'Sảnh Cộng Đồng Blush'}
          </h1>
          <p style={{ color: 'var(--text-muted)', fontSize: '.82rem', marginTop: '.2rem' }}>
            {lang === 'en' ? 'Zone AoV - Comedy Club' : 'Phân khu Liên Quân - Hội Tấu Hài'}
            <span style={{ marginLeft: '.5rem' }}>·</span>
            <span style={{ marginLeft: '.5rem', color: 'var(--cyan)', fontWeight: 600 }}>🟢 {MOCK_USERS.length * 40} {t('feed.matchesCount')}</span>
          </p>
        </div>
        <div style={{ display: 'flex', gap: '.5rem', alignItems: 'center' }}>
          <button className="btn btn-outline btn-sm" style={{ gap: '.4rem' }} onClick={() => alert(lang === 'en' ? 'Zone lobbies refreshed.' : 'Đã đồng bộ lại sảnh nhóm.')}>
            <RefreshCw size={13}/> {t('feed.refresh')}
          </button>
          {!isVip && (
            <button className="btn btn-soft btn-sm" onClick={onUpgrade} style={{ gap: '.4rem' }}>
              <Crown size={13} style={{ color: '#FFB703' }}/> {t('feed.vip')}
            </button>
          )}
        </div>
      </div>

      {/* Main split layout */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: '2rem' }} className="responsive-profile">
        
        {/* LEFT COLUMN: Main Chat Room / Social Feed / Mission Challenge */}
        <div>
          {showMission && targetMatch ? (
            <div style={{ marginBottom: '2rem' }}>
              <MissionRoom 
                match={targetMatch} 
                onMissionComplete={() => onChat(targetMatch)} 
                t={t} 
                lang={lang} 
                onCancel={() => { setShowMission(false); setTargetMatch(null); }}
              />
            </div>
          ) : (
            <>
              {/* Tab selector */}
              <div style={{ display: 'flex', background: 'rgba(255,255,255,0.03)', borderRadius: 'var(--radius-lg)', padding: '.25rem', marginBottom: '1.25rem', border: '1px solid var(--border-soft)' }}>
                <button 
                  onClick={() => setActiveTab('chat')} 
                  style={{
                    flex: 1, padding: '.6rem', borderRadius: 'var(--radius-md)', fontSize: '.84rem', fontWeight: 700, transition: 'var(--tr)',
                    background: activeTab === 'chat' ? 'var(--surface-3)' : 'transparent',
                    color: activeTab === 'chat' ? 'var(--cyan)' : 'var(--text-secondary)',
                    border: activeTab === 'chat' ? '1px solid rgba(0,245,255,.15)' : '1px solid transparent'
                  }}
                >
                  💬 {lang === 'en' ? 'Lobby Chat Room' : 'Sảnh Chat Lập Nhóm'}
                </button>
                <button 
                  onClick={() => setActiveTab('feed')} 
                  style={{
                    flex: 1, padding: '.6rem', borderRadius: 'var(--radius-md)', fontSize: '.84rem', fontWeight: 700, transition: 'var(--tr)',
                    background: activeTab === 'feed' ? 'var(--surface-3)' : 'transparent',
                    color: activeTab === 'feed' ? 'var(--cyan)' : 'var(--text-secondary)',
                    border: activeTab === 'feed' ? '1px solid rgba(0,245,255,.15)' : '1px solid transparent'
                  }}
                >
                  📱 {lang === 'en' ? 'Gaming Social Feed' : 'Bảng Tin Mạng Xã Hội'}
                </button>
              </div>

              {/* 💬 TAB: Group Lobby Chat */}
              {activeTab === 'chat' && (
                <div className="card animate-fade-in" style={{ border: '1px solid var(--border-soft)', display: 'flex', flexDirection: 'column', height: '560px', overflow: 'hidden' }}>
                  
                  {/* Pinned AI Discussion banner */}
                  <div style={{ padding: '.75rem 1.25rem', background: 'linear-gradient(90deg, rgba(157,78,221,0.15), rgba(0,245,255,0.08))', borderBottom: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', gap: '.65rem' }}>
                    <span style={{ fontSize: '1.25rem' }}>🤖</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '.68rem', fontWeight: 800, color: 'var(--cyan)', textTransform: 'uppercase', letterSpacing: '.05em' }}>AI Daily Discussion Trigger</div>
                      <div style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                        {lang === 'en' 
                          ? 'What is your go-to song to sing in voice chat while carrying the team?'
                          : 'Bài hát tủ của bạn khi hát trong voice chat gánh team Liên Quân là gì?'}
                      </div>
                    </div>
                    <span className="badge badge-purple" style={{ fontSize: '.65rem' }}>🎁 +50 EXP</span>
                  </div>

                  {/* Chat messages viewport */}
                  <div style={{ flex: 1, padding: '1.25rem', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {chatMessages.map((msg) => {
                      const isMe = msg.user === 'Khánh Linh';
                      return (
                        <div key={msg.id} style={{ display: 'flex', gap: '.75rem', alignItems: 'flex-start', alignSelf: isMe ? 'flex-end' : 'flex-start', maxWidth: '85%' }}>
                          {!isMe && (
                            <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyItems: 'center', justifyContent: 'center', fontSize: '1.1rem', flexShrink: 0 }}>
                              {msg.avatar}
                            </div>
                          )}
                          <div>
                            <div style={{ display: 'flex', alignItems: 'baseline', gap: '.4rem', marginBottom: '.15rem', justifyContent: isMe ? 'flex-end' : 'flex-start' }}>
                              <span style={{ fontSize: '.78rem', fontWeight: 800, color: isMe ? 'var(--cyan)' : 'var(--text-primary)' }}>{msg.user}</span>
                              <span style={{ fontSize: '.65rem', padding: '.1rem .4rem', borderRadius: 99, background: 'rgba(255,255,255,0.05)', color: 'var(--text-muted)', fontWeight: 600 }}>{msg.role}</span>
                              <span style={{ fontSize: '.6rem', color: 'var(--text-muted)' }}>{msg.time}</span>
                            </div>
                            
                            <div style={{
                              padding: '.75rem 1rem', borderRadius: '14px', fontSize: '.84rem', lineHeight: 1.45,
                              background: isMe ? 'var(--grad-brand)' : 'var(--surface-2)',
                              color: isMe ? '#0A0516' : 'var(--text-primary)',
                              fontWeight: isMe ? 600 : 400,
                              border: isMe ? 'none' : '1px solid var(--border-soft)',
                              borderTopLeftRadius: !isMe ? '0px' : '14px',
                              borderTopRightRadius: isMe ? '0px' : '14px',
                            }}>
                              {msg.text}
                              
                              {/* Party invite button */}
                              {msg.recruitment && !isMe && (
                                <div style={{ marginTop: '.65rem', paddingTop: '.65rem', borderTop: '1px solid rgba(255,255,255,0.08)', display: 'flex', justifyItems: 'center', justifyContent: 'space-between', alignItems: 'center' }}>
                                  <span style={{ fontSize: '.68rem', color: 'var(--cyan)', fontWeight: 700 }}>⚡ LẬP TỔ ĐỘI NGAY</span>
                                  <button 
                                    onClick={() => triggerInvite(msg.userId)}
                                    className="btn btn-primary btn-sm" 
                                    style={{ padding: '.25rem .75rem', fontSize: '.7rem', fontWeight: 800, background: '#00F5FF', color: '#0A0516', border: 'none' }}
                                  >
                                    ⚔️ Ghép Đội
                                  </button>
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                    <div ref={chatEndRef} />
                  </div>

                  {/* Input form */}
                  <form onSubmit={handleSendChatMessage} style={{ padding: '1rem', borderTop: '1px solid var(--border-soft)', display: 'flex', gap: '.5rem', background: 'var(--surface-2)' }}>
                    <input 
                      type="text" 
                      placeholder={lang === 'en' ? 'Type message or paste lobby recruitment links...' : 'Nhập tin nhắn rủ chơi game, cướp rừng, tấu hài...'} 
                      value={chatInput}
                      onChange={e => setChatInput(e.target.value)}
                      className="input" 
                      style={{ flex: 1, fontSize: '.84rem' }}
                    />
                    <button type="submit" className="btn btn-primary" style={{ padding: '0 1rem', background: 'var(--grad-brand)', border: 'none', color: '#0A0516' }}>
                      <Send size={15} />
                    </button>
                  </form>
                </div>
              )}

              {/* 📱 TAB: Gaming Social Feed */}
              {activeTab === 'feed' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }} className="animate-fade-in">
                  
                  {/* Create Post Card */}
                  <div className="card" style={{ padding: '1.25rem', border: '1px solid var(--border-soft)' }}>
                    <form onSubmit={handleCreatePost}>
                      <textarea
                        placeholder={lang === 'en' ? "Flex your win streaks, MVP screens, or off-meta builds here..." : "Chia sẻ giáo án độc lạ, chuỗi thắng rank, MVP hoặc highlight của bạn để nhận EXP..."}
                        value={postInput}
                        onChange={e => setPostInput(e.target.value)}
                        className="input"
                        style={{ width: '100%', minHeight: 70, resize: 'none', fontSize: '.84rem', padding: '.75rem', marginBottom: '.75rem' }}
                      />
                      <div style={{ display: 'flex', justifyItems: 'center', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', gap: '.5rem', color: 'var(--text-muted)' }}>
                          <button type="button" onClick={() => alert('Feature simulated!')} className="btn btn-ghost btn-sm" style={{ padding: '.35rem', color: 'var(--text-secondary)' }}><Image size={16}/> <span style={{ fontSize: '.75rem', marginLeft: '.3rem' }}>Photo</span></button>
                        </div>
                        <button type="submit" className="btn btn-primary btn-sm" style={{ background: 'var(--grad-brand)', border: 'none', color: '#0A0516', fontWeight: 800 }}>
                          <Plus size={14}/> {lang === 'en' ? 'Share Education Post' : 'Chia sẻ giáo án'}
                        </button>
                      </div>
                    </form>
                  </div>

                  {/* Posts feed list */}
                  {posts.map(post => (
                    <div key={post.id} className="card" style={{ padding: '1.25rem', border: '1px solid var(--border-soft)' }}>
                      {/* Post Header */}
                      <div style={{ display: 'flex', gap: '.65rem', alignItems: 'center', marginBottom: '.85rem' }}>
                        <div style={{ width: 36, height: 36, borderRadius: '50%', background: post.avatarBg, display: 'flex', alignItems: 'center', justifyItems: 'center', justifyContent: 'center', fontSize: '1.1rem', border: '1.5px solid #fff' }}>
                          {post.avatar}
                        </div>
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '.35rem' }}>
                            <span style={{ fontSize: '.84rem', fontWeight: 800 }}>{post.author}</span>
                            <span className="badge" style={{ fontSize: '.6rem', background: 'rgba(255,255,255,0.05)', color: 'var(--text-muted)', fontWeight: 600 }}>{post.role}</span>
                          </div>
                          <span style={{ fontSize: '.68rem', color: 'var(--text-muted)' }}>Active in Zone</span>
                        </div>
                      </div>

                      {/* Post Content */}
                      <p style={{ fontSize: '.88rem', color: 'var(--text-primary)', lineHeight: 1.5, marginBottom: '1rem' }}>
                        {post.text}
                      </p>

                      {/* Simulated Game Highlight Box */}
                      {post.hasImg && (
                        <div style={{ borderRadius: 'var(--radius-lg)', background: 'linear-gradient(135deg, #1D143A, #2A144E)', border: '1px solid var(--border)', height: 160, marginBottom: '1rem', display: 'flex', alignItems: 'center', justifyItems: 'center', justifyContent: 'center', position: 'relative', overflow: 'hidden' }}>
                          <span style={{ fontSize: '4rem', opacity: 0.15 }}>⚡</span>
                          <div style={{ position: 'absolute', top: 12, right: 12, background: 'var(--success)', color: '#0A0516', fontSize: '.68rem', fontWeight: 800, padding: '.2rem .6rem', borderRadius: 99 }}>WIN STREAK 20</div>
                          <div style={{ position: 'absolute', bottom: 12, left: 12, right: 12, display: 'flex', justifyItems: 'center', justifyContent: 'space-between', alignItems: 'baseline' }}>
                            <span style={{ fontSize: '.9rem', fontWeight: 900 }}>NAKROTH HIGHLIGHTS</span>
                            <span style={{ fontSize: '.68rem', color: 'var(--text-secondary)' }}>Arena of Valor</span>
                          </div>
                        </div>
                      )}

                      {/* Post Footer likes / comment triggers */}
                      <div style={{ display: 'flex', gap: '1.25rem', borderTop: '1px solid var(--border-soft)', paddingTop: '.75rem', marginBottom: '.75rem' }}>
                        <button 
                          onClick={() => handleLikePost(post.id)}
                          style={{ background: 'transparent', color: post.liked ? 'var(--cyan)' : 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '.35rem', fontSize: '.78rem', fontWeight: 700 }}
                        >
                          <ThumbsUp size={14}/> {post.likes} Likes
                        </button>
                        <span style={{ color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '.35rem', fontSize: '.78rem' }}>
                          <MessageCircle size={14}/> {post.comments.length} Comments
                        </span>
                      </div>

                      {/* Comments feed list */}
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '.5rem', background: 'var(--surface-2)', padding: '.75rem', borderRadius: 'var(--radius-md)', marginBottom: '1rem' }}>
                        {post.comments.length === 0 ? (
                          <span style={{ fontSize: '.76rem', color: 'var(--text-muted)' }}>No comments yet. Post strategy thoughts to earn points!</span>
                        ) : (
                          post.comments.map((comment, cIdx) => (
                            <div key={cIdx} style={{ fontSize: '.78rem', lineHeight: 1.4 }}>
                              <strong style={{ color: 'var(--cyan)', marginRight: '.3rem' }}>{comment.name}:</strong> 
                              <span style={{ color: 'var(--text-secondary)' }}>{comment.text}</span>
                            </div>
                          ))
                        )}
                      </div>

                      {/* Add comment form */}
                      <form onSubmit={(e) => handleAddComment(e, post.id)} style={{ display: 'flex', gap: '.4rem' }}>
                        <input
                          type="text"
                          placeholder={lang === 'en' ? "Write a helpful strategy comment..." : "Góp ý chiến thuật hữu ích để nhận +50 EXP..."}
                          value={post.newComment}
                          onChange={(e) => handleCommentInputChange(post.id, e.target.value)}
                          className="input"
                          style={{ flex: 1, fontSize: '.78rem', padding: '.45rem' }}
                        />
                        <button type="submit" className="btn btn-outline btn-sm" style={{ padding: '0 .75rem' }}>
                          <MessageSquare size={13}/>
                        </button>
                      </form>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}
        </div>

        {/* ── RIGHT COLUMN: ONLINE USERS & LEADERBOARD ── */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          
          {/* Active online members sidebar */}
          <div className="card" style={{ padding: '1.25rem', border: '1px solid var(--border-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem' }}>
                <Users size={16} style={{ color: 'var(--cyan)' }} />
                <h3 style={{ fontWeight: 800, fontSize: '.9rem', color: '#FFF' }}>
                  {lang === 'en' ? 'Gamers Online' : 'Game thủ online'}
                </h3>
              </div>
              <span className="badge badge-success" style={{ fontSize: '.68rem' }}>{MOCK_USERS.length} online</span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '.85rem' }}>
              {MOCK_USERS.map((gamer) => (
                <div key={gamer.id} style={{ display: 'flex', items: 'center', justifyItems: 'center', justifyContent: 'space-between', gap: '.5rem', borderBottom: '1px solid rgba(255,255,255,0.03)', paddingBottom: '.5rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '.45rem' }}>
                    <div style={{ width: 28, height: 28, borderRadius: '50%', background: gamer.avatarBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.8rem', flexShrink: 0 }}>
                      {gamer.avatar}
                    </div>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '.3rem' }}>
                        <span style={{ fontSize: '.78rem', fontWeight: 800, color: 'var(--text-primary)' }}>{gamer.name}</span>
                        {gamer.isVip && <span style={{ fontSize: '.58rem', background: '#FFB703', color: '#0A0516', borderRadius: '3px', padding: '1px 3px', fontWeight: 800 }}>VIP</span>}
                      </div>
                      <div style={{ fontSize: '.65rem', color: 'var(--text-muted)', display: 'flex', gap: '.3rem', flexWrap: 'wrap' }}>
                        <span>Lvl {gamer.level}</span>
                        <span>•</span>
                        <span style={{ color: 'var(--cyan)' }}>{gamer.interests[2] || 'Lane'}</span>
                      </div>
                    </div>
                  </div>

                  <button 
                    onClick={() => triggerInvite(gamer.id)}
                    className="btn btn-outline btn-sm" 
                    style={{ fontSize: '.7rem', padding: '.2rem .55rem', borderColor: 'var(--pink)', color: 'var(--pink)' }}
                  >
                    ⚔️ Rủ Chơi
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Local Leaderboard Gamification */}
          <div className="card" style={{ padding: '1.25rem', border: '1px solid var(--border-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem', marginBottom: '1rem' }}>
              <Award size={16} style={{ color: '#FFB703' }} />
              <h3 style={{ fontWeight: 800, fontSize: '.9rem' }}>
                {lang === 'en' ? 'Local Zone Leaderboard' : 'Bảng Xếp Hạng Phân Khu'}
              </h3>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '.6rem' }}>
              {[
                { rank: 1, name: 'Minh Tú', level: 28, exp: 4200, avatar: '⚔️', me: false },
                { rank: 2, name: 'Yến Nhi', level: 21, exp: 3100, avatar: '🌿', me: false },
                { rank: 3, name: 'Khánh An', level: 19, exp: 2800, avatar: '🧙‍♂️', me: false },
                { rank: 4, name: 'Linh Nguyễn', level: 12, exp: 1250, avatar: '🌸', me: false },
                { rank: 5, name: 'Khánh Linh', level: 12, exp: 1250, avatar: '🌸', me: true },
              ].map((gamer, gIdx) => (
                <div key={gIdx} style={{
                  display: 'flex', alignItems: 'center', justifyItems: 'center', justifyContent: 'space-between',
                  padding: '.35rem .5rem', borderRadius: '8px',
                  background: gamer.me ? 'rgba(0,245,255,0.06)' : 'transparent',
                  border: gamer.me ? '1px solid rgba(0,245,255,0.15)' : '1px solid transparent'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem' }}>
                    <span style={{
                      fontWeight: 900, fontSize: '.76rem',
                      color: gamer.rank === 1 ? '#FFB703' : (gamer.rank === 2 ? '#C0C0C0' : (gamer.rank === 3 ? '#CD7F32' : 'var(--text-muted)')),
                      width: '18px'
                    }}>
                      #{gamer.rank}
                    </span>
                    <div style={{ width: 22, height: 22, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.75rem' }}>
                      {gamer.avatar}
                    </div>
                    <span style={{ fontSize: '.78rem', fontWeight: gamer.me ? 800 : 500, color: gamer.me ? 'var(--cyan)' : 'var(--text-primary)' }}>
                      {gamer.name}
                    </span>
                  </div>
                  <div style={{ fontSize: '.72rem', fontWeight: 700, color: 'var(--text-secondary)' }}>
                    Lvl {gamer.level}
                  </div>
                </div>
              ))}
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
