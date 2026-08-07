# Critique: Estadísticas Tab Structure

## Design Health Score: 21/40 (Acceptable)

### Priority Issues
- P1: Hero-metric template en HeroMesCard (gradiente + big number + stats = cliché prohibido)
- P1: Tamaños duplicado en Resumen y Ventas sin diferenciación semántica
- P1: Pill Historial en VentasTab redundante (tab=Ventas, pill=Historial, contenido=HistorialScreen)
- P2: ResumenTab demasiado cargado (6 secciones, Hoy no es lo primero visible)
- P2: Comparar meses en Histórico no discoverable

### Sub-tab moves
- Eliminar pill Historial de VentasTab
- ResumenTab: mover Hoy a posición 1
- Histórico: Comparar meses → sticky button
