/// ============================================================
/// Stores Feature - Presentation Layer Exports
/// ============================================================
///
/// Exports pour la couche présentation de la feature stores.
library;

// ============================================================
// SCREENS
// ============================================================

export 'screens/location_screen.dart';

// ============================================================
// CONTROLLERS
// ============================================================

export 'controllers/location_controller.dart';

// ============================================================
// WIDGETS
// ============================================================

export 'widgets/categories_bottom_sheet.dart';
export 'widgets/shop_details_bottom_sheet.dart';
export 'widgets/route_bottom_sheet.dart';
export 'widgets/search_widget.dart';
export 'widgets/direction_arrow_widget.dart';

// Widgets extraits pour SRP
export 'widgets/reward_credit_card.dart';
export 'widgets/map_control_buttons_panel.dart';
export 'widgets/current_position_marker.dart';
export 'widgets/no_connection_widget.dart';
export 'widgets/shop_header_widgets.dart';
export 'widgets/loading_state_widgets.dart';

// ============================================================
// PROVIDERS (Clean Architecture)
// ============================================================

export 'providers/stores_providers.dart';
export 'providers/categories_providers.dart';
export 'providers/client_store_provider.dart';

// Legacy providers avec hide pour éviter les conflits
export 'providers/stores_provider.dart'
    hide storesRepositoryProvider, storeByIdProvider;

export 'providers/categories_provider.dart'
    hide
        categoriesServiceProvider,
        categoriesListProvider,
        categoriesProvider,
        localizedCategoriesProvider,
        categoryByIdProvider;

export 'providers/clientmagazin_provider.dart';
