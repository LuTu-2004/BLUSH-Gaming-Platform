import React, { useState } from 'react';
import { Flag, Zap } from 'lucide-react';
import ReportManager from './ReportManager';
import IceBreakerEditor from './IceBreakerEditor';

const NAV = [
  { id: 'reports',    label: 'Report Manager / Kiểm duyệt', icon: <Flag size={17} /> },
  { id: 'icebreaker', label: 'Quest Editor / Quản lý thử thách',  icon: <Zap size={17} /> },
];

export default function StaffApp() {
  const [page, setPage] = useState('reports');

  return (
    <div className="sidebar-layout">
      <div className="sidebar">
        <div className="sidebar-logo">
          🛡️ <span className="gradient-text">Staff Portal</span>
        </div>
        <div className="sidebar-group-label">Moderator Tools / Công cụ</div>
        {NAV.map(n => (
          <div key={n.id} className={`sidebar-nav-item ${page === n.id ? 'active' : ''}`} onClick={() => setPage(n.id)}>
            {n.icon} {n.label}
          </div>
        ))}
        <div style={{ marginTop: 'auto' }}>
          <div className="card" style={{ padding: '.85rem 1rem', border: '1px solid var(--border-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem' }}>
              <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--grad-brand)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.9rem', color: '#fff', border: '2px solid rgba(255,255,255,0.15)', boxShadow: 'var(--shadow-sm)' }}>🛡️</div>
              <div>
                <div style={{ fontWeight: 700, fontSize: '.84rem' }}>Hùng Moderator</div>
                <div style={{ fontSize: '.7rem', color: 'var(--success)', fontWeight: 600 }}>Staff • Online</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className="sidebar-content" style={{ background: 'var(--bg)', minHeight: '100vh', color: 'var(--text-primary)' }}>
        {page === 'reports'    && <ReportManager />}
        {page === 'icebreaker' && <IceBreakerEditor />}
      </div>
    </div>
  );
}
