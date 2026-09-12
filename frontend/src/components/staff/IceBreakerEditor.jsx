import React, { useState } from 'react';
import { Plus, Edit3, Trash2, ToggleLeft, ToggleRight, Zap, Check, X } from 'lucide-react';
import { MOCK_ICEBREAKERS } from '../../data/mockData';

const CATEGORIES = ['Strategy', 'Lobby Style', 'Team Role', 'Game Genre'];

export default function IceBreakerEditor() {
  const [questions, setQuestions] = useState(MOCK_ICEBREAKERS);
  const [adding, setAdding] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ question_en: '', question_vi: '', category: 'Strategy', active: true });

  function saveNew() {
    if (!form.question_en.trim()) return;
    setQuestions(prev => [...prev, { id: `ib${Date.now()}`, ...form }]);
    setForm({ question_en: '', question_vi: '', category: 'Strategy', active: true });
    setAdding(false);
  }

  function saveEdit() {
    setQuestions(prev => prev.map(q => q.id === editing ? { ...q, ...form } : q));
    setEditing(null);
  }

  function startEdit(q) {
    setEditing(q.id);
    setForm({ question_en: q.question_en || q.question || '', question_vi: q.question_vi || '', category: q.category, active: q.active });
    setAdding(false);
  }

  function remove(id) {
    setQuestions(prev => prev.filter(q => q.id !== id));
  }

  function toggle(id) {
    setQuestions(prev => prev.map(q => q.id === id ? { ...q, active: !q.active } : q));
  }

  const active  = questions.filter(q => q.active);
  const inactive = questions.filter(q => !q.active);

  return (
    <div>
      <div className="section-header">
        <div>
          <h2 className="section-title">⚡ Quest & Challenge Editor</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '.85rem', marginTop: '.25rem' }}>
            {active.length} active quests · {inactive.length} hidden
          </p>
        </div>
        <button className="btn btn-primary btn-sm" onClick={() => { setAdding(true); setEditing(null); setForm({ question_en: '', question_vi: '', category: 'Strategy', active: true }); }} style={{ gap: '.4rem', background: 'var(--grad-brand)', border: 'none', color: '#0A0516' }}>
          <Plus size={15} /> Add Quest Question
        </button>
      </div>

      {/* Add / Edit Form */}
      {(adding || editing) && (
        <div className="card animate-scale-in" style={{ padding: '1.5rem', borderRadius: 'var(--radius-lg)', marginBottom: '1.5rem', border: '1px solid rgba(0,245,255,.25)' }}>
          <h3 style={{ fontSize: '.95rem', fontWeight: 700, marginBottom: '1rem', color: 'var(--cyan)' }}>
            {editing ? '✏️ Edit Quest Question' : '➕ Add New Quest Question'}
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '.75rem' }}>
            <div>
              <label style={{ fontSize: '.75rem', color: 'var(--text-secondary)', display: 'block', marginBottom: '.3rem' }}>English Question</label>
              <textarea
                className="input"
                rows={2}
                placeholder="Enter English quest question..."
                value={form.question_en}
                onChange={e => setForm(f => ({ ...f, question_en: e.target.value }))}
                style={{ resize: 'none' }}
              />
            </div>
            <div>
              <label style={{ fontSize: '.75rem', color: 'var(--text-secondary)', display: 'block', marginBottom: '.3rem' }}>Vietnamese Question / Câu hỏi tiếng Việt</label>
              <textarea
                className="input"
                rows={2}
                placeholder="Nhập câu hỏi tiếng Việt..."
                value={form.question_vi}
                onChange={e => setForm(f => ({ ...f, question_vi: e.target.value }))}
                style={{ resize: 'none' }}
              />
            </div>
            <div style={{ display: 'flex', gap: '.75rem', flexWrap: 'wrap', alignItems: 'center' }}>
              <select
                className="input"
                style={{ width: 'auto', flex: '1 1 160px' }}
                value={form.category}
                onChange={e => setForm(f => ({ ...f, category: e.target.value }))}
              >
                {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
              <label style={{ display: 'flex', alignItems: 'center', gap: '.5rem', cursor: 'pointer', fontSize: '.85rem', color: 'var(--text-secondary)' }}>
                <input type="checkbox" checked={form.active} onChange={e => setForm(f => ({ ...f, active: e.target.checked }))} style={{ accentColor: 'var(--cyan)' }} />
                Activate immediately
              </label>
              <div style={{ display: 'flex', gap: '.5rem', marginLeft: 'auto' }}>
                <button className="btn btn-outline btn-sm" onClick={() => { setAdding(false); setEditing(null); }}>
                  <X size={14} /> Cancel
                </button>
                <button className="btn btn-primary btn-sm" onClick={editing ? saveEdit : saveNew} style={{ background: 'var(--grad-brand)', border: 'none', color: '#0A0516' }}>
                  <Check size={14} /> Save
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Active questions */}
      <div style={{ marginBottom: '1.5rem' }}>
        <div style={{ fontSize: '.8rem', fontWeight: 700, color: 'var(--success)', letterSpacing: '.06em', textTransform: 'uppercase', marginBottom: '.75rem' }}>
          ✅ Active Quests ({active.length})
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '.6rem' }}>
          {active.map(q => (
            <QuestionRow key={q.id} q={q} onEdit={startEdit} onRemove={remove} onToggle={toggle} isEditing={editing === q.id} />
          ))}
        </div>
      </div>

      {/* Inactive questions */}
      {inactive.length > 0 && (
        <div>
          <div style={{ fontSize: '.8rem', fontWeight: 700, color: 'var(--text-muted)', letterSpacing: '.06em', textTransform: 'uppercase', marginBottom: '.75rem' }}>
            ⏸ Hidden Quests ({inactive.length})
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '.6rem' }}>
            {inactive.map(q => (
              <QuestionRow key={q.id} q={q} onEdit={startEdit} onRemove={remove} onToggle={toggle} isEditing={editing === q.id} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function QuestionRow({ q, onEdit, onRemove, onToggle, isEditing }) {
  return (
    <div
      className="card"
      style={{
        padding: '1rem 1.25rem',
        borderRadius: 'var(--radius-md)',
        display: 'flex', alignItems: 'center', gap: '1rem',
        opacity: q.active ? 1 : 0.55,
        border: isEditing ? '1.5px solid var(--cyan)' : '1px solid var(--border-soft)',
        transition: 'var(--tr)',
        background: 'var(--surface-2)'
      }}
    >
      <Zap size={16} style={{ color: q.active ? 'var(--cyan)' : 'var(--text-muted)', flexShrink: 0 }} />
      <div style={{ flex: 1 }}>
        <p style={{ fontSize: '.88rem', marginBottom: '.25rem', fontWeight: 600, color: '#FFF' }}>{q.question_en || q.question}</p>
        <p style={{ fontSize: '.78rem', color: 'var(--text-secondary)', marginBottom: '.35rem' }}>🇻🇳 {q.question_vi || 'Chưa dịch'}</p>
        <span className="badge badge-purple" style={{ fontSize: '.68rem' }}>{q.category}</span>
      </div>
      <div style={{ display: 'flex', gap: '.4rem', flexShrink: 0 }}>
        <button className="btn btn-ghost btn-icon btn-sm" onClick={() => onToggle(q.id)} title={q.active ? 'Hide' : 'Activate'}>
          {q.active ? <ToggleRight size={18} style={{ color: 'var(--success)' }} /> : <ToggleLeft size={18} />}
        </button>
        <button className="btn btn-ghost btn-icon btn-sm" onClick={() => onEdit(q)} title="Edit">
          <Edit3 size={15} style={{ color: 'var(--cyan)' }} />
        </button>
        <button className="btn btn-ghost btn-icon btn-sm" onClick={() => onRemove(q.id)} title="Delete">
          <Trash2 size={15} style={{ color: 'var(--danger)' }} />
        </button>
      </div>
    </div>
  );
}
