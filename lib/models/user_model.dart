class UserModel {
  final String uid;
  final String name;
  final String email;
  final String department;
  final String semester;
  final String? profileImageUrl;
  final String? rollNo;
  final String? regNo;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.semester,
    this.profileImageUrl,
    this.rollNo,
    this.regNo,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'department': department,
      'semester': semester,
      'profileImageUrl': profileImageUrl,
      'rollNo': rollNo,
      'regNo': regNo,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      rollNo: map['rollNo'],
      regNo: map['regNo'],
      phoneNumber: map['phoneNumber'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? department,
    String? semester,
    String? profileImageUrl,
    String? rollNo,
    String? regNo,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rollNo: rollNo ?? this.rollNo,
      regNo: regNo ?? this.regNo,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

