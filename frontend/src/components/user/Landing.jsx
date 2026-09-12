import React, { useState } from 'react';
import { Sparkles, Heart, ArrowRight, Users, Zap, Eye, MessageCircle } from 'lucide-react';
import BlushLogo from '../BlushLogo';

export default function Landing({ onStart }) {
  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '2rem', position: 'relative' }}>

      {/* Header */}
      <div className="animate-fade-in" style={{ textAlign: 'center', marginBottom: '3rem' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '.6rem', marginBottom: '1.25rem' }}>
          <BlushLogo size={52} style={{ animation: 'heartbeat 2s ease-in-out infinite' }} />
          <div style={{ textAlign: 'left' }}>
            <div style={{ fontSize: '2rem', fontWeight: 900, letterSpacing: '-.03em', lineHeight: 1 }} className="gradient-text">BLUSH</div>
            <div style={{ fontSize: '.65rem', fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '.12em', textTransform: 'uppercase' }}>Personality First</div>
          </div>
        </div>

        <h1 style={{ fontSize: '3rem', fontWeight: 900, lineHeight: 1.15, marginBottom: '1rem', letterSpacing: '-.02em' }}>
          Kết nối bằng<br />
          <span className="gradient-text">tính cách</span>, không phải<br />ngoại hình
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '1.05rem', maxWidth: 480, margin: '0 auto' }}>
          BLUSH dùng AI phân tích tính cách, sở thích và lối sống để ghép đôi những người thật sự hợp nhau — không phán xét qua ảnh.
        </p>
      </div>

      {/* Features grid */}
      <div className="animate-fade-in-up stagger-2" style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: '1rem', maxWidth: 520, width: '100%', marginBottom: '2.5rem' }}>
        {[
          { icon: <Sparkles size={20} color="#E8547A"/>, title: 'AI Matching', desc: 'Ghép đôi dựa trên sở thích, tính cách & lối sống' },
          { icon: <Zap size={20} color="#7C5CBF"/>, title: 'Ice-Breaking Mission', desc: 'Cùng hoàn thành nhiệm vụ trước khi chat' },
          { icon: <MessageCircle size={20} color="#E8547A"/>, title: 'AI Conversation', desc: 'Gợi ý mở lời & cứu dead chat tự động' },
          { icon: <Eye size={20} color="#7C5CBF"/>, title: 'Blind Profile', desc: 'Ảnh ẩn cho đến khi hai bạn kết nối' },
        ].map((f, i) => (
          <div key={i} className="card" style={{ padding: '1.25rem', display: 'flex', gap: '.85rem', alignItems: 'flex-start' }}>
            <div style={{ width: 40, height: 40, borderRadius: 'var(--radius-md)', background: i % 2 === 0 ? 'var(--pink-soft)' : 'var(--purple-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              {f.icon}
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '.9rem', marginBottom: '.2rem' }}>{f.title}</div>
              <div style={{ fontSize: '.78rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>{f.desc}</div>
            </div>
          </div>
        ))}
      </div>

      {/* CTA */}
      <div className="animate-fade-in-up stagger-3" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '.85rem' }}>
        <button className="btn btn-primary btn-lg" onClick={onStart} style={{ gap: '.75rem', padding: '1rem 3rem' }}>
          <Sparkles size={18} />
          Bắt đầu — Hoàn toàn miễn phí
          <ArrowRight size={18} />
        </button>
        <p style={{ fontSize: '.78rem', color: 'var(--text-muted)' }}>Chỉ mất 2 phút khảo sát · Không cần ảnh ngay lập tức</p>
      </div>

      {/* Stats */}
      <div className="animate-fade-in-up stagger-4" style={{ display: 'flex', gap: '2.5rem', marginTop: '3rem' }}>
        {[
          { value: '12K+', label: 'người dùng' },
          { value: '94%', label: 'hài lòng' },
          { value: '3.8K', label: 'kết bạn thành công' },
        ].map((s,i) => (
          <div key={i} style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '1.5rem', fontWeight: 800 }} className="gradient-text">{s.value}</div>
            <div style={{ fontSize: '.75rem', color: 'var(--text-muted)' }}>{s.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
