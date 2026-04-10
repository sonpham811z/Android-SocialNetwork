class User {
  final String id;
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? username;
  final String? bio;
  final String? dateOfBirth;
  final int? age;
  final String? gender;
  final String? location;
  final String? city;
  final String? country;
  final String? website;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final String? coverPhotoUrl;
  final bool isPrivate;
  final bool isVerified;
  final int friendsCount;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String? createdAt;
  final String? lastActiveAt;

  User({
    required this.id,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.username,
    this.bio,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.location,
    this.city,
    this.country,
    this.website,
    this.phoneNumber,
    this.profilePictureUrl,
    this.coverPhotoUrl,
    this.isPrivate = false,
    this.isVerified = false,
    this.friendsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.createdAt,
    this.lastActiveAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['FirstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'])?.toString(),
      username: (json['username'] ?? json['userName'] ?? json['UserName'])
          ?.toString(),
      bio: (json['bio'] ?? json['Bio'])?.toString(),
      dateOfBirth: (json['dateOfBirth'] ?? json['DateOfBirth'])?.toString(),
      age: _parseInt(json['age'] ?? json['Age']),
      gender: (json['gender'] ?? json['Gender'])?.toString(),
      location: (json['location'] ?? json['Location'])?.toString(),
      city: (json['city'] ?? json['City'])?.toString(),
      country: (json['country'] ?? json['Country'])?.toString(),
      website: (json['website'] ?? json['Website'])?.toString(),
      phoneNumber: (json['phoneNumber'] ?? json['PhoneNumber'])?.toString(),
      profilePictureUrl:
          (json['profilePictureUrl'] ?? json['ProfilePictureUrl'] ?? json['avatar'])
              ?.toString(),
      coverPhotoUrl:
          (json['coverPhotoUrl'] ?? json['CoverPhotoUrl'])?.toString(),
      isPrivate: _parseBool(json['isPrivate'] ?? json['IsPrivate']),
      isVerified: _parseBool(json['isVerified'] ?? json['IsVerified']),
      friendsCount: _parseInt(json['friendsCount'] ?? json['FriendsCount']) ?? 0,
      followersCount:
          _parseInt(json['followersCount'] ?? json['FollowersCount']) ?? 0,
      followingCount:
          _parseInt(json['followingCount'] ?? json['FollowingCount']) ?? 0,
      postsCount: _parseInt(json['postsCount'] ?? json['PostsCount']) ?? 0,
      createdAt: (json['createdAt'] ?? json['CreatedAt'])?.toString(),
      lastActiveAt: (json['lastActiveAt'] ?? json['LastActiveAt'])?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value == null) {
      return false;
    }

    final normalized = value.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'userId': userId,
      'email' : email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'username': username,
      'bio': bio,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'gender': gender,
      'location': location,
      'city': city,
      'country': country,
      'website': website,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'isPrivate': isPrivate,
      'isVerified': isVerified,
      'friendsCount': friendsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': createdAt,
      'lastActiveAt': lastActiveAt,
    };
  }

  String get displayName {
    final computed = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (computed.isNotEmpty) {
      return computed;
    }
    if ((fullName ?? '').trim().isNotEmpty) {
      return fullName!.trim();
    }
    return email;
  }

  String get initials {
    final left = firstName.isNotEmpty ? firstName[0] : '';
    final right = lastName.isNotEmpty ? lastName[0] : '';
    final text = '$left$right'.trim();
    if (text.isNotEmpty) {
      return text.toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  String? get avatar => profilePictureUrl;

}

