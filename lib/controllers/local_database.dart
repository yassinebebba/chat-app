import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Future<Database> connect() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'database.db');
    try {
      await Directory(databasesPath).create(recursive: true);
    } catch (_) {}
    return await openDatabase(path);
  }

  static Future<void> drop() async {
    Database db = await connect();
    await db.rawQuery("DROP TABLE user;"
        "DROP TABLE contact"
        "DROP TABLE message;");
  }

  static Future<void> init() async {
    Database db = await connect();
    await db.rawQuery("CREATE TABLE IF NOT EXISTS user "
        "(id INTEGER PRIMARY KEY, "
        "country_code VARCHAR(4) NOT NULL, "
        "phone_number VARCHAR(20) NOT NULL, "
        "access_token TEXT, "
        "is_authenticated INTEGER NOT NULL DEFAULT 0 CHECK(is_authenticated IN (0, 1)));");
    await db.rawQuery("CREATE TABLE IF NOT EXISTS contact "
        "(id INTEGER PRIMARY KEY, "
        "name TEXT, "
        "country_code VARCHAR(4) NOT NULL, "
        "phone_number VARCHAR(20) UNIQUE NOT NULL, "
        "last_login DATE);");

    await db.rawQuery("CREATE TABLE IF NOT EXISTS message "
        "(id INTEGER PRIMARY KEY, "
        "content_type VARCHAR(5) NOT NULL DEFAULT 'text' CHECK(content_type IN ('text', 'image')), "
        "type VARCHAR(8) NOT NULL CHECK(type IN ('sent', 'received')), "
        "content TEXT NOT NULL, "
        "status INTEGER NOT NULL DEFAULT 0 CHECK(status IN (0, 1, 2, 3)), "
        "timestamp INTEGER NOT NULL, "
        "hash TEXT NOT NULL, "
        "deleted INTEGER NOT NULL DEFAULT 0 CHECK(deleted IN (0, 1)), "
        "sender_country_code VARCHAR(4) NOT NULL, "
        "sender_phone_number VARCHAR(20) NOT NULL, "
        "receiver_country_code VARCHAR(4) NOT NULL, "
        "receiver_phone_number VARCHAR(20) NOT NULL);");
  }

  static Future<void> insertUser(String countryCode, String phoneNumber) async {
    Database db = await connect();
    await db.rawQuery("INSERT INTO user "
        "(id, country_code, phone_number) "
        "VALUES (1, '$countryCode', '$phoneNumber') "
        "ON CONFLICT (id) "
        "DO UPDATE SET "
        "country_code=excluded.country_code,"
        " phone_number=excluded.phone_number;");
  }

  static Future<void> authorizeUser(String accessToken) async {
    Database db = await connect();
    await db.rawQuery("UPDATE user SET is_authenticated=1, access_token='$accessToken' WHERE id=1;");
  }

  static Future<void> logout() async {
    Database db = await connect();
    await db.rawQuery("UPDATE user SET is_authenticated=0, access_token='' WHERE id=1;");
  }

  static Future<Map<String, Object?>?> getUser() async {
    Database db = await connect();
    var array = await db.rawQuery("SELECT * FROM user LIMIT 1;");
    if (array.isNotEmpty) {
      return array[0];
    }
    return null;
  }

  static Future<void> insertContact(String name, String countryCode, String phoneNumber) async {
    Database db = await connect();
    phoneNumber = phoneNumber.replaceAll(' ', '');
    await db.rawQuery(
        "INSERT INTO contact (name, country_code, phone_number) VALUES ('$name', '$countryCode', '$phoneNumber') ON CONFLICT (phone_number) DO UPDATE SET name=excluded.name;");
  }

  static Future<List<Map<String, Object?>>> getContacts() async {
    Database db = await connect();
    return await db.rawQuery("SELECT * FROM contact;");
  }

  static Future<Map<String, Object?>> getContactByPhoneNumber(String countryCode, String phoneNumber) async {
    Database db = await connect();
    return (await db.rawQuery("SELECT * FROM contact WHERE country_code='$countryCode' AND phone_number='$phoneNumber';"))[0];
  }

  static Future<Map<String, Object?>> getContactByID(int id) async {
    Database db = await connect();
    return (await db.rawQuery("SELECT * FROM contact WHERE id=$id;"))[0];
  }

  static Future<void> deleteContactByPhoneNumber(String countryCode, String phoneNumber) async {
    Database db = await connect();
    await db.rawQuery("DELETE FROM contact WHERE country_code='$countryCode' AND phone_number='$phoneNumber';");
    await db.rawQuery("DELETE FROM message WHERE (sender_country_code='$countryCode' AND sender_phone_number='$phoneNumber') "
        "OR "
        "(receiver_country_code='$countryCode' AND receiver_phone_number='$phoneNumber');");
  }

  static Future<void> insertMessage(String senderCountryCode, String senderPhoneNumber, String receiverCountryCode, String receiverPhoneNumber,
      String contentType, String content, String type, String hash, int timestamp, int status) async {
    Database db = await connect();
    await db.rawQuery("INSERT INTO message "
        "(type, content_type, content, status, timestamp, hash, sender_country_code, sender_phone_number, receiver_country_code, receiver_phone_number) "
        "VALUES ('$type', '$contentType', '$content', $status, $timestamp, '$hash', "
        "'$senderCountryCode', '$senderPhoneNumber', '$receiverCountryCode', '$receiverPhoneNumber');");
  }

  static Future<List<Map<String, Object?>>> getMessages(String countryCode, String phoneNumber) async {
    Database db = await connect();
    return await db.rawQuery("SELECT * FROM message WHERE (sender_country_code='$countryCode' AND sender_phone_number='$phoneNumber') "
        "OR "
        "(receiver_country_code='$countryCode' AND receiver_phone_number='$phoneNumber') "
        "ORDER BY timestamp DESC;");
  }

  static Future<void> deleteMessage(String hash) async {
    Database db = await connect();
    await db.rawQuery("UPDATE message SET content='', deleted=1 WHERE hash='$hash';");
  }

  static Future<void> deleteMessageForever(String hash) async {
    Database db = await connect();
    await db.rawQuery("DELETE FROM message WHERE hash='$hash';");
  }

  static Future<void> markMessageAsDelivered(String hash) async {
    Database db = await connect();
    await db.rawQuery("UPDATE message SET status=2 WHERE hash='$hash';");
  }

  static Future<void> markMessageAsRead(String hash) async {
    Database db = await connect();
    await db.rawQuery("UPDATE message SET status=3 WHERE hash='$hash';");
  }

  static Future<Map<String, Object?>?> getLastMessage(String countryCode, String phoneNumber) async {
    Database db = await connect();
    final lastMessage = await db.rawQuery(
        "SELECT * FROM message WHERE "
            "(sender_country_code='$countryCode' AND sender_phone_number='$phoneNumber') "
            "OR "
            "(receiver_country_code='$countryCode' AND receiver_phone_number='$phoneNumber') "
            "ORDER BY timestamp DESC LIMIT 1;");
    if (lastMessage.isNotEmpty) {
      return lastMessage[0];
    }
    return null;
  }
}
