/// ============================================================
/// Feature: Profile - Barrel Export
/// ============================================================
library;

// Domain - Entities
export 'domain/entities/profile_entity.dart';
export 'domain/entities/client_store_entity.dart';
export 'domain/entities/device_entity.dart';

// Domain - Repositories
export 'domain/repositories/profile_repository.dart';

// Domain - Use Cases
export 'domain/usecases/profile_usecases.dart';

// Data - Services
export 'data/services/qrcode_service.dart';
export 'data/services/device_management_service.dart';
export 'data/services/device_session_service.dart';

// Presentation - Providers
export 'presentation/providers/profile_provider.dart';

// Presentation - Widgets
export 'presentation/widgets/profile_widgets.dart';

// Presentation - Screens
export 'presentation/screens/profile_screen.dart';
export 'presentation/screens/qr_code_screen.dart';
export 'presentation/screens/settings_screen.dart';
export 'presentation/screens/devices_screen.dart';

// ============================================================
// COMPATIBILITÉ - Exports des anciens modèles
// ============================================================
export 'package:mukhliss/features/profile/data/models/user_device.dart';
