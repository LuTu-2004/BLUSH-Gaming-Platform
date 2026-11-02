# 💳 Hướng dẫn bật thanh toán thật (VietQR qua PayOS)

BLUSH nhận tiền bằng chuyển khoản VietQR:

| Phương thức | Đi qua | Tiền về đâu | Tự kích hoạt VIP? |
|---|---|---|---|
| **Chuyển khoản VietQR** | [PayOS](https://payos.vn) | Thẳng tài khoản ngân hàng của nhóm | Có (webhook + backend tự hỏi lại PayOS) |

> Ví MoMo đã bỏ từ 11/2026 (cần giấy phép kinh doanh để có ví doanh nghiệp). Giao dịch MoMo cũ vẫn hiện trong lịch sử và trang Admin.

Chế độ chạy chỉnh ở `backend/appsettings.json` → `Payment:Mode`:

| Mode | Dùng khi | VietQR |
|---|---|---|
| `Mock` (mặc định) | Demo, code giao diện | QR tĩnh + nút "Giả lập: ngân hàng đã nhận tiền" |
| `Sandbox` / `Production` | Chạy thật | PayOS (**tiền thật**, PayOS không có môi trường test) |

> ⚠️ Ở `Sandbox`/`Production`, nút giả lập bị khóa (API trả 404) để không ai tự kích hoạt VIP miễn phí.

---

## Bước 1. Đăng ký tài khoản

### PayOS (VietQR)
1. Đăng ký tại https://my.payos.vn bằng tài khoản ngân hàng của nhóm (cá nhân đăng ký được).
2. Tạo **Kênh thanh toán**, liên kết tài khoản ngân hàng nhận tiền.
3. Trong kênh thanh toán, lấy 3 giá trị: **Client ID**, **Api Key**, **Checksum Key**.

## Bước 2. Đặt key (KHÔNG ghi vào appsettings.json)

`appsettings.json` bị đẩy lên GitHub, nên key đặt bằng **user-secrets** (chỉ nằm trên máy bạn). Mở terminal ở thư mục `backend/`:

```bash
dotnet user-secrets set "Payment:PayOs:ClientId"    "<Client ID>"
dotnet user-secrets set "Payment:PayOs:ApiKey"      "<Api Key>"
dotnet user-secrets set "Payment:PayOs:ChecksumKey" "<Checksum Key>"
```

Kiểm tra: `dotnet user-secrets list`. Khi deploy lên server thì đặt bằng biến môi trường, VD `Payment__PayOs__ApiKey=...`.

## Bước 3. Cho PayOS gọi được về máy bạn (ngrok)

1. Cài ngrok: https://ngrok.com/download, đăng nhập: `ngrok config add-authtoken <token>`
2. Chạy backend (`dotnet run`), rồi mở terminal khác: `ngrok http 5000`
3. Copy link `https://xxxx.ngrok-free.app` rồi đặt:
   ```bash
   dotnet user-secrets set "Payment:PublicBaseUrl" "https://xxxx.ngrok-free.app"
   dotnet user-secrets set "Payment:Mode" "Production"   # hoặc "Sandbox"
   ```
4. Khởi động lại backend. Terminal sẽ in cảnh báo nếu còn thiếu key hoặc `PublicBaseUrl` chưa phải https.

> Link ngrok miễn phí **đổi mỗi lần chạy lại** → nhớ cập nhật `PublicBaseUrl` và webhook PayOS (bước 4).
> Kể cả khi webhook không tới được (ngrok tắt), app vẫn tự biết đã thanh toán: lúc app hỏi trạng thái, backend tự hỏi thẳng PayOS.

## Bước 4. Khai báo webhook PayOS

Trong my.payos.vn → Kênh thanh toán → **Webhook URL**, nhập:

```
https://xxxx.ngrok-free.app/api/payment/payos/webhook
```

PayOS sẽ gửi thử 1 giao dịch mẫu; backend trả 200 là được chấp nhận.

## Bước 5. Thử với số tiền nhỏ

1. Đăng nhập app → Hồ sơ → BLUSH Pass → chọn **BLUSH Pass (29.000đ)** → **Chuyển khoản VietQR**.
2. Quét QR bằng app ngân hàng, chuyển đúng số tiền (app ngân hàng tự điền).
3. Trong vài giây, app chuyển sang "Thanh toán thành công", Hồ sơ hiện VIP.
4. Admin → Quản trị → **Giao dịch** thấy đơn `Thành công`, mã tham chiếu ngân hàng ở cột GatewayTransactionId.

Muốn thử rẻ hơn: tạm thêm 1 gói giá 2.000đ trong bảng `VipPackages` rồi `IsActive = 0` sau khi thử xong.

---

## Khi có sự cố

| Hiện tượng | Nguyên nhân thường gặp |
|---|---|
| App hiện "Chưa hỗ trợ" | Thiếu key PayOS ở `Sandbox`/`Production`… kiểm tra `dotnet user-secrets list` |
| "Cổng thanh toán đang lỗi" khi bấm Thanh toán | Sai key / sai Mode (key test mà đặt Production) → xem log terminal backend |
| Đã chuyển tiền nhưng app vẫn chờ | Chờ ~5 giây (backend hỏi lại PayOS). Vẫn chờ → người dùng sửa nội dung chuyển khoản / chuyển thiếu. Admin đối soát sao kê rồi bấm **Xác nhận đã nhận tiền** trong tab Giao dịch |
| PayOS báo không lưu được webhook | Backend/ngrok chưa chạy, hoặc sai đường dẫn `/api/payment/payos/webhook` |

## An toàn

- Key chỉ nằm trong user-secrets / biến môi trường, không commit, không gửi qua chat.
- Mọi kết quả từ cổng đều kiểm tra chữ ký HMAC-SHA256 + đúng số tiền của đơn; tham số trên URL quay về (return URL) không được tin mà backend tự hỏi lại cổng.
- Mỗi giao dịch chỉ kích hoạt VIP 1 lần dù cổng báo về nhiều lần.
- Thu tiền thật là hoạt động kinh doanh: nhóm nên hỏi giảng viên về việc xuất hóa đơn / nghĩa vụ thuế trước khi mở cho người ngoài nhóm.
