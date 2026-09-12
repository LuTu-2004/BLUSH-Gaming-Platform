import React, { useState } from 'react';
import './index.css';
import { TRANSLATIONS } from './data/translations';
import { LogOut } from 'lucide-react';

import RoleSwitcher  from './components/RoleSwitcher';
import HomePage      from './components/user/HomePage';
import AuthPage      from './components/user/AuthPage';
import Landing       from './components/user/Landing';
import Survey        from './components/user/Survey';
import MatchFeed     from './components/user/MatchFeed';
import ChatRoom      from './components/user/ChatRoom';
import PremiumUpgrade from './components/user/PremiumUpgrade';
import CheckoutPage  from './components/user/CheckoutPage';
import UserProfile   from './components/user/UserProfile';
import BlushLogo     from './components/BlushLogo';

// New layout screens
import MatchmakingDashboard from './components/user/MatchmakingDashboard';
import Leaderboard from './components/user/Leaderboard';
import Quests from './components/user/Quests';

import StaffApp  from './components/staff/StaffApp';
import AdminApp  from './components/admin/AdminApp';

// ── User navigation flow ─────────────────────────────────────
// 'home' → 'auth' → 'survey' → 'matchmaking' / 'feed' → 'chat' | 'premium' | 'checkout'
// ─────────────────────────────────────────────────────────────

export default function App() {
  const [lang,        setLang]        = useState('en');
  const [role,        setRole]        = useState('user');
  const [userNav,     setUserNav]     = useState('home');

  const t = (key, val) => {
    const keys = key.split('.');
    let obj = TRANSLATIONS[lang];
    for (let k of keys) {
      if (obj && obj[k] !== undefined) {
        obj = obj[k];
      } else {
        return key;
      }
    }
    if (typeof obj === 'string' && val !== undefined) {
      return obj.replace('{n}', val);
    }
    return obj;
  };

  const [authMode,    setAuthMode]    = useState('login');
  const [isVip,       setIsVip]       = useState(false);
  const [vipCount,    setVipCount]    = useState(0);
  const [activeMatch, setActiveMatch] = useState(null);
  const [loggedIn,    setLoggedIn]    = useState(false);
  const [checkoutPlan, setCheckoutPlan] = useState(null);
  const [myProfile, setMyProfile] = useState({
    name: 'Khánh Linh',
    age: 20,
    mbti: 'INFJ',
    interests: ['Liên Quân Mobile', 'Hội Tấu Hài', 'Đường Giữa'],
    lifestyle: 'Night Raider (Night)',
    bio: 'Chuyên đi Mid tấu hài, voice chat hát hò giải stress cực vui. Tìm đồng đội tấu hài cùng! 🎤',
    avatar: '🌸',
    avatarBg: 'linear-gradient(135deg,#9D4EDD,#00F5FF)',
    sundayPrompt: 'Hát hò tấu hài xả stress cùng đồng đội hoặc cày skin sự kiện vui vẻ.',
    overthinkPrompt: 'Đồng đội toxic chửi bới, afk giữa chừng hoặc phá game...',
    location: 'Server TP.HCM',
    isVip: false,
    exp: 1250,
    coins: 340,
    level: 12,
    badges: ['🎤 Top 1 Tấu Hài', '🛡️ Guide Master']
  });

  function handleUpgrade() {
    setIsVip(true);
    setVipCount(c => c + 1);
    setUserNav('feed');
  }

  function handleAuth(mode) {
    setLoggedIn(true);
    // New users go to survey, returning users go to home
    setUserNav(mode === 'register' ? 'survey' : 'home');
  }

  function handleLogout() {
    setLoggedIn(false);
    setIsVip(false);
    setUserNav('home');
    setActiveMatch(null);
  }

  // Screens that show no sidebar/greeting
  const noNav = ['home', 'auth', 'survey', 'checkout'];
  const showSidebar = role === 'user' && loggedIn && !noNav.includes(userNav);

  const UserSidebar = () => {
    const menuItems = [
      { id: 'matchmaking', label: lang === 'en' ? 'Matchmaking' : 'Ghép đội', icon: '⚡' },
      { id: 'feed', label: lang === 'en' ? 'Feed' : 'Feed', icon: '💬' },
      { id: 'leaderboard', label: lang === 'en' ? 'Leaderboard' : 'Xếp hạng', icon: '🏆' },
      { id: 'quests', label: lang === 'en' ? 'Quests' : 'Nhiệm vụ', icon: '📋' },
      { id: 'profile', label: lang === 'en' ? 'Profile' : 'Hồ sơ', icon: '👤' }
    ];

    return (
      <div className="sidebar" style={{ width: '248px', background: 'rgba(20, 14, 40, 0.95)' }}>
        {/* Brand/Logo */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', padding: '.5rem .5rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.04)', marginBottom: '1rem', cursor: 'pointer' }} onClick={() => { setUserNav('home'); setActiveMatch(null); }}>
          <BlushLogo size={32} />
          <div>
            <div style={{ fontSize: '1.1rem', fontWeight: 900, lineHeight: 1 }} className="gradient-text">BLUSH</div>
            <div style={{ fontSize: '.6rem', color: 'var(--text-muted)', fontWeight: 600, letterSpacing: '.05em', textTransform: 'uppercase' }}>Gaming Platform</div>
          </div>
        </div>

        {/* Menu Items */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '.4rem', flex: 1 }}>
          {menuItems.map(item => {
            const isActive = userNav === item.id;
            return (
              <div 
                key={item.id} 
                className={`sidebar-nav-item ${isActive ? 'active' : ''}`}
                onClick={() => { setUserNav(item.id); setActiveMatch(null); }}
                style={{ display: 'flex', alignItems: 'center', gap: '.75rem', padding: '.75rem 1rem', borderRadius: '12px', cursor: 'pointer', transition: 'var(--tr)' }}
              >
                <span style={{ fontSize: '1.1rem' }}>{item.icon}</span>
                <span style={{ fontWeight: isActive ? 700 : 500 }}>{item.label}</span>
              </div>
            );
          })}
        </div>

        {/* Bottom PASS Section */}
        <div style={{ marginTop: 'auto', paddingTop: '1rem' }}>
          <button 
            onClick={() => { setUserNav('premium'); setActiveMatch(null); }}
            style={{
              width: '100%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '.5rem',
              padding: '.85rem',
              borderRadius: '12px',
              background: 'linear-gradient(135deg, #9D4EDD 0%, #00F5FF 100%)',
              color: '#FFF',
              border: 'none',
              fontWeight: 800,
              fontSize: '.85rem',
              cursor: 'pointer',
              boxShadow: '0 4px 15px rgba(157, 78, 221, 0.3)',
              transition: 'var(--tr)'
            }}
            onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-2px)'}
            onMouseLeave={e => e.currentTarget.style.transform = 'none'}
          >
            <span>👑</span>
            PASS
          </button>
        </div>
      </div>
    );
  };

  const UserTopGreetingBar = () => {
    const hour = new Date().getHours();
    let greeting = lang === 'en' ? 'Good evening! 🎮 Ready to match?' : 'Chào buổi tối! 🎮 Sẵn sàng vào trận chưa?';
    if (hour >= 5 && hour < 11) {
      greeting = lang === 'en' ? 'Good morning! 🌅 Ready to match?' : 'Chào buổi sáng! 🌅 Sẵn sàng vào trận chưa?';
    } else if (hour >= 11 && hour < 17) {
      greeting = lang === 'en' ? 'Good afternoon! ☀️ Ready to match?' : 'Chào buổi chiều! ☀️ Sẵn sàng vào trận chưa?';
    }

    return (
      <div style={{ 
        height: '70px', padding: '0 2.5rem', display: 'flex', justifyContent: 'space-between', 
        alignItems: 'center', borderBottom: '1px solid rgba(255,255,255,0.04)', 
        background: 'rgba(10, 5, 22, 0.4)', backdropFilter: 'blur(10px)',
        position: 'sticky', top: 0, zIndex: 30
      }}>
        <div style={{ fontSize: '.95rem', fontWeight: 700, color: '#FFF' }}>
          {greeting}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          {/* Gamer Stats */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '.75rem',
            fontSize: '.82rem',
            fontWeight: 700,
            color: '#FFF',
            background: 'rgba(255, 255, 255, 0.05)',
            padding: '.45rem .85rem',
            borderRadius: '10px',
            border: '1px solid rgba(255, 255, 255, 0.08)'
          }}>
            <span style={{ color: '#FFB703' }}>🪙 {myProfile.coins}</span>
            <span style={{ color: '#00F5FF' }}>⚔️ Lvl {myProfile.level}</span>
          </div>

          {/* Notification Button */}
          <button 
            onClick={() => alert(lang === 'en' ? 'No new notifications.' : 'Không có thông báo mới.')}
            style={{
              width: 36, height: 36, borderRadius: '10px', background: 'rgba(255, 255, 255, 0.05)',
              border: '1px solid rgba(255, 255, 255, 0.08)', display: 'flex', alignItems: 'center',
              justifyContent: 'center', color: '#FFF', cursor: 'pointer', fontSize: '1rem', outline: 'none'
            }}
          >
            🔔
          </button>

          {/* Language Switch Button */}
          <button onClick={() => setLang(l => l === 'en' ? 'vi' : 'en')} style={{
            padding: '.45rem .85rem', borderRadius: '10px', fontSize: '.78rem', fontWeight: 700,
            background: 'rgba(157,78,221,.08)', color: 'var(--pink)', border: '1px solid rgba(157,78,221,.15)',
            cursor: 'pointer', transition: 'var(--tr)'
          }}>
            {lang === 'en' ? '🇺🇸 EN' : '🇻🇳 VI'}
          </button>

          {/* Logout Button */}
          <button onClick={handleLogout} style={{
            display: 'flex', alignItems: 'center', gap: '.4rem',
            padding: '.45rem 1rem', borderRadius: '10px', fontSize: '.83rem', fontWeight: 600,
            background: 'transparent', color: 'var(--text-secondary)',
            border: '1px solid var(--border-soft)', cursor: 'pointer', transition: 'var(--tr)',
          }}
          onMouseEnter={e => { e.currentTarget.style.color = 'var(--danger)'; e.currentTarget.style.borderColor = 'rgba(255,77,109,.2)'; e.currentTarget.style.background = 'rgba(255,77,109,.05)'; }}
          onMouseLeave={e => { e.currentTarget.style.color = 'var(--text-secondary)'; e.currentTarget.style.borderColor = 'var(--border-soft)'; e.currentTarget.style.background = 'transparent'; }}
          >
            <LogOut size={14}/>
            <span className="topnav-logout-text">{t('nav.logout')}</span>
          </button>
        </div>
      </div>
    );
  };

  return (
    <>
      {/* Animated pastel background */}
      <div className="app-bg" />

      <div style={{ position: 'relative', zIndex: 1 }}>

        {/* ── STAFF ── */}
        {role === 'staff' && <StaffApp />}

        {/* ── ADMIN ── */}
        {role === 'admin' && <AdminApp vipCount={vipCount} />}

        {/* ── USER ── */}
        {role === 'user' && (
          <>
            {showSidebar ? (
              <div className="sidebar-layout">
                <UserSidebar />
                <div 
                  className="sidebar-content" 
                  style={{ 
                    marginLeft: '248px', 
                    padding: 0, 
                    display: 'flex', 
                    flexDirection: 'column',
                    minHeight: '100vh',
                    width: 'calc(100% - 248px)'
                  }}
                >
                  {userNav !== 'chat' && <UserTopGreetingBar />}
                  
                  <div style={{ flex: 1 }}>
                    {/* Home page sảnh chờ dashboard (when logged in) */}
                    {userNav === 'home' && (
                      <HomePage
                        t={t}
                        lang={lang}
                        onLogin={() => { setAuthMode('login'); setUserNav('auth'); }}
                        onRegister={() => { setAuthMode('register'); setUserNav('auth'); }}
                        loggedIn={loggedIn}
                        myProfile={myProfile}
                        onSaveProfile={setMyProfile}
                        onNavigate={(dest) => {
                          setUserNav(dest);
                          setActiveMatch(null);
                        }}
                      />
                    )}

                    {/* Matchmaking Dashboard (Ghép đội) */}
                    {userNav === 'matchmaking' && (
                      <MatchmakingDashboard
                        t={t}
                        lang={lang}
                        onUpgrade={() => setUserNav('premium')}
                        onEnterRoom={(room) => {
                          const mockMatch = {
                            name: room.title,
                            avatar: room.avatars[0] || '🎮',
                            avatarBg: 'linear-gradient(135deg, #FF4D6D, #9D4EDD)',
                            lifestyle: 'Night Owl 🦉',
                            bio: room.desc,
                            sundayPrompt: 'Cày rank tryhard cùng cả team',
                            overthinkPrompt: 'Lệch pha combo',
                            interests: ['Liên Quân Mobile', room.tag],
                            level: 15,
                            coins: 450,
                            exp: 1800
                          };
                          setActiveMatch(mockMatch);
                          setUserNav('chat');
                        }}
                      />
                    )}

                    {/* Match feed */}
                    {userNav === 'feed' && !activeMatch && (
                      <MatchFeed
                        t={t}
                        lang={lang}
                        isVip={isVip}
                        onChat={match => { setActiveMatch(match); setUserNav('chat'); }}
                        onUpgrade={() => setUserNav('premium')}
                      />
                    )}

                    {/* Leaderboard (Xếp hạng) */}
                    {userNav === 'leaderboard' && (
                      <Leaderboard t={t} lang={lang} />
                    )}

                    {/* Quests (Nhiệm vụ) */}
                    {userNav === 'quests' && (
                      <Quests
                        t={t}
                        lang={lang}
                        myProfile={myProfile}
                        onUpdateProfile={setMyProfile}
                      />
                    )}

                    {/* User Profile Page */}
                    {userNav === 'profile' && (
                      <UserProfile
                        t={t}
                        lang={lang}
                        setLang={setLang}
                        myProfile={myProfile}
                        onSave={(updated) => setMyProfile(updated)}
                        onBack={() => setUserNav('matchmaking')}
                      />
                    )}

                    {/* VIP Upgrade */}
                    {userNav === 'premium' && (
                      <PremiumUpgrade
                        t={t}
                        lang={lang}
                        onCheckout={(plan) => {
                          setCheckoutPlan(plan);
                          setUserNav('checkout');
                        }}
                        onBack={() => setUserNav('matchmaking')}
                      />
                    )}

                    {/* Chat */}
                    {userNav === 'chat' && activeMatch && (
                      <ChatRoom
                        t={t}
                        lang={lang}
                        match={activeMatch}
                        isVip={isVip}
                        onBack={() => { setUserNav('matchmaking'); setActiveMatch(null); }}
                        onUpgrade={() => setUserNav('premium')}
                      />
                    )}
                  </div>
                </div>
              </div>
            ) : (
              <div>
                {/* Home page guest view */}
                {userNav === 'home' && (
                  <HomePage
                    t={t}
                    lang={lang}
                    onLogin={() => { setAuthMode('login'); setUserNav('auth'); }}
                    onRegister={() => { setAuthMode('register'); setUserNav('auth'); }}
                    loggedIn={loggedIn}
                    myProfile={myProfile}
                    onSaveProfile={setMyProfile}
                    onNavigate={(dest) => {
                      setUserNav(dest);
                      setActiveMatch(null);
                    }}
                  />
                )}

                {/* Auth (Login / Register) */}
                {userNav === 'auth' && (
                  <AuthPage
                    t={t}
                    mode={authMode}
                    onAuth={handleAuth}
                    onToggleMode={(dest) => setUserNav(dest)}
                  />
                )}

                {/* Onboarding survey (only for new users) */}
                {userNav === 'survey' && (
                  <Survey t={t} lang={lang} onComplete={() => setUserNav('matchmaking')} />
                )}

                {/* Checkout Page */}
                {userNav === 'checkout' && (
                  <CheckoutPage
                    t={t}
                    lang={lang}
                    plan={checkoutPlan}
                    onSuccess={handleUpgrade}
                    onBack={() => setUserNav('premium')}
                  />
                )}
              </div>
            )}
          </>
        )}
      </div>

      {/* Role Switcher — always visible */}
      <RoleSwitcher
        currentRole={role}
        onSwitch={r => { setRole(r); setActiveMatch(null); }}
      />
    </>
  );
}
