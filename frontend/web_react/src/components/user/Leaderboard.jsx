import React, { useState } from 'react';

const TOP_THREE = [
  {
    rank: 1,
    name: 'TryhardNam',
    exp: '12.500 EXP',
    icon: '🔥',
    avatar: '🦊',
    color: '#FFD700', // Gold
    height: '180px',
    bg: 'linear-gradient(180deg, rgba(255, 215, 0, 0.15) 0%, rgba(255, 215, 0, 0.03) 100%)',
    border: '1px solid rgba(255, 215, 0, 0.3)'
  },
  {
    rank: 2,
    name: 'MentorMinh',
    exp: '11.200 EXP',
    icon: '🎓',
    avatar: '🦁',
    color: '#C0C0C0', // Silver
    height: '150px',
    bg: 'linear-gradient(180deg, rgba(192, 192, 192, 0.15) 0%, rgba(192, 192, 192, 0.03) 100%)',
    border: '1px solid rgba(192, 192, 192, 0.2)'
  },
  {
    rank: 3,
    name: 'HàiHướcQueen',
    exp: '10.800 EXP',
    icon: '😂',
    avatar: '🦄',
    color: '#CD7F32', // Bronze
    height: '130px',
    bg: 'linear-gradient(180deg, rgba(205, 127, 50, 0.15) 0%, rgba(205, 127, 50, 0.03) 100%)',
    border: '1px solid rgba(205, 127, 50, 0.2)'
  }
];

const LEADERBOARD_LIST = [
  { rank: 4, name: 'ProGamer_VN', location: 'Hồ Chí Minh', level: 'Lv.20', winRate: '70%', exp: '9.500', avatar: '⚔️' },
  { rank: 5, name: 'SkinCollector', location: 'Cần Thơ', level: 'Lv.19', winRate: '60%', exp: '8.900', avatar: '🎁' },
  { rank: 6, name: 'KillerInstinct', location: 'Hà Nội', level: 'Lv.18', winRate: '68%', exp: '8.200', avatar: '💀' },
  { rank: 7, name: 'ChillGamer99', location: 'Huế', level: 'Lv.17', winRate: '55%', exp: '7.800', avatar: '🎵' },
  { rank: 8, name: 'DragonSlayer', location: 'Hồ Chí Minh', level: 'Lv.16', winRate: '63%', exp: '7.200', avatar: '🐉' },
  { rank: 9, name: 'NightOwlGG', location: 'Đà Nẵng', level: 'Lv.15', winRate: '58%', exp: '6.900', avatar: '🦉' },
  { rank: 10, name: 'FlashPoint', location: 'Hà Nội', level: 'Lv.14', winRate: '61%', exp: '6.500', avatar: '⚡' }
];

export default function Leaderboard({ t, lang }) {
  const [region, setRegion] = useState('Toàn quốc');

  return (
    <div style={{ padding: '2rem 1.5rem', maxWidth: '1000px', margin: '0 auto', minHeight: '85vh' }} className="animate-fade-in">
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2.5rem', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontSize: '1.8rem', fontWeight: 900, color: '#FFF' }}>
            {lang === 'en' ? 'Leaderboard' : 'Bảng xếp hạng'}
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '.84rem', marginTop: '.2rem' }}>
            {lang === 'en' ? 'Who is the regional master?' : 'Ai là trùm khu vực?'}
          </p>
        </div>
        
        {/* Dropdown Select */}
        <div>
          <select 
            value={region} 
            onChange={e => setRegion(e.target.value)}
            style={{
              padding: '.5rem 1rem', borderRadius: '10px',
              background: 'var(--surface-2)', color: '#FFF',
              border: '1px solid var(--border-soft)', fontSize: '.88rem',
              cursor: 'pointer', outline: 'none'
            }}
          >
            <option value="Toàn quốc">📍 {lang === 'en' ? 'National' : 'Toàn quốc'}</option>
            <option value="Miền Nam">📍 {lang === 'en' ? 'Southern' : 'Miền Nam'}</option>
            <option value="Miền Bắc">📍 {lang === 'en' ? 'Northern' : 'Miền Bắc'}</option>
            <option value="Miền Trung">📍 {lang === 'en' ? 'Central' : 'Miền Trung'}</option>
          </select>
        </div>
      </div>

      {/* Podium Podium section */}
      <div style={{ 
        display: 'flex', justifyContent: 'center', alignItems: 'flex-end', 
        gap: '1.5rem', marginBottom: '3rem', marginTop: '2rem', minHeight: '280px' 
      }}>
        
        {/* #2 Rank Card (Left) */}
        {(() => {
          const second = TOP_THREE[1];
          return (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: '130px' }}>
              <div style={{ position: 'relative', marginBottom: '.75rem', textAlign: 'center' }}>
                <div style={{ 
                  width: 54, height: 54, borderRadius: '50%', background: 'rgba(255,255,255,0.05)',
                  border: '2.5px solid #C0C0C0', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '1.6rem', boxShadow: '0 0 15px rgba(192, 192, 192, 0.25)'
                }}>
                  {second.avatar}
                </div>
                <span style={{ 
                  position: 'absolute', bottom: -5, right: -5, background: '#C0C0C0', color: '#0A0516',
                  borderRadius: '50%', width: 20, height: 20, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '.75rem', fontWeight: 800
                }}>
                  {second.icon}
                </span>
              </div>
              <div style={{ fontWeight: 800, fontSize: '.9rem', color: '#FFF', textAlign: 'center', marginBottom: '.15rem' }}>{second.name}</div>
              <div style={{ fontSize: '.72rem', color: 'var(--text-muted)', marginBottom: '.5rem' }}>{second.exp}</div>
              <div style={{ 
                width: '100%', height: second.height, background: second.bg, border: second.border,
                borderBottom: 'none', borderRadius: '12px 12px 0 0', display: 'flex', alignItems: 'center', justifyContent: 'center' 
              }}>
                <span style={{ fontSize: '1.8rem', fontWeight: 900, color: 'rgba(192, 192, 192, 0.4)' }}>#2</span>
              </div>
            </div>
          );
        })()}

        {/* #1 Rank Card (Center) */}
        {(() => {
          const first = TOP_THREE[0];
          return (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: '150px' }}>
              <div style={{ position: 'relative', marginBottom: '.75rem', textAlign: 'center' }}>
                {/* Crown Emoji */}
                <div style={{ position: 'absolute', top: -20, left: '50%', transform: 'translateX(-50%)', fontSize: '1.5rem', animation: 'floatOrb 3s ease-in-out infinite' }}>👑</div>
                <div style={{ 
                  width: 68, height: 68, borderRadius: '50%', background: 'rgba(255,255,255,0.05)',
                  border: '3px solid #FFD700', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '2rem', boxShadow: '0 0 25px rgba(255, 215, 0, 0.4)'
                }}>
                  {first.avatar}
                </div>
                <span style={{ 
                  position: 'absolute', bottom: -3, right: -3, background: '#FFD700', color: '#0A0516',
                  borderRadius: '50%', width: 22, height: 22, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '.85rem', fontWeight: 800
                }}>
                  {first.icon}
                </span>
              </div>
              <div style={{ fontWeight: 900, fontSize: '1rem', color: '#FFF', textAlign: 'center', marginBottom: '.15rem' }}>{first.name}</div>
              <div style={{ fontSize: '.75rem', color: 'var(--text-muted)', marginBottom: '.5rem' }}>{first.exp}</div>
              <div style={{ 
                width: '100%', height: first.height, background: first.bg, border: first.border,
                borderBottom: 'none', borderRadius: '16px 16px 0 0', display: 'flex', alignItems: 'center', justifyContent: 'center' 
              }}>
                <span style={{ fontSize: '2.2rem', fontWeight: 900, color: 'rgba(255, 215, 0, 0.4)' }}>#1</span>
              </div>
            </div>
          );
        })()}

        {/* #3 Rank Card (Right) */}
        {(() => {
          const third = TOP_THREE[2];
          return (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: '130px' }}>
              <div style={{ position: 'relative', marginBottom: '.75rem', textAlign: 'center' }}>
                <div style={{ 
                  width: 54, height: 54, borderRadius: '50%', background: 'rgba(255,255,255,0.05)',
                  border: '2.5px solid #CD7F32', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '1.6rem', boxShadow: '0 0 15px rgba(205, 127, 50, 0.25)'
                }}>
                  {third.avatar}
                </div>
                <span style={{ 
                  position: 'absolute', bottom: -5, right: -5, background: '#CD7F32', color: '#0A0516',
                  borderRadius: '50%', width: 20, height: 20, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '.75rem', fontWeight: 800
                }}>
                  {third.icon}
                </span>
              </div>
              <div style={{ fontWeight: 800, fontSize: '.9rem', color: '#FFF', textAlign: 'center', marginBottom: '.15rem' }}>{third.name}</div>
              <div style={{ fontSize: '.72rem', color: 'var(--text-muted)', marginBottom: '.5rem' }}>{third.exp}</div>
              <div style={{ 
                width: '100%', height: third.height, background: third.bg, border: third.border,
                borderBottom: 'none', borderRadius: '12px 12px 0 0', display: 'flex', alignItems: 'center', justifyContent: 'center' 
              }}>
                <span style={{ fontSize: '1.8rem', fontWeight: 900, color: 'rgba(205, 127, 50, 0.4)' }}>#3</span>
              </div>
            </div>
          );
        })()}

      </div>

      {/* Rankings List Table */}
      <div className="card" style={{ border: '1px solid var(--border-soft)', overflow: 'hidden' }}>
        <table className="data-table">
          <thead>
            <tr>
              <th style={{ width: '80px', textAlign: 'center' }}>#</th>
              <th>{lang === 'en' ? 'GAMER' : 'GAME THỦ'}</th>
              <th>{lang === 'en' ? 'LEVEL' : 'LEVEL'}</th>
              <th>{lang === 'en' ? 'WIN RATE' : 'WIN RATE'}</th>
              <th style={{ textAlign: 'right' }}>{lang === 'en' ? 'EXP' : 'EXP'}</th>
            </tr>
          </thead>
          <tbody>
            {LEADERBOARD_LIST.map(g => (
              <tr key={g.rank}>
                <td style={{ textAlign: 'center', fontWeight: 800, color: 'var(--text-muted)' }}>{g.rank}</td>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '.75rem' }}>
                    <div style={{ 
                      width: 32, height: 32, borderRadius: '50%', background: 'rgba(255,255,255,0.05)',
                      border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: '.9rem' 
                    }}>
                      {g.avatar}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, color: '#FFF' }}>{g.name}</div>
                      <div style={{ fontSize: '.72rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '.25rem' }}>
                        <span>📍</span> {g.location}
                      </div>
                    </div>
                  </div>
                </td>
                <td>
                  <span style={{ color: 'var(--pink)', fontWeight: 800 }}>{g.level}</span>
                </td>
                <td>
                  <span style={{ color: 'var(--success)', fontWeight: 700 }}>{g.winRate}</span>
                </td>
                <td style={{ textAlign: 'right', fontWeight: 700, color: '#FFF' }}>{g.exp}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Fixed bottom profile status (simulation) */}
      <div className="card-pink" style={{ padding: '1rem 1.5rem', marginTop: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid rgba(0, 245, 255, 0.2)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--text-muted)' }}>#117</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem' }}>
            <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'linear-gradient(135deg,#9D4EDD,#00F5FF)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.1rem' }}>🌸</div>
            <div>
              <div style={{ fontWeight: 800, color: '#FFF' }}>Khánh Linh (Bạn)</div>
              <div style={{ fontSize: '.7rem', color: 'var(--text-secondary)' }}>Server TP.HCM</div>
            </div>
          </div>
        </div>
        
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: '.68rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>LEVEL</div>
            <div style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--pink)' }}>Lv.12</div>
          </div>
          <div>
            <div style={{ fontSize: '.68rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>WIN RATE</div>
            <div style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--success)' }}>58%</div>
          </div>
          <div>
            <div style={{ fontSize: '.68rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>TỔNG EXP</div>
            <div style={{ fontSize: '1rem', fontWeight: 800, color: '#FFF' }}>1.250</div>
          </div>
        </div>
      </div>

    </div>
  );
}
