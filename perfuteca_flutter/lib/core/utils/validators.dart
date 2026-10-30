/// Celular peruano válido: 9 dígitos, empieza con '9'.
final _celularPeruRegex = RegExp(r'^9\d{8}$');

bool esCelularPeruValido(String celular) => _celularPeruRegex.hasMatch(celular);
