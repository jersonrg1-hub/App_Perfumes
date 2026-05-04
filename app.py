"""
app.py — Punto de entrada de la aplicación Perfuteca.

Responsabilidades de este módulo (y solo estas):
  1. Configurar la página de Streamlit
  2. Inyectar estilos CSS y JavaScript global
  3. Inicializar el estado de la app (get_state)
  4. Cargar el catálogo con manejo de errores
  5. Renderizar las tabs y delegar a los módulos correspondientes

Todo lo demás vive en sus módulos: estado en state.py, lógica en logic/,
UI en tabs/, datos en data.py, auth en auth.py.
"""
import streamlit as st
from styles import get_styles
from data import cargar_catalogo, cargar_ventas, cargar_cotizaciones, limpiar_cache_catalogo
from components import mostrar_encabezado
from errores import (
    mostrar_error_conexion,
    mostrar_error_datos_vacios,
    mostrar_error_columna,
    validar_dataframe,
)
from auth import inicializar_auth, login_seccion, check_auth, mostrar_boton_logout
from state import get_state

from tabs.tab_marca import mostrar_tab_marca
from tabs.tab_nombre import mostrar_tab_nombre
from tabs.tab_venta import mostrar_tab_venta
from tabs.tab_estadisticas import mostrar_tab_estadisticas
from tabs.tab_notas import mostrar_tab_notas

# ── Configuración de página ───────────────────────────────────────────────────

st.set_page_config(page_title="Perfumes 🌸", page_icon="🌸", layout="centered")

# Inicializa el árbol de estado antes que cualquier widget
inicializar_auth()

# ── Viewport y fuentes ────────────────────────────────────────────────────────

st.markdown(
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    unsafe_allow_html=True,
)
st.markdown("""
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&family=Lato:wght@300;400;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
""", unsafe_allow_html=True)
st.markdown(get_styles(), unsafe_allow_html=True)

# ── JavaScript global ─────────────────────────────────────────────────────────
# Guard window.__perfuteObsInstalled previene que los MutationObservers
# se dupliquen si Streamlit re-inyecta el script (re-render completo o reconexión).
# Sin el guard, cada re-render acumula N observers sobre document.body,
# degradando el rendimiento del input progresivamente.

st.markdown("""
<script>
if (!window.__perfuteObsInstalled) {
window.__perfuteObsInstalled = true;

(function() {
    // Recarga solo si vuelve del segundo plano tras 25 min Y hay error de conexión
    var hiddenAt = null;
    var LIMITE_MS = 25 * 60 * 1000;
    document.addEventListener('visibilitychange', function() {
        if (document.hidden) {
            hiddenAt = Date.now();
        } else if (hiddenAt !== null && (Date.now() - hiddenAt) > LIMITE_MS) {
            hiddenAt = null;
            setTimeout(function() {
                var hayError = document.querySelector('[data-testid="stConnectionStatus"]') ||
                               document.querySelector('.stException');
                if (hayError) { window.location.reload(); }
            }, 2000);
        } else {
            hiddenAt = null;
        }
    });
})();

(function() {
    // Banner prominente cuando Streamlit pierde conexión
    var banner = null;

    function crearBanner() {
        if (banner) return;
        banner = document.createElement('div');
        banner.style.cssText = [
            'position:fixed', 'top:0', 'left:0', 'right:0', 'z-index:99999',
            'background:#dc2626', 'color:white', 'text-align:center',
            'padding:16px 20px', 'font-weight:700', 'font-size:1.05rem',
            'cursor:pointer', 'box-shadow:0 3px 10px rgba(0,0,0,0.4)',
            'letter-spacing:0.02em'
        ].join(';');
        banner.textContent = '⚠️ App desconectada — Toca aquí para reconectar';
        banner.onclick = function() { window.location.reload(); };
        document.body.appendChild(banner);
    }

    function quitarBanner() {
        if (banner) { banner.remove(); banner = null; }
    }

    function verificarConexion() {
        var desconectado =
            document.querySelector('[data-testid="stConnectionStatus"]') ||
            document.querySelector('[class*="StatusWidget"]') ||
            document.querySelector('[class*="connectionStatus"]');
        if (desconectado) { crearBanner(); } else { quitarBanner(); }
    }

    new MutationObserver(verificarConexion)
        .observe(document.body, { childList: true, subtree: true });

    document.addEventListener('visibilitychange', function() {
        if (!document.hidden) { setTimeout(verificarConexion, 2500); }
    });
})();

(function() {
    // Teclado decimal en móvil para inputs numéricos
    function _fixInputModes() {
        document.querySelectorAll('input[type="number"]').forEach(function(el) {
            el.setAttribute('inputmode', 'decimal');
        });
    }
    _fixInputModes();
    new MutationObserver(_fixInputModes).observe(document.body, { childList: true, subtree: true });
})();

(function() {
    // Vibración táctil al agregar a cesta (detecta aparición de toast)
    new MutationObserver(function(mutations) {
        mutations.forEach(function(mut) {
            mut.addedNodes.forEach(function(node) {
                if (node.nodeType !== 1) return;
                var isToast = (node.dataset && node.dataset.testid === 'stToast') ||
                              node.querySelector && node.querySelector('[data-testid="stToast"]');
                if (isToast && navigator.vibrate) navigator.vibrate(40);
            });
        });
    }).observe(document.body, { childList: true, subtree: true });
})();

(function() {
    // Swipe izquierda en cesta para revelar botón de eliminar
    function setupSwipeDelete() {
        document.querySelectorAll('[data-testid="stHorizontalBlock"]').forEach(function(row) {
            if (row._swipeSetup) return;
            var cols = row.querySelectorAll(':scope > [data-testid="column"]');
            if (cols.length < 2) return;
            var lastCol = cols[cols.length - 1];
            var btn = lastCol.querySelector('button');
            if (!btn || btn.textContent.trim() !== '🗑️') return;
            row._swipeSetup = true;
            var firstCol = cols[0];
            var startX = 0, startY = 0, dx = 0;
            var REVEAL = 64, THRESH = 38;
            var revealed = false;

            row.style.position = 'relative';
            row.style.overflow = 'hidden';
            lastCol.style.cssText = 'position:absolute;right:0;top:0;bottom:0;width:' + REVEAL + 'px;'
                + 'background:#dc2626;border-radius:0 10px 10px 0;'
                + 'display:flex;align-items:center;justify-content:center;'
                + 'transform:translateX(' + REVEAL + 'px);transition:transform 0.22s ease;z-index:2;';
            btn.style.cssText = 'background:transparent;border:none;color:white;'
                + 'font-size:1.35rem;cursor:pointer;width:100%;height:100%;min-height:44px;';
            firstCol.style.transition = 'transform 0.22s ease';

            function snap(show) {
                revealed = show;
                firstCol.style.transform = show ? 'translateX(-' + REVEAL + 'px)' : 'translateX(0)';
                lastCol.style.transform = show ? 'translateX(0)' : 'translateX(' + REVEAL + 'px)';
            }

            firstCol.addEventListener('touchstart', function(e) {
                startX = e.touches[0].clientX;
                startY = e.touches[0].clientY;
                dx = 0;
                firstCol.style.transition = 'none';
                lastCol.style.transition = 'none';
            }, { passive: true });

            firstCol.addEventListener('touchmove', function(e) {
                dx = e.touches[0].clientX - startX;
                var dy = e.touches[0].clientY - startY;
                if (Math.abs(dy) > Math.abs(dx)) return;
                if (dx > 0 && !revealed) return;
                var base = revealed ? -REVEAL : 0;
                var clamped = Math.max(Math.min(base + dx, 0), -REVEAL);
                firstCol.style.transform = 'translateX(' + clamped + 'px)';
                lastCol.style.transform = 'translateX(' + (REVEAL + clamped) + 'px)';
            }, { passive: true });

            firstCol.addEventListener('touchend', function() {
                firstCol.style.transition = 'transform 0.22s ease';
                lastCol.style.transition = 'transform 0.22s ease';
                if (!revealed && dx < -THRESH) snap(true);
                else if (revealed && dx > THRESH / 2) snap(false);
                else snap(revealed);
            });

            document.addEventListener('touchstart', function(e) {
                if (revealed && !row.contains(e.target)) snap(false);
            }, { passive: true });
        });
    }
    setupSwipeDelete();
    new MutationObserver(function() { setupSwipeDelete(); })
        .observe(document.body, { childList: true, subtree: true });
})();

} // fin guard __perfuteObsInstalled
</script>
""", unsafe_allow_html=True)

# ── Encabezado ────────────────────────────────────────────────────────────────

mostrar_encabezado()

# ── Carga de datos y renderizado de tabs ──────────────────────────────────────

try:
    df = cargar_catalogo()

    # Precalentar caches y calcular badge de pedidos pendientes
    _n_pend = 0
    try:
        _df_v = cargar_ventas()
        cargar_cotizaciones()
        if not _df_v.empty and "Estado" in _df_v.columns and "ID_Compra" in _df_v.columns:
            _n_pend = int(
                _df_v[~_df_v["Estado"].isin(["Entregado", "Anulado"])]["ID_Compra"].nunique()
            )
    except Exception:
        pass

    if df.empty:
        mostrar_error_datos_vacios()
        if st.button("🔄 Reintentar", key="retry_empty"):
            limpiar_cache_catalogo()
            st.rerun()
        st.stop()

    columnas_faltantes = validar_dataframe(df)
    if columnas_faltantes:
        for col in columnas_faltantes:
            mostrar_error_columna(col)
        st.stop()

    _label_stats = f"📊 Estadísticas ({_n_pend})" if _n_pend > 0 else "📊 Estadísticas"
    tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
        "🏷️ Marca",
        "🔍 Nombre",
        "🎵 Notas",
        "📝 Venta",
        _label_stats,
        "🔐 Sesión",
    ])

    with tab1:
        mostrar_tab_marca(df)

    with tab2:
        mostrar_tab_nombre(df)

    with tab3:
        mostrar_tab_notas(df)

    with tab4:
        if check_auth():
            mostrar_tab_venta(df)
            mostrar_boton_logout(key_suffix="tab4")
        else:
            login_seccion(key_suffix="venta")

    with tab5:
        if check_auth():
            mostrar_tab_estadisticas(df)
            mostrar_boton_logout(key_suffix="tab5")
        else:
            login_seccion(key_suffix="stats")

    with tab6:
        if check_auth():
            st.success("### ✅ Sesión Activa")
            st.write("Tienes acceso a las secciones de administración.")
            mostrar_boton_logout(key_suffix="tab6")
        else:
            st.info("### 🔒 Modo Invitado")
            st.write("Ingresa la contraseña para gestionar ventas e inventario.")
            login_seccion(key_suffix="tab_final")

except ConnectionError:
    mostrar_error_conexion()
    if st.button("🔄 Reintentar conexión", key="retry_conn"):
        limpiar_cache_catalogo()
        st.rerun()

except Exception as e:
    log = st.session_state.setdefault("error_log", [])
    from datetime import datetime
    log.append(f"[{datetime.now().strftime('%H:%M:%S')}] [app] {type(e).__name__}: {e}")
    mostrar_error_conexion()
    if st.button("🔄 Reintentar", key="retry_exc"):
        limpiar_cache_catalogo()
        st.rerun()
