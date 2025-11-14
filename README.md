Flutter app (flutter-complete)
=============================

Structure (important files):
- lib/main.dart            -> app entry, shows SplashScreen
- lib/splash_screen.dart  -> short splash then go to LoginPage
- lib/login_page.dart     -> login form, calls ApiService
- lib/api_service.dart    -> login() and me() calling Django backend
- lib/home_user.dart      -> user home
- lib/home_admin.dart     -> admin home (superuser)
- lib/home_supervision.dart -> staff / supervision home

Usage:
1. unzip and open a terminal in flutter-complete
2. run `flutter pub get`
3. edit lib/api_service.dart if your backend base URL is not http://127.0.0.1:8000/api/
   - if using an Android emulator, use 10.0.2.2 instead of 127.0.0.1
   - if using a physical device, point to your PC's LAN IP, e.g. http://192.168.1.99:8000/api/
4. run `flutter run`

Test accounts created by the backend migration:
- superuser: saeb / saeb
- admin: admin1 / admin1
- supervision: superv1 / superv1
