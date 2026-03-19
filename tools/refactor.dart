import 'dart:io';

void main() {
  final file = File('lib/ui/screens/pos_screen.dart');
  String text = file.readAsStringSync();

  String newImports = '''
import '../widgets/pos/pos_top_bar.dart';
import '../widgets/pos/pos_search_bar.dart';
import '../widgets/pos/pos_category_sidebar.dart';
import '../widgets/pos/pos_menu_grid.dart';
import '../widgets/pos/pos_cart_table.dart';
import '../widgets/pos/pos_summary_section.dart';
''';
  text = text.replaceAll("import 'revenue_screen.dart';", "import 'revenue_screen.dart';\n\$newImports");

  String oldBody = '''        appBar: _buildTopAppBar(),
        body: Row(
          children: [
            /// LEFT SIDE
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  /// SEARCH BAR
                  _buildSearchAndQtyBar(),

                  /// CATEGORY LIST (HORIZONTAL)
                  SizedBox(
                    height: 110,
                    child: _buildLeftCategorySidebar(),
                  ),

                  /// ITEMS GRID
                  Expanded(
                    child: _buildMenuGrid(filteredMenuItems),
                  ),
                ],
              ),
            ),

            /// RIGHT SIDE BILLING
            Container(
              width: 480,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  Expanded(child: _buildCartTable()),
                  _buildCustomerAndSummarySection(),
                ],
              ),
            ),
          ],
        ),''';

  String newBody = '''        appBar: PosTopBar(
          selectedType: selectedType,
          onTypeChanged: (type) => setState(() => selectedType = type),
          onCancelTap: _handleCancelTap,
        ),
        body: Row(
          children: [
            /// LEFT SIDE
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  /// SEARCH BAR
                  PosSearchBar(
                    searchController: searchController,
                    searchFocusNode: searchFocusNode,
                    onSearchChanged: (v) => setState(() => searchQuery = v),
                    quantityToCalculate: quantityToCalculate,
                    onQuantityChanged: (qty) => setState(() => quantityToCalculate = qty),
                    onAddPressed: () {
                      final results = menu
                          .where((item) => item["name"]
                              .toString()
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))
                          .toList();
                      if (results.isNotEmpty) {
                        addItemManually(results.first, quantityToCalculate);
                      }
                    },
                  ),

                  /// CATEGORY LIST (HORIZONTAL)
                  SizedBox(
                    height: 110,
                    child: PosCategorySidebar(
                      categories: categories,
                      selectedCategoryIndex: selectedCategoryIndex,
                      onCategorySelected: (index) => setState(() => selectedCategoryIndex = index),
                      categoryScrollController: _categoryScrollController,
                    ),
                  ),

                  /// ITEMS GRID
                  Expanded(
                    child: PosMenuGrid(
                      items: filteredMenuItems,
                      onItemTap: (item) => addItemManually(item, quantityToCalculate),
                    ),
                  ),
                ],
              ),
            ),

            /// RIGHT SIDE BILLING
            Container(
              width: 480,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PosCartTable(
                      cart: widget.table.cart,
                      onQtyChanged: changeQty,
                    ),
                  ),
                  PosSummarySection(
                    now: _now,
                    cart: widget.table.cart,
                    subtotal: subtotal,
                    totalDiscount: totalDiscount,
                    totalGst: totalGst,
                    grandTotal: grandTotal,
                    isPrinting: isPrinting,
                    onClearTable: _clearTable,
                    onPrintReceipt: _simulatePrint,
                    onPayAndClose: proceedPayment,
                  ),
                ],
              ),
            ),
          ],
        ),''';

  text = text.replaceAll(oldBody, newBody);

  int idx1 = text.indexOf("  PreferredSizeWidget _buildTopAppBar() {");
  int idx2 = text.indexOf("  Future<void> _simulatePrint(String type) async {");

  if (idx1 != -1 && idx2 != -1) {
    text = text.substring(0, idx1) + text.substring(idx2);
  }

  file.writeAsStringSync(text);
}
