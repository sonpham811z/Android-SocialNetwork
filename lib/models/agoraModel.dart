class AgoraTokenResponse {
  final String token;
  final String appId;
  final String channelName;
  final int expireAt;

  AgoraTokenResponse({
    required this.token,
    required this.appId,
    required this.channelName,
    required this.expireAt,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      token:       json['token']       as String,
      appId:       json['appId']       as String,
      channelName: json['channelName'] as String,
      expireAt:    json['expireAt']    as int,
    );
  }
}
