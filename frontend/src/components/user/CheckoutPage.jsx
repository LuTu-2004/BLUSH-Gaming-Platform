import React, { useState } from 'react';
import {
  CreditCard, Smartphone, Building2, Shield, Lock,
  ChevronLeft, Check, Crown, AlertCircle, ArrowRight
} from 'lucide-react';

const BANKS = ['Vietcombank', 'BIDV', 'Techcombank', 'MB Bank', 'VPBank', 'ACB', 'Sacombank'];

function CardInput({ label, children, error }) {
  return (
    <div>
      <label style={{ fontSize: '.8rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: '.4rem' }}>{label}</label>
      {children}
      {error && <div style={{ fontSize: '.73rem', color: 'var(--danger)', marginTop: '.3rem', display: 'flex', alignItems: 'center', gap: '.3rem' }}><AlertCircle size={11}/>{error}</div>}
    </div>
  );
}

function formatCard(v) {
  return v.replace(/\D/g, '').slice(0, 16).replace(/(.{4})/g, '$1 ').trim();
}
function formatExpiry(v) {
  const d = v.replace(/\D/g, '').slice(0, 4);
  if (d.length >= 3) return d.slice(0, 2) + '/' + d.slice(2);
  return d;
}

export default function CheckoutPage({ plan, onSuccess, onBack, t, lang }) {
  const [method, setMethod] = useState('card');
  const [card, setCard] = useState({ number: '', name: '', expiry: '', cvv: '' });
  const [selectedBank, setSelectedBank] = useState('');
  const [errors, setErrors] = useState({});
  const [step, setStep] = useState('form'); // 'form' | 'processing' | 'otp' | 'success'
  const [otp, setOtp] = useState(['', '', '', '', '', '']);
  const [processingMsg, setProcessingMsg] = useState('');

  const PAYMENT_METHODS = [
    { id: 'card',     icon: <CreditCard size={18}/>, label: t('checkout.cardTab') },
    { id: 'momo',     icon: <Smartphone size={18}/>, label: t('checkout.momoTab') },
    { id: 'zalopay',  icon: <Smartphone size={18}/>, label: t('checkout.zalopayTab') },
    { id: 'bank',     icon: <Building2 size={18}/>,  label: t('checkout.bankTab') },
  ];

  const planName = lang === 'en' ? plan?.name_en : plan?.name_vi;
  const planFeatures = lang === 'en' ? plan?.features_en : plan?.features_vi;

  function validate() {
    const e = {};
    if (method === 'card') {
      if (card.number.replace(/\s/g,'').length < 16) {
        e.number = lang === 'en' ? 'Invalid card number (needs 16 digits)' : 'Số thẻ không hợp lệ (cần 16 chữ số)';
      }
      if (!card.name.trim()) {
        e.name = lang === 'en' ? 'Please enter cardholder name' : 'Vui lòng nhập tên chủ thẻ';
      }
      if (card.expiry.length < 5) {
        e.expiry = lang === 'en' ? 'Invalid expiry date (MM/YY)' : 'Ngày hết hạn không hợp lệ (MM/YY)';
      }
      if (card.cvv.length < 3) {
        e.cvv = lang === 'en' ? 'Invalid CVV' : 'CVV không hợp lệ';
      }
    }
    if (method === 'bank' && !selectedBank) {
      e.bank = lang === 'en' ? 'Please select a bank' : 'Vui lòng chọn ngân hàng';
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function handlePay() {
    if (!validate()) return;
    setStep('processing');
    const msgs = lang === 'en' 
      ? ['Connecting to payment gateway...', 'Authenticating transaction...', 'Sending secure OTP code...']
      : ['Đang kết nối cổng thanh toán...', 'Đang xác thực thông tin...', 'Đang gửi OTP...'];
    let i = 0;
    setProcessingMsg(msgs[i]);
    const interval = setInterval(() => {
      i++;
      if (i < msgs.length) setProcessingMsg(msgs[i]);
      else { clearInterval(interval); setStep('otp'); }
    }, 800);
  }

  function handleOtp(idx, val) {
    if (!/^\d?$/.test(val)) return;
    const next = [...otp];
    next[idx] = val;
    setOtp(next);
    if (val && idx < 5) document.getElementById(`otp-${idx+1}`)?.focus();
  }

  function handleVerifyOtp() {
    setStep('processing');
    setProcessingMsg(lang === 'en' ? 'Verifying secure OTP...' : 'Đang xác thực OTP...');
    setTimeout(() => { setStep('success'); setTimeout(() => onSuccess(), 2500); }, 1500);
  }

  const total = plan?.price ?? '189.000';
  const cardBrand = card.number.startsWith('4') ? '💳 Visa' : card.number.startsWith('5') ? '💳 Mastercard' : '💳 Card';

  /* ── Success screen ── */
  if (step === 'success') return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', padding: '2rem', gap: '1.25rem' }}>
      <div style={{ width: 80, height: 80, borderRadius: '50%', background: 'linear-gradient(135deg,#2ECC8A,#27AE60)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 12px 36px rgba(46,204,138,.3)', animation: 'scaleIn .5s ease' }}>
        <Check size={40} color="#fff" strokeWidth={3}/>
      </div>
      <h2 style={{ fontSize: '2rem', fontWeight: 900 }} className="gradient-text">{t('checkout.successTitle')}</h2>
      <p style={{ color: 'var(--text-secondary)', maxWidth: 340 }}>
        {lang === 'en' 
          ? `Your purchase of ${planName} has been confirmed. Your BLUSH Pass is now active!`
          : `Giao dịch ${planName} đã được xác nhận. Gói BLUSH Pass của bạn đã được kích hoạt!`}
      </p>
      <div className="card" style={{ padding: '1.25rem 2rem', display: 'flex', flexDirection: 'column', gap: '.5rem', width: '100%', maxWidth: 340 }}>
        {[
          { label: t('checkout.receiptTx'), value: `BLH${Date.now().toString().slice(-8)}` },
          { label: t('checkout.receiptPlan'), value: planName },
          { label: t('checkout.receiptAmount'), value: `${plan?.price}đ` },
          { label: t('checkout.receiptStatus'), value: `✅ ${t('checkout.receiptActive')}` },
        ].map((r,i) => (
          <div key={i} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '.85rem' }}>
            <span style={{ color: 'var(--text-secondary)' }}>{r.label}</span>
            <span style={{ fontWeight: 600 }}>{r.value}</span>
          </div>
        ))}
      </div>
      <span className="badge badge-warning" style={{ fontSize: '.88rem', padding: '.5rem 1.5rem' }}>👑 {t('checkout.receiptFoot')}</span>
    </div>
  );

  /* ── Processing screen ── */
  if (step === 'processing') return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '1.5rem', textAlign: 'center', padding: '2rem' }}>
      <div style={{ width: 60, height: 60, border: '4px solid rgba(232,84,122,.15)', borderTopColor: 'var(--pink)', borderRadius: '50%', animation: 'spin .9s linear infinite' }}/>
      <h3 style={{ fontWeight: 700, fontSize: '1.1rem' }}>{processingMsg}</h3>
      <p style={{ color: 'var(--text-muted)', fontSize: '.85rem' }}>{lang === 'en' ? 'Please do not close this window...' : 'Vui lòng không đóng trang...'}</p>
    </div>
  );

  /* ── OTP screen ── */
  if (step === 'otp') return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
      <div style={{ width: '100%', maxWidth: 400 }}>
        <div className="card animate-scale-in" style={{ padding: '2.5rem', textAlign: 'center' }}>
          <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>📱</div>
          <h2 style={{ fontWeight: 800, fontSize: '1.4rem', marginBottom: '.5rem' }}>{t('checkout.verifyOtpTitle')}</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '.88rem', marginBottom: '2rem', lineHeight: 1.5 }}>
            {t('checkout.verifyOtpDesc')}
          </p>
          <div style={{ display: 'flex', gap: '.6rem', justifyContent: 'center', marginBottom: '1.75rem' }}>
            {otp.map((d, i) => (
              <input
                key={i}
                id={`otp-${i}`}
                type="text"
                inputMode="numeric"
                maxLength={1}
                value={d}
                onChange={e => handleOtp(i, e.target.value)}
                onKeyDown={e => e.key === 'Backspace' && !d && i > 0 && document.getElementById(`otp-${i-1}`)?.focus()}
                style={{
                  width: 46, height: 56, textAlign: 'center',
                  fontSize: '1.4rem', fontWeight: 800,
                  border: `2px solid ${d ? 'var(--pink)' : 'var(--border-soft)'}`,
                  borderRadius: 'var(--radius-md)', outline: 'none',
                  background: d ? 'var(--pink-soft)' : 'var(--surface)',
                  color: 'var(--text-primary)', transition: 'var(--tr)',
                  fontFamily: 'Outfit, sans-serif',
                }}
              />
            ))}
          </div>
          <button
            className="btn btn-primary btn-w"
            onClick={handleVerifyOtp}
            disabled={otp.some(d => !d)}
            style={{ marginBottom: '1rem' }}
          >
            <Shield size={16}/> {t('checkout.verifyOtpTitle')}
          </button>
          <button style={{ background: 'none', border: 'none', color: 'var(--pink)', fontWeight: 600, cursor: 'pointer', fontSize: '.83rem' }}>
            {t('checkout.resendOtp')} (59s)
          </button>
        </div>
      </div>
    </div>
  );

  const momoBadges = t('checkout.momoBadges');
  const zaloBadges = t('checkout.zaloBadges');

  return (
    <div style={{ minHeight: '100vh', padding: '2rem', maxWidth: 800, margin: '0 auto' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem' }}>
        <button className="btn btn-ghost btn-icon" onClick={onBack}><ChevronLeft size={20}/></button>
        <div>
          <h1 style={{ fontSize: '1.4rem', fontWeight: 800 }}>{t('checkout.title')}</h1>
          <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem', marginTop: '.2rem' }}>
            <Lock size={11} style={{ color: 'var(--success)' }}/>
            <span style={{ fontSize: '.75rem', color: 'var(--success)', fontWeight: 600 }}>{t('checkout.sslTip')}</span>
          </div>
        </div>
      </div>

      <div className="responsive-checkout" style={{ alignItems: 'start' }}>

        {/* ── LEFT: Payment form ── */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>

          {/* Payment method tabs */}
          <div className="card" style={{ padding: '1.5rem' }}>
            <h2 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '1.1rem', color: 'var(--text-secondary)' }}>{t('checkout.methodsLabel')}</h2>
            <div className="responsive-grid-2" style={{ gap: '.6rem' }}>
              {PAYMENT_METHODS.map(m => (
                <button key={m.id} onClick={() => setMethod(m.id)} style={{
                  display: 'flex', alignItems: 'center', gap: '.65rem',
                  padding: '.85rem 1rem', borderRadius: 'var(--radius-md)', cursor: 'pointer',
                  background: method === m.id ? 'var(--pink-soft)' : 'var(--surface-2)',
                  border: `1.5px solid ${method === m.id ? 'var(--pink)' : 'var(--border-soft)'}`,
                  color: method === m.id ? 'var(--pink)' : 'var(--text-secondary)',
                  fontWeight: method === m.id ? 700 : 500, fontSize: '.84rem',
                  transition: 'var(--tr)',
                }}>
                  <span style={{ color: method === m.id ? 'var(--pink)' : 'var(--text-muted)' }}>{m.icon}</span>
                  {m.label}
                </button>
              ))}
            </div>
          </div>

          {/* ── Credit card form ── */}
          {method === 'card' && (
            <div className="card animate-scale-in" style={{ padding: '1.5rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.25rem' }}>
                <h2 style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--text-secondary)' }}>{t('checkout.cardInfo')}</h2>
                <div style={{ display: 'flex', gap: '.35rem' }}>
                  {['VISA', 'MC', 'JCB'].map(b => (
                    <div key={b} style={{ padding: '.2rem .5rem', borderRadius: 4, border: '1px solid var(--border-soft)', fontSize: '.62rem', fontWeight: 800, color: 'var(--text-muted)' }}>{b}</div>
                  ))}
                </div>
              </div>

              {/* Card preview */}
              <div style={{ borderRadius: 'var(--radius-lg)', background: 'linear-gradient(135deg,#E8547A,#7C5CBF)', padding: '1.25rem 1.5rem', marginBottom: '1.5rem', color: '#fff', position: 'relative', overflow: 'hidden', minHeight: 90 }}>
                <div style={{ position: 'absolute', inset: 0, background: 'url("data:image/svg+xml,%3Csvg width=\'200\' height=\'200\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'150\' cy=\'50\' r=\'100\' fill=\'rgba(255,255,255,.06)\'/%3E%3Ccircle cx=\'50\' cy=\'150\' r=\'80\' fill=\'rgba(255,255,255,.04)\'/%3E%3C/svg%3E")', backgroundSize: 'cover' }}/>
                <div style={{ fontSize: '.68rem', opacity: .7, marginBottom: '.4rem' }}>{cardBrand}</div>
                <div style={{ fontSize: '1.1rem', fontWeight: 700, letterSpacing: '.15em', fontFamily: 'monospace' }}>
                  {card.number || '•••• •••• •••• ••••'}
                </div>
                <div style={{ display: 'flex', gap: '2rem', marginTop: '.6rem', fontSize: '.8rem' }}>
                  <div><div style={{ fontSize: '.58rem', opacity: .6 }}>{t('checkout.holderLabel')}</div><div style={{ fontWeight: 600 }}>{card.name || t('checkout.holderDefault')}</div></div>
                  <div><div style={{ fontSize: '.58rem', opacity: .6 }}>{t('checkout.expiryLabel')}</div><div style={{ fontWeight: 600 }}>{card.expiry || 'MM/YY'}</div></div>
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <CardInput label={t('checkout.numberLabel')} error={errors.number}>
                  <input className="input" placeholder="0000 0000 0000 0000" value={card.number}
                    onChange={e => setCard(c => ({ ...c, number: formatCard(e.target.value) }))}
                    style={{ fontFamily: 'monospace', letterSpacing: '.1em' }}
                  />
                </CardInput>
                <CardInput label={t('checkout.nameLabel')} error={errors.name}>
                  <input className="input" placeholder="NGUYEN VAN A" value={card.name}
                    onChange={e => setCard(c => ({ ...c, name: e.target.value.toUpperCase() }))}
                  />
                </CardInput>
                <div className="responsive-grid-2">
                  <CardInput label={lang === 'en' ? 'Expiry Date' : 'Ngày hết hạn'} error={errors.expiry}>
                    <input className="input" placeholder="MM/YY" value={card.expiry}
                      onChange={e => setCard(c => ({ ...c, expiry: formatExpiry(e.target.value) }))}
                    />
                  </CardInput>
                  <CardInput label={t('checkout.cvvLabel')} error={errors.cvv}>
                    <input className="input" placeholder="•••" maxLength={4} type="password" value={card.cvv}
                      onChange={e => setCard(c => ({ ...c, cvv: e.target.value.replace(/\D/,'').slice(0,4) }))}
                    />
                  </CardInput>
                </div>
              </div>
            </div>
          )}

          {/* ── MoMo ── */}
          {method === 'momo' && (
            <div className="card animate-scale-in" style={{ padding: '2rem', textAlign: 'center' }}>
              <div style={{ fontSize: '3.5rem', marginBottom: '1rem' }}>🟣</div>
              <h3 style={{ fontWeight: 800, fontSize: '1.15rem', marginBottom: '.5rem' }}>{t('checkout.momoTitle')}</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '.88rem', lineHeight: 1.5, marginBottom: '1.5rem' }}>
                {t('checkout.momoDesc', total + 'đ')}
              </p>
              <div style={{ display: 'flex', gap: '.5rem', justifyContent: 'center', flexWrap: 'wrap' }}>
                {(Array.isArray(momoBadges) ? momoBadges : []).map(f => (
                  <span key={f} className="badge badge-purple" style={{ fontSize: '.75rem' }}>{f}</span>
                ))}
              </div>
            </div>
          )}

          {/* ── ZaloPay ── */}
          {method === 'zalopay' && (
            <div className="card animate-scale-in" style={{ padding: '2rem', textAlign: 'center' }}>
              <div style={{ fontSize: '3.5rem', marginBottom: '1rem' }}>🔵</div>
              <h3 style={{ fontWeight: 800, fontSize: '1.15rem', marginBottom: '.5rem' }}>{t('checkout.zaloTitle')}</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '.88rem', lineHeight: 1.5, marginBottom: '1.5rem' }}>
                {t('checkout.zaloDesc', total + 'đ')}
              </p>
              <div style={{ display: 'flex', gap: '.5rem', justifyContent: 'center', flexWrap: 'wrap' }}>
                {(Array.isArray(zaloBadges) ? zaloBadges : []).map(f => (
                  <span key={f} className="badge badge-soft" style={{ fontSize: '.75rem' }}>{f}</span>
                ))}
              </div>
            </div>
          )}

          {/* ── Bank transfer ── */}
          {method === 'bank' && (
            <div className="card animate-scale-in" style={{ padding: '1.5rem' }}>
              <h2 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '1rem', color: 'var(--text-secondary)' }}>{t('checkout.bankTitle')}</h2>
              {errors.bank && <div style={{ fontSize: '.78rem', color: 'var(--danger)', marginBottom: '.75rem', display: 'flex', alignItems: 'center', gap: '.3rem' }}><AlertCircle size={13}/> {errors.bank}</div>}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(130px,1fr))', gap: '.6rem', marginBottom: '1.25rem' }}>
                {BANKS.map(b => (
                  <button key={b} onClick={() => setSelectedBank(b)} style={{
                    padding: '.7rem .5rem', borderRadius: 'var(--radius-md)', cursor: 'pointer',
                    border: `1.5px solid ${selectedBank === b ? 'var(--pink)' : 'var(--border-soft)'}`,
                    background: selectedBank === b ? 'var(--pink-soft)' : 'var(--surface)',
                    color: selectedBank === b ? 'var(--pink)' : 'var(--text-secondary)',
                    fontWeight: selectedBank === b ? 700 : 500, fontSize: '.82rem',
                    transition: 'var(--tr)', textAlign: 'center',
                  }}>{b}</button>
                ))}
              </div>
              {selectedBank && (
                <div style={{ padding: '1rem', background: 'var(--pink-pastel)', borderRadius: 'var(--radius-md)', fontSize: '.83rem', lineHeight: 1.7, color: 'var(--text-secondary)' }}>
                  <div style={{ fontWeight: 700, marginBottom: '.4rem' }}>{t('checkout.bankInfoTitle', selectedBank)}</div>
                  <div>🏦 {t('checkout.bankAcc')} <strong>1234 5678 9012</strong></div>
                  <div>👤 {t('checkout.bankHolder')} <strong>BLUSH VN</strong></div>
                  <div>💬 {t('checkout.bankDesc')} <strong>BLUSH {Date.now().toString().slice(-8)}</strong></div>
                  <div style={{ marginTop: '.5rem', fontSize: '.76rem', color: 'var(--text-muted)' }}>{t('checkout.bankWarning')}</div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* ── RIGHT: Order summary ── */}
        <div style={{ position: 'sticky', top: '80px', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div className="card" style={{ padding: '1.5rem' }}>
            <h2 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '1.25rem', color: 'var(--text-secondary)' }}>{t('checkout.orderTitle')}</h2>
            <div style={{ padding: '1rem', background: 'linear-gradient(135deg,var(--pink-pastel),var(--purple-soft))', borderRadius: 'var(--radius-lg)', marginBottom: '1.1rem', border: '1.5px solid rgba(0,245,255,.25)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '.6rem', marginBottom: '.5rem' }}>
                <Crown size={18} style={{ color: '#F59E0B' }}/>
                <span style={{ fontWeight: 800, fontSize: '1rem' }}>{planName}</span>
              </div>
              <div style={{ fontSize: '.82rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
                {planFeatures?.map(f => `✅ ${f}`).join('\n')}
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '.6rem', marginBottom: '1.1rem' }}>
              {[
                { label: t('checkout.orderPrice'), value: total + 'đ' },
                { label: t('checkout.orderDiscount'), value: '—' },
                { label: 'VAT (0%)', value: '0đ' },
              ].map((r,i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '.84rem', color: 'var(--text-secondary)' }}>
                  <span>{r.label}</span><span style={{ fontWeight: 600 }}>{r.value}</span>
                </div>
              ))}
            </div>

            <div style={{ height: 1, background: 'var(--border-soft)', margin: '.75rem 0' }}/>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 800, fontSize: '1.1rem' }}>
              <span>{t('checkout.orderTotal')}</span>
              <span className="gradient-text">{total}đ</span>
            </div>
          </div>

          {/* Pay button */}
          <button className="btn btn-primary btn-w btn-lg" onClick={handlePay} style={{ justifyContent: 'center', gap: '.6rem' }}>
            <Lock size={16}/> {t('checkout.payBtn', total + 'đ')}
            <ArrowRight size={16}/>
          </button>

          <div style={{ textAlign: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '.4rem', marginBottom: '.4rem' }}>
              {['visa.svg','mc.svg','jcb.svg'].map((_,i) => (
                <div key={i} style={{ width: 32, height: 20, background: 'var(--surface-3)', borderRadius: 4, border: '1px solid var(--border-soft)' }}/>
              ))}
              <Shield size={14} style={{ color: 'var(--success)' }}/>
            </div>
            <p style={{ fontSize: '.7rem', color: 'var(--text-muted)', lineHeight: 1.5, whiteSpace: 'pre-line' }}>
              {t('checkout.sslFoot')}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
