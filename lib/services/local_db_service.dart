import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:pos_app/models/cart_item.dart';

class LocalDbService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }
static Future<bool> deleteTable(int tableId) async {
  final db = await database;

  final cart = await db.query(
    'cart',
    where: 'tableId = ?',
    whereArgs: [tableId],
  );

  if (cart.isNotEmpty) {
    return false;
  }

  await db.delete(
    'tables',
    where: 'id = ?',
    whereArgs: [tableId],
  );

  return true;
}

  static Future<Database> _initDB() async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'pos_database.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 13,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE tables(
  id INTEGER PRIMARY KEY,
  name TEXT,
  status TEXT,
  occupiedAt TEXT
)
          ''');

          await db.execute('''
          CREATE TABLE cart(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tableId INTEGER,
            name TEXT,
            quantity INTEGER,
            price REAL,
            image TEXT,
            category TEXT,
            isKotSent INTEGER DEFAULT 0
          )
          ''');

          await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE
          )
          ''');

          await db.execute('''
          CREATE TABLE menu(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price REAL,
            category TEXT,
            image TEXT,
            isAvailable INTEGER DEFAULT 1,
            isNonVeg INTEGER DEFAULT 0
          )
          ''');

          await db.execute('''
          CREATE TABLE sales(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL,
            discount REAL DEFAULT 0,
            paymentMethod TEXT,
            timestamp TEXT
          )
          ''');

          await db.execute('''
          CREATE TABLE sale_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            saleId INTEGER,
            name TEXT,
            quantity INTEGER,
            price REAL,
            category TEXT
          )
          ''');

          await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL,
            description TEXT,
            category TEXT,
            timestamp TEXT
          )
          ''');

          await db.execute('''
          CREATE TABLE invoices(
            invoice_no TEXT PRIMARY KEY,
            date TEXT,
            time TEXT,
            table_no TEXT,
            order_type TEXT,
            items TEXT,
            qty TEXT,
            discount REAL,
            grand_total REAL
          )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await db.execute('''
            CREATE TABLE sales(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount REAL,
              timestamp TEXT
            )
            ''');
          }
          if (oldVersion < 4) {
            await db.execute('''
            CREATE TABLE sale_items(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              saleId INTEGER,
              name TEXT,
              quantity INTEGER,
              price REAL
            )
            ''');
          }
          if (oldVersion < 5) {
            try {
              await db.execute("ALTER TABLE tables ADD COLUMN occupiedAt TEXT");
            } catch (e) {}
          }
          if (oldVersion < 6) {
            try {
              await db.execute(
                  "ALTER TABLE menu ADD COLUMN isAvailable INTEGER DEFAULT 1");
              await db.execute(
                  "ALTER TABLE sales ADD COLUMN discount REAL DEFAULT 0");
              await db
                  .execute("ALTER TABLE sale_items ADD COLUMN category TEXT");
            } catch (e) {}
          }
          if (oldVersion < 7) {
            try {
              await db
                  .execute("ALTER TABLE sales ADD COLUMN paymentMethod TEXT");
              await db.execute('''
              CREATE TABLE expenses(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount REAL,
                description TEXT,
                category TEXT,
                timestamp TEXT
              )
              ''');
            } catch (e) {}
          }
          if (oldVersion < 8) {
            try {
              await db.execute("ALTER TABLE cart ADD COLUMN category TEXT");
            } catch (e) {}
          }
          if (oldVersion < 9) {
            try {
              await db.execute("ALTER TABLE tables ADD COLUMN name TEXT");
            } catch (e) {}
          }
          if (oldVersion < 12) {
            try {
              await db.execute(
                  "ALTER TABLE menu ADD COLUMN isNonVeg INTEGER DEFAULT 0");
            } catch (e) {}
          }
          if (oldVersion < 13) {
            try {
              await db.execute('''
              CREATE TABLE invoices(
                invoice_no TEXT PRIMARY KEY,
                date TEXT,
                time TEXT,
                table_no TEXT,
                order_type TEXT,
                items TEXT,
                qty TEXT,
                discount REAL,
                grand_total REAL
              )
              ''');
            } catch (e) {}
          }
        },
      ),
    );
  }

  static Future<void> createTable(int tableId) async {
    final db = await database;

    await db.insert(
      'tables',
      {
        'id': tableId,
        'name': 'Table $tableId',
        'status': 'available',
        'occupiedAt': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<List<int>> loadTableIds() async {
    final db = await database;

    final result = await db.query('tables');

    return result.map((e) => e['id'] as int).toList();
  }

  static Future<void> addCategory(String name) async {
    final db = await database;
    await db.insert(
      'categories',
      {"name": name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<List<String>> loadCategories() async {
    final db = await database;
    final result = await db.query('categories');
    return result.map((e) => e["name"]?.toString() ?? "Unknown").toList();
  }

  // ===== MENU =====
  static Future<void> addMenuItem(
      String name, double price, String category, String image,
      {int isAvailable = 1, int isNonVeg = 0}) async {
    final db = await database;

    // Ensure category exists in categories table
    await addCategory(category);

    await db.insert('menu', {
      "name": name,
      "price": price,
      "category": category,
      "image": image,
      "isAvailable": isAvailable,
      "isNonVeg": isNonVeg,
    });
  }

  static Future<void> bulkImportMenuItems(
      List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var item in items) {
        // Ensure category exists
        await txn.insert(
          'categories',
          {"name": item["category"]},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        // Insert item
        await txn.insert('menu', {
          "name": item["name"],
          "price": item["price"],
          "category": item["category"],
          "image": item["image"] ?? "",
          "isAvailable": item["isAvailable"] ?? 1,
          "isNonVeg": item["isNonVeg"] ?? 0,
        });
      }
    });
  }

  static Future<List<Map<String, dynamic>>> loadMenuItems() async {
    final db = await database;
    
    // Failsafe to ensure column is physically present in the SQLite file
    try {
      await db.execute("ALTER TABLE menu ADD COLUMN isNonVeg INTEGER DEFAULT 0");
    } catch (_) {}

    final result = await db.query('menu');

    return result
        .map((e) {
              int storedIsNonVeg = e["isNonVeg"] as int? ?? 0;
              bool isNonVeg = storedIsNonVeg == 1;

              // Auto-detect non-veg based on name or category if it's currently 0
              if (storedIsNonVeg == 0) {
                final name = e["name"]?.toString().toLowerCase() ?? "";
                final cat = e["category"]?.toString().toLowerCase() ?? "";
                if (name.contains("chicken") || name.contains("mutton") || 
                    name.contains("fish") || name.contains("prawn") || 
                    name.contains("egg") || name.contains("kodi") || 
                    name.contains("tangdi") || name.contains("meat") ||
                    cat.contains("chicken") || cat.contains("mutton") || 
                    cat.contains("seafood") || cat.contains("egg") || 
                    cat.contains("non-veg") || cat.contains("nonveg") ||
                    cat.contains("non veg")) {
                  isNonVeg = true;
                }
              }

              return {
                "id": e["id"] ?? 0,
                "name": e["name"]?.toString() ?? "Unknown",
                "price": (e["price"] as num?)?.toDouble() ?? 0.0,
                "category": e["category"]?.toString() ?? "General",
                "image": e["image"]?.toString(),
                "isAvailable": (e["isAvailable"] as int? ?? 1) == 1,
                "isNonVeg": isNonVeg,
              };
            })
        .toList();
  }

  // ===== TABLE =====
  static Future<void> saveTableStatus(int tableId, String status,
      {DateTime? occupiedAt}) async {
    final db = await database;
    await db.insert(
      'tables',
      {
        'id': tableId,
        'status': status,
        'occupiedAt': occupiedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateTableName(int tableId, String newName) async {
    final db = await database;
    await db.update(
      'tables',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }

  static Future<Map<int, Map<String, dynamic>>> loadTables() async {
    final db = await database;
    final result = await db.query('tables');

    Map<int, Map<String, dynamic>> tableMap = {};
    for (var row in result) {
      tableMap[row['id'] as int] = {
        'status': row['status']?.toString() ?? 'available',
        'occupiedAt': row['occupiedAt']?.toString(),
        'name': row['name']?.toString(),
      };
    }
    return tableMap;
  }

  // ===== CART =====
  static Future<void> saveOrUpdateCartItem(
      int tableId, String name, double price, int quantity,
      {String? image, String? category, bool? isKotSent}) async {
    final db = await database;

    final existing = await db.query(
      'cart',
      where: 'tableId = ? AND name = ?',
      whereArgs: [tableId, name],
    );

    if (existing.isEmpty) {
      await db.insert('cart', {
        'tableId': tableId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'image': image,
        'category': category ?? 'General',
        'isKotSent': (isKotSent ?? false) ? 1 : 0,
      });
    } else {
      if (quantity <= 0) {
        await db.delete(
          'cart',
          where: 'tableId = ? AND name = ?',
          whereArgs: [tableId, name],
        );
      } else {
        await db.update(
          'cart',
          {
            'quantity': quantity,
            if (category != null) 'category': category,
            if (isKotSent != null) 'isKotSent': isKotSent ? 1 : 0
          },
          where: 'tableId = ? AND name = ?',
          whereArgs: [tableId, name],
        );
      }
    }
  }

  static Future<List<CartItem>> loadCartItems(int tableId) async {
    final db = await database;

    final result =
        await db.query('cart', where: 'tableId = ?', whereArgs: [tableId]);

    return result
        .map((item) => CartItem(
              name: item['name']?.toString() ?? "Unknown",
              category: item['category']?.toString() ?? 'General',
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              quantity: item['quantity'] as int? ?? 1,
              image: item['image']?.toString(),
              isKotSent: (item['isKotSent'] as int? ?? 0) == 1,
            ))
        .toList();
  }

  static Future<void> clearCart(int tableId) async {
    final db = await database;
    await db.delete('cart', where: 'tableId = ?', whereArgs: [tableId]);
  }

  // ===== SEEDING =====
  static Future<void> seedData({bool force = false}) async {
    final cats = await loadCategories();
    if (cats.isNotEmpty && !force) return;

    if (force) {
      await clearMenu();
    }

    final items = [
      {"name": "Veg Corn Soup", "price": 92.0, "cat": "Veg Soup"},
      {"name": "Veg Manchow Soup", "price": 92.0, "cat": "Veg Soup"},
      {"name": "Veg Hot & Sour Soup", "price": 92.0, "cat": "Veg Soup"},
      {"name": "Veg Coriander Soup", "price": 109.0, "cat": "Veg Soup"},
      {"name": "Lemon Coriander Soup", "price": 109.0, "cat": "Veg Soup"},
      {"name": "Chicken Corn Soup", "price": 119.0, "cat": "Non-Veg Soup"},
      {"name": "Chicken Manchow Soup", "price": 119.0, "cat": "Non-Veg Soup"},
      {
        "name": "Chicken Hot & Sour Soup",
        "price": 119.0,
        "cat": "Non-Veg Soup"
      },
      {"name": "Chicken Coriander Soup", "price": 129.0, "cat": "Non-Veg Soup"},
      {"name": "Mutton Bone Soup", "price": 179.0, "cat": "Non-Veg Soup"},
      {"name": "Mutton Paya Soup", "price": 179.0, "cat": "Non-Veg Soup"},
      {"name": "Chicken Manchurian", "price": 259.0, "cat": "Chicken Starter"},
      {"name": "Chilli Chicken", "price": 259.0, "cat": "Chicken Starter"},
      {"name": "Chicken 65", "price": 259.0, "cat": "Chicken Starter"},
      {"name": "Chicken Majestic", "price": 259.0, "cat": "Chicken Starter"},
      {
        "name": "Guntur Chicken Pakoda",
        "price": 369.0,
        "cat": "Chicken Starter"
      },
      {"name": "Kodi Vepudu", "price": 369.0, "cat": "Chicken Starter"},
      {
        "name": "Boneless Chicken Vepudu",
        "price": 369.0,
        "cat": "Chicken Starter"
      },
      {"name": "Chicken Kebab", "price": 359.0, "cat": "Chicken Starter"},
      {"name": "Tangdi Kebab", "price": 385.0, "cat": "Chicken Starter"},
      {"name": "Apollo Fish", "price": 359.0, "cat": "Seafood Starter"},
      {"name": "Chilli Fish", "price": 359.0, "cat": "Seafood Starter"},
      {"name": "Chilli Prawns", "price": 359.0, "cat": "Seafood Starter"},
      {"name": "Loose Prawns", "price": 359.0, "cat": "Seafood Starter"},
      {"name": "Paneer Manchurian", "price": 199.0, "cat": "Paneer Starter"},
      {"name": "Paneer 65", "price": 199.0, "cat": "Paneer Starter"},
      {"name": "Chilli Paneer", "price": 199.0, "cat": "Paneer Starter"},
      {
        "name": "Mushroom Manchurian",
        "price": 199.0,
        "cat": "Mushroom Starter"
      },
      {"name": "Crispy Corn", "price": 199.0, "cat": "Veg Starter"},
      {"name": "Baby Corn Chilli", "price": 209.0, "cat": "Veg Starter"},
      {"name": "Gobi Manchurian", "price": 209.0, "cat": "Veg Starter"},
      {"name": "Veg Manchurian", "price": 157.0, "cat": "Veg Starter"},
      {"name": "Paneer Butter Masala", "price": 219.0, "cat": "Veg Curry"},
      {"name": "Palak Paneer", "price": 219.0, "cat": "Veg Curry"},
      {"name": "Mixed Veg Curry", "price": 219.0, "cat": "Veg Curry"},
      {"name": "Mushroom Masala", "price": 259.0, "cat": "Veg Curry"},
      {"name": "Kaju Curry", "price": 219.0, "cat": "Veg Curry"},
      {"name": "Butter Chicken", "price": 259.0, "cat": "Chicken Curry"},
      {"name": "Chicken Curry", "price": 259.0, "cat": "Chicken Curry"},
      {"name": "Fish Curry", "price": 359.0, "cat": "Seafood Curry"},
      {"name": "Prawns Curry", "price": 359.0, "cat": "Seafood Curry"},
      {"name": "Egg Curry", "price": 149.0, "cat": "Egg Curry"},
      {"name": "Veg Biryani", "price": 219.0, "cat": "Veg Biryani"},
      {"name": "Paneer Biryani", "price": 290.0, "cat": "Veg Biryani"},
      {"name": "Chicken Dum Biryani", "price": 219.0, "cat": "Chicken Biryani"},
      {
        "name": "Fry Piece Chicken Biryani",
        "price": 350.0,
        "cat": "Chicken Biryani"
      },
      {"name": "Mutton Biryani", "price": 449.0, "cat": "Mutton Biryani"},
      {"name": "Fish Biryani", "price": 369.0, "cat": "Seafood Biryani"},
      {"name": "Prawns Biryani", "price": 369.0, "cat": "Seafood Biryani"},
      {"name": "Veg Pulao", "price": 299.0, "cat": "Pulao"},
      {"name": "Chicken Pulao", "price": 369.0, "cat": "Pulao"},
    ];

    for (var i in items) {
      await addMenuItem(
        i["name"] as String,
        (i["price"] as num).toDouble(),
        i["cat"] as String,
        "",
      );
    }
  }

  // ===== UTILITIES =====
  static Future<void> clearHistory() async {
    final db = await database;
    await db.delete('sales');
    await db.delete('sale_items');
  }

  static Future<void> clearMenu() async {
    final db = await database;
    await db.delete('menu');
    await db.delete('categories');
  }

  // ===== SALES =====
  static Future<void> recordSale(double amount, List<CartItem> items,
      {double discount = 0, String paymentMethod = "Cash"}) async {
    final db = await LocalDbService.database;

    // Insert sale
    final saleId = await db.insert('sales', {
      'amount': amount,
      'discount': discount,
      'paymentMethod': paymentMethod,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Insert items
    for (var item in items) {
      await db.insert('sale_items', {
        'saleId': saleId,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
        'category': item.category,
      });
    }
  }

  static Future<List<Map<String, dynamic>>> loadSalesReport() async {
    final db = await database;
    return await db.query('sales', orderBy: 'timestamp DESC');
  }

  static Future<void> recordInvoice(
      String invoiceNo,
      String tableNo,
      String orderType,
      List<CartItem> items,
      double discount,
      double grandTotal) async {
    final db = await LocalDbService.database;
    final now = DateTime.now();

    final itemsJson = items.map((e) => {"name": e.name, "qty": e.quantity}).toList();
    final qtyTotal = items.fold(0, (sum, item) => sum + item.quantity);

    await db.insert('invoices', {
      'invoice_no': invoiceNo,
      'date': "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
      'time': "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
      'table_no': tableNo,
      'order_type': orderType,
      'items': jsonEncode(itemsJson),
      'qty': qtyTotal.toString(),
      'discount': discount > 0 ? discount : null,
      'grand_total': grandTotal,
    });
  }

  static Future<Map<String, dynamic>> getTodaySummary() async {
    final sales = await loadSalesReport();
    final expenses = await loadExpenses();
    final now = DateTime.now();
    double totalRevenue = 0;
    double totalExpenses = 0;
    int count = 0;

    for (var s in sales) {
      final dt = DateTime.parse(s['timestamp']);
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        totalRevenue += (s['amount'] as num).toDouble();
        count++;
      }
    }

    for (var e in expenses) {
      final dt = DateTime.parse(e['timestamp']);
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        totalExpenses += (e['amount'] as num).toDouble();
      }
    }

    return {
      'revenue': totalRevenue,
      'expenses': totalExpenses,
      'profit': totalRevenue - totalExpenses,
      'orders': count
    };
  }

  // ===== EXPENSES =====
  static Future<void> addExpense(
      double amount, String description, String category) async {
    final db = await database;
    await db.insert('expenses', {
      'amount': amount,
      'description': description,
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> loadExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'timestamp DESC');
  }

  static Future<Map<String, double>> getPaymentModeStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT paymentMethod, SUM(amount) as total 
      FROM sales 
      GROUP BY paymentMethod
    ''');

    Map<String, double> stats = {};
    for (var row in result) {
      stats[row['paymentMethod'] as String? ?? 'Other'] =
          (row['total'] as num).toDouble();
    }
    return stats;
  }

  static Future<List<Map<String, dynamic>>> loadSaleItems(int saleId) async {
    final db = await database;
    return await db
        .query('sale_items', where: 'saleId = ?', whereArgs: [saleId]);
  }

  static Future<void> cancelSaleItem(
      int saleId, int saleItemId, int cancelQty, double pricePerUnit) async {
    final db = await database;

    await db.transaction((txn) async {
      final List<Map<String, dynamic>> items = await txn
          .query('sale_items', where: 'id = ?', whereArgs: [saleItemId]);
      if (items.isEmpty) return;

      final item = items.first;
      int currentQty = item['quantity'] as int;
      double amountToDeduct = pricePerUnit * cancelQty;

      if (currentQty <= cancelQty) {
        await txn
            .delete('sale_items', where: 'id = ?', whereArgs: [saleItemId]);
      } else {
        await txn.update('sale_items', {'quantity': currentQty - cancelQty},
            where: 'id = ?', whereArgs: [saleItemId]);
      }

      final List<Map<String, dynamic>> salesList =
          await txn.query('sales', where: 'id = ?', whereArgs: [saleId]);
      if (salesList.isNotEmpty) {
        double currentTotal = (salesList.first['amount'] as num).toDouble();
        double newTotal = currentTotal - amountToDeduct;
        if (newTotal < 0) newTotal = 0;
        await txn.update('sales', {'amount': newTotal},
            where: 'id = ?', whereArgs: [saleId]);
      }
    });
  }

  static Future<List<Map<String, dynamic>>> loadPopularItems() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT name, SUM(quantity) as totalQty 
      FROM sale_items 
      GROUP BY name 
      ORDER BY totalQty DESC 
      LIMIT 10
    ''');
  }

  static Future<Map<String, double>> getCategoryWiseRevenue() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(price * quantity) as revenue 
      FROM sale_items 
      GROUP BY category
    ''');

    Map<String, double> report = {};
    for (var row in result) {
      report[row['category'] as String? ?? 'Uncategorized'] =
          (row['revenue'] as num).toDouble();
    }
    return report;
  }
}
