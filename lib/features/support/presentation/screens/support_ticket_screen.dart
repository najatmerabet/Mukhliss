import 'package:flutter/material.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
// ✅ Nouvelle architecture
import 'package:mukhliss/features/support/support.dart';
import 'package:mukhliss/features/auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';
import 'package:mukhliss/core/routes/app_router.dart';

import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/widgets/Appbar/app_bar_types.dart';

class SupportTicketFormScreen extends StatefulWidget {
  const SupportTicketFormScreen({super.key});
  @override
  _SupportTicketFormScreenState createState() =>
      _SupportTicketFormScreenState();
}

class _SupportTicketFormScreenState extends State<SupportTicketFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isSubmitting = false;
  String _selectedPriority = 'Normal';
  String _selectedCategory = 'Général';

  late List<String> _priorities;
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);

    // Initialisez les listes avec les traductions
    _priorities = [
      l10n?.faible ?? 'Faible',
      l10n?.normale ?? 'Normal',
      l10n?.eleve ?? 'Élevé',
      l10n?.urgent ?? 'Urgent',
    ];

    _categories = [
      l10n?.generale ?? 'Général',
      l10n?.technique ?? 'Technique',
      l10n?.autre ?? 'Autre',
    ];

    // Définissez les valeurs par défaut en fonction de la langue
    _selectedPriority = _priorities[1]; // Normal
    _selectedCategory = _categories[0]; // Général
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeProvider);
        final isDarkMode = themeMode == AppThemeMode.dark;
        return Scaffold(
          backgroundColor: isDarkMode ? Color(0xFF0A0E27) : AppColors.surface,
          body: CustomScrollView(
            slivers: [
              AppBarTypes.supportAppBar(context),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Card
                              _buildHeaderCard(ref),
                              SizedBox(height: 24),

                              // Priority Selection
                              _buildPrioritySelector(ref),
                              SizedBox(height: 20),

                              // Category Selection
                              _buildCategorySelector(ref),
                              SizedBox(height: 20),

                              // Subject Field
                              _buildSubjectField(ref),
                              SizedBox(height: 20),

                              // Message Field
                              _buildMessageField(ref),
                              SizedBox(height: 30),

                              // Submit Button
                              _buildSubmitButton(ref),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = ref.watch(themeProvider) == AppThemeMode.light;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [
                    const Color.fromARGB(255, 59, 66, 94),
                    const Color.fromARGB(255, 41, 47, 75),
                  ]
                  : [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? AppColors.darkBackground : AppColors.purpleDark,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent, size: 40, color: Colors.white),
          SizedBox(height: 12),
          Text(
            l10n?.besoinaide ?? "Besoin d'aide ?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n?.description ??
                "Décrivez votre problème et nous vous aiderons rapidement",
            style: TextStyle(fontSize: 16, color: AppColors.surface),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = themeMode == AppThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.priorite ?? "Priorité",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.surface : AppColors.darkBackground,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children:
              _priorities.map((priority) {
                bool isSelected = _selectedPriority == priority;
                Color color = _getPriorityColor(priority);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? color
                                : isDarkMode
                                ? Color(0xFF0A0E27)
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? color
                                  : isDarkMode
                                  ? Colors.grey[700]!
                                  : const Color.fromARGB(255, 204, 201, 201),
                          width: 2,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                                : [],
                      ),
                      child: Center(
                        child: Text(
                          priority,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.categoie ?? "Catégorie",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.surface : Colors.black,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF0A0E27) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDarkMode
                      ? Color(0xFF0A0E27)
                      : Color.fromARGB(255, 204, 201, 201),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: isDarkMode ? Color(0xFF0A0E27) : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: isDarkMode ? Colors.white : Colors.deepPurple,
              ),
              style: TextStyle(
                color:
                    isDarkMode
                        ? Colors.white
                        : Colors.black, // Couleur du texte sélectionné
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              items:
                  _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? Colors.white
                                  : Colors
                                      .black, // Couleur des items dans la liste
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectField(WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.sujet ?? "Sujet",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.surface : Colors.black,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _subjectController,
          style: TextStyle(
            color:
                isDarkMode
                    ? Colors.white
                    : Colors.black, // Couleur du texte saisi
          ),
          decoration: InputDecoration(
            hintText: l10n?.resume ?? "Résumé de votre problème",
            hintStyle: TextStyle(
              color:
                  isDarkMode
                      ? const Color.fromARGB(255, 228, 230, 241)
                      : Colors.grey.shade600,
            ),
            prefixIcon: Icon(
              Icons.title,
              color: isDarkMode ? Colors.grey.shade400 : Colors.deepPurple,
            ),
            filled: true,
            fillColor: isDarkMode ? Color(0xFF0A0E27) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDarkMode ? AppColors.primary : AppColors.darkPurpleDark,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
          ),
          validator:
              (v) => v!.isEmpty ? l10n?.champsrequi ?? 'Champ requis' : null,
        ),
      ],
    );
  }

  Widget _buildMessageField(WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.descriptiondetaille ?? "Description détaillée",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.surface : Colors.black,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _messageController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText:
                l10n?.poblemedetaille ?? "Décrivez votre problème en détail...",
            hintStyle: TextStyle(
              color:
                  isDarkMode
                      ? const Color.fromARGB(255, 228, 230, 241)
                      : Colors.grey.shade600,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 120),
              child: Icon(
                Icons.description,
                color:
                    isDarkMode
                        ? AppColors.surface
                        : const Color.fromARGB(255, 212, 223, 231),
              ),
            ),
            filled: true,
            fillColor: isDarkMode ? Color(0xFF0A0E27) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          validator:
              (v) => v!.isEmpty ? l10n?.champsrequi ?? 'Champ requis' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDarkMode ? Color.fromARGB(255, 13, 21, 70) : AppColors.primary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppColors.darkPurpleDark.withValues(alpha: 0.4),
        ),
        child:
            _isSubmitting
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      l10n?.envoiencours ?? "Envoi en cours...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, size: 20),
                    SizedBox(width: 8),
                    Text(
                      l10n?.envoyerticket ?? "Envoyer le ticket",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Faible':
        return AppColors.success;
      case 'Normal':
        return AppColors.accent;
      case 'Élevé':
        return AppColors.warning;
      case 'Urgent':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  Future<void> _submitTicket() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final container = ProviderScope.containerOf(context);
        final userId = container.read(currentClientIdProvider);

        if (userId == null) throw Exception("Utilisateur non connecté");

        // Utilisation du nouveau provider
        final ticketData = {
          'user_id': userId,
          'email': 'user.$userId@example.com', // Placeholder
          'sujet': _subjectController.text,
          'message': _messageController.text,
          'status': 'open',
          'priority': _selectedPriority,
          'category': _selectedCategory,
        };

        await container.read(createTicketProvider(ticketData).future);

        // Animation de succès
        if (mounted) {
          _showSuccessDialog();
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 50, color: Colors.green),
                ),
                SizedBox(height: 20),
                Text(
                  l10n?.ticketenvoye ?? "Ticket envoyé !",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  l10n?.ticketsucces ??
                      "Votre ticket a été créé avec succès. Vous recevrez une réponse sous 24h.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Ferme le dialogue
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter
                            .profile, // Remplacez par votre route nommée pour ProfileScreen
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n?.continuer ?? "Continuer"),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text("Erreur: $error")),
          ],
        ),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
