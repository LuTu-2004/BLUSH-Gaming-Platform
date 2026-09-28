import React, { useState } from 'react';
import { DollarSign, ShieldAlert, Zap, Server } from 'lucide-react';

export default function CostStructure() {
  const [activeUsers, setActiveUsers] = useState(10000);
  const [vipRatio, setVipRatio] = useState(5); // 5% VIP users

  // Cost configurations
  const pricing = {
    // AI Cost (GPT-4o-mini average cost per user: Input $0.15/1M, Output $0.60/1M)
    // Avg 1 request = 300 input tokens + 100 output tokens = $0.000105
    // Free user avg 20 requests/mo = 8,000 tokens = $0.0021 / month
    // VIP user avg 150 requests/mo = 60,000 tokens = $0.01575 / month
    aiFreePerUser: 0.0021 * 25000, // in VND (approx 52 VND/user/mo)
    aiVipPerUser: 0.01575 * 25000, // in VND (approx 393 VND/user/mo)
    
    // Server hosting & database Suppabase/Vercel (Scales with user tiers)
    getServerCost: (users) => {
      if (users <= 10000) return 20 * 25000;
      if (users <= 50000) return 100 * 25000;
      return 250 * 25000;
    },
    
    // SMS OTP verify cost (assumes 15% new users register per month, 1 SMS = 800 VND)
    smsVerifyPerNewUser: 800,
    newUsersRatioPerMonth: 0.15, // 15% new users per month
  };

  const vipCount = Math.round((activeUsers * vipRatio) / 100);
  const freeCount = activeUsers - vipCount;

  // Monthly Calculations
  const monthlyAiCost = Math.round(
    freeCount * pricing.aiFreePerUser + vipCount * pricing.aiVipPerUser
  );
  const monthlyServerCost = pricing.getServerCost(activeUsers);
  const monthlySmsCost = Math.round(
    activeUsers * pricing.newUsersRatioPerMonth * pricing.smsVerifyPerNewUser
  );
  const monthlyOtherCost = 15 * 25000; // Storage, domains prorated, support software

  const totalMonthlyCost = monthlyAiCost + monthlyServerCost + monthlySmsCost + monthlyOtherCost;
  
  // Format currency VND
  const f = (val) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);

  return (
    <div className="animate-fade-in" style={{ color: 'var(--text-primary)' }}>
      {/* Header */}
      <div className="section-header">
        <h2 className="section-title">💰 Cost Structure & Operational Budget / Cơ cấu chi phí & Kiểm soát</h2>
        <span className="badge badge-warning">Gemini & GPT-4o Operational Audit</span>
      </div>

      {/* Main explanation cards */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '2rem' }} className="responsive-grid-2">
        
        {/* Left: AI Token Allocation & Throttling */}
        <div className="card" style={{ padding: '1.5rem', border: '1px solid rgba(157,78,221,.25)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', color: 'var(--cyan)', marginBottom: '1rem' }}>
            <Zap size={18} />
            <h3 style={{ fontWeight: 800, fontSize: '1rem' }}>AI Cost & Token Quota Control / Kiểm soát Token AI</h3>
          </div>
          
          <p style={{ fontSize: '.84rem', color: 'var(--text-secondary)', lineHeight: 1.5, marginBottom: '1rem' }}>
            Blush tích hợp LLM (như <strong>Gemini 1.5 Flash / GPT-4o-mini</strong>) để gợi ý mở lời (AI Starters) và tạo câu hỏi thảo luận hàng ngày. Để tối ưu hóa chi phí API, hệ thống thiết lập hạn mức token nghiêm ngặt:
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '.75rem', fontSize: '.82rem' }}>
            <div style={{ background: 'rgba(0,0,0,0.2)', padding: '.75rem', borderRadius: '8px', borderLeft: '3px solid var(--cyan)' }}>
              <strong>Hạn mức Người dùng Miễn phí (Free User Quota):</strong>
              <div style={{ color: 'var(--text-secondary)', marginTop: '.2rem' }}>
                Hạn mức <strong>10,000 tokens/tháng</strong> (~50 lượt gợi ý AI). Chi phí trung bình: <strong>{f(pricing.aiFreePerUser)} / user / tháng</strong>.
              </div>
            </div>

            <div style={{ background: 'rgba(0,0,0,0.2)', padding: '.75rem', borderRadius: '8px', borderLeft: '3px solid var(--pink)' }}>
              <strong>Hạn mức Hội viên VIP (BLUSH Pass Quota):</strong>
              <div style={{ color: 'var(--text-secondary)', marginTop: '.2rem' }}>
                Hạn mức <strong>100,000 tokens/tháng</strong> (~500 lượt gợi ý AI). Chi phí trung bình: <strong>{f(pricing.aiVipPerUser)} / user / tháng</strong>.
              </div>
            </div>

            <div style={{ background: 'rgba(255, 77, 109, 0.05)', padding: '.75rem', borderRadius: '8px', border: '1px solid rgba(255, 77, 109, 0.2)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem', color: 'var(--danger)', fontWeight: 700, marginBottom: '.25rem' }}>
                <ShieldAlert size={14} /> Chiến lược kiểm soát tránh đội chi phí (Cost Protection):
              </div>
              <ul style={{ paddingLeft: '1.1rem', listStyleType: 'disc', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '.25rem', fontSize: '.78rem' }}>
                <li><strong>Rate Limiting:</strong> Giới hạn tối đa 5 lượt gọi AI trong 1 giờ cho mỗi user để tránh spam bot phá hoại.</li>
                <li><strong>Context Caching:</strong> Lưu bộ nhớ đệm (caching) các prompt hệ thống để giảm 50% chi phí Input Token.</li>
                <li><strong>Fallback Offline:</strong> Khi tổng chi phí API chạm hạn mức ví doanh nghiệp tháng (ví dụ $100/tháng ở giai đoạn đầu), hệ thống sẽ tự động tắt API và chuyển sang dùng kho câu hỏi cứng (Rule-based Offline) cho đến chu kỳ tiếp theo.</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Right: Operational Tooling & Cloud Budget */}
        <div className="card" style={{ padding: '1.5rem', border: '1px solid rgba(157,78,221,.25)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', color: 'var(--success)', marginBottom: '1rem' }}>
            <Server size={18} />
            <h3 style={{ fontWeight: 800, fontSize: '1rem' }}>Infrastructure & Software Stack / Các loại chi phí khác</h3>
          </div>

          <p style={{ fontSize: '.84rem', color: 'var(--text-secondary)', lineHeight: 1.5, marginBottom: '1rem' }}>
            Để vận hành ứng dụng Blush thực tế, đội ngũ kỹ thuật phân bổ chi phí thành hai phần rõ rệt: Chi phí cố định (One-off) và Chi phí định kỳ (Monthly/Annual):
          </p>

          <table className="data-table" style={{ fontSize: '.78rem' }}>
            <thead>
              <tr>
                <th>Công cụ / Stack</th>
                <th>Chu kỳ</th>
                <th>Đơn giá dự kiến (VND)</th>
                <th>Logic kiểm soát & Khả năng mở rộng</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Tên miền (.vn / .com)</td>
                <td>Hàng năm</td>
                <td>300.000đ / năm</td>
                <td>Cố định. Không tăng theo lượng user.</td>
              </tr>
              <tr>
                <td>Database & Hosting (Supabase/Vercel)</td>
                <td>Định kỳ tháng</td>
                <td>500.000đ / tháng</td>
                <td>Tăng theo cấp bậc (Tier). Free tối đa 10k users. Lên 50k users trả gói Pro.</td>
              </tr>
              <tr>
                <td>SMS OTP Verify (Đăng ký)</td>
                <td>Theo lượt</td>
                <td>800đ / SMS</td>
                <td>Mỗi tài khoản đăng ký chỉ cấp tối đa 1 mã OTP. Có captcha để chống spam OTP ảo phá phí.</td>
              </tr>
              <tr>
                <td>Bảo mật Auth (Firebase/Clerk)</td>
                <td>Định kỳ tháng</td>
                <td>Miễn phí</td>
                <td>Miễn phí cho 10,000 người dùng đầu tiên, sau đó $0.005/user tiếp theo.</td>
              </tr>
              <tr>
                <td>Giấy phép ĐKKD Startup</td>
                <td>Một lần</td>
                <td>2.000.000đ</td>
                <td>Chi phí pháp lý một lần duy nhất lúc thành lập.</td>
              </tr>
            </tbody>
          </table>
        </div>

      </div>

      {/* Dynamic Calculator & Interactive Scaling Dashboard */}
      <div className="card" style={{ padding: '1.75rem', border: '1.5px solid var(--cyan)', background: 'linear-gradient(145deg, #140E28, #111A35)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', color: 'var(--cyan)', marginBottom: '1.25rem' }}>
          <DollarSign size={20} />
          <h3 style={{ fontWeight: 800, fontSize: '1.05rem' }}>Dynamic Operational Cost Simulator / Mô phỏng chi phí vận hành theo quy mô User</h3>
        </div>

        <p style={{ fontSize: '.84rem', color: 'var(--text-secondary)', marginBottom: '1.5rem', lineHeight: 1.5 }}>
          Điều chỉnh thanh trượt dưới đây để kiểm tra mức tăng trưởng chi phí vận hành thực tế khi ứng dụng Blush mở rộng quy mô người dùng (Active Users) và tỷ lệ nâng cấp gói VIP BLUSH Pass.
        </p>

        {/* Sliders Control Panel */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginBottom: '1.75rem' }} className="responsive-grid-2">
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '.82rem', fontWeight: 700, marginBottom: '.5rem' }}>
              <span>Quy mô Người dùng hoạt động (Monthly Active Users):</span>
              <span style={{ color: 'var(--cyan)' }}>{activeUsers.toLocaleString()} Users</span>
            </div>
            <input 
              type="range" 
              min="1000" 
              max="100000" 
              step="1000"
              value={activeUsers} 
              onChange={e => setActiveUsers(parseInt(e.target.value))}
              style={{ width: '100%', accentColor: 'var(--cyan)' }}
            />
          </div>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '.82rem', fontWeight: 700, marginBottom: '.5rem' }}>
              <span>Tỷ lệ hội viên VIP (BLUSH Pass Ratio):</span>
              <span style={{ color: 'var(--pink)' }}>{vipRatio}% VIP ({vipCount.toLocaleString()} Users)</span>
            </div>
            <input 
              type="range" 
              min="1" 
              max="20" 
              step="1"
              value={vipRatio} 
              onChange={e => setVipRatio(parseInt(e.target.value))}
              style={{ width: '100%', accentColor: 'var(--pink)' }}
            />
          </div>
        </div>

        {/* Results Grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem', marginBottom: '1.5rem' }} className="responsive-grid-4">
          <div style={{ background: 'rgba(0,0,0,0.25)', padding: '1rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.03)' }}>
            <div style={{ fontSize: '.73rem', color: 'var(--text-muted)', marginBottom: '.25rem' }}>CHI PHÍ API AI / THÁNG</div>
            <div style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--cyan)' }}>{f(monthlyAiCost)}</div>
            <div style={{ fontSize: '.65rem', color: 'var(--text-muted)', marginTop: '.15rem' }}>Cấp quota hạn mức theo tháng</div>
          </div>
          <div style={{ background: 'rgba(0,0,0,0.25)', padding: '1rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.03)' }}>
            <div style={{ fontSize: '.73rem', color: 'var(--text-muted)', marginBottom: '.25rem' }}>SMS VERIFY / THÁNG</div>
            <div style={{ fontSize: '1.15rem', fontWeight: 800, color: '#FFB703' }}>{f(monthlySmsCost)}</div>
            <div style={{ fontSize: '.65rem', color: 'var(--text-muted)', marginTop: '.15rem' }}>Giả định 15% user mới/tháng</div>
          </div>
          <div style={{ background: 'rgba(0,0,0,0.25)', padding: '1rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.03)' }}>
            <div style={{ fontSize: '.73rem', color: 'var(--text-muted)', marginBottom: '.25rem' }}>HOSTING & STORAGE / THÁNG</div>
            <div style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--success)' }}>{f(monthlyServerCost + monthlyOtherCost)}</div>
            <div style={{ fontSize: '.65rem', color: 'var(--text-muted)', marginTop: '.15rem' }}>Bao gồm CSDL Supabase Pro + AWS S3</div>
          </div>
          <div style={{ background: 'rgba(157,78,221,0.1)', padding: '1rem', borderRadius: '12px', border: '1px solid rgba(157,78,221,0.25)' }}>
            <div style={{ fontSize: '.73rem', color: 'var(--text-muted)', marginBottom: '.25rem', fontWeight: 700 }}>TỔNG CHI PHÍ VẬN HÀNH / THÁNG</div>
            <div style={{ fontSize: '1.25rem', fontWeight: 900, color: 'var(--pink-light)' }}>{f(totalMonthlyCost)}</div>
            <div style={{ fontSize: '.65rem', color: 'var(--text-secondary)', marginTop: '.15rem' }}>Logic mở rộng hiệu quả, kiểm soát tốt</div>
          </div>
        </div>

        {/* Cost Optimization Highlights */}
        <div style={{ background: 'rgba(0,0,0,0.3)', padding: '1rem', borderRadius: '12px', fontSize: '.78rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
          <strong>💡 Phân tích tính logic tài chính:</strong> Khi lượng user tăng gấp 10 lần (từ 10,000 lên 100,000), nhờ cơ chế thiết lập quota và lưu cache, chi phí Server & DB tăng bậc thang cực kỳ chậm (chỉ từ {f(pricing.getServerCost(10000))} lên {f(pricing.getServerCost(100000))}), trong khi chi phí AI tăng tuyến tính nhưng luôn được bù đắp trực tiếp bởi dòng doanh thu VIP từ {vipCount.toLocaleString()} hội viên VIP ({f(vipCount * 49000)}/tháng nếu tính gói 1 tháng 49k), đảm bảo tỷ suất lợi nhuận ròng của Blush luôn tăng trưởng dương ổn định.
        </div>
      </div>
    </div>
  );
}
