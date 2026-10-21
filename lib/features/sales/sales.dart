/// Sales feature module.
///
/// Handles point-of-sale recording, automatic profit calculation,
/// pricing snapshots at sale time, sales history, and offline receipt logging.
library;

export 'data/repositories/local_sales_repository.dart';
export 'domain/models/sale_item_model.dart';
export 'domain/models/sale_line_item.dart';
export 'domain/models/sale_model.dart';
export 'domain/models/sales_day_group.dart';
export 'domain/repositories/sales_repository.dart';
export 'presentation/providers/sales_providers.dart';
export 'presentation/screens/new_sale_screen.dart';
export 'presentation/screens/sale_details_screen.dart';
export 'presentation/screens/sale_success_screen.dart';
export 'presentation/screens/sales_list_tab.dart';
