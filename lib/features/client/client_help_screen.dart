import 'package:flutter/material.dart';
import 'help_detail_screen.dart';

class ClientHelpScreen extends StatelessWidget {

  const ClientHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayuda"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

        ListTile(
        leading: const Icon(Icons.shopping_cart),
        title: const Text("¿Cómo hacer un pedido?"),
        subtitle: const Text("Explicación paso a paso"),
        onTap: () {

            Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const HelpDetailScreen(
                title: "Cómo hacer un pedido",
                text: """
        1a. Para hacer un pedido de Ofertas entra a la sección Ofertas.

        2a. Selecciona el producto que te interesa.

        3a. Agrega al carrito.

        4a. Una vez estes decidido a comprar envía solicitud a administrador

        5a. El administrador revisará el pedido y te enviara el OK.

        6a. Si es aprobado recibirás instrucciones de pago al ingresar al detalle del pedido.
        
        1b. Para hacer una cotización debes seleccionar la plataforma de donde quieres pedir.

        2b. En URL debes pegar el http://... de la plataforma y ítem que viste, esto nos permite idenficar y hacer el seguimiento de lo que quieres.

        3b. Ojo el URL no es de las plataformas es de la web de la empresa, ya que el sistema solo funciona de esta forma por políticas de los proveedores.

        4b. Debes seleccionar la moneda en la cual te han cotizado, ten cuidad que en la web de la plataforma selecciona Latinoamérica o mejor chile.

        5b. En categoría debes seleccionar de acuerdo del tamaño del producto, esto determina el precio de la importación:
            Pequeño; todo artículo como carcasas de celulares, joyería, esmaltes, etc. 
            Mediano; todo artículo como ser zapatos, perfumes, ropa, colecciones esmaltes, etc. 
            Grande; electrónicos, etc.

        6b. Pones el precio que te dio la web te dijo.

        7b. Al apretar calcular el sistema te dará el resultado tomando en cuenta el tipo cambio y tamaño de importación.

        8b. Si estas de acuerdo subes al carrito y cuando estes listo mandas aprobación, nuestra gente se encargara de revisar todo y te contestara para realizar los pagos o mayor información requerida.

        """,
                ),
            ),
            );

        },
        ),

          Divider(),

        ListTile(
        leading: const Icon(Icons.qr_code),
        title: const Text("¿Cómo pagar?"),
        subtitle: const Text("Información sobre pagos"),
        onTap: () {

            Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const HelpDetailScreen(
                title: "Cómo realizar un pago",
                text: """
        Una vez aprobado tu pedido, el sistema divide en dos pagos el primero del 60% y el segundo con la llegada y entrega de tu pedido del saldo pro el 40%:

        1. El sistema puede rechazar, aprobar o hacerte mas preguntas como ser talla, color o mayores datos, o mandarte un nuevo precio ya sea para arriba o abajo dependiendo las variaciones en los proveedores.

        2. Si tu aceptas de forma inmediata te mandara a la pantalla del primer pago por QR.

        3. En este punto puedes bajar el QR para facilitar tu pago, realiza el pago y sube el comprobante ahí el sistema manda este comprobante para su verificación.

        4. El 1er pago una vez verificado se te será informado y se te pondrá en espera para el segundo pago.

        5. Cuando el producto llegue a Bolivia se te informa para realizar el 2do pago y se coordina el despacho.

        """,
                ),
            ),
            );

        },
        ),

          Divider(),

          ListTile(
            leading: Icon(Icons.upload),
            title: Text("¿Cómo subir el comprobante?"),
            subtitle: Text(
              "Después de pagar puedes subir el comprobante desde tu pedido."
            ),
onTap: () {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpDetailScreen(
          title: "Cómo subir el comprobante",
          text: """
            Una vez aprobado tu pedido:

            1. El sistema mostrará un código QR de pago.

            2. Realiza el pago desde tu banco o aplicación.

            3. Guarda el comprobante.

            4. Sube el comprobante dentro del pedido.

            5. El administrador confirmará el pago.
            """,
                    ),
                ),
                );

            },
            ),

          Divider(),

          ListTile(
            leading: Icon(Icons.support_agent),
            title: Text("¿Necesitas ayuda?"),
            subtitle: Text(
              "Puedes contactar al administrador desde el chat."
            ),
          ),

        ],
      ),
    );
  }
}