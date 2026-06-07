# Rediseño Estadísticas — 3 Tabs

**Fecha:** 2026-06-07
**Feature:** Reducir pantalla de Estadísticas de 6 tabs a 3: Resumen / Histórico / Más

---

## Problema

La pantalla de Estadísticas tiene 6 tabs (Resumen, Ventas, Clientes, Histórico, Stock, Cotizaciones). El usuario tiene que navegar mucho para encontrar lo que necesita, los datos tardan en cargar tab por tab, y no hay una vista rápida de lo importante.

## Solución

Reducir a 3 tabs. El acceso menos frecuente se agrupa bajo "Más" como menú de lista.

---

## Arquitectura

### Nueva estructura de tabs

| Índice | Tab | Contenido |
|--------|-----|-----------|
| 0 | Resumen | `ResumenTab()` (mejorado — ver abajo) |
| 1 | Histórico | `HistoricoTab()` (sin cambios) |
| 2 | Más | `_MasTab()` — nuevo widget con navegación interna |

### Tab "Más" — navegación interna

`_MasTab` es un `ConsumerStatefulWidget` con estado `String? _seccion`:
- `null` → muestra menú de lista con 4 ítems
- `'ventas'` → muestra `VentasTab()`
- `'clientes'` → muestra `ClientesTab()`
- `'stock'` → muestra `AnalisisTab()`
- `'cotizaciones'` → muestra `CotizacionesTab()`

Al tocar un ítem: `setState(() => _seccion = 'ventas')`.
Al tocar "← Volver" (AppBar contextual o botón en header): `setState(() => _seccion = null)`.

### Menú de "Más" (estado `_seccion == null`)

```
┌─────────────────────────────────────────┐
│ 📊  Ventas                           >  │
├─────────────────────────────────────────┤
│ 👥  Clientes                         >  │
├─────────────────────────────────────────┤
│ 🧴  Stock                            >  │
├─────────────────────────────────────────┤
│ 💬  Cotizaciones                     >  │
└─────────────────────────────────────────┘
```

Cada ítem es un `ListTile` con `onTap: () => setState(() => _seccion = 'ventas')`.

### Mejoras al Resumen

Agregar al inicio del `ResumenTab` (antes del contenido actual) una fila con 3 métricas de hoy:
- `S/ X.XX` — total ventas hoy
- `N órdenes` — pedidos hoy
- `N pendientes` — pedidos con estado Pendiente

Estos datos ya existen en `resumenBackendProvider` (campos `hoy.total`, `hoy.ventas`) y `pendientesProvider`.

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `perfuteca_flutter/lib/features/estadisticas/screens/estadisticas_screen.dart` | `TabController(length: 6)` → `length: 3`; 3 tabs en TabBar; 3 children en TabBarView; agregar `_MasTab`; refresh button invalida los mismos providers |
| `perfuteca_flutter/lib/features/estadisticas/screens/resumen_tab.dart` | Agregar fila de métricas de hoy al inicio |

### Tabs sin cambios (reutilizadas dentro de `_MasTab`)
- `VentasTab` — sin modificar
- `ClientesTab` — sin modificar
- `HistoricoTab` — sin modificar
- `AnalisisTab` — sin modificar
- `CotizacionesTab` — sin modificar

---

## Comportamiento del refresh

El botón de refresh en el AppBar invalida los mismos providers que antes. No cambia.

## Criterios de éxito

- TabBar muestra exactamente 3 tabs: Resumen, Histórico, Más
- Tab "Más" muestra menú con 4 ítems al abrir
- Tocar un ítem del menú navega a esa pantalla dentro del tab
- "← Volver" regresa al menú
- ResumenTab muestra métricas de hoy al inicio (total, órdenes, pendientes)
- Tabs existentes (VentasTab, ClientesTab, etc.) sin cambios visuales
- Refresh invalida todos los providers igual que antes
