# InnerLamp · Ảnh launch (trước Splash)

Màu nền: sáng #F4ECDD · tối #141210. Logo: vòng tròn vàng + ngọn đèn, căn giữa, không chữ.

## iOS (Xcode)
1. Kéo `ios/LaunchLogo.imageset` và `ios/LaunchBackground.colorset` vào `Assets.xcassets`.
2. Info.plist:
```xml
<key>UILaunchScreen</key>
<dict>
  <key>UIImageName</key><string>LaunchLogo</string>
  <key>UIColorName</key><string>LaunchBackground</string>
  <key>UIImageRespectsSafeAreaInsets</key><true/>
</dict>
```
File @2x/@3x được đặt tên `-2x`/`-3x`, Contents.json đã khớp. Logo 120pt (@1x 120px · @2x 240px · @3x 360px), có bản tối tự đổi theo hệ thống.

## Android (SplashScreen API)
- Chép thư mục `android/res` vào `app/src/main/res`.
- Icon: khung 288dp, logo 160dp nằm trong vùng an toàn 192dp (hệ thống cắt tròn). mdpi 288px → xxxhdpi 1152px, có bản `-night`.
- Thêm `implementation "androidx.core:core-splashscreen:1.0.1"`, đặt `android:theme="@style/Theme.InnerLamp.Starting"` cho Activity khởi động, gọi `installSplashScreen()` trước `super.onCreate()`.
