import React, { useState } from 'react';
import { Flag, Zap, Shield, CheckCircle, AlertTriangle, Clock, UserX } from 'lucide-react';
import { MOCK_REPORTS } from '../../data/mockData';

const SEV = {
  high:   { badge: 'badge-danger',   icon: <AlertTriangle size={13}/>, label: 'Nghiêm trọng' },
  medium: { badge: 'badge-warning',  icon: <Clock size={13}/>,         label: 'Trung bình' },
  low:    { badge: 'badge-success',  icon: <CheckCircle size={13}/>,   label: 'Nhẹ' },
};

export default function ReportManager() {
  const [reports, setReports] = useState(MOCK_REPORTS);

  function resolve(id, action) {
    setReports(prev => prev.map(r => r.id === id ? { ...r, status: 'resolved', action } : r));
  }

  const pending  = reports.filter(r => r.status === 'pending');
  const resolved = reports.filter(r => r.status === 'resolved');

  return (
    <div>
      <div className="section-header">
        <h2 className="section-title">🚨 Kiểm duyệt báo cáo</h2>
        <span className="badge badge-danger">{pending.length} chờ xử lý</span>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '1rem', marginBottom: '2rem' }}>
        {[
          { label: 'Chờ xử lý', value: pending.length, color: 'var(--danger)', icon: <Flag size={18}/> },
          { label: 'Đã xử lý', value: resolved.length, color: 'var(--success)', icon: <CheckCircle size={18}/> },
          { label: 'Tổng', value: reports.length, color: 'var(--purple)', icon: <Shield size={18}/> },
        ].map((s, i) => (
          <div key={i} className="stat-card">
            <div className="stat-icon" style={{ background: `${s.color}15` }}>
              <span style={{ color: s.color }}>{s.icon}</span>
            </div>
            <div className="stat-value" style={{ color: s.color, fontSize: '1.6rem' }}>{s.value}</div>
            <div className="stat-label">{s.label}</div>
          </div>
        ))}
      </div>

      {pending.length > 0 && (
        <div className="card" style={{ overflow: 'hidden', marginBottom: '1.5rem' }}>
          <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid var(--border-soft)', fontWeight: 700, fontSize: '.9rem', color: 'var(--text-primary)' }}>
            ⏳ Chờ xử lý ({pending.length})
          </div>
          {pending.map(r => {
            const sev = SEV[r.severity];
            return (
              <div key={r.id} style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid rgba(255, 255, 255, .04)', transition: 'var(--tr)' }}
                onMouseEnter={e => e.currentTarget.style.background='rgba(157, 78, 221, .08)'}
                onMouseLeave={e => e.currentTarget.style.background='transparent'}
              >
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '1rem' }}>
                  <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'var(--pink-soft)', color: 'var(--pink)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.2rem', flexShrink: 0 }}>👤</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', marginBottom: '.2rem', flexWrap: 'wrap' }}>
                      <span style={{ fontWeight: 700 }}>{r.reportedName}</span>
                      <span className={`badge ${sev.badge}`} style={{ fontSize: '.68rem' }}>{sev.icon} {sev.label}</span>
                    </div>
                    <div style={{ fontSize: '.84rem', color: 'var(--text-secondary)', marginBottom: '.4rem' }}>{r.reason}</div>
                    
                    {/* AI Toxicity Score analysis */}
                    <div style={{ 
                      background: 'rgba(0, 245, 255, 0.04)', 
                      border: '1px solid rgba(0, 245, 255, 0.15)',
                      borderRadius: '8px',
                      padding: '.5rem .75rem',
                      marginBottom: '.5rem',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '.15rem',
                      maxWidth: '450px'
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '.3rem', fontSize: '.74rem', color: 'var(--cyan)', fontWeight: 700 }}>
                        <Zap size={11} />
                        <span>🤖 AI Guard Sentiment Review</span>
                      </div>
                      <div style={{ fontSize: '.72rem', color: 'var(--text-secondary)', lineHeight: 1.3 }}>
                        {r.id === 'r1' && <span>Đánh giá độ độc hại: <strong style={{ color: 'var(--danger)' }}>86% Toxic</strong> (Đe dọa & Lăng mạ đối thủ trong game).</span>}
                        {r.id === 'r2' && <span>Đánh giá độ độc hại: <strong style={{ color: 'var(--warning)' }}>45% Spam</strong> (Quảng bá trang web bên thứ ba trái phép).</span>}
                        {r.id !== 'r1' && r.id !== 'r2' && <span>Đánh giá độ độc hại: <strong style={{ color: 'var(--success)' }}>12% Safe</strong> (Không phát hiện ngôn từ gây thù ghét).</span>}
                      </div>
                    </div>

                    <div style={{ fontSize: '.73rem', color: 'var(--text-muted)' }}>Bởi {r.reportedBy} · {r.reportDate}</div>
                  </div>
                  <div style={{ display: 'flex', gap: '.5rem', flexShrink: 0 }}>
                    <button className="btn btn-sm btn-soft" onClick={() => resolve(r.id, 'warned')} style={{ gap: '.3rem', color: 'var(--warning)', background: 'rgba(245,158,11,.1)', border: '1px solid rgba(245,158,11,.2)' }}>
                      <CheckCircle size={12}/> Cảnh cáo
                    </button>
                    <button className="btn btn-sm" onClick={() => resolve(r.id, 'banned')} style={{ gap: '.3rem', background: 'rgba(239,68,68,.1)', color: 'var(--danger)', border: '1px solid rgba(239,68,68,.2)' }}>
                      <UserX size={12}/> Khóa TK
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {resolved.length > 0 && (
        <div className="card" style={{ overflow: 'hidden' }}>
          <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid var(--border-soft)', fontWeight: 700, fontSize: '.9rem', color: 'var(--text-secondary)' }}>
            ✅ Đã xử lý ({resolved.length})
          </div>
          {resolved.map(r => (
            <div key={r.id} style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255, 255, 255, .04)', display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'var(--surface-2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>👤</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: '.9rem' }}>{r.reportedName}</div>
                <div style={{ fontSize: '.76rem', color: 'var(--text-muted)' }}>{r.reason}</div>
              </div>
              <span className="badge badge-success" style={{ fontSize: '.7rem' }}>
                <CheckCircle size={10}/> {r.action === 'banned' ? 'Đã khóa' : 'Đã cảnh cáo'}
              </span>
            </div>
          ))}
        </div>
      )}

      {pending.length === 0 && (
        <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
          <CheckCircle size={40} style={{ margin: '0 auto 1rem', color: 'var(--success)' }}/>
          <p>Tất cả báo cáo đã được xử lý! 🎉</p>
        </div>
      )}
    </div>
  );
}
