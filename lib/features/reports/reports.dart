/// Reports feature module.
///
/// Provides daily, weekly, and monthly sales summaries, revenue & profit graphs
/// powered by fl_chart, top 5 selling parts, and inventory valuation.
library;

export 'data/repositories/local_reports_repository.dart';
export 'domain/models/chart_point.dart';
export 'domain/models/date_range_filter.dart';
export 'domain/models/inventory_valuation.dart';
export 'domain/models/report_period.dart';
export 'domain/models/sales_summary.dart';
export 'domain/models/top_selling_part.dart';
export 'domain/repositories/reports_repository.dart';
export 'presentation/providers/reports_providers.dart';
export 'presentation/screens/reports_screen.dart';
