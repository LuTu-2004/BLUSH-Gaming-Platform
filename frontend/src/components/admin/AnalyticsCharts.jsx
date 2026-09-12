import React, { useEffect, useRef } from 'react';
import { ArrowUpRight, ArrowDownRight } from 'lucide-react';

function RevenueUsersChart() {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const W = canvas.width, H = canvas.height;
    const pad = { top: 20, right: 20, bottom: 30, left: 40 };
    const iW = W - pad.left - pad.right;
    const iH = H - pad.top - pad.bottom;
    ctx.clearRect(0, 0, W, H);

    // Mock data for T1 to T12
    const data = [1000, 1500, 2200, 3100, 4200, 5500, 7100, 9000, 11200, 13800, 16500, 19500];
    const labels = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
    const max = 20000;

    // Grid lines
    for (let i = 0; i <= 4; i++) {
      const y = pad.top + (iH / 4) * i;
      ctx.strokeStyle = 'rgba(255,255,255,.04)';
      ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(pad.left, y); ctx.lineTo(pad.left + iW, y); ctx.stroke();
      const val = max - (max / 4) * i;
      ctx.fillStyle = 'rgba(255,255,255,.4)';
      ctx.font = '9px Outfit, sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText(val, pad.left - 8, y + 3);
    }

    // X axis labels
    ctx.fillStyle = 'rgba(255,255,255,.5)';
    ctx.font = '10px Outfit, sans-serif';
    ctx.textAlign = 'center';
    labels.forEach((lbl, i) => {
      const x = pad.left + (iW / (data.length - 1)) * i;
      ctx.fillText(lbl, x, H - 6);
    });

    // Area Gradient
    const grad = ctx.createLinearGradient(0, pad.top, 0, pad.top + iH);
    grad.addColorStop(0, 'rgba(0, 245, 255, 0.18)');
    grad.addColorStop(1, 'rgba(0, 245, 255, 0.00)');
    ctx.beginPath();
    data.forEach((v, i) => {
      const x = pad.left + (iW / (data.length - 1)) * i;
      const y = pad.top + iH - (v / max) * iH;
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    });
    ctx.lineTo(pad.left + iW, pad.top + iH);
    ctx.lineTo(pad.left, pad.top + iH);
    ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();

    // Line
    ctx.beginPath();
    ctx.strokeStyle = '#00F5FF';
    ctx.lineWidth = 2.5;
    ctx.shadowColor = 'rgba(0, 245, 255, 0.4)';
    ctx.shadowBlur = 8;
    data.forEach((v, i) => {
      const x = pad.left + (iW / (data.length - 1)) * i;
      const y = pad.top + iH - (v / max) * iH;
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    });
    ctx.stroke();
    ctx.shadowBlur = 0;
  }, []);

  return <canvas ref={canvasRef} width={500} height={200} style={{ width: '100%', height: 'auto' }} />;
}

function WeeklyActivityChart() {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const W = canvas.width, H = canvas.height;
    const pad = { top: 20, right: 20, bottom: 30, left: 40 };
    const iW = W - pad.left - pad.right;
    const iH = H - pad.top - pad.bottom;
    ctx.clearRect(0, 0, W, H);

    // Weekdays
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    // Regs & Transactions mock values
    const regs = [45, 52, 40, 68, 90, 125, 140];
    const txs = [12, 15, 8, 22, 32, 45, 58];
    const max = 160;

    // Grid lines
    for (let i = 0; i <= 4; i++) {
      const y = pad.top + (iH / 4) * i;
      ctx.strokeStyle = 'rgba(255,255,255,.04)';
      ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(pad.left, y); ctx.lineTo(pad.left + iW, y); ctx.stroke();
      const val = max - (max / 4) * i;
      ctx.fillStyle = 'rgba(255,255,255,.4)';
      ctx.font = '9px Outfit, sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText(val, pad.left - 8, y + 3);
    }

    // X Labels & Bars
    const barWidth = 14;
    const gap = 4;
    const stepX = iW / labels.length;

    labels.forEach((lbl, i) => {
      const x = pad.left + stepX * i + stepX / 2;
      ctx.fillStyle = 'rgba(255,255,255,.5)';
      ctx.font = '10px Outfit, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(lbl, x, H - 6);

      // Draw Registrations Bar (Green/Cyan)
      const regVal = regs[i];
      const regH = (regVal / max) * iH;
      const regX = x - barWidth - gap / 2;
      const regY = pad.top + iH - regH;
      
      ctx.fillStyle = '#00FF9F';
      ctx.beginPath();
      if (ctx.roundRect) {
        ctx.roundRect(regX, regY, barWidth, regH, [4, 4, 0, 0]);
      } else {
        ctx.rect(regX, regY, barWidth, regH);
      }
      ctx.fill();

      // Draw Transactions Bar (Purple)
      const txVal = txs[i];
      const txH = (txVal / max) * iH;
      const txX = x + gap / 2;
      const txY = pad.top + iH - txH;

      ctx.fillStyle = '#9D4EDD';
      ctx.beginPath();
      if (ctx.roundRect) {
        ctx.roundRect(txX, txY, barWidth, txH, [4, 4, 0, 0]);
      } else {
        ctx.rect(txX, txY, barWidth, txH);
      }
      ctx.fill();
    });
  }, []);

  return <canvas ref={canvasRef} width={500} height={200} style={{ width: '100%', height: 'auto' }} />;
}

export default function AnalyticsCharts() {
  const kpis = [
    { label: 'Tổng người dùng', value: '19.5K', change: '+21%', trend: 'up', color: '#00F5FF', icon: '👥' },
    { label: 'Doanh thu tháng', value: '142.8M', change: '+18%', trend: 'up', color: '#FFB703', icon: '💰' },
    { label: 'Phòng hoạt động', value: '186', change: '+12%', trend: 'up', color: '#9D4EDD', icon: '🎮' },
    { label: 'Tỉ lệ chuyển đổi', value: '8.4%', change: '-2%', trend: 'down', color: '#FF4D6D', icon: '📈' }
  ];

  const middleStats = [
    { label: 'Đăng ký hôm nay', value: '156', change: '+23% so với hôm qua', color: '#00F5FF' },
    { label: 'GD hôm nay', value: '58', change: '+15% so với hôm qua', color: '#9D4EDD' },
    { label: 'Doanh thu hôm nay', value: '4.2M', change: '+8% so với hôm qua', color: '#FFB703' }
  ];

  const recentTxs = [
    { id: 'TX-9821', user: 'Khánh An', plan: 'BLUSH Pass Pro', amount: '49.000đ', method: 'MoMo', status: 'Hoàn thành', time: '10 phút trước' },
    { id: 'TX-9820', user: 'Hoàng Nam', plan: 'BLUSH Pass', amount: '29.000đ', method: 'ZaloPay', status: 'Hoàn thành', time: '34 phút trước' },
    { id: 'TX-9819', user: 'Yến Nhi', plan: 'BLUSH Pass Pro', amount: '49.000đ', method: 'Visa/Master', status: 'Hoàn thành', time: '1 giờ trước' },
    { id: 'TX-9818', user: 'Tuấn Kiệt', plan: 'BLUSH Pass', amount: '29.000đ', method: 'Chuyển khoản', status: 'Hoàn thành', time: '2 giờ trước' },
    { id: 'TX-9817', user: 'Phúc Bảo', plan: 'BLUSH Pass Pro', amount: '49.000đ', method: 'MoMo', status: 'Hoàn thành', time: '4 giờ trước' }
  ];

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      
      {/* Header title */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontSize: '1.8rem', fontWeight: 900, color: '#FFF' }}>Admin Dashboard</h1>
          <div style={{ color: 'var(--text-secondary)', fontSize: '.84rem', marginTop: '.2rem' }}>
            Quản trị hệ thống BLUSH
          </div>
        </div>

        <span style={{
          display: 'flex', alignItems: 'center', gap: '.4rem', background: 'rgba(0, 255, 159, 0.08)',
          border: '1px solid rgba(0, 255, 159, 0.2)', padding: '.4rem .9rem', borderRadius: '8px',
          fontSize: '.78rem', fontWeight: 700, color: 'var(--success)'
        }}>
          ● Hệ thống hoạt động
        </span>
      </div>

      {/* KPI Cards Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.25rem' }}>
        {kpis.map(k => (
          <div key={k.label} className="card" style={{ padding: '1.25rem', border: '1px solid var(--border-soft)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: '.78rem', color: 'var(--text-secondary)', marginBottom: '.25rem' }}>{k.label}</div>
              <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#FFF', lineHeight: 1.1 }}>{k.value}</div>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '.5rem' }}>
              <div style={{ 
                width: 36, height: 36, borderRadius: '10px', background: `${k.color}15`, 
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.1rem' 
              }}>
                {k.icon}
              </div>
              <span style={{ 
                fontSize: '.72rem', fontWeight: 700, color: k.trend === 'up' ? 'var(--success)' : 'var(--danger)',
                display: 'flex', alignItems: 'center', gap: '.1rem' 
              }}>
                {k.trend === 'up' ? <ArrowUpRight size={10} /> : <ArrowDownRight size={10} />}
                {k.change}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Charts split row */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }} className="responsive-grid-2">
        {/* Left Chart */}
        <div className="card" style={{ padding: '1.5rem', border: '1px solid var(--border-soft)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem' }}>
            <div>
              <h3 style={{ fontSize: '.95rem', fontWeight: 800, color: '#FFF' }}>Doanh thu & Người dùng</h3>
              <div style={{ fontSize: '.72rem', color: 'var(--text-muted)' }}>Theo tháng (2026)</div>
            </div>
            
            <div style={{ display: 'flex', gap: '1rem', fontSize: '.72rem', fontWeight: 700 }}>
              <span style={{ color: '#00F5FF', display: 'flex', alignItems: 'center', gap: '.25rem' }}>● Người dùng</span>
              <span style={{ color: '#9D4EDD', display: 'flex', alignItems: 'center', gap: '.25rem' }}>● Doanh thu (Trđ)</span>
            </div>
          </div>
          <RevenueUsersChart />
        </div>

        {/* Right Chart */}
        <div className="card" style={{ padding: '1.5rem', border: '1px solid var(--border-soft)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem' }}>
            <div>
              <h3 style={{ fontSize: '.95rem', fontWeight: 800, color: '#FFF' }}>Hoạt động trong tuần</h3>
              <div style={{ fontSize: '.72rem', color: 'var(--text-muted)' }}>Đăng ký & Giao dịch hằng ngày</div>
            </div>
            
            <div style={{ display: 'flex', gap: '1rem', fontSize: '.72rem', fontWeight: 700 }}>
              <span style={{ color: '#00FF9F', display: 'flex', alignItems: 'center', gap: '.25rem' }}>● Đăng ký</span>
              <span style={{ color: '#9D4EDD', display: 'flex', alignItems: 'center', gap: '.25rem' }}>● Giao dịch</span>
            </div>
          </div>
          <WeeklyActivityChart />
        </div>
      </div>

      {/* Middle Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1.25rem' }} className="responsive-profile">
        {middleStats.map(stat => (
          <div 
            key={stat.label} 
            className="card" 
            style={{ 
              padding: '1.25rem', border: '1px solid var(--border-soft)', textAlign: 'center', 
              background: 'linear-gradient(145deg, #140E28 0%, rgba(255,255,255,0.01) 100%)' 
            }}
          >
            <div style={{ fontSize: '.78rem', color: 'var(--text-secondary)', marginBottom: '.25rem' }}>{stat.label}</div>
            <div style={{ fontSize: '1.8rem', fontWeight: 900, color: stat.color, marginBottom: '.25rem' }}>{stat.value}</div>
            <div style={{ fontSize: '.72rem', color: 'var(--success)', fontWeight: 600 }}>{stat.change}</div>
          </div>
        ))}
      </div>

      {/* Recent Transactions Table */}
      <div className="card" style={{ border: '1px solid var(--border-soft)', overflow: 'hidden' }}>
        <div style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-soft)' }}>
          <h3 style={{ fontSize: '.95rem', fontWeight: 800, color: '#FFF' }}>Giao dịch gần đây</h3>
          <p style={{ fontSize: '.72rem', color: 'var(--text-muted)', marginTop: '.15rem' }}>
            Theo dõi thanh toán BLUSH Pass
          </p>
        </div>
        
        <table className="data-table">
          <thead>
            <tr>
              <th>MÃ GD</th>
              <th>NGƯỜI DÙNG</th>
              <th>GÓI</th>
              <th>SỐ TIỀN</th>
              <th>PTTT</th>
              <th>TRẠNG THÁI</th>
              <th style={{ textAlign: 'right' }}>THỜI GIAN</th>
            </tr>
          </thead>
          <tbody>
            {recentTxs.map(tx => (
              <tr key={tx.id}>
                <td style={{ fontWeight: 800, color: 'var(--text-muted)' }}>{tx.id}</td>
                <td style={{ fontWeight: 700, color: '#FFF' }}>{tx.user}</td>
                <td>
                  <span style={{ 
                    fontSize: '.72rem', fontWeight: 700, padding: '.2rem .5rem', borderRadius: '4px',
                    background: tx.plan.includes('Pro') ? 'rgba(157,78,221,0.15)' : 'rgba(0,245,255,0.1)',
                    color: tx.plan.includes('Pro') ? 'var(--pink)' : 'var(--cyan)'
                  }}>
                    {tx.plan}
                  </span>
                </td>
                <td style={{ fontWeight: 700, color: '#FFF' }}>{tx.amount}</td>
                <td>{tx.method}</td>
                <td>
                  <span className="badge badge-success" style={{ padding: '.2rem .6rem', fontSize: '.7rem' }}>
                    {tx.status}
                  </span>
                </td>
                <td style={{ textAlign: 'right', color: 'var(--text-secondary)' }}>{tx.time}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

    </div>
  );
}
