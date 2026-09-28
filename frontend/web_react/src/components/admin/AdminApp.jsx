import React, { useState } from 'react';
import { BarChart2, Users, DollarSign } from 'lucide-react';
import AnalyticsCharts from './AnalyticsCharts';
import UserManagement from './UserManagement';
import CostStructure from './CostStructure';

const NAV = [
  { id: 'analytics', label: 'Analytics / Thống kê', icon: <BarChart2 size={17} /> },
  { id: 'users',     label: 'User Manager / Thành viên',   icon: <Users size={17} /> },
  { id: 'costs',     label: 'Cost Structure / Chi phí',    icon: <DollarSign size={17} /> },
];

export default function AdminApp({ vipCount }) {
  const [page, setPage] = useState('analytics');

  return (
    <div className="sidebar-layout">
      <div className="sidebar">
        <div className="sidebar-logo">
          ⚙️ <span className="gradient-text">Admin Panel</span>
        </div>
        <div className="sidebar-group-label">System Admin / Quản trị</div>
        {NAV.map(n => (
          <div key={n.id} className={`sidebar-nav-item ${page === n.id ? 'active' : ''}`} onClick={() => setPage(n.id)}>
            {n.icon} {n.label}
          </div>
        ))}
        <div style={{ marginTop: 'auto' }}>
          <div className="card" style={{ padding: '.85rem 1rem', border: '1px solid var(--border-soft)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem' }}>
              <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--grad-brand)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.9rem', color: '#fff', border: '2px solid rgba(255,255,255,0.15)', boxShadow: 'var(--shadow-sm)' }}>⚙️</div>
              <div>
                <div style={{ fontWeight: 700, fontSize: '.84rem' }}>Super Admin</div>
                <div style={{ fontSize: '.7rem', color: 'var(--cyan)', fontWeight: 600 }}>Admin • Root</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className="sidebar-content" style={{ background: 'var(--bg)', minHeight: '100vh', color: 'var(--text-primary)' }}>
        {page === 'analytics' && <AnalyticsCharts vipCount={vipCount} />}
        {page === 'users'     && <UserManagement />}
        {page === 'costs'     && <CostStructure />}
      </div>
    </div>
  );
}
