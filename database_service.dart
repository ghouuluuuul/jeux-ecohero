import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/user_model.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bileleva.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dbPath = await databaseFactoryFfi.getDatabasesPath();
      final path = join(dbPath, filePath);

      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: _createDB,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 3) {
              await db.execute('ALTER TABLE users ADD COLUMN memoryGameScore INTEGER NOT NULL DEFAULT 0');
            }
            if (oldVersion < 4) {
              await db.execute('ALTER TABLE users ADD COLUMN snakeGameScore INTEGER NOT NULL DEFAULT 0');
            }
          },
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 4,
        onCreate: _createDB,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await db.execute('ALTER TABLE users ADD COLUMN memoryGameScore INTEGER NOT NULL DEFAULT 0');
          }
          if (oldVersion < 4) {
            await db.execute('ALTER TABLE users ADD COLUMN snakeGameScore INTEGER NOT NULL DEFAULT 0');
          }
        },
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        sudokuScore INTEGER NOT NULL DEFAULT 0,
        puzzleScore INTEGER NOT NULL DEFAULT 0,
        carGameScore INTEGER NOT NULL DEFAULT 0,
        memoryGameScore INTEGER NOT NULL DEFAULT 0,
        snakeGameScore INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    debugPrint('✅ Table users créée avec succès');
  }

  Future<UserModel?> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> exists = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      debugPrint('Email $email - Résultats: ${exists.length}');

      if (exists.isNotEmpty) {
        debugPrint('❌ Email déjà utilisé');
        return null;
      }

      final id = await db.insert(
        'users',
        {
          'name': name,
          'email': email,
          'password': password,
          'sudokuScore': 0,
          'puzzleScore': 0,
          'carGameScore': 0,
          'memoryGameScore': 0,
          'snakeGameScore': 0,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Utilisateur créé avec ID: $id');

      return UserModel(
        id: id,
        name: name,
        email: email,
        createdAt: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ Erreur création: $e');
      return null;
    }
  }

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;

      final results = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (results.isNotEmpty) {
        return UserModel.fromMap(results.first);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur connexion: $e');
      return null;
    }
  }

  Future<UserModel?> getUser(int id) async {
    try {
      final db = await database;

      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty) {
        return UserModel.fromMap(results.first);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur récupération utilisateur: $e');
      return null;
    }
  }

  Future<bool> updateScore({
    required int userId,
    required String gameType,
    required int score,
  }) async {
    try {
      final db = await database;

      final user = await getUser(userId);
      if (user == null) return false;

      int currentScore = 0;
      switch (gameType) {
        case 'sudoku':
          currentScore = user.sudokuScore;
          break;
        case 'puzzle':
          currentScore = user.puzzleScore;
          break;
        case 'carGame':
          currentScore = user.carGameScore;
          break;
        case 'memoryGame':
          currentScore = user.memoryGameScore;
          break;
        case 'snakeGame':
          currentScore = user.snakeGameScore;
          break;
      }

      if (score > currentScore) {
        await db.update(
          'users',
          {'${gameType}Score': score},
          where: 'id = ?',
          whereArgs: [userId],
        );
      }

      return true;
    } catch (e) {
      debugPrint('Erreur mise à jour score: $e');
      return false;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final db = await database;
      final results = await db.query('users');
      return results.map((json) => UserModel.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Erreur récupération utilisateurs: $e');
      return [];
    }
  }

  Future<void> deleteAllUsers() async {
    try {
      final db = await database;
      await db.delete('users');
      debugPrint('✅ Tous les utilisateurs supprimés');

      final count = await db.query('users');
      debugPrint('Utilisateurs restants: ${count.length}');
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');
    }
  }

  Future<void> deleteDatabaseFile() async {
    try {
      await close();

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final dbPath = await databaseFactoryFfi.getDatabasesPath();
        final path = join(dbPath, 'bileleva.db');
        await databaseFactoryFfi.deleteDatabase(path);
      } else {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'bileleva.db');
        await deleteDatabase(path);
      }

      _database = null;
      debugPrint('✅ Base de données complètement supprimée');
    } catch (e) {
      debugPrint('❌ Erreur suppression DB: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
