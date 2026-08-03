import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

const _paqueteWhatsappBusiness = 'com.whatsapp.w4b';

/// Normaliza un alias de WhatsApp: quita espacios y un '@' inicial.
/// Retorna null si el resultado queda vacío (alias ausente o solo '@'/espacios).
String? _aliasNormalizadoOrNull(String? alias) {
  final sinEspacios = alias?.trim() ?? '';
  final sinArroba = sinEspacios.startsWith('@')
      ? sinEspacios.substring(1)
      : sinEspacios;
  return sinArroba.isEmpty ? null : sinArroba;
}

/// Resuelve el destino para el deep-link de wa.me.
///
/// Si [alias] tiene contenido (ignorando espacios) se usa tal cual
/// (WhatsApp resuelve `wa.me/<alias>` directo, sin prefijo de país).
/// Si no, cae al comportamiento con [celular]: agrega prefijo `51` si
/// falta. Si ambos son null/vacíos retorna '' (selector de chat).
String resolverDestinoWhatsApp({String? celular, String? alias}) {
  final aliasNormalizado = _aliasNormalizadoOrNull(alias);
  if (aliasNormalizado != null) return aliasNormalizado;

  if (celular == null || celular.isEmpty) return '';
  return celular.startsWith('51') ? celular : '51$celular';
}

/// Línea de contacto para mensajes de texto: celular + alias juntos si
/// hay alias, o solo celular si no.
String lineaContacto(String celular, String? alias) {
  final aliasNormalizado = _aliasNormalizadoOrNull(alias);
  if (aliasNormalizado == null) return celular;
  return '$celular (@$aliasNormalizado)';
}

/// Abre WhatsApp Business con [mensaje] ya listo para enviar.
///
/// Si se pasa [alias] (no vacío), abre el chat directo con ese alias
/// (`wa.me/<alias>`). Si no, y se pasa [celular], abre el chat directo con
/// ese número (prefijo `51` agregado automáticamente si falta). Si ambos
/// son null, abre el selector de chat/grupo de WhatsApp (para enviar a la
/// comunidad).
///
/// Si WhatsApp Business no está instalado, cae a `wa.me` normal (WhatsApp
/// estándar o selector del sistema si hay varias apps).
Future<void> abrirWhatsAppBusiness({
  String? celular,
  String? alias,
  required String mensaje,
}) async {
  final texto = Uri.encodeComponent(mensaje);
  final destino = resolverDestinoWhatsApp(celular: celular, alias: alias);
  final url = 'https://wa.me/${Uri.encodeComponent(destino)}?text=$texto';

  try {
    final intent = AndroidIntent(
      action: 'action_view',
      package: _paqueteWhatsappBusiness,
      data: url,
    );
    await intent.launch();
  } catch (_) {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
