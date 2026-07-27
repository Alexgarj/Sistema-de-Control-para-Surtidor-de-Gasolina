import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:surtidor_gasolina_app/features/dashboard/presentation/widgets/crear_surtidor_dialog.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/widgets/surtidor_card.dart';
import '../../../../features/surtidores/presentation/widgets/crear_surtidor_dialog.dart';

class SurtidoresControlPage extends StatefulWidget {
  const SurtidoresControlPage({super.key});

  @override
  State<SurtidoresControlPage> createState() => _SurtidoresControlPageState();
}

class _SurtidoresControlPageState extends State<SurtidoresControlPage> {
  final List<String> _tiposCombustible = [
    'Todos',
    'Gasolina Especial',
    'Gasolina Premium',
    'Diésel',
    'GNV',
  ];

  String _filtroCombustible = 'Todos';
  String _filtroEstado = 'Todos';

  List<Map<String, dynamic>> _surtidores = [];
  bool _cargando = true;
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarRolYCargar();
  }

  Future<void> _verificarRolYCargar() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      final perfil = await supabase
          .from('perfiles')
          .select('rol')
          .eq('id', user.id)
          .maybeSingle();

      if (perfil != null) {
        final rol = (perfil['rol'] ?? '').toString().toLowerCase();
        _esAdmin = rol == 'admin' || rol == 'administrador';
      }
    }
    await _cargarSurtidores();
  }

  Future<void> _cargarSurtidores() async {
    setState(() => _cargando = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('surtidores')
          .select()
          .order('id', ascending: true);

      setState(() {
        _surtidores = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar surtidores: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirDialogoNuevoSurtidor() async {
    final guardadoConExito = await showDialog<bool>(
      context: context,
      builder: (context) => const CrearSurtidorDialog(),
    );

    if (guardadoConExito == true) {
      _cargarSurtidores();
    }
  }

  Color _obtenerColorTipo(String? tipo) {
    switch (tipo) {
      case 'Diésel':
        return Colors.amber;
      case 'Gasolina Premium':
        return Colors.red;
      case 'GNV':
        return Colors.blue;
      case 'Gasolina Especial':
      default:
        return Colors.green;
    }
  }

  Color _obtenerColorEstado(String? estado) {
    switch (estado) {
      case 'Despachando':
        return Colors.green;
      case 'En espera':
        return Colors.orange;
      case 'Mantenimiento':
      case 'Fuera de servicio':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surtidoresFiltrados = _surtidores.where((s) {
      final tipoBd = s['tipo_combustible'] ?? s['tipo'] ?? '';
      final estadoBd = s['estado'] ?? '';

      final coincideTipo =
          _filtroCombustible == 'Todos' || tipoBd == _filtroCombustible;
      final coincideEstado =
          _filtroEstado == 'Todos' || estadoBd == _filtroEstado;
      return coincideTipo && coincideEstado;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Control y Gestión de Surtidores',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // 🛑 Muestra el botón únicamente si el usuario es Administrador
          if (_esAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: _abrirDialogoNuevoSurtidor,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Nuevo Surtidor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Control de Surtidores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _cargarSurtidores,
                  tooltip: 'Actualizar datos desde la base de datos',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtros de Selección
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroCombustible,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Combustible',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    items: _tiposCombustible.map((tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _filtroCombustible = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroEstado,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'Despachando',
                        child: Text('Despachando'),
                      ),
                      DropdownMenuItem(
                        value: 'En espera',
                        child: Text('En espera'),
                      ),
                      DropdownMenuItem(
                        value: 'Mantenimiento',
                        child: Text('Mantenimiento'),
                      ),
                      DropdownMenuItem(
                        value: 'Fuera de servicio',
                        child: Text('Fuera de servicio'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _filtroEstado = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grilla de Surtidores
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : surtidoresFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay surtidores registrados que coincidan.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: surtidoresFiltrados.length,
                      itemBuilder: (context, index) {
                        final item = surtidoresFiltrados[index];
                        final tipo =
                            item['tipo_combustible'] ??
                            item['tipo'] ??
                            'Desconocido';
                        final estado = item['estado'] ?? 'En espera';
                        final idNum =
                            item['numero_surtidor'] ??
                            item['numero'] ??
                            item['id']?.toString() ??
                            'N/A';

                        return SurtidorCard(
                          id: idNum.toString(),
                          tipoCombustible: tipo,
                          colorCombustible: _obtenerColorTipo(tipo),
                          estado: estado,
                          colorEstado: _obtenerColorEstado(estado),
                          porcentajeTanque:
                              (item['porcentaje_tanque'] as num?)?.toDouble() ??
                              1.0,
                          litrosHoy: (item['litros_hoy'] ?? '0').toString(),
                          tiempo: 'En línea',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
