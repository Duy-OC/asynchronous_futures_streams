# FocusFlow — Pomodoro Timer

> Ứng dụng đồng hồ Pomodoro cho Android, xây dựng bằng Flutter/Dart. Minh họa lập trình bất đồng bộ với `Future` và `Stream`.

---

## 2. Demo

| Màn hình chính | Phiên nghỉ | Lịch sử |
|:-:|:-:|:-:|
| Đồng hồ đếm ngược tập trung | Đồng hồ đếm ngược nghỉ ngắn/dài | Danh sách phiên đã hoàn thành |

> **APK:** `build/app/outputs/flutter-apk/app-release.apk` (~48 MB)

---

## 3. Tính năng nổi bật

- **Ba chế độ đồng hồ** — Tập trung (mặc định 25 phút), nghỉ ngắn (5 phút), nghỉ dài (15 phút)
- **Điều khiển đầy đủ** — Start, Pause, Resume và Reset
- **Tự động chuyển phiên** — Sau khi hết giờ, ứng dụng tự chuyển sang phiên tiếp theo
- **Tuỳ chỉnh thời gian tập trung** — Cài thời gian từ 1–180 phút, lưu vào thiết bị
- **Tiến trình theo chu kỳ** — Hiển thị số phiên trong chu kỳ (4 phiên tập trung → nghỉ dài)
- **Lịch sử phiên** — Lưu và xem lại toàn bộ lịch sử trên thiết bị
- **Giao diện Material 3** — Màu sắc thay đổi theo trạng thái (xanh = tập trung, cam = nghỉ)
- **Không cần mạng / tài khoản** — Hoàn toàn offline, lưu cục bộ

---

## 4. Công nghệ sử dụng

| Thành phần | Chi tiết |
|---|---|
| **Ngôn ngữ** | Dart 3 |
| **Framework** | Flutter 3 (Material 3) |
| **Bất đồng bộ** | `Future` & `Stream` / `StreamController` |
| **Lưu trữ** | `shared_preferences ^2.5.6` |
| **State management** | `StreamBuilder` (built-in Flutter) |
| **Build** | Gradle 9.3.1 · Android Gradle Plugin |
| **Linting** | `flutter_lints ^6.0.0` |
| **Testing** | `flutter_test` · `fake_async ^1.3.3` |

---

## 5. Yêu cầu hệ thống

### Để chạy ứng dụng (người dùng)
- Android **5.0 (API 21)** trở lên
- ~50 MB dung lượng trống

### Để build từ source (lập trình viên)
| Công cụ | Phiên bản |
|---|---|
| Flutter SDK | ≥ 3.13.5 |
| Dart SDK | ≥ 3.13.5 |
| Android SDK | API 21+ (compileSdk theo Flutter mặc định) |
| Java | 17 |
| Gradle | 9.3.1 (tự động tải qua wrapper) |
| OS build | Windows 10+, macOS 12+, hoặc Ubuntu 20.04+ |

---

## 6. Hướng dẫn cài đặt

### Cài APK trực tiếp (nhanh nhất)

1. Ấn vào file `app-release.apk` — trình duyệt sẽ tự động tải file về thiết bị
2. Mở file APK vừa tải xuống và chọn **Cài đặt**
3. Nếu hệ thống yêu cầu, bật **Cho phép cài đặt từ nguồn không rõ** rồi cài lại

### Build từ source code

```bash
# 1. Clone dự án
git clone <repository-url>
cd pomodoro

# 2. Cài đặt dependencies
flutter pub get

# 3. Build APK release
flutter build apk --release
# APK xuất ra: build/app/outputs/flutter-apk/app-release.apk

# Hoặc chạy trực tiếp trên thiết bị/emulator
flutter run
```

---

## 7. Cách sử dụng

```
1. Mở ứng dụng → màn hình chính hiển thị đồng hồ 25:00 (Tập trung)
2. Nhấn [Start] để bắt đầu đếm ngược
3. Nhấn [Pause] để tạm dừng, [Resume] để tiếp tục
4. Nhấn [Reset] để về lại đầu phiên hiện tại
5. Khi hết giờ → ứng dụng tự chuyển sang phiên Nghỉ ngắn (5 phút)
6. Sau 4 phiên tập trung → chuyển sang Nghỉ dài (15 phút)
7. Nhấn nút cài đặt (tune) để thay đổi thời gian tập trung (1–180 phút)
8. Nhấn nút lịch sử ở góc trên phải để xem lịch sử phiên đã lưu
```

**Màu sắc giao diện:**
- **Xanh lá** — Đang ở phiên Tập trung
- **Cam** — Đang ở phiên Nghỉ ngắn hoặc Nghỉ dài

---

## 8. Cấu trúc thư mục

```
pomodoro/
├── lib/
│   ├── main.dart                   # Khởi tạo app, cấu hình theme Material 3
│   ├── models/
│   │   ├── pomodoro_state.dart     # Trạng thái timer: loại phiên, thời gian, status
│   │   └── session_record.dart     # Model một phiên đã hoàn thành + JSON serialization
│   ├── services/
│   │   ├── pomodoro_timer.dart     # Logic đếm ngược (Timer.periodic + StreamController)
│   │   └── session_repository.dart # Đọc/ghi lịch sử với shared_preferences (Future/async)
│   ├── screens/
│   │   ├── pomodoro_screen.dart    # Màn hình chính, dùng StreamBuilder cập nhật UI
│   │   └── history_screen.dart     # Màn hình lịch sử phiên đã lưu
│   └── widgets/
│       ├── timer_display.dart      # Widget hiển thị đồng hồ đếm ngược
│       ├── timer_controls.dart     # Widget các nút Start/Pause/Resume/Reset
│       └── session_progress.dart   # Widget thanh tiến trình chu kỳ phiên
├── test/
│   ├── pomodoro_timer_test.dart    # Kiểm thử logic đếm ngược timer
│   └── session_repository_test.dart# Kiểm thử lưu/đọc lịch sử
├── android/                        # Cấu hình Android (Gradle, AndroidManifest)
├── pubspec.yaml                    # Dependencies và metadata dự án
└── README.md
```

---

## 9. Giấy phép

Dự án này được phát hành theo giấy phép **MIT License**.

```
MIT License

Copyright (c) 2026 FocusFlow Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
