import 'dart:async';

/// Retrasa la ejecución de [run] hasta que pase [delay] sin una nueva
/// llamada — cancela el timer pendiente en cada invocación.
class Debouncer {
  Debouncer(this.delay);
  final Duration delay;

  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
