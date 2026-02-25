// lib/features/client/client_main_menu_screen.dart

import 'package:flutter/material.dart';
import '../quote/platform_quote_screen.dart';
import 'client_offers_screen.dart';
import '../../core/services/offer_service.dart';

import 'client_offer_detail_screen.dart';


class ClientMainMenuScreen extends StatefulWidget {
  const ClientMainMenuScreen({super.key});

  @override
  State<ClientMainMenuScreen> createState() =>
      _ClientMainMenuScreenState();
}

class _ClientMainMenuScreenState
    extends State<ClientMainMenuScreen> {

  List<dynamic> _offers = [];
  bool _loadingOffers = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final data = await OffersService.fetchActiveOffers();

      if (!mounted) return;

      setState(() {
        _offers = data;
        _loadingOffers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingOffers = false;
      });
    }
  }

  Widget _platformButton(
    BuildContext context, String name, String assetPath) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PlatformQuoteScreen(platform: name),
        ),
      );
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.grey.shade100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              assetPath,
              height: 42,
              width: 42,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                name[0],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        //Text(name), OJO ESTE FUE EL CAMBIO EN TEXTO
        SizedBox(
          width: 90, // límite real de ancho
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}


 Widget _offersPreview(BuildContext context) {
  if (_loadingOffers) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  if (_offers.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('No hay ofertas disponibles'),
    );
  }

  return SizedBox(
  height: 260,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _offers.length,
      separatorBuilder: (_, __) =>
          const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final offer = _offers[index];

        final double price =
            double.tryParse(offer['price']?.toString() ?? '0') ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ClientOfferDetailScreen(offer: offer),
              ),
            );
          },
          child: SizedBox(
            width: 220,
  child: SizedBox(
  width: 220,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (offer['image_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                offer['image_url'],
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),

          Text(
            offer['title'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          Text(
            offer['description'] ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  ),
),
          ),
        );
      },
    ),
  );
}


@override
Widget build(BuildContext context) {
  const shein = 'assets/logos/shein.png';
  const amazon = 'assets/logos/amazon.png';
  const aliexpress = 'assets/logos/aliexpress.png';
  const temu = 'assets/logos/temu.png';

  return Scaffold(
    body: Stack(
      children: [

        // 🌿 Fondo emocional claro
        Positioned.fill(
          child: Image.asset(
            'assets/logos/fondoGeneral.png',
            fit: BoxFit.cover,
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 10),

                const Text(
                  "El mundo en tus manos",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Cotiza o accede a ofertas exclusivas.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 30),



                const SizedBox(height: 36),

                const Text(
                  'Selecciona plataforma',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _platformButton(context, 'Shein', shein),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _platformButton(context, 'Amazon', amazon),
                      ),
                    ),
                  ],
                ),

//                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _platformButton(context, 'AliExpress', aliexpress),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _platformButton(context, 'Temu', temu),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Row(
  children: [
    const Expanded(
      child: Text(
        'Ofertas',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ClientOffersScreen(),
          ),
        );
      },
      child: const Text('Ver todas'),
    ),
  ],
),

                const SizedBox(height: 14),

                _offersPreview(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}