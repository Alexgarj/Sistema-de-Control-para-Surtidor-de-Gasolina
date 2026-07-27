import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/pos/presentation/pages/pos_page.dart';
import 'features/control/presentation/pages/surtidores_control_page.dart';
import 'features/reportes/presentation/pages/arqueo_caja_page.dart';
import 'features/auth/presentation/widgets/crear_usuario_dialog.dart';
import 'features/auth/data/auth_service.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  late Timer _timer;
  RealtimeChannel? _notifChannel; // Canal de tiempo real para notificaciones
  String _currentTime = '';
  String _userName = 'Cargando...';
  String _userInitials = '...';
  String _userRole = 'cajero';
  String _userTurno = 'Turno Actual';
  int _notificacionesCount = 0;
  bool _initializedFromArgs = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _startClock();
    _loadUserProfile();
    _listenNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      final Map<String, dynamic>? args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        setState(() {
          _userRole = _normalizeRole(args['role'] ?? 'cajero');
          if (args['name'] != null && args['name'].toString().isNotEmpty) {
            _userName = args['name'];
            _userInitials = _getInitials(_userName);
          }
        });
        _initializedFromArgs = true;
      }
    }
  }

  @override
  void dispose() {
    if (_notifChannel != null) {
      Supabase.instance.client.removeChannel(_notifChannel!);
    }
    _timer.cancel();
    super.dispose();
  }

  String _normalizeRole(dynamic rawRole) {
    final roleStr = rawRole.toString().toLowerCase().trim();
    if (roleStr == 'admin' || roleStr == 'administrador') {
      return 'admin';
    }
    return 'cajero';
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d "de" MMMM · hh:mm:ss a', 'es_ES');
    if (mounted) {
      setState(() {
        _currentTime = formatter.format(now);
      });
    }
  }

  String _getInitials(String nombre) {
    List<String> partes = nombre.trim().split(' ');
    if (partes.length >= 2 && partes[1].isNotEmpty) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    } else if (nombre.length >= 2) {
      return nombre.substring(0, 2).toUpperCase();
    }
    return 'US';
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('perfiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null && mounted) {
          final String nombre = data['nombre_completo'] ?? _userName;
          final String rol = _normalizeRole(data['rol'] ?? _userRole);

          setState(() {
            _userName = nombre;
            _userInitials = _getInitials(nombre);
            _userRole = rol;
          });
        }
      } catch (e) {
        debugPrint("Error cargando perfil: $e");
      }
    }
  }

  /// Escucha notificaciones en tiempo real para el Administrador
  void _listenNotifications() {
    _notifChannel =
        Supabase.instance.client
            .channel('public:notificaciones')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notificaciones',
              callback: (payload) {
                if (mounted && _userRole == 'admin') {
                  final newRecord = payload.newRecord;

                  setState(() {
                    _notificacionesCount++;
                  });

                  // Mostrar SnackBar de alerta flotante en vivo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surface,
                      duration: const Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      content: Row(
                        children: [
                          const Icon(
                            LucideIcons.bell,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  newRecord['titulo'] ?? 'Nueva Notificación',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  newRecord['mensaje'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            )
          ..subscribe();
  }

  // --- MAPEO DE VISTAS SEGÚN ROL ---
  List<Widget> _getAvailablePages() {
    if (_userRole == 'admin') {
      return const [
        DashboardPage(),
        SurtidoresControlPage(), // Admin administra y resuelve fallas
        ArqueoCajaPage(), // Admin supervisa reportes recibidos
      ];
    }
    // Cajero
    return const [
      PosPage(), // Venta POS principal
      ArqueoCajaPage(), // Generar y enviar arqueo de caja
      SurtidoresControlPage(), // Reportar estado de surtidor
    ];
  }

  List<String> _getAvailableTitles() {
    if (_userRole == 'admin') {
      return const [
        'Dashboard General',
        'Control y Gestión de Surtidores',
        'Supervisión de Reportes',
      ];
    }
    return const [
      'Venta POS',
      'Arqueo de Caja y Reportes',
      'Estado de Surtidores',
    ];
  }

  /// Despliega el buzón de notificaciones consultando la BD
  void _onNotificationsPressed() async {
    final response = await Supabase.instance.client
        .from('notificaciones')
        .select()
        .order('created_at', ascending: false)
        .limit(10);

    final List<Map<String, dynamic>> notificaciones =
        List<Map<String, dynamic>>.from(response);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Buzón de Notificaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _notificacionesCount = 0);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Limpiar Badge',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.cardBorder),
              notificaciones.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No hay notificaciones recientes.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: notificaciones.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: AppColors.cardBorder,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = notificaciones[index];
                          final hora = item['created_at'] != null
                              ? DateTime.parse(
                                  item['created_at'],
                                ).toLocal().toString().substring(11, 16)
                              : '--:--';

                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              LucideIcons.shoppingBag,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              item['titulo'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              item['mensaje'] ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              hora,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _onSettingsPressed() {
    showDialog(
      context: context,
      builder: (context) => const CrearUsuarioDialog(),
    );
  }

  Future<void> _onLogoutPressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir del sistema?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().cerrarSesion();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getAvailablePages();
    final pageTitles = _getAvailableTitles();

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: AppColors.sidebar,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.droplets,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'GasFlow',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: AppColors.emerald, size: 8),
                      const SizedBox(width: 8),
                      Text(
                        'Supabase — En línea',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Ítems de Navegación según Rol
                if (_userRole == 'admin') ...[
                  _buildNavItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
                  _buildNavItem(1, LucideIcons.gauge, 'Surtidores (Admin)'),
                  _buildNavItem(
                    2,
                    LucideIcons.fileText,
                    'Supervisión Reportes',
                  ),
                ] else ...[
                  _buildNavItem(0, LucideIcons.zap, 'Venta POS'),
                  _buildNavItem(1, LucideIcons.fileText, 'Arqueo / Reportes'),
                  _buildNavItem(2, LucideIcons.gauge, 'Estado Surtidores'),
                ],

                const Spacer(),
                const Divider(
                  color: AppColors.cardBorder,
                  indent: 16,
                  endIndent: 16,
                ),

                if (_userRole == 'admin')
                  _buildSidebarAction(
                    LucideIcons.userPlus,
                    'Crear Usuario',
                    AppColors.textSecondary,
                    onTap: _onSettingsPressed,
                  ),
                _buildSidebarAction(
                  LucideIcons.logOut,
                  'Cerrar sesión',
                  AppColors.danger,
                  onTap: _onLogoutPressed,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Área Principal
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: AppColors.background,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pageTitles[_selectedIndex],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _currentTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                onPressed: _onNotificationsPressed,
                                icon: const Icon(
                                  LucideIcons.bell,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_notificacionesCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$_notificacionesCount',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    _userInitials,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _userName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${_userRole.toUpperCase()} · $_userTurno',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _userRole == 'admin'
                                            ? AppColors.secondary
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected
            ? AppColors.primary.withOpacity(0.15)
            : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.secondary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildSidebarAction(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: color, size: 18),
        title: Text(label, style: TextStyle(color: color, fontSize: 14)),
        onTap: onTap,
      ),
    );
  }
}
