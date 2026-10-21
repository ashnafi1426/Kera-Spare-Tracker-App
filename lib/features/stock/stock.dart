/// Stock feature module.
///
/// Implements ledger-based stock management through stock movements.
/// Quantity is derived by summing movement records to prevent concurrent overwrite issues.
library;

export 'data/repositories/local_stock_repository.dart';
export 'domain/models/stock_movement_item.dart';
export 'domain/repositories/stock_repository.dart';
export 'presentation/dialogs/update_stock_dialog.dart';
export 'presentation/providers/stock_providers.dart';
export 'presentation/screens/low_stock_screen.dart';
export 'presentation/screens/stock_history_screen.dart';
