import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_two/core/auth_api.dart';
import 'package:project_two/models/app_user.dart';
import 'package:project_two/models/role.dart';
import 'package:project_two/state/auth_notifier.dart';

import 'mock_adapter.dart';

void main() {
  // ─────────────────────────────────────────────
  // Role.fromString
  // ─────────────────────────────────────────────
  group('Role.fromString', () {
    test('парсит manager', () {
      expect(Role.fromString('manager'), Role.manager);
    });

    test('парсит logist', () {
      expect(Role.fromString('logist'), Role.logist);
    });

    test('парсит admin', () {
      expect(Role.fromString('admin'), Role.admin);
    });

    test('неизвестное → manager', () {
      expect(Role.fromString('unknown'), Role.manager);
      expect(Role.fromString(null), Role.manager);
    });
  });

  // ─────────────────────────────────────────────
  // Уровни
  // ─────────────────────────────────────────────
  test('уровни ролей: manager < logist < admin', () {
    expect(Role.manager.level, 1);
    expect(Role.logist.level, 2);
    expect(Role.admin.level, 3);
  });

  // ─────────────────────────────────────────────
  // has() — основная логика
  // ─────────────────────────────────────────────
  group('AuthNotifier.has', () {
    late AuthNotifier auth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = MockAdapter();
      final dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8080/api',
        validateStatus: (s) => s != null && s < 500,
      ));
      dio.httpClientAdapter = adapter;
      final api = AuthApi(dio);
      auth = AuthNotifier(prefs, api);
    });

    test('без пользователя — все false', () {
      expect(auth.has(Role.manager), false);
      expect(auth.has(Role.logist), false);
      expect(auth.has(Role.admin), false);
    });

    test('manager: manager=true, logist=false, admin=false', () {
      auth.debugSetUser(_user('manager', Role.manager));
      expect(auth.has(Role.manager), true);
      expect(auth.has(Role.logist), false);
      expect(auth.has(Role.admin), false);
    });

    test('logist: manager=true, logist=true, admin=false', () {
      auth.debugSetUser(_user('logist', Role.logist));
      expect(auth.has(Role.manager), true);
      expect(auth.has(Role.logist), true);
      expect(auth.has(Role.admin), false);
    });

    test('admin: все true', () {
      auth.debugSetUser(_user('admin', Role.admin));
      expect(auth.has(Role.manager), true);
      expect(auth.has(Role.logist), true);
      expect(auth.has(Role.admin), true);
    });
  });

  // ─────────────────────────────────────────────
  // hasExactly() — точное сравнение
  // ─────────────────────────────────────────────
  group('AuthNotifier.hasExactly', () {
    late AuthNotifier auth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = MockAdapter();
      final dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8080/api',
        validateStatus: (s) => s != null && s < 500,
      ));
      dio.httpClientAdapter = adapter;
      final api = AuthApi(dio);
      auth = AuthNotifier(prefs, api);
    });

    test('manager: hasExactly(manager)=true, остальные=false', () {
      auth.debugSetUser(_user('manager', Role.manager));
      expect(auth.hasExactly(Role.manager), true);
      expect(auth.hasExactly(Role.logist), false);
      expect(auth.hasExactly(Role.admin), false);
    });

    test('logist: hasExactly(logist)=true', () {
      auth.debugSetUser(_user('logist', Role.logist));
      expect(auth.hasExactly(Role.logist), true);
      expect(auth.hasExactly(Role.manager), false);
      expect(auth.hasExactly(Role.admin), false);
    });

    test('admin: hasExactly(admin)=true', () {
      auth.debugSetUser(_user('admin', Role.admin));
      expect(auth.hasExactly(Role.admin), true);
      expect(auth.hasExactly(Role.manager), false);
      expect(auth.hasExactly(Role.logist), false);
    });
  });

  // ─────────────────────────────────────────────
  // isAuthenticated
  // ─────────────────────────────────────────────
  test('isAuthenticated: false до, true после', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final adapter = MockAdapter();
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      validateStatus: (s) => s != null && s < 500,
    ));
    dio.httpClientAdapter = adapter;
    final api = AuthApi(dio);
    final auth = AuthNotifier(prefs, api);

    expect(auth.isAuthenticated, false);

    auth.debugSetUser(_user('logist', Role.logist));
    expect(auth.isAuthenticated, true);
  });
}

// ─────────────────────────────────────────────
// Помощники
// ─────────────────────────────────────────────

AppUser _user(String username, Role role) => AppUser(
      id: 1,
      username: username,
      fullName: username,
      email: '$username@test.local',
      role: role,
    );
