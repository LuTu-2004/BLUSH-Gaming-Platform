import React, { useState } from 'react';
import { Eye, EyeOff, ArrowRight, Sparkles, Users, Gamepad2, Trophy } from 'lucide-react';
import BlushLogo from '../BlushLogo';

const DEMO_ACCOUNTS = [
  { role: 'Gamer', email: 'gamer@blush.vn', color: '#00F5FF', icon: '🎮' },
  { role: 'Mentor', email: 'mentor@blush.vn', color: '#9D4EDD', icon: '🎓' },
  { role: 'Admin', email: 'admin@blush.vn', color: '#FF4D6D', icon: '⚙️' },
];

const FEATURE_TAGS = [
  { label: 'Leo Rank', icon: '🔥', color: '#FF4D6D' },
  { label: 'Tấu Hài', icon: '🎤', color: '#9D4EDD' },
  { label: 'Cây Skin', icon: '🎁', color: '#00FF9F' },
  { label: 'AI Matching', icon: '🤖', color: '#00F5FF' },
  { label: 'Bảng xếp hạng', icon: '🏆', color: '#FFB703' },
];

export default function AuthPage({ mode = 'login', onAuth, onToggleMode, t }) {
  const [tab, setTab]           = useState(mode);
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading]   = useState(false);
  const [form, setForm]         = useState({ email: '', password: '', confirmPassword: '' });
  const [selectedDemo, setSelectedDemo] = useState(null);

  function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      onAuth(tab);
    }, 1200);
  }

  function handleDemoLogin(acc) {
    setSelectedDemo(acc.role);
    setForm(f => ({ ...f, email: acc.email, password: '••••••••' }));
    setTab('login');
    setTimeout(() => {
      setLoading(true);
      setTimeout(() => {
        setLoading(false);
        onAuth('login');
      }, 900);
    }, 200);
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', background: 'var(--bg)', position: 'relative', overflow: 'hidden' }}>
      
      {/* Background glow effects */}
      <div style={{ position: 'absolute', left: '-10%', top: '20%', width: 400, height: 400, borderRadius: '50%', background: 'radial-gradient(circle, rgba(0,245,255,0.06) 0%, transparent 70%)', pointerEvents: 'none' }} />
      <div style={{ position: 'absolute', right: '10%', bottom: '10%', width: 350, height: 350, borderRadius: '50%', background: 'radial-gradient(circle, rgba(157,78,221,0.08) 0%, transparent 70%)', pointerEvents: 'none' }} />

      {/* ── LEFT PANEL: Marketing ── */}
      <div style={{
        flex: '1 1 520px', display: 'flex', flexDirection: 'column', justifyContent: 'center',
        padding: '4rem 3rem 3rem', position: 'relative', borderRight: '1px solid rgba(255,255,255,0.04)',
        minHeight: '100vh'
      }} className="auth-left-panel">
        
        {/* Logo */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', marginBottom: '4rem' }}>
          <BlushLogo size={36} />
          <div>
            <div style={{ fontSize: '1.1rem', fontWeight: 900, lineHeight: 1 }} className="gradient-text">BLUSH</div>
            <div style={{ fontSize: '.6rem', color: 'var(--text-muted)', fontWeight: 600, letterSpacing: '.1em', textTransform: 'uppercase' }}>Gaming Social Platform</div>
          </div>
        </div>

        {/* Hero Headline */}
        <div style={{ maxWidth: 480 }}>
          <h1 style={{ fontSize: 'clamp(2.2rem, 4vw, 3rem)', fontWeight: 900, lineHeight: 1.15, color: '#FFF', marginBottom: '1.25rem', letterSpacing: '-.02em' }}>
            Tìm đồng đội{' '}
            <span style={{ color: '#00F5FF' }}>cùng tần số</span>{' '}
            trong 3 giây <span style={{ fontSize: '1em' }}>⚡</span>
          </h1>

          <p style={{ fontSize: '1rem', color: 'var(--text-secondary)', lineHeight: 1.65, marginBottom: '2rem', maxWidth: 420 }}>
            AI Matching ghép bạn với người có cùng mục đích chơi — Leo Rank, Tấu Hài, hay Cây Skin. Không còn lệch pha, không còn toxic.
          </p>

          {/* Feature tags */}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '.5rem', marginBottom: '4rem' }}>
            {FEATURE_TAGS.map(tag => (
              <div key={tag.label} style={{
                display: 'flex', alignItems: 'center', gap: '.35rem',
                background: 'rgba(255,255,255,0.04)', border: `1px solid ${tag.color}30`,
                borderRadius: '99px', padding: '.35rem .85rem',
                fontSize: '.8rem', fontWeight: 600, color: '#FFF',
                transition: 'var(--tr)', cursor: 'default'
              }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = tag.color; e.currentTarget.style.boxShadow = `0 0 12px ${tag.color}25`; }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = `${tag.color}30`; e.currentTarget.style.boxShadow = 'none'; }}
              >
                <span>{tag.icon}</span> {tag.label}
              </div>
            ))}
          </div>
        </div>

        {/* Stats footer */}
        <div style={{ display: 'flex', gap: '3rem', marginTop: 'auto', paddingTop: '2rem', borderTop: '1px solid rgba(255,255,255,0.06)' }}>
          {[
            { val: '2.4K+', label: 'Online now', icon: <Users size={14}/> },
            { val: '186', label: 'Phòng đang chờ', icon: <Gamepad2 size={14}/> },
            { val: '50K+', label: 'Game thủ', icon: <Trophy size={14}/> },
          ].map((s, i) => (
            <div key={i}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '.35rem', fontSize: '1.5rem', fontWeight: 900, color: '#FFF' }}>
                {s.val}
              </div>
              <div style={{ fontSize: '.74rem', color: 'var(--text-muted)', marginTop: '.1rem', display: 'flex', alignItems: 'center', gap: '.25rem' }}>
                <span style={{ color: 'var(--cyan)' }}>{s.icon}</span> {s.label}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── RIGHT PANEL: Form ── */}
      <div style={{
        flex: '0 0 480px', display: 'flex', flexDirection: 'column',
        justifyContent: 'center', alignItems: 'center',
        padding: '3rem 2.5rem', background: 'rgba(20,14,40,0.6)', backdropFilter: 'blur(20px)'
      }} className="auth-right-panel">
        
        <div style={{ width: '100%', maxWidth: 380 }}>
          
          {/* Header */}
          <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
            <div style={{
              width: 56, height: 56, borderRadius: '50%',
              background: tab === 'login' ? 'rgba(0,245,255,0.1)' : 'rgba(157,78,221,0.1)',
              border: `2px solid ${tab === 'login' ? 'rgba(0,245,255,0.3)' : 'rgba(157,78,221,0.3)'}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              margin: '0 auto 1rem', fontSize: '1.5rem'
            }}>
              {tab === 'login' ? '→' : '🎮'}
            </div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 800, marginBottom: '.3rem', color: '#FFF' }}>
              {tab === 'login' ? 'Đăng nhập' : 'Tạo tài khoản'}
            </h2>
            <p style={{ fontSize: '.84rem', color: 'var(--text-muted)' }}>
              {tab === 'login' ? 'Vào trận cùng BLUSH ngay 🎮' : 'Tham gia cộng đồng 50K+ game thủ 🚀'}
            </p>
          </div>

          {/* Demo Accounts (Login only) */}
          {tab === 'login' && (
            <div style={{
              background: 'rgba(0,245,255,0.04)', border: '1px solid rgba(0,245,255,0.15)',
              borderRadius: '12px', padding: '1rem', marginBottom: '1.25rem'
            }}>
              <div style={{ fontSize: '.7rem', fontWeight: 700, color: 'var(--cyan)', textTransform: 'uppercase', letterSpacing: '.08em', marginBottom: '.75rem' }}>
                🎭 Tài khoản Demo:
              </div>
              <div style={{ display: 'flex', gap: '.5rem' }}>
                {DEMO_ACCOUNTS.map(acc => (
                  <button
                    key={acc.role}
                    onClick={() => handleDemoLogin(acc)}
                    style={{
                      flex: 1, padding: '.5rem .4rem', borderRadius: '8px', cursor: 'pointer',
                      background: selectedDemo === acc.role ? `${acc.color}18` : 'rgba(255,255,255,0.03)',
                      border: `1px solid ${selectedDemo === acc.role ? acc.color : 'rgba(255,255,255,0.06)'}`,
                      color: '#FFF', fontSize: '.72rem', fontWeight: 600, textAlign: 'center',
                      transition: 'var(--tr)', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '.2rem'
                    }}
                    onMouseEnter={e => { e.currentTarget.style.borderColor = acc.color; e.currentTarget.style.background = `${acc.color}12`; }}
                    onMouseLeave={e => { if (selectedDemo !== acc.role) { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)'; e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; } }}
                  >
                    <span style={{ fontSize: '1.1rem' }}>{acc.icon}</span>
                    <span style={{ color: acc.color }}>{acc.role}</span>
                    <span style={{ color: 'var(--text-muted)', fontSize: '.65rem' }}>{acc.email}</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Register steps indicator */}
          {tab === 'register' && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', marginBottom: '1.5rem' }}>
              {['Tạo TK', 'Xác nhận', 'Setup'].map((step, i) => (
                <React.Fragment key={step}>
                  <div style={{
                    display: 'flex', alignItems: 'center', gap: '.3rem',
                    fontSize: '.72rem', fontWeight: 600,
                    color: i === 0 ? 'var(--cyan)' : 'var(--text-muted)'
                  }}>
                    <div style={{
                      width: 18, height: 18, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.65rem', fontWeight: 800,
                      background: i === 0 ? 'var(--cyan)' : 'rgba(255,255,255,0.08)',
                      color: i === 0 ? '#0A0516' : 'var(--text-muted)'
                    }}>{i + 1}</div>
                    {step}
                  </div>
                  {i < 2 && <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.08)' }} />}
                </React.Fragment>
              ))}
            </div>
          )}

          {/* Google button */}
          <button
            type="button"
            style={{
              width: '100%', padding: '.75rem', borderRadius: '10px', marginBottom: '1rem',
              background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)',
              color: '#FFF', fontWeight: 600, fontSize: '.9rem', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '.6rem',
              transition: 'var(--tr)'
            }}
            onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.08)'; }}
            onMouseLeave={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; }}
          >
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
              <path d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.716v2.258h2.908c1.702-1.567 2.684-3.874 2.684-6.615z" fill="#4285F4"/>
              <path d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332C2.438 15.983 5.482 18 9 18z" fill="#34A853"/>
              <path d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z" fill="#FBBC05"/>
              <path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0 5.482 0 2.438 2.017.957 4.958L3.964 6.29C4.672 4.163 6.656 3.58 9 3.58z" fill="#EA4335"/>
            </svg>
            {tab === 'login' ? 'Đăng nhập với Google' : 'Đăng ký với Google'}
          </button>

          {/* Divider */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '.75rem', marginBottom: '1rem' }}>
            <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.07)' }} />
            <span style={{ fontSize: '.73rem', color: 'var(--text-muted)', fontWeight: 500 }}>HOẶC</span>
            <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.07)' }} />
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '.85rem' }}>

            {/* Email */}
            <div>
              <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.35rem' }}>Email</label>
              <div style={{ position: 'relative' }}>
                <span style={{ position: 'absolute', left: '.85rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: '.85rem' }}>✉</span>
                <input
                  className="input"
                  type="email"
                  placeholder="ban@example.com"
                  style={{ paddingLeft: '2.2rem' }}
                  value={form.email}
                  onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                  required
                />
              </div>
            </div>

            {/* Password */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '.35rem' }}>
                <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Mật khẩu</label>
                {tab === 'login' && (
                  <button type="button" style={{ fontSize: '.75rem', color: 'var(--cyan)', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 600 }}>Quên mật khẩu?</button>
                )}
              </div>
              <div style={{ position: 'relative' }}>
                <span style={{ position: 'absolute', left: '.85rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: '.85rem' }}>🔒</span>
                <input
                  className="input"
                  type={showPass ? 'text' : 'password'}
                  placeholder="••••••••"
                  style={{ paddingLeft: '2.2rem', paddingRight: '2.8rem' }}
                  value={form.password}
                  onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                  required
                />
                <button type="button" onClick={() => setShowPass(v => !v)} style={{ position: 'absolute', right: '.75rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}>
                  {showPass ? <EyeOff size={15}/> : <Eye size={15}/>}
                </button>
              </div>
            </div>

            {/* Confirm password (register only) */}
            {tab === 'register' && (
              <div>
                <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.35rem' }}>Xác nhận mật khẩu</label>
                <div style={{ position: 'relative' }}>
                  <span style={{ position: 'absolute', left: '.85rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: '.85rem' }}>🔒</span>
                  <input
                    className="input"
                    type={showPass ? 'text' : 'password'}
                    placeholder="••••••••"
                    style={{ paddingLeft: '2.2rem' }}
                    value={form.confirmPassword}
                    onChange={e => setForm(f => ({ ...f, confirmPassword: e.target.value }))}
                    required
                  />
                </div>
              </div>
            )}

            {/* Submit button */}
            <button
              className="btn btn-w"
              type="submit"
              disabled={loading}
              style={{
                marginTop: '.25rem', padding: '.85rem',
                background: 'linear-gradient(135deg, #00FF9F 0%, #00F5FF 100%)',
                border: 'none', color: '#0A0516', fontWeight: 800, fontSize: '.95rem',
                borderRadius: '10px', cursor: loading ? 'not-allowed' : 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '.6rem',
                transition: 'var(--tr)', opacity: loading ? 0.8 : 1
              }}
              onMouseEnter={e => { if (!loading) e.currentTarget.style.transform = 'translateY(-1px)'; }}
              onMouseLeave={e => { e.currentTarget.style.transform = 'none'; }}
            >
              {loading ? (
                <><div style={{ width: 17, height: 17, border: '2px solid rgba(10,5,22,.35)', borderTopColor: '#0A0516', borderRadius: '50%', animation: 'spin .8s linear infinite' }}/> Đang xử lý...</>
              ) : tab === 'login' ? (
                <><Gamepad2 size={17}/> Vào game</>
              ) : (
                <><Sparkles size={17}/> Đăng ký miễn phí</>
              )}
            </button>

            {tab === 'register' && (
              <p style={{ textAlign: 'center', fontSize: '.72rem', color: 'var(--text-muted)', lineHeight: 1.5 }}>
                Bằng việc đăng ký, bạn đồng ý với Điều khoản & Chính sách bảo mật của BLUSH
              </p>
            )}
          </form>

          {/* Switch tab */}
          <p style={{ textAlign: 'center', marginTop: '1.5rem', fontSize: '.84rem', color: 'var(--text-secondary)' }}>
            {tab === 'login' ? 'Chưa có tài khoản?' : 'Đã có tài khoản?'}
            {' '}
            <button
              onClick={() => setTab(tab === 'login' ? 'register' : 'login')}
              style={{ background: 'none', border: 'none', color: 'var(--cyan)', fontWeight: 700, cursor: 'pointer', fontSize: '.84rem' }}
            >
              {tab === 'login' ? 'Đăng ký ngay' : 'Đăng nhập'}
            </button>
          </p>

          {/* Role icons shown at bottom */}
          {tab === 'login' && (
            <div style={{ textAlign: 'center', marginTop: '1.5rem' }}>
              <div style={{ fontSize: '.7rem', color: 'var(--text-muted)', marginBottom: '.5rem' }}>BLUSH có 3 vai trò:</div>
              <div style={{ display: 'flex', justifyContent: 'center', gap: '1rem' }}>
                {DEMO_ACCOUNTS.map(acc => (
                  <div key={acc.role} style={{ textAlign: 'center' }}>
                    <div style={{
                      width: 36, height: 36, borderRadius: '50%', background: `${acc.color}15`,
                      border: `2px solid ${acc.color}40`, display: 'flex', alignItems: 'center',
                      justifyContent: 'center', fontSize: '1rem', margin: '0 auto .25rem'
                    }}>{acc.icon}</div>
                    <div style={{ fontSize: '.65rem', color: 'var(--text-muted)' }}>{acc.role}</div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
