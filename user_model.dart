class UserModel {
  int? id;
  String name;
  String email;
  int sudokuScore;
  int puzzleScore;
  int carGameScore;
  int memoryGameScore;
  int snakeGameScore;
  String createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.sudokuScore = 0,
    this.puzzleScore = 0,
    this.carGameScore = 0,
    this.memoryGameScore = 0,
    this.snakeGameScore = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'sudokuScore': sudokuScore,
      'puzzleScore': puzzleScore,
      'carGameScore': carGameScore,
      'memoryGameScore': memoryGameScore,
      'snakeGameScore': snakeGameScore,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      sudokuScore: map['sudokuScore'] ?? 0,
      puzzleScore: map['puzzleScore'] ?? 0,
      carGameScore: map['carGameScore'] ?? 0,
      memoryGameScore: map['memoryGameScore'] ?? 0,
      snakeGameScore: map['snakeGameScore'] ?? 0,
      createdAt: map['createdAt'],
    );
  }
}
