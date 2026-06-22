class Environment {
  static const _env = String.fromEnvironment('ENV', defaultValue: 'prod');
  static const _isLocal = _env == 'local';

  // Android emulator dùng 10.0.2.2 để trỏ về localhost của máy host
  // iOS simulator hoặc web dùng localhost
  static const _localHost = '10.0.2.2';

  static const String baseUrl = _isLocal
      ? 'http://$_localHost:5210/api'
      : 'https://sonpham-socialnet-api.duckdns.org/identity/api';

  static const String userServiceBaseUrl = _isLocal
      ? 'http://$_localHost:5220/api'
      : 'https://sonpham-socialnet-api.duckdns.org/user/api';

  static const String friendServiceBaseUrl = _isLocal
      ? 'http://$_localHost:5178/api'
      : 'https://sonpham-socialnet-api.duckdns.org/friend/api';

  static const String postServiceBaseUrl = _isLocal
      ? 'http://$_localHost:5175/api'
      : 'https://sonpham-socialnet-api.duckdns.org/post/api';

  static const String messageServiceBaseUrl = _isLocal
      ? 'http://$_localHost:5177/api'
      : 'https://sonpham-socialnet-api.duckdns.org/message/api';

  static const String messageHubUrl = _isLocal
      ? 'http://$_localHost:5177/hubs/message'
      : 'https://sonpham-socialnet-api.duckdns.org/message/hubs/message';

  static const String notificationServiceBaseUrl = _isLocal
      ? 'http://$_localHost:5095/api'
      : 'https://sonpham-socialnet-api.duckdns.org/notification/api';

  static const String notificationHubUrl = _isLocal
      ? 'http://$_localHost:5095/hubs/notification'
      : 'https://sonpham-socialnet-api.duckdns.org/notification/hubs/notification';

  static const String googleClientId =
      '69350263890-k8a18rev98t4g3mjs1njnmq4qbjt3hsc.apps.googleusercontent.com';

  // Agora – lấy từ https://console.agora.io → Project → App ID
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '256733ae43b748bc8262e674ef5fc862',
  );

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String googleLoginEndpoint = '/auth/google';
}