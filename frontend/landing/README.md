# 🌐 BLUSH Landing Page

Trang giới thiệu + tải APK cho người **chưa có app**. HTML/CSS/JS thuần, không cần build, host miễn phí ở đâu cũng được.

```
landing/
├── index.html    nội dung trang
├── styles.css    giao diện (màu lấy theo app: lib/services/theme_service.dart)
├── main.js       menu, hiệu ứng, nút tải, Google Analytics
├── config.js     ⚙️ CHỈ CẦN SỬA FILE NÀY: link APK, phiên bản, mã GA
└── assets/       logo, favicon, ảnh chia sẻ, ảnh chụp màn hình app thật
```

## Xem trên máy

```bash
cd frontend/landing
python -m http.server 8090
# mở http://localhost:8090
```

## Trước khi đưa lên mạng: sửa `config.js`

| Mục | Ý nghĩa |
|---|---|
| `apkUrl` | Link tải file APK. Hiện đang trỏ file trực tiếp `./BLUSH-1.0.0.apk`. Gợi ý thêm: có thể tạo GitHub Release, đính kèm file tên `BLUSH-1.0.0.apk`, rồi dùng `https://github.com/LuTu-2004/BLUSH-Gaming-Platform/releases/latest/download/BLUSH-1.0.0.apk` |
| `apkVersion`, `apkSize` | Hiện dưới nút tải, đang để `1.0.0` và `62.3 MB` |
| `gaMeasurementId` | Mã Google Analytics 4 dạng `G-XXXXXXXXXX` (analytics.google.com → Admin → Data streams → Web) |

## Đưa lên mạng miễn phí

- **Vercel** (dễ nhất): vercel.com → Add New Project → chọn repo → **Root Directory** = `frontend/landing` → Framework = *Other* → Deploy.
- **Netlify**: kéo thả cả thư mục `landing` vào app.netlify.com/drop.
- **GitHub Pages**: copy thư mục ra repo riêng hoặc dùng GitHub Actions.

## Đo người dùng đến từ đâu (Google, Facebook, TikTok...)

Khi đã điền `gaMeasurementId`, GA tự ghi nguồn truy cập. Khi đăng link ở đâu thì thêm `utm_source` tương ứng:

```
https://<trang-của-bạn>/?utm_source=facebook&utm_medium=social&utm_campaign=ra_mat
https://<trang-của-bạn>/?utm_source=tiktok&utm_medium=social&utm_campaign=ra_mat
https://<trang-của-bạn>/?utm_source=zalo&utm_medium=group&utm_campaign=ra_mat
```

Xem ở GA: **Reports → Acquisition → Traffic acquisition** (theo *Session source*).
Trang còn gửi sự kiện riêng:

| Sự kiện | Khi nào | Tham số |
|---|---|---|
| `download_apk` | Bấm nút "Tải BLUSH.apk" | `source` (facebook / google.com / direct...), `version` |
| `click_download_cta` | Bấm các nút "Tải" khác trên trang | `label` (chữ trên nút) |

→ Biết được bao nhiêu người **bấm tải** từ mỗi kênh, không chỉ bao nhiêu người vào trang.

## Cập nhật ảnh chụp màn hình

Ảnh trong `assets/screen-*.webp` chụp từ app thật (bản web Flutter, khung 390×844, độ nét x2), lưu WebP chất lượng 80. App đổi giao diện thì chụp lại và ghi đè cùng tên.
