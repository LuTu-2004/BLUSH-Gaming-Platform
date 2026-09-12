import React, { useState } from 'react';
import { Search, Crown, Shield, User, Lock, Unlock, UserX, ChevronDown } from 'lucide-react';
import { MOCK_USERS, MOCK_STAFF } from '../../data/mockData';

const STATUS_STYLE = {
  active:  { badge: 'badge-success', label: 'Active / Hoạt động' },
  flagged: { badge: 'badge-danger',  label: 'Flagged / Báo cáo' },
  banned:  { badge: 'badge-warning', label: 'Banned / Khóa' },
};

export default function UserManagement() {
  const allAccounts = [
    ...MOCK_USERS.map(u => ({ ...u, role: 'user' })),
    ...MOCK_STAFF.map(s => ({ ...s, role: 'staff', status: 'active', isVip: false, mbti: '-', interests: [], bio: '-', avatar: '🛡️', avatarBg: 'linear-gradient(135deg,#00F5FF,#9D4EDD)' })),
  ];
  const [accounts, setAccounts] = useState(allAccounts);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');

  const filtered = accounts.filter(a => {
    const matchSearch = a.name.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === 'all' || a.role === filter || (filter === 'vip' && a.isVip);
    return matchSearch && matchFilter;
  });

  function toggleVip(id) {
    setAccounts(prev => prev.map(a => a.id === id ? { ...a, isVip: !a.isVip } : a));
  }

  function setRole(id, role) {
    setAccounts(prev => prev.map(a => a.id === id ? { ...a, role } : a));
  }

  function toggleStatus(id) {
    setAccounts(prev => prev.map(a =>
      a.id === id ? { ...a, status: a.status === 'banned' ? 'active' : 'banned' } : a
    ));
  }

  return (
    <div>
      <div className="section-header">
        <div>
          <h2 className="section-title">👥 Gamer & Staff Accounts / Tài khoản</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '.85rem', marginTop: '.25rem' }}>
            {accounts.filter(a=>a.role==='user').length} Gamers · {accounts.filter(a=>a.role==='staff').length} Staff · {accounts.filter(a=>a.isVip).length} VIP
          </p>
        </div>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ position: 'relative', flex: '1 1 220px' }}>
          <Search size={15} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input
            className="input"
            style={{ paddingLeft: '2.2rem' }}
            placeholder={lang => "Search by name / Tìm kiếm..."}
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        {['all', 'user', 'staff', 'vip'].map(f => (
          <button key={f} onClick={() => setFilter(f)} style={{
            padding: '.4rem 1rem', borderRadius: 99, fontSize: '.8rem', fontWeight: 600,
            background: filter === f ? 'var(--grad-brand)' : 'var(--surface-3)',
            color: filter === f ? '#0A0516' : 'var(--text-secondary)',
            border: `1px solid ${filter === f ? 'transparent' : 'var(--border-soft)'}`,
            cursor: 'pointer', transition: 'var(--tr)',
          }}>
            {f === 'all' ? 'All / Tất cả' : f === 'vip' ? '👑 VIP Pass' : f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="card" style={{ borderRadius: 'var(--radius-lg)', overflow: 'hidden', border: '1px solid var(--border-soft)' }}>
        <table className="data-table">
          <thead>
            <tr>
              <th>Gamer / User</th>
              <th>Role / Vai trò</th>
              <th>Status / Trạng thái</th>
              <th>VIP Pass</th>
              <th>Joined / Tham gia</th>
              <th>Actions / Thao tác</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(a => {
              const st = STATUS_STYLE[a.status] || STATUS_STYLE.active;
              return (
                <tr key={a.id} style={{ opacity: a.status === 'banned' ? 0.5 : 1, transition: 'var(--tr)' }}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '.75rem' }}>
                      <div style={{ width: 36, height: 36, borderRadius: '50%', background: a.avatarBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1rem', flexShrink: 0 }}>
                        {a.avatar}
                      </div>
                      <div>
                        <div style={{ fontWeight: 600, fontSize: '.9rem', color: '#FFF' }}>{a.name}</div>
                        {a.mbti !== '-' && <div style={{ fontSize: '.75rem', color: 'var(--text-muted)' }}>{a.mbti.split(' ')[0]} · {a.location || 'N/A'}</div>}
                      </div>
                    </div>
                  </td>
                  <td>
                    <select
                      className="input"
                      style={{ width: 'auto', padding: '.3rem .6rem', fontSize: '.8rem', background: 'var(--surface-3)', border: '1px solid var(--border-soft)', color: 'var(--text-primary)' }}
                      value={a.role}
                      onChange={e => setRole(a.id, e.target.value)}
                    >
                      <option value="user">👤 User</option>
                      <option value="staff">🛡️ Staff</option>
                    </select>
                  </td>
                  <td>
                    <span className={`badge ${st.badge}`} style={{ fontSize: '.72rem' }}>{st.label}</span>
                  </td>
                  <td>
                    {a.isVip
                      ? <span className="badge badge-warning" style={{ fontSize: '.72rem', color: '#0A0516', fontWeight: 800 }}>👑 VIP Pass</span>
                      : <span className="badge" style={{ fontSize: '.72rem', background: 'var(--surface-3)', color: 'var(--text-muted)', border: '1px solid var(--border-soft)' }}>Free</span>
                    }
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '.82rem' }}>{a.joinDate || '—'}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '.4rem' }}>
                      <button
                        className="btn btn-ghost btn-icon btn-sm"
                        title={a.isVip ? 'Remove VIP' : 'Grant VIP'}
                        onClick={() => toggleVip(a.id)}
                      >
                        <Crown size={14} style={{ color: a.isVip ? 'var(--warning)' : 'var(--text-muted)' }} />
                      </button>
                      <button
                        className="btn btn-ghost btn-icon btn-sm"
                        title={a.status === 'banned' ? 'Unlock Account' : 'Lock Account'}
                        onClick={() => toggleStatus(a.id)}
                      >
                        {a.status === 'banned'
                          ? <Unlock size={14} style={{ color: 'var(--success)' }} />
                          : <Lock size={14} style={{ color: 'var(--danger)' }} />
                        }
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>No gamer accounts found / Không tìm thấy tài khoản.</div>
        )}
      </div>
    </div>
  );
}
