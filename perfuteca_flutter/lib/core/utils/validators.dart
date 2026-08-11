/// Celular peruano válido: 9 dígitos, empieza con '9'.
bool esCelularPeruValido(String celular) =>
    celular.length == 9 && celular.startsWith('9');
