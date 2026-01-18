import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> main() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'hadith_premium.db');
  final db = await openDatabase(path);

  print("COLLECTIONS:");
  final cols = await db.query('collections');
  for (var c in cols) print(c);

  print("\nBOOKS (First 5):");
  final books = await db.query('books', limit: 5);
  for (var b in books) print(b);

  print("\nHADITHS (First 5):");
  final hadiths = await db.query('hadiths', limit: 5);
  for (var h in hadiths) print(h);

  await db.close();
}
