import React, { useState } from 'react';
import { ChevronLeft, Save, Eye, EyeOff, Sparkles, Tag, Check, Award, MapPin } from 'lucide-react';

const MBTI_TYPES = [
  'INTJ (Tactician)', 'INTP (Theorycrafter)', 'ENTJ (Shotcaller)', 'ENTP (Innovator)',
  'INFJ (Guide)', 'INFP (Lorekeeper)', 'ENFJ (Motivator)', 'ENFP (Lobby Starter)',
  'ISTJ (Grinder)', 'ISFP (Artist)', 'ESTJ (Captain)', 'ESFP (Bard)',
  'ISTP (Duelist)', 'ISFJ (Support)', 'ESTP (Fragger)', 'ESFJ (Co-op Buddy)'
];

const PRESET_INTERESTS = [
  'Valorant', 'Genshin Impact', 'Honkai: Star Rail', 'Wuthering Waves', 'League of Legends',
  'CS2', 'Apex Legends', 'Minecraft', 'Gacha', 'MOBA', 'FPS', 'RPG', 'Strategy',
  'Try-hard', 'Casual', 'Explorer', 'Mentor', 'Co-op'
];

const PRESET_EMOJIS = ['🎮', '👾', '🧙‍♂️', '⚔️', '🛡️', '🔫', '🏹', '👑', '🏆', '🌸', '🎸', '🌿', '☕', '🎨', '📷', '💫', '🌻', '🛹'];

const PRESET_GRADS = [
  { name: 'Neon Dream',  val: 'linear-gradient(135deg,#7B2CBF,#00F5FF)' },
  { name: 'Toxic Mint',  val: 'linear-gradient(135deg,#00F5FF,#00FF9F)' },
  { name: 'Doom Flame',  val: 'linear-gradient(135deg,#FF4D6D,#9D4EDD)' },
  { name: 'Royal Purple', val: 'linear-gradient(135deg,#9D4EDD,#7B2CBF)' },
  { name: 'Amber Glow',  val: 'linear-gradient(135deg,#FFB703,#FF4D6D)' }
];

/* ── Silhouette SVG for Preview ── */
function SilhouetteSVG({ color1 = '#9D4EDD', color2 = '#00F5FF' }) {
  return (
    <svg width="140" height="170" viewBox="0 0 180 220" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ opacity: .45 }}>
      <defs>
        <linearGradient id="sil-grad-user" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={color1} stopOpacity=".75"/>
          <stop offset="100%" stopColor={color2} stopOpacity=".55"/>
        </linearGradient>
      </defs>
      <ellipse cx="90" cy="60" rx="38" ry="42" fill="url(#sil-grad-user)"/>
      <rect x="76" y="98" width="28" height="20" rx="8" fill="url(#sil-grad-user)"/>
      <path d="M20 200 Q30 130 90 118 Q150 130 160 200 Z" fill="url(#sil-grad-user)"/>
      <ellipse cx="90" cy="32" rx="36" ry="22" fill="url(#sil-grad-user)" opacity=".6"/>
      <ellipse cx="58" cy="55" rx="12" ry="30" fill="url(#sil-grad-user)" opacity=".4"/>
      <ellipse cx="122" cy="55" rx="12" ry="30" fill="url(#sil-grad-user)" opacity=".4"/>
    </svg>
  );
}

export default function UserProfile({ myProfile, onSave, onBack, t, lang, setLang }) {
  const [formData, setFormData] = useState({ ...myProfile });
  const [newTag, setNewTag] = useState('');
  const [previewMode, setPreviewMode] = useState('blind'); // 'blind' | 'public'
  const [savedSuccess, setSavedSuccess] = useState(false);

  function handleSave(e) {
    e.preventDefault();
    onSave(formData);
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3000);
  }

  function toggleInterest(tag) {
    const next = formData.interests.includes(tag)
      ? formData.interests.filter(t => t !== tag)
      : [...formData.interests, tag];
    setFormData({ ...formData, interests: next });
  }

  function handleAddCustomTag() {
    const clean = newTag.trim();
    if (!clean) return;
    if (!formData.interests.includes(clean)) {
      setFormData({ ...formData, interests: [...formData.interests, clean] });
    }
    setNewTag('');
  }

  const lifestyleLabel = formData.lifestyle.includes('Night') 
    ? t('profile.lifestyleOwl') 
    : formData.lifestyle.includes('Morning') 
      ? t('profile.lifestyleBird') 
      : t('profile.lifestyleFlex');

  return (
    <div style={{ minHeight: '100vh', padding: '2.5rem 2rem', maxWidth: 1000, margin: '0 auto', background: 'var(--bg)' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '2rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <button className="btn btn-outline btn-sm" onClick={onBack}><ChevronLeft size={20}/></button>
          <div>
            <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#FFF' }}>{t('profile.title')}</h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: '.82rem', marginTop: '.2rem' }}>
              {t('profile.subtitle')}
            </p>
          </div>
        </div>

        {savedSuccess && (
          <div className="badge badge-success animate-fade-in" style={{ padding: '.5rem 1rem', fontSize: '.85rem' }}>
            {t('profile.success')}
          </div>
        )}
      </div>

      <div className="responsive-profile" style={{ alignItems: 'start' }}>
        
        {/* ── LEFT: Edit Form ── */}
        <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          
          {/* Language select card */}
          <div className="card" style={{ padding: '1.75rem', border: '1px solid var(--border-soft)' }}>
            <h2 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '.4rem' }}>
              🌐 {t('profile.langCardTitle')}
            </h2>
            <div>
              <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>
                {t('profile.langSelectLabel')}
              </label>
              <select className="input" value={lang} onChange={e => setLang(e.target.value)}>
                <option value="en">English (Default)</option>
                <option value="vi">Tiếng Việt</option>
              </select>
            </div>
          </div>

          {/* Basic info section */}
          <div className="card" style={{ padding: '1.75rem', border: '1px solid var(--border-soft)' }}>
            <h2 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '.4rem' }}>
              {t('profile.basicInfo')}
            </h2>
            
            <div className="profile-basic-grid">
              <div>
                <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{t('profile.nameLabel')}</label>
                <input required className="input" value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} placeholder="VD: Khánh Linh" />
              </div>
              <div>
                <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{t('profile.ageLabel')}</label>
                <input required type="number" min={18} max={100} className="input" value={formData.age} onChange={e => setFormData({ ...formData, age: parseInt(e.target.value) || 18 })} />
              </div>
              <div>
                <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{t('profile.mbtiLabel')}</label>
                <select className="input" value={formData.mbti} onChange={e => setFormData({ ...formData, mbti: e.target.value })}>
                  {MBTI_TYPES.map(m => <option key={m} value={m}>{m}</option>)}
                </select>
              </div>
            </div>

            <div className="responsive-grid-2" style={{ marginBottom: '1.25rem' }}>
              <div>
                <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{t('profile.lifestyleLabel')}</label>
                <select className="input" value={formData.lifestyle} onChange={e => setFormData({ ...formData, lifestyle: e.target.value })}>
                  <option value="Night Raider (Night)">{t('profile.lifestyleOwl')}</option>
                  <option value="Early Grinder (Morning)">{t('profile.lifestyleBird')}</option>
                  <option value="Flexible Hours">{t('profile.lifestyleFlex')}</option>
                </select>
              </div>
              <div>
                <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{t('profile.locationLabel')}</label>
                <input required className="input" value={formData.location} onChange={e => setFormData({ ...formData, location: e.target.value })} placeholder="VD: Server TP.HCM, Server Hà Nội" />
              </div>
            </div>

            <div>
              <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{t('profile.bioLabel')}</label>
              <textarea required rows={2} className="input" value={formData.bio} onChange={e => setFormData({ ...formData, bio: e.target.value })} placeholder={t('profile.bioPlaceholder')} style={{ resize: 'none' }} />
            </div>
          </div>

          {/* Avatar & Gradient selector */}
          <div className="card" style={{ padding: '1.75rem', border: '1px solid var(--border-soft)' }}>
            <h2 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '.4rem' }}>
              {t('profile.avatarTitle')}
            </h2>

            <div className="profile-avatar-grid">
              <div style={{
                width: 80, height: 80, borderRadius: '50%',
                background: formData.avatarBg,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: '2.5rem', boxShadow: 'var(--shadow-md)', border: '3px solid rgba(255,255,255,0.1)'
              }}>
                {formData.avatar}
              </div>

              <div>
                <div style={{ marginBottom: '1rem' }}>
                  <label style={{ fontSize: '.78rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{t('profile.emojiLabel')}</label>
                  <div style={{ display: 'flex', gap: '.4rem', overflowX: 'auto', paddingBottom: '.3rem' }}>
                    {PRESET_EMOJIS.map(em => (
                      <button key={em} type="button" onClick={() => setFormData({ ...formData, avatar: em })} style={{
                        fontSize: '1.3rem', width: 34, height: 34, borderRadius: 8,
                        background: formData.avatar === em ? 'var(--pink-soft)' : 'var(--surface-3)',
                        border: `2.5px solid ${formData.avatar === em ? 'var(--cyan)' : 'transparent'}`,
                        transition: 'var(--tr)', cursor: 'pointer', flexShrink: 0
                      }}>{em}</button>
                    ))}
                  </div>
                </div>

                <div>
                  <label style={{ fontSize: '.78rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{t('profile.gradientLabel')}</label>
                  <div style={{ display: 'flex', gap: '.45rem' }}>
                    {PRESET_GRADS.map(g => (
                      <button key={g.name} type="button" onClick={() => setFormData({ ...formData, avatarBg: g.val })} style={{
                        width: 26, height: 26, borderRadius: '50%', background: g.val,
                        border: `2px solid ${formData.avatarBg === g.val ? 'var(--text-primary)' : '#140E28'}`,
                        boxShadow: 'var(--shadow-sm)', transition: 'var(--tr)', cursor: 'pointer'
                      }} title={g.name} />
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Compatibility tags section */}
          <div className="card" style={{ padding: '1.75rem', border: '1px solid var(--border-soft)' }}>
            <h2 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '.4rem' }}>
              <Tag size={16} style={{ color: 'var(--cyan)' }}/> {t('profile.interestsTitle')}
            </h2>
            <p style={{ fontSize: '.78rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>
              {t('profile.interestsDesc')}
            </p>

            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '.4rem', marginBottom: '1.25rem' }}>
              {PRESET_INTERESTS.map(tag => {
                const selected = formData.interests.includes(tag);
                return (
                  <button key={tag} type="button" onClick={() => toggleInterest(tag)} className={`tag ${selected ? 'selected' : ''}`} style={{
                    cursor: 'pointer', transition: 'var(--tr)', padding: '.35rem .9rem', borderRadius: 99,
                    border: '1px solid var(--border-soft)',
                    background: selected ? 'var(--pink-soft)' : 'var(--surface)',
                    color: selected ? 'var(--cyan)' : 'var(--text-secondary)',
                    borderColor: selected ? 'var(--cyan)' : 'var(--border-soft)',
                    fontWeight: selected ? 600 : 400
                  }}>
                    {selected && <Check size={11} style={{ marginRight: '.2rem', display: 'inline' }}/>}
                    #{tag}
                  </button>
                );
              })}
            </div>

            <div style={{ display: 'flex', gap: '.5rem', maxWidth: 300 }}>
              <input className="input input-sm" placeholder={t('profile.interestsCustomPlaceholder')} value={newTag} onChange={e => setNewTag(e.target.value)} onKeyDown={e => e.key === 'Enter' && (e.preventDefault(), handleAddCustomTag())} />
              <button type="button" onClick={handleAddCustomTag} className="btn btn-outline btn-sm">{t('profile.interestsAddBtn')}</button>
            </div>
          </div>

          {/* Custom prompts section */}
          <div className="card" style={{ padding: '1.75rem', border: '1px solid var(--border-soft)' }}>
            <h2 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '.4rem' }}>
              {t('profile.qaTitle')}
            </h2>
            <p style={{ fontSize: '.78rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>
              {t('profile.qaDesc')}
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div>
                <label style={{ fontSize: '.8rem', fontWeight: 700, color: 'var(--cyan)', display: 'block', marginBottom: '.4rem' }}>{t('profile.qaSunday')}</label>
                <input required className="input" value={formData.sundayPrompt} onChange={e => setFormData({ ...formData, sundayPrompt: e.target.value })} placeholder={t('profile.qaSundayPlaceholder')} />
              </div>
              <div>
                <label style={{ fontSize: '.8rem', fontWeight: 700, color: 'var(--cyan)', display: 'block', marginBottom: '.4rem' }}>{t('profile.qaOverthink')}</label>
                <input required className="input" value={formData.overthinkPrompt} onChange={e => setFormData({ ...formData, overthinkPrompt: e.target.value })} placeholder={t('profile.qaOverthinkPlaceholder')} />
              </div>
            </div>
          </div>

          {/* Save button */}
          <button type="submit" className="btn btn-primary btn-lg" style={{ alignSelf: 'flex-start', minWidth: 200, justifyContent: 'center', gap: '.6rem', background: 'var(--grad-brand)', border: 'none', color: '#0A0516' }}>
            <Save size={18}/> {t('profile.saveBtn')}
          </button>
        </form>

        {/* ── RIGHT: Preview Card ── */}
        <div style={{ position: 'sticky', top: '90px', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '.25rem' }}>
            <h3 style={{ fontSize: '.9rem', fontWeight: 800, color: 'var(--text-secondary)' }}>{t('profile.previewHeader')}</h3>
            
            {/* Preview Toggle tabs */}
            <div style={{ display: 'flex', gap: '.25rem', background: 'var(--surface-3)', padding: '.2rem', borderRadius: 99 }}>
              {[
                { id: 'blind', label: t('profile.previewBlind') },
                { id: 'public', label: t('profile.previewPublic') }
              ].map(tTab => (
                <button key={tTab.id} type="button" onClick={() => setPreviewMode(tTab.id)} style={{
                  padding: '.25rem .6rem', borderRadius: 99, fontSize: '.68rem', fontWeight: 700,
                  background: previewMode === tTab.id ? 'var(--surface-2)' : 'transparent',
                  color: previewMode === tTab.id ? 'var(--cyan)' : 'var(--text-muted)',
                  border: 'none',
                  cursor: 'pointer', transition: 'var(--tr)'
                }}>{tTab.label}</button>
              ))}
            </div>
          </div>

          <div className="card" style={{ overflow: 'hidden', border: '1.5px solid rgba(157,78,221,.25)' }}>
            {/* Profile Avatar background */}
            <div style={{
              position: 'relative',
              background: formData.avatarBg,
              minHeight: 220, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden',
              transition: 'all .3s ease'
            }}>
              {previewMode === 'blind' ? (
                <>
                  <SilhouetteSVG color1="#FFFFFF" color2="#FFFFFF" />
                  <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '.5rem', textAlign: 'center', background: 'rgba(20,14,40,.85)', borderTop: '1px solid rgba(157,78,221,.25)', fontSize: '.68rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '.3rem' }}>
                    <EyeOff size={11}/> {t('profile.previewBlindOverlay')}
                  </div>
                </>
              ) : (
                <>
                  <div style={{
                    width: 100, height: 100, borderRadius: '50%',
                    background: 'rgba(20,14,40,.85)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: '3.2rem', boxShadow: 'var(--shadow-md)', border: '4px solid rgba(255,255,255,0.15)',
                    animation: 'scaleIn .3s ease'
                  }}>
                    {formData.avatar}
                  </div>
                  <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '.5rem', textAlign: 'center', background: 'rgba(20,14,40,.85)', borderTop: '1px solid rgba(157,78,221,.25)', fontSize: '.68rem', color: 'var(--success)', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '.3rem' }}>
                    <Eye size={11}/> {t('profile.previewPublicOverlay')}
                  </div>
                </>
              )}

              {/* Match match ring */}
              <div style={{ position: 'absolute', top: 12, right: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', width: 42, height: 42, background: 'rgba(20,14,40,.85)', border: '1px solid rgba(157,78,221,.25)', borderRadius: '50%', fontSize: '.8rem', fontWeight: 800, color: 'var(--cyan)', boxShadow: 'var(--shadow-sm)' }}>
                {t('profile.previewYou')}
              </div>

              {/* AI Vibe Match label */}
              <div style={{ position: 'absolute', top: 12, left: 12, display: 'flex', alignItems: 'center', gap: '.3rem', background: 'rgba(20,14,40,.85)', border: '1px solid rgba(157,78,221,.25)', borderRadius: 99, padding: '.2rem .6rem' }}>
                <Sparkles size={10} style={{ color: 'var(--cyan)' }} />
                <span style={{ fontSize: '.62rem', fontWeight: 700, color: 'var(--cyan)' }}>{t('profile.previewVibe')}</span>
              </div>
            </div>

            {/* Profile Info Details */}
            <div style={{ padding: '1.25rem' }}>
              <div style={{ marginBottom: '.6rem' }}>
                <h2 style={{ fontSize: '1.2rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '.4rem' }}>
                  {formData.name || 'Tên hiển thị'}, <span style={{ fontWeight: 500 }}>{formData.age}</span>
                </h2>
                <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem', color: 'var(--text-secondary)', fontSize: '.75rem', marginTop: '.2rem' }}>
                  <span>{lifestyleLabel}</span>
                  <span>·</span>
                  <span style={{ fontWeight: 600, color: 'var(--cyan)' }}>{formData.mbti.split(' ')[0]}</span>
                  <span>·</span>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '.1rem' }}><MapPin size={10}/> {formData.location}</span>
                </div>
              </div>

              <p style={{ fontSize: '.82rem', color: 'var(--text-secondary)', lineHeight: 1.5, marginBottom: '1rem', whiteSpace: 'pre-wrap' }}>
                {formData.bio || 'Chưa viết bio giới thiệu...'}
              </p>

              {/* Tags */}
              <div style={{ marginBottom: '1rem' }}>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '.3rem' }}>
                  {formData.interests.length > 0 ? (
                    formData.interests.map(tTag => (
                      <span key={tTag} style={{ fontSize: '.68rem', padding: '.2rem .55rem', borderRadius: 99, background: 'rgba(157,78,221,0.15)', color: 'var(--pink-light)', border: '1px solid rgba(157,78,221,0.25)' }}>#{tTag}</span>
                    ))
                  ) : (
                    <span style={{ fontSize: '.72rem', color: 'var(--text-muted)' }}>{t('profile.previewNoInterests')}</span>
                  )}
                </div>
              </div>

              {/* Prompts Preview */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '.5rem', borderTop: '1px solid var(--border-soft)', paddingTop: '.75rem' }}>
                <div style={{ background: 'var(--pink-soft)', borderRadius: 'var(--radius-md)', padding: '.6rem .75rem' }}>
                  <div style={{ fontSize: '.58rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '.05em', marginBottom: '.2rem' }}>{t('profile.qaSunday')}</div>
                  <div style={{ fontSize: '.78rem', fontWeight: 600, color: 'var(--text-primary)', lineHeight: 1.3 }}>{formData.sundayPrompt || '...'}</div>
                </div>
                <div style={{ background: 'var(--purple-soft)', borderRadius: 'var(--radius-md)', padding: '.6rem .75rem' }}>
                  <div style={{ fontSize: '.58rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '.05em', marginBottom: '.2rem' }}>{t('profile.qaOverthink')}</div>
                  <div style={{ fontSize: '.78rem', fontWeight: 600, color: 'var(--text-primary)', lineHeight: 1.3 }}>{formData.overthinkPrompt || '...'}</div>
                </div>
              </div>
            </div>
          </div>
          
        </div>
      </div>
    </div>
  );
}
