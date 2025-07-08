import 'package:flutter/material.dart';
import 'package:mukhliss/providers/support_tickets_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';

class SupportTicketFormScreen extends StatefulWidget {
  @override
  _SupportTicketFormScreenState createState() => _SupportTicketFormScreenState();
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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
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
        final isDarkMode = themeMode == AppThemeMode.light;
        return Scaffold(
          backgroundColor:isDarkMode ? AppColors.darkSurface : AppColors.surface,
          body:CustomScrollView(
            slivers: [
           AppBarTypes.SupportAppBar(context),
          SliverToBoxAdapter(
            child:    FadeTransition(
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
                        _buildHeaderCard(),
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
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          )
        
          ]
        )
        );
      },
    );
  }

  Widget _buildHeaderCard() {
      final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDark,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.support_agent,
            size: 40,
            color: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
          l10n?.besoinaide ??  "Besoin d'aide ?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n?.description ??  "Décrivez votre problème et nous vous aiderons rapidement",
            style: TextStyle(
              fontSize: 16,
              color:AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(WidgetRef ref) {
     final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
   final isDarkMode = themeMode == AppThemeMode.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.priorite ??  "Priorité",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:isDarkMode ? AppColors.surface :AppColors.darkGrey50,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: _priorities.map((priority) {
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
                    color: isSelected ? color :AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ] : [],
                  ),
                  child: Center(
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    final isDarkMode = themeMode == AppThemeMode.light;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
        l10n?.categoie ??  "Catégorie",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:isDarkMode ? AppColors.surface : AppColors.darkGrey50,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.deepPurple),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
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
    final isDarkMode = themeMode == AppThemeMode.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.sujet ?? "Sujet",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:isDarkMode ? AppColors.surface : AppColors.darkGrey50,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _subjectController,
          decoration: InputDecoration(
            hintText: l10n?.resume ?? "Résumé de votre problème",
            prefixIcon: Icon(Icons.title, color: Colors.deepPurple),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.darkPurpleDark, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          validator: (v) => v!.isEmpty ? l10n?.champsrequi ?? 'Champ requis' : null,
        ),
      ],
    );
  }

  Widget _buildMessageField(WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.descriptiondetaille ?? "Description détaillée",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:isDarkMode ?AppColors.surface:AppColors.darkGrey50,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _messageController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText:  l10n?.poblemedetaille ?? "Décrivez votre problème en détail...",
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 80),
              child: Icon(Icons.description, color: AppColors.darkPurpleDark),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.darkPurpleDark, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          validator: (v) => v!.isEmpty ? l10n?.champsrequi ?? 'Champ requis' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
     final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor:AppColors.primary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppColors.darkPurpleDark.withOpacity(0.4),
        ),
        child: _isSubmitting
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
        await container.read(supportTicketsProvider).createSupportTicket(
          sujet: _subjectController.text,
          message: _messageController.text,
          priority: _selectedPriority,
          category: _selectedCategory,
        );
        
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
      builder: (context) => AlertDialog(
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
              child: Icon(
                Icons.check,
                size: 50,
                color: Colors.green,
              ),
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
              l10n?.ticketsucces ?? "Votre ticket a été créé avec succès. Vous recevrez une réponse sous 24h.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                 Navigator.of(context).pop(); // Ferme le dialogue
  Navigator.pushNamedAndRemoveUntil(
    context,
    AppRouter.profile, // Remplacez par votre route nommée pour ProfileScreen
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
                child: Text( l10n?.continuer ?? "Continuer"),
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
            Expanded(
              child: Text("Erreur: $error"),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }
}