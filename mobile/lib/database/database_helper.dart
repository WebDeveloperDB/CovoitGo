import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trajet.dart';
import '../models/demande.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('covoitgo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trajets (
        id TEXT PRIMARY KEY,
        idConducteur TEXT NOT NULL,
        depart_latitude REAL NOT NULL,
        depart_longitude REAL NOT NULL,
        destination_latitude REAL NOT NULL,
        destination_longitude REAL NOT NULL,
        heureDepart TEXT NOT NULL,
        capacite INTEGER NOT NULL,
        placesDisponibles INTEGER NOT NULL,
        statut TEXT NOT NULL,
        synced INTEGER NOT NULL,
        lastModified TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE demandes (
        id TEXT PRIMARY KEY,
        idTrajet TEXT NOT NULL,
        idPassager TEXT NOT NULL,
        placesDemandees INTEGER NOT NULL,
        statut TEXT NOT NULL,
        motif TEXT NOT NULL,
        synced INTEGER NOT NULL,
        lastModified TEXT NOT NULL
      )
    ''');
  }

  // --- CRUD Trajets ---
  Future<int> insertTrajet(Trajet trajet) async {
    final db = await instance.database;
    return await db.insert('trajets', trajet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Trajet>> getAllTrajets() async {
    final db = await instance.database;
    final result = await db.query('trajets');
    return result.map((json) => Trajet.fromMap(json)).toList();
  }
  
  Future<List<Trajet>> getPendingTrajets() async {
    final db = await instance.database;
    final result = await db.query('trajets', where: 'synced = ?', whereArgs: [0]);
    return result.map((json) => Trajet.fromMap(json)).toList();
  }

  Future<int> updateTrajet(Trajet trajet) async {
    final db = await instance.database;
    return db.update(
      'trajets',
      trajet.toMap(),
      where: 'id = ?',
      whereArgs: [trajet.id],
    );
  }

  Future<int> deleteTrajet(String id) async {
    final db = await instance.database;
    return await db.delete(
      'trajets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Demandes ---
  Future<int> insertDemande(Demande demande) async {
    final db = await instance.database;
    return await db.insert('demandes', demande.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Demande>> getAllDemandes() async {
    final db = await instance.database;
    final result = await db.query('demandes');
    return result.map((json) => Demande.fromMap(json)).toList();
  }
  
  Future<List<Demande>> getPendingDemandes() async {
    final db = await instance.database;
    final result = await db.query('demandes', where: 'synced = ?', whereArgs: [0]);
    return result.map((json) => Demande.fromMap(json)).toList();
  }

  Future<int> updateDemande(Demande demande) async {
    final db = await instance.database;
    return db.update(
      'demandes',
      demande.toMap(),
      where: 'id = ?',
      whereArgs: [demande.id],
    );
  }

  Future<int> deleteDemande(String id) async {
    final db = await instance.database;
    return await db.delete(
      'demandes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
