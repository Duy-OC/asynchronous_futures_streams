# FocusFlow — Pomodoro Timer

## 1. Ý tưởng

FocusFlow là ứng dụng Pomodoro cho Android được xây dựng bằng Dart/Flutter. Project tập trung minh họa lập trình bất đồng bộ với `Future` và `Stream`.

### Chức năng cơ bản
- Timer tập trung 25 phút, nghỉ ngắn 5 phút, nghỉ dài 15 phút.
- Các nút Start, Pause, Resume và Reset.
- Tự chuyển giữa phiên tập trung và phiên nghỉ.
- Hiển thị thời gian còn lại, trạng thái phiên và số phiên đã hoàn thành.
- Lưu lịch sử phiên hoàn thành trên thiết bị bằng `shared_preferences`.
- Xem lại lịch sử phiên đã lưu.

## 2. Cây thư mục dự kiến

```text
focus_flow/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── pomodoro_state.dart
│   │   └── session_record.dart
│   ├── services/
│   │   ├── pomodoro_timer.dart
│   │   └── session_repository.dart
│   ├── screens/
│   │   ├── pomodoro_screen.dart
│   │   └── history_screen.dart
│   └── widgets/
│       ├── timer_display.dart
│       ├── timer_controls.dart
│       └── session_progress.dart
├── test/
│   ├── pomodoro_timer_test.dart
│   └── session_repository_test.dart
├── pubspec.yaml
└── README.md
```

### Vai trò các thành phần
- `main.dart`: khởi tạo ứng dụng và mở màn hình chính.
- `pomodoro_state.dart`: định nghĩa trạng thái timer, loại phiên và thời gian còn lại.
- `session_record.dart`: mô hình dữ liệu một phiên hoàn thành và chuyển đổi JSON.
- `pomodoro_timer.dart`: quản lý countdown, điều khiển timer, chuyển phiên và phát trạng thái qua Stream.
- `session_repository.dart`: đọc/ghi lịch sử cục bộ bằng `Future` và `shared_preferences`.
- `pomodoro_screen.dart`: màn hình timer chính, dùng `StreamBuilder` để cập nhật UI.
- `history_screen.dart`: hiển thị lịch sử phiên đã lưu.
- `widgets/`: các thành phần giao diện dùng lại.
- `test/`: kiểm thử logic timer và lưu trữ.

## 3. Hướng triển khai cơ bản

1. Tạo project Flutter và thêm package `shared_preferences`.
2. Định nghĩa model trạng thái timer và model lịch sử phiên.
3. Xây dựng `PomodoroTimer`:
   - Dùng `Timer.periodic` để kích hoạt cập nhật.
   - Dùng `StreamController<PomodoroState>` để phát trạng thái.
   - Cài đặt Start, Pause, Resume và Reset.
   - Tự chuyển phiên tập trung/nghỉ khi hết giờ.
   - Hủy timer khi không chạy; đóng controller khi đối tượng không còn được sử dụng.
4. Xây dựng `SessionRepository`:
   - Dùng `Future` và `async/await` để tải/lưu lịch sử.
   - Lưu danh sách phiên dưới dạng JSON trong `shared_preferences`.
5. Xây dựng UI:
   - Dùng `StreamBuilder` lắng nghe stream từ `PomodoroTimer`.
   - Hiển thị thời gian, loại phiên, tiến trình và các nút điều khiển.
   - Tạo màn hình lịch sử và tải dữ liệu từ repository.
6. Tích hợp và kiểm thử các luồng Start → Pause/Resume → hoàn thành phiên → lưu lịch sử.

## 4. Luồng hoạt động

```text
App khởi chạy
    |
    v
Tải lịch sử bằng Future
    |
    v
PomodoroScreen
    |
    v
StreamBuilder lắng nghe PomodoroTimer.stream
    |
    v
Start / Pause / Resume / Reset
    |
    v
PomodoroTimer cập nhật và phát PomodoroState
    |
    v
StreamBuilder cập nhật giao diện
    |
    v
Khi phiên hoàn thành
    |
    +--> Lưu SessionRecord bằng Future
    |
    +--> Chuyển sang phiên tiếp theo
```

## 5. Lưu ý kỹ thuật

- `Future` dùng cho thao tác tải/lưu lịch sử; `Stream` dùng để phát nhiều trạng thái timer theo thời gian.
- `StreamBuilder` chỉ hiển thị dữ liệu, không chứa logic đếm ngược.
- UI không tự tạo timer riêng; `PomodoroTimer` là nơi quản lý countdown.
- Khi Pause/Reset, hủy timer đang chạy nhưng không đóng `StreamController`.
- Khi timer không còn được sử dụng, hủy timer và đóng controller để tránh rò rỉ tài nguyên.
- Tính thời gian còn lại từ mốc thời gian kết thúc dự kiến (`endTime`) để hạn chế sai lệch khi callback bị trễ.
- Không cần backend hoặc đăng nhập; lịch sử được lưu cục bộ trên thiết bị.
"""