import React, { useState, useRef, useEffect } from 'react';
import { Send, Sparkles, Zap, ChevronLeft, Lock, Crown, Flag, Heart } from 'lucide-react';
import { MOCK_CHAT_EN, MOCK_CHAT_VI, AI_STARTERS, MOCK_ICEBREAKERS } from '../../data/mockData';

const BOT_REPLIES_EN = [
  'Yeah absolutely! Same here 😊 let\'s play another match',
  'Really? What rank are you in Valorant?',
  'Haha I totally get that feeling, gaming with randoms is tough 😂',
  'Oh interesting! I usually build Mavuika with energy recharge relics ✨',
  'I do that too! Let\'s lobby up next Saturday 🎮',
  '👀 You just said exactly what our strategy should be!',
];

const BOT_REPLIES_VI = [
  'Ừ đúng rồi! Mình cũng vậy 😊 làm trận nữa đi',
  'Thật à? Bạn đang rank gì bên Valorant thế?',
  'Haha mình hiểu cảm giác đó, leo rank đơn cực lắm 😂',
  'Ồ thú vị! Mình hay build Mavuika theo hướng nạp năng lượng ✨',
  'Mình cũng hay vậy! Thứ 7 tuần này lập party cày nha 🎮',
  '👀 Bạn vừa nói đúng chiến thuật đi lane mình đang nghĩ luôn!',
];

function DeadChatBanner({ onUse, suggestions, t }) {
  const [dismissed, setDismissed] = useState(false);

  if (dismissed) return null;
  return (
    <div style={{ margin: '.5rem 0', padding: '1rem', background: 'var(--pink-pastel)', borderRadius: 'var(--radius-lg)', border: '1px dashed rgba(0, 245, 255, 0.3)', animation: 'fadeInUp .3s ease' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem', marginBottom: '.6rem' }}>
        <Sparkles size={14} style={{ color: 'var(--cyan)' }}/>
        <span style={{ fontSize: '.78rem', fontWeight: 700, color: 'var(--cyan)' }}>{t('chat.deadChatTitle')}</span>
      </div>
      <div style={{ display: 'flex', gap: '.4rem', flexWrap: 'wrap' }}>
        {suggestions.map((s, i) => (
          <button key={i} onClick={() => { onUse(s); setDismissed(true); }} style={{
            padding: '.35rem .75rem', borderRadius: 99, fontSize: '.78rem',
            background: 'var(--surface)', border: '1px solid rgba(0, 245, 255, 0.25)',
            color: 'var(--cyan)', cursor: 'pointer', transition: 'var(--tr)',
          }}>
            {s}
          </button>
        ))}
        <button onClick={() => setDismissed(true)} style={{ marginLeft: 'auto', fontSize: '.72rem', color: 'var(--text-muted)', background: 'none', border: 'none', cursor: 'pointer' }}>{t('chat.dismiss')}</button>
      </div>
    </div>
  );
}

export default function ChatRoom({ match, isVip, onBack, onUpgrade, t, lang }) {
  const [messages, setMessages] = useState(lang === 'en' ? MOCK_CHAT_EN : MOCK_CHAT_VI);
  const [input, setInput] = useState('');
  const [showStarters, setShowStarters] = useState(false);
  const [iceActive, setIceActive] = useState(false);
  const [iceAnswer, setIceAnswer] = useState(null);
  const [showDeadChat, setShowDeadChat] = useState(false);
  const [showAiAnalysis, setShowAiAnalysis] = useState(false);
  const [showReportModal, setShowReportModal] = useState(false);
  const [reportReason, setReportReason] = useState('');
  const [reportSubmitted, setReportSubmitted] = useState(false);
  const bottomRef = useRef(null);

  const myMsgCount = messages.filter(m => m.from === 'me').length;
  const blurLevel = isVip ? 0 : Math.max(0, 14 - myMsgCount * 2.5);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    if (myMsgCount === 3 && !showDeadChat) {
      const timer = setTimeout(() => setShowDeadChat(true), 2000);
      return () => clearTimeout(timer);
    }
  }, [myMsgCount]);

  function send(text) {
    if (!text.trim()) return;
    const ts = new Date().toLocaleTimeString('vi', { hour: '2-digit', minute: '2-digit' });
    setMessages(prev => [...prev, { id: Date.now(), from: 'me', text, time: ts }]);
    setInput('');
    setShowStarters(false);
    setShowDeadChat(false);

    setTimeout(() => {
      const replies = lang === 'en' ? BOT_REPLIES_EN : BOT_REPLIES_VI;
      const reply = replies[Math.floor(Math.random() * replies.length)];
      setMessages(prev => [...prev, { id: Date.now() + 1, from: 'them', text: reply, time: new Date().toLocaleTimeString('vi', { hour: '2-digit', minute: '2-digit' }) }]);
    }, 800 + Math.random() * 500);
  }

  const iceQ = MOCK_ICEBREAKERS.find(q => q.active);
  const iceOptions = lang === 'en'
    ? ['Focus on Objectives! 🏆', 'Duo coordination! 🤝', 'Play casual & chill! 🌸', 'Depends on game context! 🛡️']
    : ['Tập trung mục tiêu! 🏆', 'Phối hợp nhịp nhàng! 🤝', 'Cày chill vui vẻ! 🌸', 'Tùy tình huống game! 🛡️'];

  const deadChatSuggestions = AI_STARTERS.slice(2, 4).map(s => lang === 'en' ? s.en : s.vi);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', maxWidth: 680, margin: '0 auto', background: 'var(--surface)' }}>

      {/* Header */}
      <div style={{ padding: '1rem 1.5rem', background: 'rgba(20,14,40,0.92)', backdropFilter: 'blur(16px)', borderBottom: '1px solid rgba(157,78,221,0.25)', display: 'flex', alignItems: 'center', gap: '1rem', flexShrink: 0 }}>
        <button className="btn btn-ghost btn-icon" onClick={onBack}>
          <ChevronLeft size={20} style={{ color: 'var(--text-primary)' }}/>
        </button>
        <div style={{
          width: 42, height: 42, borderRadius: '50%',
          background: match.avatarBg,
          display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.2rem',
          filter: `blur(${blurLevel}px)`, transition: 'filter .5s ease',
          flexShrink: 0, border: '2px solid rgba(255,255,255,.2)',
          boxShadow: 'var(--shadow-sm)',
        }}>
          {match.avatar}
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 700, fontSize: '1rem', color: '#FFF' }}>
            {blurLevel > 0 ? 'Lobby Teammate' : match.name}
          </div>
          <div style={{ fontSize: '.73rem', color: 'var(--success)', display: 'flex', alignItems: 'center', gap: '.3rem' }}>
            <div style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--success)' }}/> {t('chat.online')} · {match.compatibility}% {t('chat.comp')}
          </div>
        </div>
        <div style={{ display: 'flex', gap: '.4rem', alignItems: 'center' }}>
          <button 
            onClick={() => setShowAiAnalysis(true)} 
            style={{ 
              background: 'rgba(0, 245, 255, 0.1)', 
              border: '1px solid rgba(0, 245, 255, 0.25)', 
              borderRadius: '8px', 
              padding: '.35rem .6rem', 
              color: 'var(--cyan)', 
              fontSize: '.72rem', 
              fontWeight: 700, 
              display: 'flex', 
              alignItems: 'center', 
              gap: '.25rem', 
              cursor: 'pointer' 
            }}
            title={lang === 'en' ? 'View AI matchmaking reasons' : 'Xem lý do ghép cặp của AI'}
          >
            <Sparkles size={11} />
            <span>{lang === 'en' ? 'AI Analysis' : 'Lý do AI'}</span>
          </button>

          <button 
            onClick={() => setShowReportModal(true)} 
            style={{ 
              background: 'rgba(239, 68, 68, 0.1)', 
              border: '1px solid rgba(239, 68, 68, 0.25)', 
              borderRadius: '8px', 
              padding: '.35rem .6rem', 
              color: 'var(--danger)', 
              fontSize: '.72rem', 
              fontWeight: 700, 
              display: 'flex', 
              alignItems: 'center', 
              gap: '.25rem', 
              cursor: 'pointer' 
            }}
            title={lang === 'en' ? 'Report toxicity' : 'Báo cáo toxic'}
          >
            <Flag size={11} />
          </button>

          {!isVip && blurLevel > 0 && (
            <span className="badge" style={{ background: 'rgba(157,78,221,0.15)', color: 'var(--pink-light)', fontSize: '.68rem', border: '1px solid rgba(157,78,221,0.3)' }}>
              <Lock size={10}/> {lang === 'en' ? 'Card Hidden' : 'Thẻ ẩn'}
            </span>
          )}
          {!isVip && (
            <button className="btn btn-soft btn-sm" onClick={onUpgrade} style={{ gap: '.3rem' }}>
              <Crown size={12} style={{ color: '#FFB703' }}/> {t('feed.vip')}
            </button>
          )}
        </div>

      </div>

      {/* Blur unlock bar */}
      {!isVip && (
        <div style={{ padding: '.5rem 1.5rem', background: 'rgba(157,78,221,0.15)', borderBottom: '1px solid rgba(157,78,221,0.25)', display: 'flex', alignItems: 'center', gap: '.75rem', flexShrink: 0 }}>
          <Lock size={12} style={{ color: 'var(--cyan)', flexShrink: 0 }}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: '.7rem', color: 'var(--text-secondary)', marginBottom: '.2rem' }}>
              {t('chat.unlockProgress', Math.max(0, 6 - myMsgCount))} · <button onClick={onUpgrade} style={{ background: 'none', border: 'none', color: 'var(--cyan)', fontWeight: 700, cursor: 'pointer', fontSize: '.7rem', padding: 0 }}>{t('chat.unlockVipLink')}</button>
            </div>
            <div className="progress-bar" style={{ height: 3 }}>
              <div className="progress-fill" style={{ width: `${Math.min(100, (myMsgCount / 6) * 100)}%` }}/>
            </div>
          </div>
        </div>
      )}

      {/* Messages */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '1.25rem 1.5rem', display: 'flex', flexDirection: 'column', gap: '.15rem', background: 'rgba(10,5,22,0.5)' }}>

        {/* AI Starters (first open) */}
        {messages.length <= 3 && (
          <div className="animate-fade-in" style={{ textAlign: 'center', padding: '1.25rem', background: 'rgba(157,78,221,0.08)', borderRadius: 'var(--radius-lg)', border: '1px dashed rgba(157,78,221,0.25)', marginBottom: '.75rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '.4rem', marginBottom: '.5rem' }}>
              <Sparkles size={14} style={{ color: 'var(--cyan)' }}/>
              <span style={{ fontSize: '.8rem', fontWeight: 700, color: 'var(--cyan)' }}>{t('chat.starterTitle')}</span>
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '.82rem', marginBottom: '.75rem' }}>
              {t('chat.starterDesc', match.compatibility)}
            </p>
            <div style={{ display: 'flex', gap: '.4rem', flexWrap: 'wrap', justifyContent: 'center' }}>
              {AI_STARTERS.slice(0, 3).map((s, i) => {
                const starterText = lang === 'en' ? s.en : s.vi;
                return (
                  <button key={i} onClick={() => send(starterText)} style={{
                    padding: '.38rem .8rem', borderRadius: 99, fontSize: '.78rem',
                    background: 'var(--surface)', border: '1px solid rgba(0, 245, 255, 0.25)',
                    color: 'var(--text-secondary)', cursor: 'pointer', transition: 'var(--tr)',
                  }}
                  onMouseEnter={e => { e.target.style.borderColor = 'var(--cyan)'; e.target.style.color = 'var(--cyan)'; }}
                  onMouseLeave={e => { e.target.style.borderColor = 'rgba(0, 245, 255, 0.25)'; e.target.style.color = 'var(--text-secondary)'; }}
                  >
                    {starterText}
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {messages.map(m => (
          <div key={m.id} className={`bubble-wrap ${m.from === 'me' ? 'me' : ''}`}>
            {m.from === 'them' && (
              <div style={{ width: 26, height: 26, borderRadius: '50%', background: match.avatarBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.8rem', flexShrink: 0, filter: `blur(${Math.max(0,blurLevel-4)}px)` }}>
                {match.avatar}
              </div>
            )}
            <div>
              <div className={`bubble ${m.from}`} style={{
                background: m.from === 'me' ? 'var(--grad-brand)' : 'var(--surface-2)',
                color: m.from === 'me' ? '#0A0516' : 'var(--text-primary)',
                fontWeight: m.from === 'me' ? 700 : 400,
                border: m.from === 'them' ? '1px solid var(--border-soft)' : 'none'
              }}>{m.text}</div>
              <div style={{ fontSize: '.65rem', color: 'var(--text-muted)', marginTop: '.15rem', padding: '0 .25rem', textAlign: m.from === 'me' ? 'right' : 'left' }}>{m.time}</div>
            </div>
          </div>
        ))}

        {/* Dead chat AI banner */}
        {showDeadChat && <DeadChatBanner onUse={send} suggestions={deadChatSuggestions} t={t} />}

        {/* Ice-breaker game */}
        {iceActive && (
          <div className="animate-scale-in" style={{ margin: '.5rem 0', padding: '1.25rem', background: 'rgba(0, 245, 255, 0.08)', borderRadius: 'var(--radius-xl)', border: '1px solid rgba(0, 245, 255, 0.25)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem', marginBottom: '.85rem' }}>
              <Zap size={15} style={{ color: 'var(--cyan)' }}/>
              <span style={{ fontSize: '.8rem', fontWeight: 700, color: 'var(--cyan)' }}>{t('chat.iceTitle')}</span>
            </div>
            <p style={{ fontWeight: 600, fontSize: '.9rem', marginBottom: '1rem', color: 'var(--text-primary)' }}>❓ {lang === 'en' ? iceQ?.question_en : iceQ?.question_vi}</p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '.5rem' }}>
              {iceOptions.map((opt, i) => (
                <button key={i} onClick={() => { setIceAnswer(i); }} style={{
                  padding: '.6rem .75rem', borderRadius: 'var(--radius-md)', fontSize: '.8rem', fontWeight: 500,
                  background: iceAnswer === i ? 'rgba(0, 245, 255, 0.15)' : 'var(--surface)',
                  border: `1.5px solid ${iceAnswer === i ? 'var(--cyan)' : 'var(--border-soft)'}`,
                  color: iceAnswer === i ? 'var(--cyan)' : 'var(--text-secondary)',
                  cursor: 'pointer', transition: 'var(--tr)', textAlign: 'left',
                }}>
                  {opt}
                </button>
              ))}
            </div>
            {iceAnswer !== null && (
              <p style={{ marginTop: '.75rem', fontSize: '.78rem', color: 'var(--success)', textAlign: 'center' }}>
                {t('chat.iceResponded')}
              </p>
            )}
          </div>
        )}

        <div ref={bottomRef}/>
      </div>

      {/* AI suggestion strip */}
      {showStarters && (
        <div style={{ padding: '.6rem 1.25rem', background: 'rgba(157,78,221,0.12)', borderTop: '1px solid rgba(157,78,221,0.25)', display: 'flex', gap: '.4rem', flexWrap: 'wrap' }}>
          {AI_STARTERS.map((s, i) => {
            const text = lang === 'en' ? s.en : s.vi;
            return (
              <button key={i} onClick={() => send(text)} style={{
                padding: '.3rem .7rem', borderRadius: 99, fontSize: '.75rem',
                background: 'var(--surface)', border: '1px solid rgba(0, 245, 255, 0.25)',
                color: 'var(--cyan)', cursor: 'pointer',
              }}>{text}</button>
            );
          })}
        </div>
      )}

      {/* Input bar */}
      <div style={{ padding: '.9rem 1.25rem', background: 'rgba(20,14,40,0.95)', borderTop: '1px solid rgba(157,78,221,0.25)', display: 'flex', gap: '.6rem', alignItems: 'center', flexShrink: 0 }}>
        <button className="btn btn-outline btn-icon btn-sm" onClick={() => setShowStarters(s => !s)} title={t('chat.starterInputTip')} style={{ borderColor: showStarters ? 'var(--cyan)' : 'var(--border-soft)', color: showStarters ? 'var(--cyan)' : 'var(--text-muted)' }}>
          <Sparkles size={16}/>
        </button>
        <button className="btn btn-outline btn-icon btn-sm" onClick={() => setIceActive(v => !v)} title={t('chat.icebreakerInputTip')} style={{ borderColor: iceActive ? 'var(--cyan)' : 'var(--border-soft)', color: iceActive ? 'var(--cyan)' : 'var(--text-muted)' }}>
          <Zap size={16}/>
        </button>
        <input className="input" style={{ flex: 1 }} placeholder={t('chat.placeholder')} value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && send(input)}/>
        <button className="btn btn-primary btn-icon btn-sm" onClick={() => send(input)} disabled={!input.trim()} style={{ background: 'var(--grad-brand)', border: 'none', color: '#0A0516' }}>
          <Send size={16}/>
        </button>
      </div>

      {/* AI Compatibility Analysis Modal */}
      {showAiAnalysis && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 100, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem', backdropFilter: 'blur(4px)' }}>
          <div className="card" style={{ padding: '2rem', maxWidth: '480px', width: '100%', border: '1px solid var(--border-soft)', position: 'relative' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', marginBottom: '1.25rem' }}>
              <Sparkles size={20} style={{ color: 'var(--cyan)' }} />
              <h3 style={{ fontSize: '1.2.rem', fontWeight: 800, color: '#FFF' }}>
                {lang === 'en' ? 'AI Matching Analysis' : 'Phân tích so khớp AI'}
              </h3>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', fontSize: '.84rem', lineHeight: 1.5, color: 'var(--text-secondary)' }}>
              <div>
                <div style={{ fontWeight: 700, color: 'var(--cyan)', marginBottom: '.2rem' }}>🧠 Mức độ tương thích: {match.compatibility}%</div>
                <div>Được tính toán dựa trên dữ liệu hành vi, vị trí chơi và khảo sát tính cách.</div>
              </div>
              <div style={{ borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '.8rem' }}>
                <div style={{ fontWeight: 700, color: '#FFF', marginBottom: '.2rem' }}>🎭 Phân tích tâm lý (MBTI)</div>
                <div>Bạn là <strong>INFJ</strong> và đồng đội là <strong>{match.mbti || 'ENFP'}</strong>. Nhóm tính cách này bổ trợ rất tốt: một người trầm tĩnh call chiến thuật và một người năng động giữ lửa tinh thần party.</div>
              </div>
              <div style={{ borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '.8rem' }}>
                <div style={{ fontWeight: 700, color: '#FFF', marginBottom: '.2rem' }}>🎮 Phối hợp vị trí trong trận</div>
                <div>Bạn chơi <strong>Đường Giữa (Mid)</strong> và đối phương chơi <strong>Đường Rừng (Jungle)</strong>. Đây là cặp đôi vàng để roam-gank bản đồ, tạo lợi thế sớm cho team.</div>
              </div>
              <div style={{ borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '.8rem' }}>
                <div style={{ fontWeight: 700, color: 'var(--success)', marginBottom: '.2rem' }}>🛡️ Chỉ số an toàn (Anti-Toxic Shield)</div>
                <div>Người chơi này có <strong>99% điểm an toàn</strong>. Chat log lịch sử không chứa từ khóa độc hại, không có tiền sử phá trận hay bị cảnh cáo.</div>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1.5rem' }}>
              <button onClick={() => setShowAiAnalysis(false)} className="btn btn-primary btn-sm">Đóng</button>
            </div>
          </div>
        </div>
      )}

      {/* Toxicity Report Modal */}
      {showReportModal && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 100, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem', backdropFilter: 'blur(4px)' }}>
          <div className="card" style={{ padding: '2rem', maxWidth: '450px', width: '100%', border: '1px solid rgba(239, 68, 68, 0.3)', position: 'relative' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: '#FFF', marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '.4rem' }}>
              <span>🚨</span> {lang === 'en' ? 'Report Toxic Behavior' : 'Báo cáo hành vi Toxic'}
            </h3>

            {!reportSubmitted ? (
              <div>
                <p style={{ fontSize: '.84rem', color: 'var(--text-secondary)', marginBottom: '1rem' }}>
                  Giúp giữ cộng đồng BLUSH sạch đẹp. Báo cáo của bạn sẽ được gửi tới AI Guard của chúng tôi để kiểm tra.
                </p>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '.5rem', marginBottom: '1rem' }}>
                  {[
                    { label: 'Ngôn từ xúc phạm, chửi tục', val: 'verbal' },
                    { label: 'Cố tình quăng game, phá game', val: 'griefing' },
                    { label: 'AFK, thoát trận giữa chừng', val: 'afk' },
                    { label: 'Spam quảng cáo / Cày thuê trái phép', val: 'spam' }
                  ].map(opt => (
                    <label key={opt.val} style={{ display: 'flex', alignItems: 'center', gap: '.5rem', fontSize: '.82rem', color: 'var(--text-secondary)', cursor: 'pointer', padding: '.4rem', background: 'rgba(255,255,255,0.02)', borderRadius: '6px' }}>
                      <input 
                        type="radio" 
                        name="report_reason" 
                        value={opt.val} 
                        checked={reportReason === opt.val} 
                        onChange={() => setReportReason(opt.val)} 
                      />
                      <span>{opt.label}</span>
                    </label>
                  ))}
                </div>
                <textarea 
                  placeholder="Mô tả cụ thể hành vi hoặc nhập tin nhắn gây toxic..." 
                  className="input" 
                  style={{ height: '70px', resize: 'none', fontSize: '.82rem', marginBottom: '1.25rem' }}
                />
                <div style={{ display: 'flex', gap: '.75rem', justifyContent: 'flex-end' }}>
                  <button onClick={() => setShowReportModal(false)} className="btn btn-outline btn-sm">Hủy</button>
                  <button 
                    onClick={() => setReportSubmitted(true)} 
                    className="btn btn-sm" 
                    style={{ background: 'var(--danger)', color: '#FFF' }}
                  >
                    Gửi báo cáo
                  </button>
                </div>
              </div>
            ) : (
              <div style={{ textAlign: 'center', padding: '1rem 0' }}>
                <div style={{ width: 48, height: 48, borderRadius: '50%', background: 'rgba(0, 255, 159, 0.1)', border: '1px solid var(--success)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1rem', fontSize: '1.5rem', color: 'var(--success)' }}>✓</div>
                <h4 style={{ fontWeight: 800, color: '#FFF', marginBottom: '.5rem' }}>Đã gửi báo cáo thành công!</h4>
                <p style={{ fontSize: '.8rem', color: 'var(--text-secondary)', lineHeight: 1.5, marginBottom: '1.5rem' }}>
                  🤖 <strong>AI Guard Sentiment Engine</strong> đang phân tích chat logs của phòng này. Điểm số Toxicity Score sẽ được tính toán trong vòng 30 giây để hỗ trợ kiểm duyệt viên thực thi hình phạt nhanh chóng.
                </p>
                <button 
                  onClick={() => {
                    setShowReportModal(false);
                    setReportSubmitted(false);
                    setReportReason('');
                  }} 
                  className="btn btn-primary btn-sm"
                >
                  Đồng ý
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
