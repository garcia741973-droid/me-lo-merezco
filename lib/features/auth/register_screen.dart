import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/auth_service.dart';
import '../../shared/models/seller.dart';
import '../client/client_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();

  // NUEVOS CAMPOS
  final documentCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final birthDateCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  // INTERESES
  List<String> selectedInterests = [];

  bool isLoading = false;

  List<Seller> sellers = [];
  bool loadingSellers = true;
  int? selectedSellerId;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();

    documentCtrl.dispose();
    phoneCtrl.dispose();
    birthDateCtrl.dispose();
    countryCtrl.dispose();
    cityCtrl.dispose();
    addressCtrl.dispose();

    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

    Future<void> _openUrl(String url) async {
      final uri = Uri.parse(url);

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir $url');
      }
    }  

  Future<void> _loadSellers() async {
    try {
      final res = await http.get(
        Uri.parse('https://me-lo-merezco-backend.onrender.com/sellers'),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          sellers = data.map((e) => Seller.fromJson(e)).toList();
          loadingSellers = false;
        });
      } else {
        setState(() => loadingSellers = false);
      }
    } catch (_) {
      setState(() => loadingSellers = false);
    }
  }

  Future<void> _register() async {

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    final pass2 = pass2Ctrl.text;

    final documentId = documentCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final birthDate = birthDateCtrl.text.trim();
    final country = countryCtrl.text.trim();
    final city = cityCtrl.text.trim();
    final address = addressCtrl.text.trim();

    if (
      name.isEmpty ||
      email.isEmpty ||
      pass.isEmpty ||
      pass2.isEmpty
    ) {
      _showMessage('Completa los campos obligatorios');
      return;
    }

    if (pass != pass2) {
      _showMessage('Las contraseñas no coinciden');
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await AuthService().register(
        name: name,
        email: email,
        password: pass,
        documentId: documentId,
        phone: phone,
        birthDate: birthDate,
        country: country,
        city: city,
        address: address,
        interests: selectedInterests,
        sellerId: selectedSellerId,
      );

      if (!mounted) return;

      if (!success) {
        _showMessage('El email ya está registrado');
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
        (_) => false,
      );

    } catch (_) {
      _showMessage('No se pudo registrar. Intenta más tarde.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        extendBodyBehindAppBar: true,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              'assets/logos/fondoGeneral.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [

                  const SizedBox(height: 50),

                  const Text(
                    "Crear cuenta",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 35),

                  _inputField(nameCtrl, "Nombre"),
                  const SizedBox(height: 14),

                  _inputField(documentCtrl, "Documento de identidad (opcional)"),
                  const SizedBox(height: 14),

                  _inputField(phoneCtrl, "Telefono (opcional)"),
                  const SizedBox(height: 14),

                  _inputField(
                    emailCtrl,
                    "Email",
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: _selectBirthDate,
                    child: AbsorbPointer(
                      child: _inputField(
                        birthDateCtrl,
                        "Fecha de nacimiento (opcional)",
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _inputField(countryCtrl, "Pais (opcional)"),
                  const SizedBox(height: 14),

                  _inputField(cityCtrl, "Ciudad (opcional)"),
                  const SizedBox(height: 14),

                  _inputField(addressCtrl, "Direccion (opcional)"),
                  const SizedBox(height: 20),

                  const Text(
                    "Intereses",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  _interestSelector(),
                  const SizedBox(height: 20),

                  loadingSellers
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        )
                      : 
                        DropdownButtonFormField<int?>(
                          isExpanded: true,
                          value: selectedSellerId,
                          decoration: _inputDecoration("Vendedor"),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                "No tengo vendedor opcional",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...sellers.map((seller) {
                              return DropdownMenuItem<int?>(
                                value: seller.id,
                                child: Text(
                                  seller.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedSellerId = value;
                            });
                          },
                        ),

                  const SizedBox(height: 14),

                  _inputField(passCtrl, "Contraseña", obscure: true),
                  const SizedBox(height: 14),

                  _inputField(pass2Ctrl, "Confirmar contraseña", obscure: true),

                  const SizedBox(height: 30),

                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAEDFC8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "Crear cuenta",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            _openUrl(
                              "https://minicore.estuvia.org/melomerezco",
                            );
                          },
                          child: const Text(
                            "Conoce más sobre Me Lo Merezco",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Al crear una cuenta aceptas nuestros",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [

                            GestureDetector(
                              onTap: () {
                                _openUrl(
                                  "https://minicore.estuvia.org/melomerezco/terms.html",
                                );
                              },
                              child: const Text(
                                "Términos de uso",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const Text(" y "),

                            GestureDetector(
                              onTap: () {
                                _openUrl(
                                  "https://minicore.estuvia.org/melomerezco/privacy.html",
                                );
                              },
                              child: const Text(
                                "Política de privacidad",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          ],
                        ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

    Future<void> _selectBirthDate() async {

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1940),
        lastDate: DateTime.now(),
      );

      if (picked != null) {
        final formatted =
            "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";

        setState(() {
          birthDateCtrl.text = formatted;
        });
      }
    }

  Widget _interestSelector() {

    final interests = [
      "Tecnologia",
      "Deportes",
      "Cuidado personal",
      "Ganaderia",
      "Ocio",
      "Electrodomesticos"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: interests.map((interest) {

        final selected = selectedInterests.contains(interest);

        return CheckboxListTile(
          value: selected,
          title: Text(interest),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedInterests.add(interest);
              } else {
                selectedInterests.remove(interest);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}