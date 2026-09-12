import React from 'react';

const roles = [
  { id: 'user',  label: '👤 User' },
  { id: 'staff', label: '🛡️ Staff' },
  { id: 'admin', label: '⚙️ Admin' },
];

export default function RoleSwitcher({ currentRole, onSwitch }) {
  return (
    <div className="role-switcher">
      <div className="role-switcher-label">🎭 Demo Role</div>
      {roles.map(r => (
        <button
          key={r.id}
          className={`role-btn ${currentRole === r.id ? 'active' : ''}`}
          onClick={() => onSwitch(r.id)}
        >
          {r.label}
        </button>
      ))}
    </div>
  );
}
