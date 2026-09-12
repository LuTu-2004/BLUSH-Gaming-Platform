import React, { useState } from 'react';
import { ChevronRight, ChevronLeft, Sparkles } from 'lucide-react';
import { SURVEY_QUESTIONS } from '../../data/mockData';

export default function Survey({ onComplete, t, lang }) {
  const [current, setCurrent] = useState(0);
  const [answers, setAnswers] = useState({});
  const [done, setDone] = useState(false);

  const q = SURVEY_QUESTIONS[current];

  function select(value) {
    setAnswers(prev => ({ ...prev, [q.id]: value }));
  }

  function next() {
    if (current < SURVEY_QUESTIONS.length - 1) {
      setCurrent(c => c + 1);
    } else {
      setDone(true);
      setTimeout(() => onComplete(answers), 2000);
    }
  }

  if (done) return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: '1.5rem', textAlign: 'center', padding: '2rem' }}>
      <div style={{ fontSize: '4rem', animation: 'heartbeat 1.2s ease-in-out 3' }}>🛡️</div>
      <h2 style={{ fontSize: '1.6rem', fontWeight: 800 }} className="gradient-text">{t('survey.doneTitle')}</h2>
      <p style={{ color: 'var(--text-secondary)' }}>{t('survey.doneSub')}</p>
      <div style={{ width: 220, height: 5, background: 'rgba(157,78,221,.12)', borderRadius: 99, overflow: 'hidden' }}>
        <div style={{ width: '100%', height: '100%', background: 'linear-gradient(90deg,var(--pink),var(--cyan))', backgroundSize: '200% 100%', animation: 'shimmer 1.2s infinite' }} />
      </div>
    </div>
  );

  const progress = ((current + (answers[q.id] ? 1 : 0)) / SURVEY_QUESTIONS.length) * 100;
  const qText = lang === 'en' ? q.text_en : q.text_vi;

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
      <div style={{ width: '100%', maxWidth: 540 }}>

        {/* Progress */}
        <div className="animate-fade-in" style={{ marginBottom: '2rem', textAlign: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '.5rem' }}>
            <span style={{ fontSize: '.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>{t('survey.progress')} {current + 1} / {SURVEY_QUESTIONS.length}</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: '.3rem' }}>
              <Sparkles size={13} style={{ color: 'var(--pink)' }} />
              <span style={{ fontSize: '.78rem', color: 'var(--pink)', fontWeight: 600 }}>{t('survey.quizTitle')}</span>
            </div>
          </div>
          <div className="progress-bar">
            <div className="progress-fill" style={{ width: `${progress}%` }} />
          </div>
        </div>

        {/* Question */}
        <div className="card animate-scale-in" style={{ padding: '2.5rem' }} key={q.id}>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800, marginBottom: '2rem', textAlign: 'center', lineHeight: 1.35, color: 'var(--text-primary)' }}>
            {qText}
          </h2>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '.75rem' }}>
            {q.options.map(opt => {
              const sel = answers[q.id] === opt.value;
              const optLabel = lang === 'en' ? opt.label_en : opt.label_vi;
              return (
                <button key={opt.value} className={`survey-option ${sel ? 'selected' : ''}`} onClick={() => select(opt.value)}>
                  <div className="option-dot">
                     {sel && <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#fff' }} />}
                  </div>
                  {optLabel}
                </button>
              );
            })}
          </div>

          <div style={{ display: 'flex', gap: '.75rem', marginTop: '2rem' }}>
            <button className="btn btn-outline" onClick={() => setCurrent(c => Math.max(0, c-1))} disabled={current === 0}>
              <ChevronLeft size={16} /> {t('survey.back')}
            </button>
            <button className="btn btn-primary btn-w" onClick={next} disabled={!answers[q.id]} style={{ flex: 1 }}>
              {current === SURVEY_QUESTIONS.length - 1 ? <><Sparkles size={16}/> {t('survey.results')}</> : <>{t('survey.next')} <ChevronRight size={16} /></>}
            </button>
          </div>
        </div>

        {/* Dot nav */}
        <div style={{ display: 'flex', gap: '.35rem', justifyContent: 'center', marginTop: '1.5rem' }}>
          {SURVEY_QUESTIONS.map((sq, i) => (
            <div key={sq.id} onClick={() => setCurrent(i)} style={{
              width: 28, height: 5, borderRadius: 99, cursor: 'pointer',
              background: answers[sq.id] ? (i === current ? 'var(--pink)' : 'rgba(157,78,221,.35)') : 'rgba(255,255,255,.08)',
              transition: 'var(--tr)',
            }} />
          ))}
        </div>
      </div>
    </div>
  );
}
