# 💳 Hướng dẫn bật thanh toán thật (MoMo + VietQR qua PayOS)

BLUSH nhận tiền bằng 2 cách:

| Phương thức | Đi qua | Tiền về đâu | Tự kích hoạt VIP? |
|---|---|---|---|
| **Ví MoMo** | MoMo Payment Gateway (API v2) | Ví doanh nghiệp MoMo của nhóm | Có (IPN + backend tự hỏi lại MoMo) |
| **Chuyển khoản VietQR** | [PayOS](https://payos.vn) | Thẳng tài khoản ngân hàng của nhóm | Có (webhook + backend tự hỏi lại PayOS) |

Chế độ chạy chỉnh ở `backend/appsettings.json` → `Payment:Mode`:

| Mode | Dùng khi | MoMo | VietQR |
|---|---|---|---|
| `Mock` (mặc định) | Demo, code giao diện | Trang giả lập trong app | QR tĩnh + nút "Giả lập: ngân hàng đã nhận tiền" |
| `Sandbox` | Thử tích hợp | `test-payment.momo.vn` (tiền giả) | PayOS (**tiền thật**, PayOS không có môi trường test) |
| `Production` | Chạy thật | `payment.momo.vn` (**tiền thật**) | PayOS (**tiền thật**) |

> ⚠️ Ở `Sandbox`/`Production`, nút giả lập bị khóa (API trả 404) để không ai tự kích hoạt VIP miễn phí.

---

## Bước 1. Đăng ký tài khoản

### PayOS (VietQR)
1. Đăng ký tại https://my.payos.vn bằng tài khoản ngân hàng của nhóm (cá nhân đăng ký được).
2. Tạo **Kênh thanh toán**, liên kết tài khoản ngân hàng nhận tiền.
3. Trong kênh thanh toán, lấy 3 giá trị: **Client ID**, **Api Key**, **Checksum Key**.

### MoMo
- **Tiền thật (Production)**: cần tài khoản **MoMo Business** (doanh nghiệp / hộ kinh doanh, thường phải có giấy phép kinh doanh). Đăng ký tại https://business.momo.vn, ký hợp đồng xong MoMo cấp **Partner Code**, **Access Key**, **Secret Key**.
- **Chưa có giấy phép**: dùng `Mode: "Sandbox"` với key test lấy ở https://developers.momo.vn (mục test credentials). Tiền giả, quét bằng app MoMo bản test.
- Chưa có key MoMo thì app tự ẩn MoMo ("Chưa hỗ trợ"), VietQR vẫn chạy bình thường.

## Bước 2. Đặt key (KHÔNG ghi vào appsettings.json)

`appsettings.json` bị đẩy lên GitHub, nên key đặt bằng **user-secrets** (chỉ nằm trên máy bạn). Mở terminal ở thư mục `backend/`:

```bash
dotnet user-secrets set "Payment:PayOs:ClientId"    "<Client ID>"
dotnet user-secrets set "Payment:PayOs:ApiKey"      "<Api Key>"
dotnet user-secrets set "Payment:PayOs:ChecksumKey" "<Checksum Key>"

dotnet user-secrets set "Payment:Momo:PartnerCode" "<Partner Code>"
dotnet user-secrets set "Payment:Momo:AccessKey"   "<Access Key>"
dotnet user-secrets set "Payment:Momo:SecretKey"   "<Secret Key>"
```

Kiểm tra: `dotnet user-secrets list`. Khi deploy lên server thì đặt bằng biến môi trường, VD `Payment__PayOs__ApiKey=...`.

## Bước 3. Cho MoMo/PayOS gọi được về máy bạn (ngrok)

1. Cài ngrok: https://ngrok.com/download, đăng nhập: `ngrok config add-authtoken <token>`
2. Chạy backend (`dotnet run`), rồi mở terminal khác: `ngrok http 5000`
3. Copy link `https://xxxx.ngrok-free.app` rồi đặt:
   ```bash
   dotnet user-secrets set "Payment:PublicBaseUrl" "https://xxxx.ngrok-free.app"
   dotnet user-secrets set "Payment:Mode" "Production"   # hoặc "Sandbox"
   ```
4. Khởi động lại backend. Terminal sẽ in cảnh báo nếu còn thiếu key hoặc `PublicBaseUrl` chưa phải https.

> Link ngrok miễn phí **đổi mỗi lần chạy lại** → nhớ cập nhật `PublicBaseUrl` và webhook PayOS (bước 4).
> Kể cả khi webhook không tới được (ngrok tắt), app vẫn tự biết đã thanh toán: lúc app hỏi trạng thái, backend tự hỏi thẳng MoMo/PayOS.

## Bước 4. Khai báo webhook PayOS

Trong my.payos.vn → Kênh thanh toán → **Webhook URL**, nhập:

```
https://xxxx.ngrok-free.app/api/payment/payos/webhook
```

PayOS sẽ gửi thử 1 giao dịch mẫu; backend trả 200 là được chấp nhận. (MoMo không cần khai báo: link IPN gửi kèm mỗi đơn.)

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
| App hiện "Chưa hỗ trợ" | Thiếu key, hoặc đang `Mode: Mock`… kiểm tra `dotnet user-secrets list` |
| "Cổng thanh toán đang lỗi" khi bấm Thanh toán | Sai key / sai Mode (key test mà đặt Production) → xem log terminal backend |
| Đã chuyển tiền nhưng app vẫn chờ | Chờ ~5 giây (backend hỏi lại PayOS). Vẫn chờ → người dùng sửa nội dung chuyển khoản / chuyển thiếu. Admin đối soát sao kê rồi bấm **Xác nhận đã nhận tiền** trong tab Giao dịch |
| PayOS báo không lưu được webhook | Backend/ngrok chưa chạy, hoặc sai đường dẫn `/api/payment/payos/webhook` |

## An toàn

- Key chỉ nằm trong user-secrets / biến môi trường, không commit, không gửi qua chat.
- Mọi kết quả từ cổng đều kiểm tra chữ ký HMAC-SHA256 + đúng số tiền của đơn; tham số trên URL quay về (return URL) không được tin mà backend tự hỏi lại cổng.
- Mỗi giao dịch chỉ kích hoạt VIP 1 lần dù cổng báo về nhiều lần.
- Thu tiền thật là hoạt động kinh doanh: nhóm nên hỏi giảng viên về việc xuất hóa đơn / nghĩa vụ thuế trước khi mở cho người ngoài nhóm.
