import React from 'react';
import { Sparkles, Crown, MessageSquare, Zap, Trophy, Lock, BookOpen, Brain, Bot, ArrowRight } from 'lucide-react';

export default function PremiumUpgrade({ onCheckout, onBack, t, lang }) {
  const features = [
    {
      icon: <Sparkles size={20} color="#00F5FF" />,
      title: lang === 'en' ? 'Glowing Avatar Frame' : 'Khung avatar động phát sáng',
      desc: lang === 'en' ? 'Stand out in all chats and comments' : 'Nổi bật trong mọi phòng chat và bình luận'
    },
    {
      icon: <MessageSquare size={20} color="#9D4EDD" />,
      title: lang === 'en' ? 'Exclusive Chat Bubbles' : 'Bong bóng chat độc quyền',
      desc: lang === 'en' ? 'Your messages will look completely unique' : 'Tin nhắn của bạn sẽ khác biệt hoàn toàn'
    },
    {
      icon: <Zap size={20} color="#FF4D6D" />,
      title: lang === 'en' ? 'Priority Matchmaking' : 'Ưu tiên ghép đội',
      desc: lang === 'en' ? 'Get matched faster during peak hours' : 'Được ghép nhanh hơn trong giờ cao điểm'
    },
    {
      icon: <Brain size={20} color="#00FF9F" />,
      title: lang === 'en' ? 'Premium AI Token Quota' : 'Tăng hạn mức Token AI',
      desc: lang === 'en' ? 'Up to 150,000 tokens/mo for daily AI interactions and topics' : 'Nhận tới 150.000 tokens/tháng cho các sảnh và bình luận AI'
    },
    {
      icon: <Bot size={20} color="#00F5FF" />,
      title: lang === 'en' ? 'Unlimited AI Chat Starters' : 'Trợ lý AI mở đầu không giới hạn',
      desc: lang === 'en' ? 'Get high-quality icebreakers customized to your matched lobbies' : 'Tự động tạo câu mở đầu phá băng chất lượng cao theo sảnh đấu'
    },
    {
      icon: <Trophy size={20} color="#FFB703" />,
      title: lang === 'en' ? 'Unique Gamer Titles' : 'Danh hiệu độc lạ',
      desc: lang === 'en' ? 'Display custom titles next to your tag' : 'Hiển thị cạnh tên khi tương tác'
    },
    {
      icon: <Lock size={20} color="#9D4EDD" />,
      title: lang === 'en' ? 'Pro-Player Closed Lobby' : 'Nhóm kín Pro-Player',
      desc: lang === 'en' ? 'Access VIP rooms with Mentors and Pros' : 'Truy cập phòng VIP có Mentor và Cao Thủ'
    },
    {
      icon: <BookOpen size={20} color="#FF4D6D" />,
      title: lang === 'en' ? 'Esports Coaching 1-1' : 'Coaching chiến thuật 1-1',
      desc: lang === 'en' ? 'Tactical gameplay analysis and match reviews (No rank boosting)' : 'Phân tích chiến thuật & review trận đấu trực tiếp (Không cày thuê/boosting)'
    }
  ];

  const plans = [
    {
      id: 'month_basic',
      name: 'BLUSH Pass',
      price: '29K',
      priceNum: 29000,
      period: lang === 'en' ? '/month' : '/tháng',
      popular: false,
      bullets: lang === 'en' ? [
        'Glowing dynamic avatar frames',
        'Special chat bubble styling',
        'Peak hours priority matching',
        'AI quota: 50,000 tokens/month',
        '10 daily AI Icebreaker suggestions'
      ] : [
        'Khung avatar động phát sáng',
        'Bong bóng chat đặc biệt',
        'Ưu tiên gánh đội giờ cao điểm',
        'Hạn mức AI: 50.000 tokens/tháng',
        '10 gợi ý AI phá băng / ngày'
      ]
    },
    {
      id: 'month_pro',
      name: 'BLUSH Pass Pro',
      price: '49K',
      priceNum: 49000,
      period: lang === 'en' ? '/month' : '/tháng',
      popular: true,
      badge: lang === 'en' ? 'POPULAR 🔥' : 'PHỔ BIẾN NHẤT 🔥',
      bullets: lang === 'en' ? [
        'All basic features from 29K plan',
        'Access to Pro-Player closed rooms',
        'Esports Coaching & Match Review 1-1',
        'AI quota: 150,000 tokens/month',
        'Unlimited AI chat starters',
        'VIP priority matchmaking level'
      ] : [
        'Tất cả từ gói 29K',
        'Truy cập nhóm kín Pro-Player',
        'Coaching chiến thuật & Review 1-1',
        'Hạn mức AI: 150.000 tokens/tháng',
        'Trợ lý AI mở đầu không giới hạn',
        'Ưu tiên ghép đội VIP'
      ]
    }
  ];

  return (
    <div style={{ padding: '2rem 1.5rem', maxWidth: '1000px', margin: '0 auto', minHeight: '85vh' }} className="animate-fade-in">
      
      {/* Welcome banner */}
      <div className="card-pink" style={{ padding: '2.5rem', marginBottom: '2.5rem', position: 'relative', overflow: 'hidden', textAlign: 'center' }}>
        <div style={{
          position: 'absolute', left: '-5%', top: '-25%', width: '250px', height: '250px',
          borderRadius: '50%', background: 'radial-gradient(circle, rgba(157,78,221,0.12) 0%, transparent 70%)',
          pointerEvents: 'none'
        }} />
        <div style={{
          position: 'absolute', right: '-5%', bottom: '-25%', width: '250px', height: '250px',
          borderRadius: '50%', background: 'radial-gradient(circle, rgba(0,245,255,0.1) 0%, transparent 70%)',
          pointerEvents: 'none'
        }} />

        <div style={{ position: 'relative', zIndex: 2 }}>
          <div style={{ 
            width: 60, height: 60, borderRadius: '50%', background: 'rgba(0, 245, 255, 0.1)', 
            border: '1px solid rgba(0, 245, 255, 0.25)', display: 'flex', alignItems: 'center', 
            justifyContent: 'center', margin: '0 auto 1rem', fontSize: '1.8rem',
            boxShadow: '0 0 15px rgba(0, 245, 255, 0.3)'
          }}>
            👑
          </div>
          
          <h1 style={{ fontSize: '2.4rem', fontWeight: 900, marginBottom: '.75rem', color: '#FFF' }}>
            {lang === 'en' ? 'Upgrade ' : 'Nâng cấp '}
            <span style={{ color: 'var(--cyan)' }}>BLUSH Pass</span>
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '.95rem', maxWidth: '580px', margin: '0 auto' }}>
            {lang === 'en' 
              ? 'Unlock the ultimate gaming experience at a student price — from just 29K/month'
              : 'Mở khóa trải nghiệm gaming đỉnh cao với giá "sinh viên" — chỉ từ 29K/tháng'}
          </p>
        </div>
      </div>

      {/* Grid of features */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', 
        gap: '1.25rem', 
        marginBottom: '3rem' 
      }}>
        {features.map((feat, idx) => (
          <div 
            key={idx} 
            className="card" 
            style={{ 
              padding: '1.25rem', 
              border: '1px solid var(--border-soft)',
              display: 'flex',
              gap: '1rem',
              alignItems: 'flex-start',
              background: 'var(--surface)'
            }}
          >
            <div style={{ 
              width: 44, height: 44, borderRadius: '12px', background: 'rgba(255,255,255,0.03)',
              border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', 
              justifyContent: 'center', flexShrink: 0
            }}>
              {feat.icon}
            </div>
            <div>
              <h3 style={{ fontSize: '.95rem', fontWeight: 800, color: '#FFF', marginBottom: '.25rem' }}>{feat.title}</h3>
              <p style={{ fontSize: '.78rem', color: 'var(--text-secondary)', lineHeight: 1.4 }}>{feat.desc}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Price comparison plans */}
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        gap: '2rem', 
        flexWrap: 'wrap',
        maxWidth: '850px',
        margin: '0 auto'
      }} className="responsive-profile">
        {plans.map(plan => (
          <div 
            key={plan.id}
            className="card"
            style={{
              flex: '1 1 350px',
              padding: '2rem',
              background: plan.popular ? 'linear-gradient(145deg, #140E28, #182C3D)' : 'var(--surface)',
              border: plan.popular ? '2px solid var(--success)' : '1px solid var(--border-soft)',
              borderRadius: '24px',
              position: 'relative',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              boxShadow: plan.popular ? '0 0 30px rgba(0, 255, 159, 0.15)' : 'none',
              transform: plan.popular ? 'scale(1.02)' : 'none'
            }}
          >
            {plan.popular && (
              <span style={{
                position: 'absolute', top: '-14px', left: '50%', transform: 'translateX(-50%)',
                background: 'var(--success)', color: '#0A0516', fontSize: '.7rem', fontWeight: 900,
                padding: '.35rem 1rem', borderRadius: '99px', letterSpacing: '.05em', boxShadow: '0 0 10px rgba(0, 255, 159, 0.5)'
              }}>
                {plan.badge}
              </span>
            )}

            <div>
              <div style={{ fontSize: '.88rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '.05em', marginBottom: '.5rem' }}>
                {plan.name}
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '.25rem', marginBottom: '1.5rem' }}>
                <span style={{ fontSize: '3rem', fontWeight: 900, color: '#FFF' }}>{plan.price}</span>
                <span style={{ fontSize: '.9rem', color: 'var(--text-muted)' }}>{plan.period}</span>
              </div>

              {/* Bullet Features */}
              <ul style={{ display: 'flex', flexDirection: 'column', gap: '.85rem', marginBottom: '2rem' }}>
                {plan.bullets.map((bullet, i) => (
                  <li key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: '.5rem', fontSize: '.86rem', color: 'var(--text-secondary)' }}>
                    <span style={{ color: plan.popular ? 'var(--success)' : 'var(--cyan)', fontWeight: 800 }}>✓</span>
                    <span>{bullet}</span>
                  </li>
                ))}
              </ul>
            </div>

            <button
              onClick={() => onCheckout({ id: plan.id, name: plan.name, price: plan.price + '.000', priceNum: plan.priceNum })}
              className="btn btn-w"
              style={{
                background: plan.popular ? 'var(--success)' : 'rgba(255,255,255,0.05)',
                color: plan.popular ? '#0A0516' : '#FFF',
                border: plan.popular ? 'none' : '1px solid var(--border-soft)',
                padding: '.85rem',
                borderRadius: '12px',
                fontWeight: 800,
                fontSize: '.9rem',
                gap: '.5rem',
                boxShadow: plan.popular ? '0 4px 15px rgba(0, 255, 159, 0.2)' : 'none'
              }}
            >
              {lang === 'en' ? 'Choose this plan' : 'Chọn gói này'}
              <ArrowRight size={15} />
            </button>
          </div>
        ))}
      </div>

    </div>
  );
}
