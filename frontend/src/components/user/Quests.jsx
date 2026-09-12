import React, { useState } from 'react';
import { Award, Clock, CheckCircle } from 'lucide-react';

const INITIAL_DAILY_QUESTS = [
  {
    id: 1,
    title: 'Ghép đội 1 lần',
    desc: 'Sử dụng AI Matching để tìm đồng đội',
    current: 1,
    target: 1,
    rewardCoins: 10,
    rewardExp: 25,
    claimed: true
  },
  {
    id: 2,
    title: 'Đăng 1 bài trên Feed',
    desc: 'Chia sẻ chiến tích hoặc chiến thuật',
    current: 0,
    target: 1,
    rewardCoins: 15,
    rewardExp: 30,
    claimed: false
  },
  {
    id: 3,
    title: 'Like 5 bài viết',
    desc: 'Tương tác với cộng đồng',
    current: 3,
    target: 5,
    rewardCoins: 5,
    rewardExp: 15,
    claimed: false
  },
  {
    id: 4,
    title: 'Chơi 3 trận cùng nhóm BLUSH',
    desc: 'Vào trận với đồng đội từ BLUSH',
    current: 1,
    target: 3,
    rewardCoins: 20,
    rewardExp: 50,
    claimed: false
  }
];

const WEEKLY_QUESTS = [
  {
    id: 101,
    title: 'Đạt chuỗi 3 trận thắng',
    desc: 'Cùng đồng đội ghép sảnh thắng liên tiếp 3 trận',
    current: 2,
    target: 3,
    rewardCoins: 100,
    rewardExp: 250,
    claimed: false
  },
  {
    id: 102,
    title: 'Hỗ trợ 5 tân thủ mới',
    desc: 'Tham gia lobby với người chơi cấp dưới level 5',
    current: 5,
    target: 5,
    rewardCoins: 80,
    rewardExp: 200,
    claimed: false
  },
  {
    id: 103,
    title: 'Hoàn thành thử thách tuần Razer',
    desc: 'Chụp hình góc máy Razer của bạn đăng lên feed',
    current: 1,
    target: 1,
    rewardCoins: 150,
    rewardExp: 300,
    claimed: true
  }
];

const SEASONAL_QUESTS = [
  {
    id: 201,
    title: 'Đạt rank Cao Thủ mùa giải mới',
    desc: 'Được AI ghi nhận đạt thứ hạng Cao Thủ trở lên',
    current: 0,
    target: 1,
    rewardCoins: 500,
    rewardExp: 1000,
    claimed: false
  },
  {
    id: 202,
    title: 'Tương tác 50 lần trên Feed phân khu',
    desc: 'Đóng góp ý kiến thảo luận xây dựng cộng đồng',
    current: 34,
    target: 50,
    rewardCoins: 300,
    rewardExp: 600,
    claimed: false
  }
];

export default function Quests({ myProfile, onUpdateProfile, t, lang }) {
  const [activeTab, setActiveTab] = useState('daily'); // 'daily' | 'weekly' | 'seasonal'
  const [dailyQuests, setDailyQuests] = useState(INITIAL_DAILY_QUESTS);
  const [weeklyQuests, setWeeklyQuests] = useState(WEEKLY_QUESTS);
  const [seasonalQuests, setSeasonalQuests] = useState(SEASONAL_QUESTS);

  // Get current active quests list
  const getActiveQuests = () => {
    if (activeTab === 'weekly') return weeklyQuests;
    if (activeTab === 'seasonal') return seasonalQuests;
    return dailyQuests;
  };

  const getActiveSetter = () => {
    if (activeTab === 'weekly') return setWeeklyQuests;
    if (activeTab === 'seasonal') return setSeasonalQuests;
    return setDailyQuests;
  };

  // Calculate completed daily count
  const completedDailyCount = dailyQuests.filter(q => q.current >= q.target).length;
  const progressPercent = Math.round((completedDailyCount / dailyQuests.length) * 100);

  const handleClaim = (questId) => {
    const setter = getActiveSetter();
    const questsList = getActiveQuests();
    const quest = questsList.find(q => q.id === questId);
    
    if (!quest || quest.claimed || quest.current < quest.target) return;

    // Update quest status
    setter(prev => prev.map(q => q.id === questId ? { ...q, claimed: true } : q));

    // Add rewards to profile
    if (myProfile && onUpdateProfile) {
      onUpdateProfile({
        ...myProfile,
        coins: myProfile.coins + quest.rewardCoins,
        exp: myProfile.exp + quest.rewardExp
      });
      
      alert(lang === 'en'
        ? `Claimed! You received +${quest.rewardCoins} Coins and +${quest.rewardExp} EXP!`
        : `Nhận quà thành công! Bạn nhận được +${quest.rewardCoins} Coins và +${quest.rewardExp} EXP!`);
    }
  };

  return (
    <div style={{ padding: '2rem 1.5rem', maxWidth: '850px', margin: '0 auto', minHeight: '85vh' }} className="animate-fade-in">
      
      {/* Title */}
      <div style={{ marginBottom: '2rem' }}>
        <h1 style={{ fontSize: '1.8rem', fontWeight: 900, color: '#FFF' }}>
          {lang === 'en' ? 'Quests' : 'Nhiệm vụ'}
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '.84rem', marginTop: '.2rem' }}>
          {lang === 'en' ? 'Complete quests to earn Coins & EXP' : 'Hoàn thành nhiệm vụ để nhận Coin & EXP'}
        </p>
      </div>

      {/* Daily Progress Card */}
      <div className="card" style={{ padding: '1.5rem', marginBottom: '2rem', border: '1px solid var(--border-soft)', background: 'var(--surface)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '.75rem' }}>
          <div style={{ fontWeight: 800, color: '#FFF', fontSize: '1rem' }}>
            {lang === 'en' ? 'Today Progress' : 'Tiến độ hôm nay'}
          </div>
          <div style={{ color: 'var(--success)', fontWeight: 800 }}>
            {completedDailyCount}/{dailyQuests.length}
          </div>
        </div>
        
        {/* Progress Bar */}
        <div className="progress-bar" style={{ height: '8px', marginBottom: '1rem' }}>
          <div className="progress-fill" style={{ width: `${progressPercent}%`, backgroundColor: 'var(--success)', boxShadow: '0 0 10px rgba(0, 255, 159, 0.4)' }} />
        </div>

        <p style={{ fontSize: '.78rem', color: 'var(--text-muted)' }}>
          {lang === 'en'
            ? 'Complete all daily quests to receive double reward bonus x2!'
            : 'Hoàn thành tất cả nhiệm vụ hàng ngày để nhận thưởng bonus x2'}
        </p>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '.5rem', borderBottom: '1px solid var(--border-soft)', paddingBottom: '1rem', marginBottom: '1.5rem' }}>
        {[
          { id: 'daily', label: lang === 'en' ? 'Daily' : 'Hàng ngày', icon: '⏱️' },
          { id: 'weekly', label: lang === 'en' ? 'Weekly' : 'Hàng tuần', icon: '📅' },
          { id: 'seasonal', label: lang === 'en' ? 'Seasonal' : 'Mùa giải', icon: '🏆' }
        ].map(tab => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              style={{
                display: 'flex', alignItems: 'center', gap: '.4rem',
                padding: '.6rem 1.25rem', borderRadius: '10px',
                fontSize: '.85rem', fontWeight: 700, cursor: 'pointer',
                transition: 'var(--tr)',
                background: isActive ? 'rgba(0, 255, 159, 0.12)' : 'transparent',
                color: isActive ? 'var(--success)' : 'var(--text-secondary)',
                border: `1px solid ${isActive ? 'rgba(0,255,159,.2)' : 'transparent'}`
              }}
            >
              <span>{tab.icon}</span>
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Quests List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {getActiveQuests().map(quest => {
          const isDone = quest.current >= quest.target;
          const questPercent = Math.min(100, Math.round((quest.current / quest.target) * 100));
          return (
            <div 
              key={quest.id} 
              className="card"
              style={{ 
                padding: '1.25rem', 
                border: isDone ? '1px solid rgba(0, 255, 159, 0.25)' : '1px solid var(--border-soft)',
                background: isDone ? 'rgba(0, 255, 159, 0.02)' : 'var(--surface)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: '1.5rem',
                flexWrap: 'wrap'
              }}
            >
              {/* Left Column: Icon & Info */}
              <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flex: 1, minWidth: '260px' }}>
                <div style={{ 
                  width: 44, height: 44, borderRadius: '50%',
                  background: isDone ? 'rgba(0, 255, 159, 0.1)' : 'rgba(255, 255, 255, 0.03)',
                  border: isDone ? '1px solid rgba(0, 255, 159, 0.3)' : '1px solid var(--border-soft)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '1.2rem', color: isDone ? 'var(--success)' : 'var(--text-muted)'
                }}>
                  {isDone ? <CheckCircle size={20} /> : <Clock size={20} />}
                </div>
                
                <div style={{ flex: 1 }}>
                  <h3 style={{ fontSize: '.95rem', fontWeight: 800, color: '#FFF' }}>{quest.title}</h3>
                  <div style={{ fontSize: '.78rem', color: 'var(--text-secondary)', marginTop: '.15rem' }}>{quest.desc}</div>
                  
                  {/* Progress Line */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '.75rem', marginTop: '.65rem' }}>
                    <div className="progress-bar" style={{ height: '4px', width: '120px' }}>
                      <div className="progress-fill" style={{ width: `${questPercent}%`, backgroundColor: isDone ? 'var(--success)' : 'var(--pink)' }} />
                    </div>
                    <span style={{ fontSize: '.72rem', fontWeight: 700, color: isDone ? 'var(--success)' : 'var(--text-muted)' }}>
                      {quest.current}/{quest.target} ({questPercent}%)
                    </span>
                  </div>
                </div>
              </div>

              {/* Right Column: Rewards & Actions */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', flexWrap: 'wrap' }}>
                {/* Rewards values */}
                <div style={{ display: 'flex', gap: '.85rem', fontSize: '.8rem', fontWeight: 700 }}>
                  <span style={{ color: '#FFB703', background: 'rgba(255,183,3,0.08)', padding: '.25rem .5rem', borderRadius: '6px', border: '1px solid rgba(255,183,3,0.15)' }}>
                    🪙 +{quest.rewardCoins}
                  </span>
                  <span style={{ color: 'var(--cyan)', background: 'rgba(0,245,255,0.08)', padding: '.25rem .5rem', borderRadius: '6px', border: '1px solid rgba(0,245,255,0.15)' }}>
                    ⚡ +{quest.rewardExp} EXP
                  </span>
                </div>

                {/* Action button */}
                <button
                  onClick={() => handleClaim(quest.id)}
                  disabled={!isDone || quest.claimed}
                  className="btn btn-sm"
                  style={{
                    background: quest.claimed 
                      ? 'rgba(255, 255, 255, 0.03)' 
                      : isDone 
                        ? 'linear-gradient(135deg, #00FF9F 0%, #00F5FF 100%)' 
                        : 'rgba(255, 255, 255, 0.05)',
                    color: quest.claimed 
                      ? 'var(--text-muted)' 
                      : isDone 
                        ? '#0A0516' 
                        : 'var(--text-muted)',
                    fontWeight: 800,
                    cursor: (!isDone || quest.claimed) ? 'not-allowed' : 'pointer',
                    border: 'none',
                    padding: '.5rem 1.25rem',
                    borderRadius: '8px',
                    minWidth: '95px',
                    textAlign: 'center'
                  }}
                >
                  {quest.claimed 
                    ? (lang === 'en' ? 'Claimed' : 'Đã nhận') 
                    : isDone 
                      ? (lang === 'en' ? 'Claim' : 'Nhận quà') 
                      : (lang === 'en' ? 'In Progress' : 'Chưa xong')}
                </button>
              </div>

            </div>
          );
        })}
      </div>
      
    </div>
  );
}
