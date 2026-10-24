# FocusFlow

Ứng dụng Pomodoro cho Android viết bằng Flutter. Một chu kỳ gồm bốn phiên tập trung 25 phút, xen kẽ nghỉ ngắn 5 phút và kết thúc bằng nghỉ dài 15 phút.

## Tính năng

- Bắt đầu, tạm dừng, tiếp tục và đặt lại phiên hiện tại.
- Tự chuyển sang phiên tiếp theo khi hết giờ.
- Hiển thị tiến trình chu kỳ và số phiên tập trung đã hoàn thành.
- Lưu các phiên hoàn thành trên thiết bị và xem lịch sử, không cần tài khoản hay mạng.

## Chạy dự án

Yêu cầu Flutter SDK và Android SDK. Tại thư mục dự án:

```sh
flutter pub get
flutter run
```

Kiểm tra mã nguồn và chạy test:

```sh
flutter analyze
flutter test
```

`PomodoroTimer` dùng `Timer.periodic` và phát trạng thái qua `Stream`; thời gian còn lại được tính từ thời điểm kết thúc. `SessionRepository` lưu lịch sử JSON bằng `shared_preferences` qua `Future`.
