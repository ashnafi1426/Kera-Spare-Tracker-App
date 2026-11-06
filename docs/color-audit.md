# Kera Spare Tracker — Extended Color Audit Baseline Report

**Generated Date:** 2026-11-06T12:19:01.145Z
**Scope:** All Dart source files under `lib/` (excluding `lib/core/theme/` and `lib/core/design/tokens/`)

## Executive Summary

| Violation Category | Count |
| :--- | :---: |
| **Files with Rogue Color References** | **70 files** |
| **Rogue `Colors.<hue>` References** | **120** |
| **Hardcoded `Color(0x...)` References** | **564** |
| **`Color.fromARGB(...)` References** | **0** |
| **`Color.fromRGBO(...)` References** | **0** |
| **`MaterialColor` References** | **0** |
| **`Colors.primaries` / `accents`** | **0** |
| **Grand Total Violations** | **684** |

---

## Detailed File-by-File Extended Audit

| # | File Path | `Colors.<hue>` | `Color(0x...)` | `fromARGB/fromRGBO` | Total | Redesigned Status |
| :-: | :--- | :-: | :-: | :-: | :-: | :-: |
| 1 | `lib/features/sales/presentation/screens/new_sale_screen.dart` | 2 | 60 | 0 | **62** | Pending Migration |
| 2 | `lib/features/parts/presentation/screens/inventory_screen.dart` | 2 | 59 | 0 | **61** | Pending Migration |
| 3 | `lib/features/parts/presentation/screens/part_form_screen.dart` | 1 | 45 | 0 | **46** | Pending Migration |
| 4 | `lib/features/sync/presentation/screens/offline_dashboard_screen.dart` | 0 | 44 | 0 | **44** | Pending Migration |
| 5 | `lib/features/sales/presentation/screens/sales_list_tab.dart` | 3 | 29 | 0 | **32** | Pending Migration |
| 6 | `lib/features/admin/presentation/screens/admin_owner_details_screen.dart` | 1 | 26 | 0 | **27** | Pending Migration |
| 7 | `lib/features/reports/presentation/screens/reports_screen.dart` | 10 | 16 | 0 | **26** | Pending Migration |
| 8 | `lib/features/admin/presentation/screens/admin_settings_screen.dart` | 2 | 22 | 0 | **24** | Pending Migration |
| 9 | `lib/features/admin/presentation/screens/admin_reports_screen.dart` | 0 | 23 | 0 | **23** | Pending Migration |
| 10 | `lib/features/admin/presentation/screens/admin_backup_screen.dart` | 0 | 18 | 0 | **18** | Pending Migration |
| 11 | `lib/features/admin/presentation/screens/admin_sync_monitor_screen.dart` | 0 | 18 | 0 | **18** | Pending Migration |
| 12 | `lib/features/sync/presentation/screens/sync_center_screen.dart` | 13 | 5 | 0 | **18** | Pending Migration |
| 13 | `lib/features/admin/presentation/screens/admin_plans_screen.dart` | 0 | 14 | 0 | **14** | Pending Migration |
| 14 | `lib/features/parts/presentation/widgets/inventory_filter_sheet.dart` | 1 | 13 | 0 | **14** | Pending Migration |
| 15 | `lib/core/design/widgets/dashboard_header_bar.dart` | 0 | 13 | 0 | **13** | Pending Migration |
| 16 | `lib/features/dashboard/presentation/screens/business_dashboard_screen.dart` | 0 | 13 | 0 | **13** | Pending Migration |
| 17 | `lib/features/admin/presentation/screens/admin_add_owner_screen.dart` | 0 | 12 | 0 | **12** | Pending Migration |
| 18 | `lib/features/admin/presentation/screens/admin_notifications_screen.dart` | 0 | 12 | 0 | **12** | Pending Migration |
| 19 | `lib/core/design/widgets/owner_header_bar.dart` | 1 | 10 | 0 | **11** | Pending Migration |
| 20 | `lib/features/dashboard/presentation/widgets/dashboard_offline_banner.dart` | 0 | 10 | 0 | **10** | Pending Migration |
| 21 | `lib/features/stock/presentation/screens/stock_history_screen.dart` | 1 | 9 | 0 | **10** | Pending Migration |
| 22 | `lib/features/auth/presentation/screens/forgot_password_screen.dart` | 0 | 9 | 0 | **9** | Pending Migration |
| 23 | `lib/features/reports/presentation/widgets/best_sellers_sheet.dart` | 7 | 1 | 0 | **8** | Pending Migration |
| 24 | `lib/features/settings/presentation/widgets/profile_photo_avatar.dart` | 0 | 8 | 0 | **8** | Pending Migration |
| 25 | `lib/features/admin/presentation/screens/admin_dashboard_screen.dart` | 1 | 6 | 0 | **7** | Pending Migration |
| 26 | `lib/features/dashboard/presentation/widgets/dashboard_low_stock_banner.dart` | 0 | 7 | 0 | **7** | Pending Migration |
| 27 | `lib/features/reports/presentation/widgets/profit_reports_sheet.dart` | 7 | 0 | 0 | **7** | Pending Migration |
| 28 | `lib/features/reports/presentation/widgets/sales_analytics_sheet.dart` | 7 | 0 | 0 | **7** | Pending Migration |
| 29 | `lib/features/sync/presentation/screens/sync_diagnostics_screen.dart` | 7 | 0 | 0 | **7** | Pending Migration |
| 30 | `lib/core/widgets/kera_image_widget.dart` | 4 | 2 | 0 | **6** | Pending Migration |
| 31 | `lib/features/admin/presentation/widgets/admin_metric_tile.dart` | 0 | 6 | 0 | **6** | Pending Migration |
| 32 | `lib/features/auth/presentation/widgets/session_banners.dart` | 6 | 0 | 0 | **6** | Pending Migration |
| 33 | `lib/features/sales/presentation/screens/sale_details_screen.dart` | 6 | 0 | 0 | **6** | Pending Migration |
| 34 | `lib/features/admin/presentation/widgets/admin_header_bar.dart` | 0 | 5 | 0 | **5** | Pending Migration |
| 35 | `lib/features/dashboard/presentation/widgets/dashboard_empty_onboarding.dart` | 0 | 5 | 0 | **5** | Pending Migration |
| 36 | `lib/features/dashboard/presentation/widgets/dashboard_metrics_grid.dart` | 1 | 4 | 0 | **5** | Pending Migration |
| 37 | `lib/features/reports/presentation/widgets/inventory_reports_sheet.dart` | 5 | 0 | 0 | **5** | Pending Migration |
| 38 | `lib/features/settings/presentation/screens/settings_screen.dart` | 4 | 1 | 0 | **5** | Pending Migration |
| 39 | `lib/features/sync/presentation/screens/conflict_resolution_screen.dart` | 5 | 0 | 0 | **5** | Pending Migration |
| 40 | `lib/core/design/widgets/kera_app_footer.dart` | 0 | 4 | 0 | **4** | Pending Migration |
| 41 | `lib/features/auth/presentation/screens/login_screen.dart` | 1 | 3 | 0 | **4** | Pending Migration |
| 42 | `lib/features/auth/presentation/screens/pending_approval_screen.dart` | 0 | 4 | 0 | **4** | Pending Migration |
| 43 | `lib/features/dashboard/presentation/widgets/dashboard_sales_trend.dart` | 2 | 2 | 0 | **4** | Pending Migration |
| 44 | `lib/features/home/presentation/screens/home_screen.dart` | 0 | 4 | 0 | **4** | Pending Migration |
| 45 | `lib/core/widgets/kera_loading_indicator.dart` | 0 | 3 | 0 | **3** | Pending Migration |
| 46 | `lib/features/dashboard/presentation/widgets/dashboard_header.dart` | 3 | 0 | 0 | **3** | Pending Migration |
| 47 | `lib/features/settings/presentation/screens/security_sessions_screen.dart` | 3 | 0 | 0 | **3** | Pending Migration |
| 48 | `lib/core/widgets/server_config_dialog.dart` | 0 | 2 | 0 | **2** | Pending Migration |
| 49 | `lib/features/admin/presentation/screens/admin_owners_list_screen.dart` | 0 | 2 | 0 | **2** | Pending Migration |
| 50 | `lib/features/dashboard/presentation/widgets/dashboard_best_sellers.dart` | 0 | 2 | 0 | **2** | Pending Migration |
| 51 | `lib/features/dashboard/presentation/widgets/dashboard_quick_actions.dart` | 1 | 1 | 0 | **2** | Pending Migration |
| 52 | `lib/features/notifications/presentation/screens/notification_settings_screen.dart` | 1 | 1 | 0 | **2** | Pending Migration |
| 53 | `lib/features/sales/presentation/screens/sale_success_screen.dart` | 1 | 1 | 0 | **2** | Pending Migration |
| 54 | `lib/features/security/presentation/widgets/app_lock_settings_card.dart` | 2 | 0 | 0 | **2** | Pending Migration |
| 55 | `lib/features/settings/presentation/screens/language_selection_screen.dart` | 2 | 0 | 0 | **2** | Pending Migration |
| 56 | `lib/features/stock/presentation/dialogs/update_stock_dialog.dart` | 0 | 2 | 0 | **2** | Pending Migration |
| 57 | `lib/main.dart` | 2 | 0 | 0 | **2** | Pending Migration |
| 58 | `lib/core/design/widgets/kera_card.dart` | 1 | 0 | 0 | **1** | Pending Migration |
| 59 | `lib/core/design/widgets/skeleton_loader.dart` | 0 | 1 | 0 | **1** | Pending Migration |
| 60 | `lib/core/widgets/announcement_banner_widget.dart` | 0 | 1 | 0 | **1** | Pending Migration |
| 61 | `lib/core/widgets/kera_logo_widget.dart` | 0 | 1 | 0 | **1** | Pending Migration |
| 62 | `lib/core/widgets/maintenance_banner_widget.dart` | 0 | 1 | 0 | **1** | Pending Migration |
| 63 | `lib/features/auth/presentation/screens/change_password_screen.dart` | 1 | 0 | 0 | **1** | Pending Migration |
| 64 | `lib/features/auth/presentation/screens/register_screen.dart` | 0 | 1 | 0 | **1** | Pending Migration |
| 65 | `lib/features/dashboard/presentation/widgets/dashboard_recent_sales.dart` | 1 | 0 | 0 | **1** | Pending Migration |
| 66 | `lib/features/dashboard/presentation/widgets/dashboard_sync_error_sheet.dart` | 0 | 1 | 0 | **1** | Pending Migration |
| 67 | `lib/features/notifications/presentation/screens/notification_center_screen.dart` | 1 | 0 | 0 | **1** | Pending Migration |
| 68 | `lib/features/settings/presentation/screens/business_profile_screen.dart` | 0 | 1 | 0 | **1** | Pending Migration |
| 69 | `lib/features/stock/presentation/screens/low_stock_screen.dart` | 0 | 1 | 0 | **1** | Pending Migration |
| 70 | `lib/features/sync/presentation/screens/initial_sync_screen.dart` | 1 | 0 | 0 | **1** | Pending Migration |

---
*Baseline strictly locked in `test/color_audit_baseline.json`. Any violation increase fails the automated CI test.*
