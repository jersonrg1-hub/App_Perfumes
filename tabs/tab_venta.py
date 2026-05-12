"""
tabs/tab_venta.py — Wizard de registro de ventas (3 pasos).

Arquitectura aplicada:
  Estado  : state.get_state()["venta" | "cliente" | "cesta" | "busqueda"]
            No hay claves sueltas en st.session_state para estado de la app.
  Lógica  : funciones puras en logic/venta.py (sin Streamlit).
  Handlers: funciones _on_* — modifican estado y llaman st.rerun().
  Render  : funciones _render_* — solo leen estado y producen widgets.
  Flujo   : usuario → widget → handler → estado → render (siguiente rerun).

Widget keys usadas (FIJAS, sin contadores):
  Paso 1: v_fecha, v_envio, v_comp, v_cel, v_dir
  Paso 2: v_busq, v_marca, v_perf, v_ml, v_pago, v_editar, v_precio
  Eliminación de items: del_{uuid} (estable por vida del item, no por índice)
  Conversión de cotizaciones: conv_btn_{fila}, conv_ok_{fila}, conv_cancel_{fila}
"""
import html
import re
import pandas as pd
import streamlit as st
from urllib.parse import quote

from config import (
    ML_OPCIONES, METODOS_PAGO, TIPOS_ENVIO,
    fmt_precio, hoy_peru, STOCK_CRITICO, STOCK_BAJO, DatosCliente,
)
from costos import costo_total_item
from data import (
    cargar_ventas, cargar_cotizaciones,
    registrar_venta_completa, StockUpdateError,
    obtener_proximo_id, guardar_venta,
    actualizar_stock_perfumes_batch, actualizar_estado_cotizacion,
    limpiar_cache_ventas, limpiar_cache_cotizaciones,
)
from components import generar_url_whatsapp, separador
from tabs.tab_cotizacion import mostrar_seccion_cotizacion
from estadisticas.historial_cotizaciones import _parsear_items_cotizacion
from state import get_state, reset_venta, reset_busqueda
from logic.venta import (
    filtrar_catalogo, precio_catalogo, construir_item,
    eliminar_item, calcular_total,
    buscar_cliente_previo, validar_paso_cliente,
)


# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES DE RENDER (sin estado — solo HTML/widgets)
# ═══════════════════════════════════════════════════════════════════════════════

def _html_items_cesta(cesta: list) -> str:
    return "".join([
        f"<div style='display:flex;justify-content:space-between;align-items:center;"
        f"padding:0.45rem 0;border-bottom:1px solid #f5ede6;font-size:0.88rem;'>"
        f"<div><span style='color:#2c1a0e;font-weight:600;'>🌸 {html.escape(str(i['perfume']))}</span>"
        f"<span style='color:#a07850;font-size:0.78rem;'> · {html.escape(str(i['ml']))}ml"
        f" · {html.escape(str(i['metodo']))}</span></div>"
        f"<span style='font-family:Inter,sans-serif;font-weight:700;color:#2c1a0e;"
        f"font-variant-numeric:tabular-nums;'>S/ {fmt_precio(i['precio'])}</span></div>"
        for i in cesta
    ])


def _render_stock_precio(precio_item: float, stock_val, ml_vendido: str) -> None:
    """Tarjeta de stock + precio según nivel de disponibilidad."""
    if stock_val not in (None, "", 0):
        stock_num = float(stock_val)
        if stock_num < float(ml_vendido):
            st.error(
                f"❌ Stock insuficiente — quedan {stock_num:.0f}ml"
                f" · necesitas {float(ml_vendido):.0f}ml"
            )
            return
        if stock_num <= STOCK_CRITICO:
            bg, border, txt, num = "#fee2e2", "#dc2626", "#991b1b", "#7f1d1d"
            label = f"🔴 Stock crítico — solo {stock_num:.0f}ml"
        elif stock_num <= STOCK_BAJO:
            bg, border, txt, num = "#fef9c3", "#ca8a04", "#854d0e", "#713f12"
            label = f"🟡 Stock bajo — {stock_num:.0f}ml"
        else:
            bg, border, txt, num = "#dcfce7", "#16a34a", "#166534", "#14532d"
            label = f"🟢 Stock: {stock_num:.0f}ml disponibles"
    else:
        bg, border, txt, num = "#dcfce7", "#16a34a", "#166534", "#14532d"
        label = "🟢 Disponible"

    st.markdown(
        f"""<div style="background:{bg};border-left:4px solid {border};border-radius:10px;
        padding:0.8rem 1.2rem;display:flex;justify-content:space-between;align-items:center;">
        <span style="color:{txt};font-weight:600;">{label}</span>
        <span style="color:{num};font-family:'Inter',sans-serif;font-size:1.6rem;
        font-weight:800;font-variant-numeric:tabular-nums;">S/ {fmt_precio(precio_item)}</span>
        </div>""",
        unsafe_allow_html=True,
    )


def _render_barra_progreso(paso_actual: int) -> None:
    pasos = ["Cliente", "Perfumes", "Confirmar"]
    col1, col2, col3, col4, col5 = st.columns([2, 1, 2, 1, 2])
    columnas_pasos = [col1, col3, col5]
    columnas_conectores = [col2, col4]

    for i, (col, nombre) in enumerate(zip(columnas_pasos, pasos), 1):
        if i < paso_actual:
            circulo_bg, circulo_color, texto_color, contenido = "#2c1a0e", "white", "#2c1a0e", "✓"
        elif i == paso_actual:
            circulo_bg, circulo_color, texto_color, contenido = "#c8956c", "white", "#c8956c", str(i)
        else:
            circulo_bg, circulo_color, texto_color, contenido = "#ede0d4", "#a07850", "#a07850", str(i)

        with col:
            st.markdown(
                f"""<div style="display:flex;flex-direction:column;align-items:center;
                    gap:4px;padding:0.5rem 0;">
                    <div style="width:28px;height:28px;border-radius:50%;background:{circulo_bg};
                    color:{circulo_color};display:flex;align-items:center;justify-content:center;
                    font-size:0.8rem;font-weight:700;">{contenido}</div>
                    <div style="font-size:0.7rem;font-weight:600;color:{texto_color};
                    text-transform:uppercase;letter-spacing:0.08em;text-align:center;">
                    {nombre}</div></div>""",
                unsafe_allow_html=True,
            )

    for j, col in enumerate(columnas_conectores):
        linea_color = "#2c1a0e" if (j + 1) < paso_actual else "#ede0d4"
        with col:
            st.markdown(
                f"""<div style="height:28px;display:flex;align-items:center;padding-top:0.5rem;">
                    <div style="flex:1;height:1px;background:{linea_color};"></div></div>""",
                unsafe_allow_html=True,
            )
    st.markdown("")


# ═══════════════════════════════════════════════════════════════════════════════
# HANDLERS — modifican estado + disparan rerun
# Convención: _on_<acción>(state, *args) → None
# ═══════════════════════════════════════════════════════════════════════════════

def _on_autocomplete(state: dict, cliente: dict) -> None:
    """
    Aplica los datos del cliente anterior directamente en los widgets.
    No usa estado intermediario (_autocomplete_pendiente) — se aplica
    en el mismo callback que detecta el clic, evitando la race condition
    donde cualquier rerun aplicaba el autocomplete sin clic del usuario.
    """
    st.session_state["v_comp"] = cliente["nombre"]
    st.session_state["v_dir"] = cliente["direccion"]
    if cliente["metodo"] in METODOS_PAGO:
        st.session_state["v_pago"] = cliente["metodo"]
    if cliente["tipo_envio"] in TIPOS_ENVIO:
        st.session_state["v_envio"] = cliente["tipo_envio"]
    state["autocomplete"]["aplicado"] = True
    state["autocomplete"]["celular_buscado"] = st.session_state.get("v_cel", "")
    st.toast(f"✨ Datos de {cliente['nombre']} cargados", icon="👤")
    st.rerun()


def _on_avanzar_paso_1(state: dict) -> None:
    """Valida los datos del cliente y avanza al paso 2 si son correctos."""
    comprador = st.session_state.get("v_comp", "").title()
    celular   = st.session_state.get("v_cel", "")
    direccion = st.session_state.get("v_dir", "")
    tipo_envio = st.session_state.get("v_envio", TIPOS_ENVIO[0])
    fecha      = st.session_state.get("v_fecha", hoy_peru())

    errores = validar_paso_cliente(comprador, celular, direccion, tipo_envio)
    if errores:
        for err in errores:
            st.error(f"⚠️ {err}")
        return

    state["cliente"] = {
        "comprador": comprador,
        "celular": celular,
        "direccion": direccion,
        "tipo_envio": tipo_envio,
        "fecha": fecha,
    }
    state["venta"]["paso"] = 2
    st.rerun()


def _on_agregar_item(df: pd.DataFrame, state: dict) -> None:
    """
    Agrega el perfume seleccionado a la cesta.
    Lee los valores de los widgets, crea un item con UUID y limpia el formulario.
    Usar UUID en lugar de índice de lista elimina el bug de index-shift
    al borrar items mientras el formulario está visible.
    """
    perfume_nombre = st.session_state.get("v_perf")
    if not perfume_nombre:
        return

    ml     = st.session_state.get("v_ml", ML_OPCIONES[0])
    metodo = st.session_state.get("v_pago", METODOS_PAGO[0])

    matches = df[df["Nombre"] == perfume_nombre]
    if matches.empty:
        return

    perfume_row = matches.iloc[0]
    precio_cat = precio_catalogo(perfume_row, ml)
    if precio_cat is None:
        return

    editar = st.session_state.get("v_editar", False)
    precio_final = (
        float(st.session_state.get("v_precio", precio_cat))
        if editar else precio_cat
    )

    item = construir_item(perfume_row, ml, metodo, precio_final)
    state["cesta"].append(item)
    state["busqueda"]["metodo"] = metodo

    reset_busqueda()
    st.toast(f"Agregado: {perfume_nombre}", icon="✅")
    st.rerun()


def _on_eliminar_item(state: dict, item_id: str) -> None:
    """
    Elimina un item de la cesta por su UUID.
    Al usar UUID en lugar de índice, el borrado es correcto
    independientemente del orden de renderizado de Streamlit.
    """
    state["cesta"] = eliminar_item(state["cesta"], item_id)
    st.rerun()


def _on_guardar_venta(state: dict) -> None:
    """Persiste la venta en Google Sheets y actualiza el estado post-guardado."""
    if state["venta"]["guardada"]:
        return
    cliente: DatosCliente = {
        "comprador": state["cliente"]["comprador"],
        "celular":   state["cliente"]["celular"],
        "direccion": state["cliente"]["direccion"],
        "tipo_envio": state["cliente"]["tipo_envio"],
        "fecha": state["cliente"]["fecha"].strftime("%Y-%m-%d")
        if hasattr(state["cliente"]["fecha"], "strftime")
        else str(state["cliente"]["fecha"]),
    }
    total = calcular_total(state["cesta"])

    try:
        with st.status("🚀 Guardando venta...", expanded=False) as status:
            id_compra = registrar_venta_completa(state["cesta"], cliente)
            status.update(label="✅ ¡Venta guardada!", state="complete")
    except StockUpdateError as e:
        id_compra = e.id_compra
        st.warning(
            f"⚠️ Venta guardada ({id_compra}), pero el stock no pudo actualizarse. "
            f"Corrígelo manualmente en el catálogo. ({type(e.causa).__name__})"
        )
    except Exception as e:
        st.error(f"❌ Error al guardar: {e}")
        return

    url_wa = generar_url_whatsapp(
        id_compra,
        state["cliente"]["comprador"],
        state["cliente"]["celular"],
        state["cliente"]["direccion"],
        state["cliente"]["tipo_envio"],
        state["cesta"],
        total,
    )

    state["venta"]["guardada"]  = True
    state["venta"]["id_compra"] = id_compra
    state["venta"]["url_wa"]    = url_wa
    state["venta"]["total"]     = total

    st.toast(f"✅ Venta {id_compra} guardada correctamente", icon="🌸")
    st.balloons()
    st.rerun()


def _on_nueva_venta() -> None:
    """Resetea todo el wizard para iniciar una venta nueva."""
    reset_venta()
    st.rerun()


# ═══════════════════════════════════════════════════════════════════════════════
# RENDERS — solo leen estado y producen UI
# Convención: _render_<sección>(state, *args) → None
# ═══════════════════════════════════════════════════════════════════════════════

def _render_cotizaciones_hoy(df: pd.DataFrame, state: dict) -> None:
    """Muestra las cotizaciones del día con formulario inline para convertirlas a venta."""
    try:
        df_cot = cargar_cotizaciones()
    except Exception:
        return
    if df_cot.empty:
        return

    hoy = hoy_peru()
    df_hoy = df_cot[df_cot["Fecha"].dt.date == hoy]
    df_hoy = df_hoy[~df_hoy["Estado"].isin(["Aceptada", "Rechazada"])]
    if df_hoy.empty:
        return

    st.markdown(
        '<div style="font-size:0.75rem;color:#a07850;text-transform:uppercase;'
        'font-weight:700;letter-spacing:0.12em;padding-bottom:0.4rem;'
        'border-bottom:1px solid #ede0d4;margin-bottom:0.7rem;">📋 Cotizaciones de hoy</div>',
        unsafe_allow_html=True,
    )

    for row in df_hoy.sort_values("Fecha", ascending=False).to_dict("records"):
        id_cot      = str(row.get("ID_Cotizacion", ""))
        celular     = str(row.get("Celular", ""))
        perfumes_txt = str(row.get("Perfumes", ""))
        total       = float(row.get("Total", 0))
        fila_cot    = int(row.get("fila_sheet", 0))
        conv_key    = str(fila_cot)

        preview = " · ".join(
            re.sub(r"\s+S/.*$", "", i.strip())
            for i in perfumes_txt.split(" | ") if i.strip()
        )
        st.markdown(
            f'<div style="background:#f5ede6;border-left:3px solid #c8956c;'
            f'border-radius:10px;padding:0.6rem 0.9rem;margin-bottom:0.5rem;">'
            f'<div style="display:flex;justify-content:space-between;align-items:center;">'
            f'<span style="font-weight:700;color:#2c1a0e;">📱 {html.escape(celular)}</span>'
            f'<span style="font-weight:700;color:#c8956c;font-family:Inter,sans-serif;">'
            f'S/ {fmt_precio(total)}</span></div>'
            f'<div style="font-size:0.78rem;color:#6b4226;margin-top:0.2rem;">'
            f'{html.escape(preview)}</div></div>',
            unsafe_allow_html=True,
        )

        if not state["conv_activas"].get(conv_key):
            if st.button("✅ Convertir a Venta", key=f"conv_btn_{fila_cot}",
                         use_container_width=True, type="primary"):
                state["conv_activas"][conv_key] = True
                st.rerun()
        else:
            _render_form_conversion(df, state, id_cot, celular, perfumes_txt,
                                    total, fila_cot, conv_key)

    separador()


def _render_form_conversion(
    df: pd.DataFrame,
    state: dict,
    id_cot: str,
    celular: str,
    perfumes_txt: str,
    total: float,
    fila_cot: int,
    conv_key: str,
) -> None:
    """Formulario inline para convertir una cotización a venta directa."""
    comprador_raw = st.text_input("👤 Nombre", placeholder="Nombre completo",
                                  key=f"conv_comp_{fila_cot}")
    comprador  = comprador_raw.title() if comprador_raw else ""
    tipo_envio = st.selectbox("🚚 Envío", TIPOS_ENVIO, key=f"conv_envio_{fila_cot}")
    direccion  = st.text_input("📍 Dirección", placeholder="Distrito / Referencia",
                               key=f"conv_dir_{fila_cot}")
    metodo_pago = st.selectbox("💳 Pago", METODOS_PAGO, key=f"conv_pago_{fila_cot}")

    col_ok, col_cancel = st.columns(2)
    with col_ok:
        if st.button("✅ Confirmar", key=f"conv_ok_{fila_cot}",
                     type="primary", use_container_width=True):
            if not comprador:
                st.error("⚠️ Ingresa el nombre")
            elif tipo_envio != "Contraentrega" and not direccion.strip():
                st.error(f"⚠️ Dirección requerida para {tipo_envio}")
            else:
                _ejecutar_conversion(
                    df, state, id_cot, celular, perfumes_txt, total,
                    fila_cot, conv_key, comprador, tipo_envio, direccion, metodo_pago,
                )
    with col_cancel:
        if st.button("✖ Cancelar", key=f"conv_cancel_{fila_cot}",
                     use_container_width=True):
            state["conv_activas"].pop(conv_key, None)
            st.rerun()


def _ejecutar_conversion(
    df, state, id_cot, celular, perfumes_txt, total,
    fila_cot, conv_key, comprador, tipo_envio, direccion, metodo_pago,
) -> None:
    """Lógica de conversión de cotización → venta. Separada para claridad."""
    items_venta, errores = _parsear_items_cotizacion(perfumes_txt, df)
    if errores:
        st.error("❌ " + " · ".join(errores))
        return

    for it in items_venta:
        it["metodo"] = metodo_pago

    try:
        id_compra = obtener_proximo_id()
        filas = [
            [id_compra, str(hoy_peru()), comprador.strip().title(), celular,
             it["id_perfume"], str(it["ml"]),
             round(float(it["precio"]), 2),
             metodo_pago, tipo_envio, direccion.strip().title(), "Pendiente"]
            for it in items_venta
        ]
        guardar_venta(filas)
        try:
            actualizar_stock_perfumes_batch(items_venta)
        except Exception:
            st.warning("⚠️ Stock no pudo actualizarse, corrígelo manualmente.")
        actualizar_estado_cotizacion(id_cot, "Aceptada", fila_sheet=fila_cot)
        limpiar_cache_ventas()
        limpiar_cache_cotizaciones()
        state["conv_activas"].pop(conv_key, None)

        items_lineas = "\n".join([
            f"  • {it['marca']} {it['perfume']} {it['ml']}ml — S/ {fmt_precio(it['precio'])}"
            for it in items_venta
        ])
        dir_linea = f"\n📍 *Dirección:* {direccion}" if direccion.strip() else ""
        msg = (
            f"📦 *Perfuteca — Pedido Nuevo {id_compra}*\n────────────────────\n"
            f"👤 *Cliente:* {comprador}\n📱 *Celular:* {celular}\n"
            f"🚚 *Envío:* {tipo_envio}{dir_linea}\n────────────────────\n"
            f"🌸 *Perfumes:*\n{items_lineas}\n────────────────────\n"
            f"💰 *Total: S/ {fmt_precio(total)}*\n💳 *Pago:* {metodo_pago}"
        )
        st.success(f"✅ Venta {id_compra} registrada")
        st.markdown(
            f'<a href="https://wa.me/?text={quote(msg)}" target="_blank"'
            f' style="text-decoration:none;display:block;background:#25D366;'
            f'color:white !important;padding:10px;border-radius:8px;'
            f'text-align:center;font-weight:700;font-size:0.9rem;margin:8px 0;">'
            f'📲 Enviar pedido a comunidad</a>',
            unsafe_allow_html=True,
        )
        if st.button("✖ Cerrar", key=f"conv_cerrar_{fila_cot}",
                     use_container_width=True):
            st.rerun()
    except Exception as e:
        st.error(f"❌ Error: {e}")


def _render_paso_1(df: pd.DataFrame, state: dict) -> None:
    """Paso 1: formulario de datos del cliente."""
    st.markdown("#### 👤 Datos del comprador")

    st.markdown(
        "<div style='font-size:0.68rem;color:#a07850;text-transform:uppercase;"
        "font-weight:700;letter-spacing:0.12em;padding-bottom:0.4rem;"
        "border-bottom:1px solid #ede0d4;margin:0.3rem 0 0.6rem;'>📦 Pedido</div>",
        unsafe_allow_html=True,
    )
    st.date_input(
        "📅 Fecha",
        value=state["cliente"]["fecha"],
        format="DD/MM/YYYY",
        key="v_fecha",
    )
    st.selectbox("🚚 Tipo de Envío", TIPOS_ENVIO, key="v_envio")

    st.markdown(
        "<div style='font-size:0.68rem;color:#a07850;text-transform:uppercase;"
        "font-weight:700;letter-spacing:0.12em;padding-bottom:0.4rem;"
        "border-bottom:1px solid #ede0d4;margin:0.8rem 0 0.6rem;'>👤 Comprador</div>",
        unsafe_allow_html=True,
    )
    st.text_input("👤 Nombre", placeholder="Comprador", key="v_comp")
    st.text_input("📱 Celular", max_chars=9, key="v_cel")

    # ── Autocomplete ─────────────────────────────────────────────────────────
    # Se aplica DIRECTAMENTE en el callback del botón (no via estado intermediario).
    # Esto previene la race condition donde cualquier rerun aplicaba el autocomplete
    # sin que el usuario hubiera hecho clic en el botón.
    celular = st.session_state.get("v_cel", "")
    ac = state["autocomplete"]

    if len(celular) == 9 and celular.isdigit():
        if celular != ac.get("celular_buscado", ""):
            ac["aplicado"] = False
            ac["celular_buscado"] = celular

        if not ac.get("aplicado"):
            df_ventas = cargar_ventas()
            cliente_previo = buscar_cliente_previo(df_ventas, celular)
            if cliente_previo:
                if st.button(
                    f"✨ Cargar datos de {cliente_previo['nombre']}",
                    key="btn_autocomplete",
                    use_container_width=True,
                ):
                    _on_autocomplete(state, cliente_previo)
    else:
        ac["aplicado"] = False
        ac["celular_buscado"] = ""

    st.text_input("📍 Dirección", placeholder="Distrito / Referencia", key="v_dir")

    st.markdown("")
    if st.button("Siguiente →", key="paso1_sig", type="primary",
                 use_container_width=True):
        _on_avanzar_paso_1(state)


def _render_cesta(state: dict, total_precalc: float | None = None) -> None:
    """Renderiza los items de la cesta con botón de eliminar por UUID."""
    cesta = state["cesta"]
    if not cesta:
        return

    separador()
    st.markdown(f"**🛍️ Cesta — {len(cesta)} item(s)**")
    st.markdown("")

    for item in cesta:
        col_item, col_del = st.columns([6, 1])
        with col_item:
            st.markdown(
                f"""<div style="background:#ffffff;border:1px solid #ede0d4;
                    border-radius:10px;padding:0.65rem 1rem;
                    display:flex;justify-content:space-between;align-items:center;">
                    <div>
                        <div style="font-size:0.9rem;font-weight:600;color:#2c1a0e;">
                            🌸 {html.escape(str(item['perfume']))} · {item['ml']}ml
                        </div>
                        <div style="font-size:0.75rem;color:#a07850;margin-top:2px;">
                            {html.escape(str(item['metodo']))}
                        </div>
                    </div>
                    <div style="font-family:'Inter','DM Sans',sans-serif;
                        font-size:1rem;font-weight:700;color:#2c1a0e;
                        font-variant-numeric:tabular-nums;">
                        S/ {fmt_precio(item['precio'])}
                    </div>
                </div>""",
                unsafe_allow_html=True,
            )
        with col_del:
            # Key basada en UUID — estable durante la vida del item,
            # no se desplaza si se borra otro item de la lista
            if st.button("🗑️", key=f"del_{item['id']}"):
                _on_eliminar_item(state, item["id"])

    total = total_precalc if total_precalc is not None else calcular_total(cesta)
    st.markdown(
        f"""<div style="background:#fdf6f0;border:1px solid #ede0d4;
            border-radius:10px;padding:0.65rem 1.2rem;
            display:flex;justify-content:space-between;align-items:center;
            margin-top:0.3rem;">
            <div style="font-size:0.8rem;font-weight:600;color:#a07850;
                text-transform:uppercase;letter-spacing:0.08em;">Total</div>
            <div style="font-family:'Inter','DM Sans',sans-serif;
                font-size:1.2rem;font-weight:700;color:#2c1a0e;
                font-variant-numeric:tabular-nums;">S/ {fmt_precio(total)}</div>
        </div>""",
        unsafe_allow_html=True,
    )


def _render_paso_2(df: pd.DataFrame, state: dict) -> None:
    """Paso 2: buscador de perfumes + cesta."""
    cesta = state["cesta"]
    total_cesta = calcular_total(cesta) if cesta else 0.0
    if cesta:
        n = len(cesta)
        total_actual = total_cesta
        st.markdown(
            f"""<div style="background:linear-gradient(135deg,#2c1a0e 0%,#4a2e18 100%);
                border-radius:12px;padding:0.75rem 1.2rem;margin-bottom:0.8rem;
                display:flex;justify-content:space-between;align-items:center;">
                <div style="color:#f5e6d8;font-size:0.85rem;font-weight:600;">
                    🛍️ {n} item{'s' if n != 1 else ''} en cesta
                </div>
                <div style="color:#c8956c;font-family:'Inter',sans-serif;font-size:1.25rem;
                    font-weight:800;font-variant-numeric:tabular-nums;">
                    S/ {fmt_precio(total_actual)}</div>
            </div>""",
            unsafe_allow_html=True,
        )

    st.markdown("#### 🛒 Agregar perfumes")

    # Widgets de búsqueda — claves FIJAS (v_busq, v_marca, v_perf, v_ml, v_pago)
    # Se limpian en reset_busqueda() tras agregar un item, no via contador.
    st.text_input("🔍 Buscar perfume", placeholder="Nombre o marca...", key="v_busq")
    busqueda_texto = st.session_state.get("v_busq", "")

    marcas = sorted(df["Marca"].dropna().unique().tolist())
    st.selectbox(
        "🏷️ Marca (opcional)", marcas,
        index=None, placeholder="— Todas las marcas —",
        key="v_marca",
    )
    marca_sel = st.session_state.get("v_marca")

    df_filtrado = filtrar_catalogo(df, texto=busqueda_texto, marca=marca_sel)
    nombres = sorted(df_filtrado["Nombre"].dropna().unique().tolist())

    if not nombres and (busqueda_texto or marca_sel):
        st.caption("Sin resultados para la búsqueda.")
        perfume_sel = None
    elif len(nombres) == 1:
        perfume_sel = nombres[0]
        st.caption(f"✓ {perfume_sel}")
        st.session_state["v_perf"] = perfume_sel
    else:
        st.selectbox(
            "🌸 Perfume", nombres,
            index=None, placeholder="— Elige un perfume —",
            key="v_perf",
        )
        perfume_sel = st.session_state.get("v_perf")

    st.selectbox("📏 Tamaño", ML_OPCIONES, key="v_ml")
    st.selectbox("💳 Pago", METODOS_PAGO, key="v_pago")
    ml_sel = st.session_state.get("v_ml", ML_OPCIONES[0])

    if perfume_sel:
        matches = df[df["Nombre"] == perfume_sel]
        if not matches.empty:
            perfume_row = matches.iloc[0]
            precio_cat = precio_catalogo(perfume_row, ml_sel)

            if precio_cat is not None:
                _render_stock_precio(precio_cat, perfume_row.get("Stock_ml"), ml_sel)

                try:
                    cb = float(perfume_row.get("Costo_Botella") or 0)
                    mb = float(perfume_row.get("Ml_Botella") or 0)
                    costo_est = costo_total_item(ml_sel, cb, mb)
                    gan_est = precio_cat - costo_est
                    st.markdown(
                        f"<div style='font-size:0.78rem;color:#6b7280;margin:0.3rem 0 0.5rem;'>"
                        f"💸 Costo estimado: <b>S/ {fmt_precio(costo_est)}</b>"
                        f"&nbsp;&nbsp;|&nbsp;&nbsp;"
                        f"💰 Ganancia: <b style='color:#16a34a'>S/ {fmt_precio(gan_est)}</b>"
                        f"</div>",
                        unsafe_allow_html=True,
                    )
                except Exception:
                    pass

                # Si el usuario cambia perfume o ml sin agregar, v_precio y v_editar
                # quedarían con valores del perfume anterior (value= es ignorado
                # cuando la clave existe en session_state). Los purgamos al detectar cambio.
                _perf_ml_key = f"{perfume_sel}|{ml_sel}"
                if state["busqueda"].get("_last_perf_ml") != _perf_ml_key:
                    state["busqueda"]["_last_perf_ml"] = _perf_ml_key
                    st.session_state.pop("v_precio", None)
                    st.session_state.pop("v_editar", None)

                st.toggle("✏️ Editar precio", key="v_editar", value=False)
                editar = st.session_state.get("v_editar", False)
                st.number_input(
                    "💰 Precio final",
                    min_value=0.0,
                    value=float(precio_cat),
                    step=0.5,
                    format="%.2f",
                    key="v_precio",
                    disabled=not editar,
                )

                if st.button("➕ Agregar a la cesta", key="btn_agregar",
                             use_container_width=True):
                    _on_agregar_item(df, state)
            else:
                st.warning("⚠️ Sin precio configurado para este tamaño")
        else:
            st.warning("⚠️ Perfume no encontrado. Recarga los datos.")

    _render_cesta(state, total_precalc=total_cesta)

    st.markdown("")
    col_ant, col_sig = st.columns(2)
    with col_ant:
        if st.button("← Volver", key="paso2_volver", use_container_width=True):
            state["venta"]["paso"] = 1
            st.rerun()
    with col_sig:
        if st.button("Siguiente →", key="paso2_sig", type="primary",
                     use_container_width=True):
            if not state["cesta"]:
                st.error("⚠️ Agrega al menos un perfume")
            else:
                state["venta"]["paso"] = 3
                st.rerun()


def _render_paso_3(state: dict) -> None:
    """Paso 3: resumen y confirmación de la venta."""
    st.markdown("#### ✅ Confirmar venta")

    cliente = state["cliente"]
    comprador  = html.escape(str(cliente["comprador"]))
    celular    = html.escape(str(cliente["celular"]))
    direccion  = html.escape(str(cliente.get("direccion") or "—"))
    tipo_envio = html.escape(str(cliente["tipo_envio"]))
    fecha_str  = (
        cliente["fecha"].strftime("%d/%m/%Y")
        if hasattr(cliente["fecha"], "strftime")
        else str(cliente["fecha"])
    )

    st.markdown(
        f"""<div style="background:#ffffff;border:1px solid #ede0d4;border-radius:12px;
            padding:1rem 1.2rem;margin-bottom:0.8rem;">
            <div style="font-size:0.68rem;color:#a07850;text-transform:uppercase;
                font-weight:600;letter-spacing:0.1em;margin-bottom:0.6rem;">
                Datos del comprador</div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:0.5rem;
                font-size:0.88rem;color:#2c1a0e;">
                <div><span style="color:#a07850;font-size:0.75rem;">👤 Nombre</span>
                    <br><strong>{comprador}</strong></div>
                <div><span style="color:#a07850;font-size:0.75rem;">📱 Celular</span>
                    <br><strong>{celular}</strong></div>
                <div><span style="color:#a07850;font-size:0.75rem;">📅 Fecha</span>
                    <br><strong>{fecha_str}</strong></div>
                <div><span style="color:#a07850;font-size:0.75rem;">🚚 Envío</span>
                    <br><strong>{tipo_envio}</strong></div>
                <div style="grid-column:1/-1;">
                    <span style="color:#a07850;font-size:0.75rem;">📍 Dirección</span>
                    <br><strong>{direccion}</strong></div>
            </div>
        </div>""",
        unsafe_allow_html=True,
    )

    cesta = state["cesta"]
    total = calcular_total(cesta)
    items_html = _html_items_cesta(cesta)

    st.markdown(
        f"""<div style="background:#ffffff;border:1px solid #ede0d4;border-radius:12px;
            padding:1rem 1.2rem;margin-bottom:0.8rem;">
            <div style="font-size:0.68rem;color:#a07850;text-transform:uppercase;
                font-weight:600;letter-spacing:0.1em;margin-bottom:0.5rem;">Perfumes</div>
            {items_html}
            <div style="display:flex;justify-content:space-between;align-items:center;
                margin-top:0.6rem;padding-top:0.5rem;border-top:1px solid #ede0d4;">
                <span style="font-size:0.8rem;font-weight:600;color:#a07850;
                    text-transform:uppercase;letter-spacing:0.08em;">Total</span>
                <span style="font-family:'Inter','DM Sans',sans-serif;font-size:1.15rem;
                    font-weight:700;color:#2c1a0e;font-variant-numeric:tabular-nums;">
                    S/ {fmt_precio(total)}</span>
            </div>
        </div>""",
        unsafe_allow_html=True,
    )

    col_ant, col_guar = st.columns(2)
    with col_ant:
        if st.button("← Volver", key="paso3_volver", use_container_width=True):
            state["venta"]["paso"] = 2
            st.rerun()
    with col_guar:
        if st.button("✅ Guardar venta", key="btn_guardar",
                     type="primary", use_container_width=True):
            _on_guardar_venta(state)


def _render_venta_guardada(state: dict) -> None:
    """Pantalla de confirmación post-venta con links de WhatsApp."""
    venta    = state["venta"]
    cliente  = state["cliente"]
    cesta    = state["cesta"]

    id_compra  = html.escape(str(venta.get("id_compra", "")))
    comprador  = html.escape(str(cliente.get("comprador", "")))
    celular    = html.escape(str(cliente.get("celular", "")))
    direccion  = html.escape(str(cliente.get("direccion") or "—"))
    tipo_envio = html.escape(str(cliente.get("tipo_envio", "")))
    total      = venta.get("total", 0)
    fecha_val  = cliente.get("fecha")
    fecha_str  = (
        fecha_val.strftime("%d/%m/%Y")
        if hasattr(fecha_val, "strftime")
        else str(fecha_val or "—")
    )

    st.markdown(
        f"""<div style="background:linear-gradient(135deg,#16a34a 0%,#15803d 100%);
            border-radius:16px;padding:1.2rem 1.4rem;text-align:center;margin-bottom:0.8rem;">
            <div style="font-size:2.2rem;margin-bottom:0.3rem;">✅</div>
            <div style="color:white;font-size:1.1rem;font-weight:700;margin-bottom:0.2rem;">
                ¡Venta guardada!</div>
            <div style="color:#bbf7d0;font-size:0.9rem;">
                {id_compra} · {comprador} ·
                <b style="color:white;font-family:'Inter',sans-serif;">
                S/ {fmt_precio(total)}</b>
            </div>
        </div>""",
        unsafe_allow_html=True,
    )

    if st.button("🆕 Nueva venta", key="btn_nueva_venta",
                 type="primary", use_container_width=True):
        _on_nueva_venta()

    url_wa = venta.get("url_wa", "")
    if url_wa:
        st.markdown(
            f"""<a href="{url_wa}"
                onclick="window.open(this.href,'_blank','noopener,noreferrer');return false;"
                target="_blank" rel="noopener noreferrer"
                style="text-decoration:none;display:block;margin-top:0.6rem;">
            <div style="background:#25D366;color:white;padding:14px;border-radius:10px;
            text-align:center;font-weight:700;font-size:1rem;">
                📲 Enviar Comprobante por WhatsApp
            </div></a>""",
            unsafe_allow_html=True,
        )

    items_lineas = "\n".join([
        f"  • {it['marca']} {it['perfume']} {it['ml']}ml — S/ {fmt_precio(it['precio'])}"
        for it in cesta
    ])
    dir_linea = f"\n📍 *Dirección:* {cliente.get('direccion', '')}" if cliente.get("direccion") else ""
    msg_comunidad = (
        f"📦 *Perfuteca — Pedido Nuevo {id_compra}*\n────────────────────\n"
        f"👤 *Cliente:* {comprador}\n📱 *Celular:* {celular}\n"
        f"🚚 *Envío:* {tipo_envio}{dir_linea}\n────────────────────\n"
        f"🌸 *Perfumes:*\n{items_lineas}\n────────────────────\n"
        f"💰 *Total: S/ {fmt_precio(total)}*\n"
        f"💳 *Pago:* {cesta[0]['metodo'] if cesta else ''}"
    )
    st.markdown(
        f'<a href="https://wa.me/?text={quote(msg_comunidad)}" target="_blank"'
        f' style="text-decoration:none;display:block;background:#128C7E;'
        f'color:white !important;padding:12px;border-radius:10px;'
        f'text-align:center;font-weight:700;font-size:1rem;margin-top:0.5rem;">'
        f'📲 Enviar pedido a comunidad</a>',
        unsafe_allow_html=True,
    )

    st.markdown("<br>", unsafe_allow_html=True)
    with st.expander("📋 Ver detalle de la venta"):
        items_html = _html_items_cesta(cesta)
        st.markdown(
            f"""<div style="background:white;border:1px solid #ede0d4;border-radius:14px;
                padding:1.2rem 1.4rem;">
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:0.5rem;
                    margin-bottom:1rem;font-size:0.88rem;">
                    <div><span style="color:#a07850;font-size:0.75rem;">👤 Comprador</span>
                        <br><strong style="color:#2c1a0e;">{comprador}</strong></div>
                    <div><span style="color:#a07850;font-size:0.75rem;">📱 Celular</span>
                        <br><strong style="color:#2c1a0e;">{celular}</strong></div>
                    <div><span style="color:#a07850;font-size:0.75rem;">📅 Fecha</span>
                        <br><strong style="color:#2c1a0e;">{fecha_str}</strong></div>
                    <div><span style="color:#a07850;font-size:0.75rem;">🚚 Envío</span>
                        <br><strong style="color:#2c1a0e;">{tipo_envio}</strong></div>
                    <div style="grid-column:1/-1;">
                        <span style="color:#a07850;font-size:0.75rem;">📍 Dirección</span>
                        <br><strong style="color:#2c1a0e;">{direccion}</strong></div>
                </div>
                <div style="font-size:0.68rem;color:#a07850;text-transform:uppercase;
                    font-weight:600;letter-spacing:0.1em;margin-bottom:0.4rem;">Perfumes</div>
                {items_html}
                <div style="display:flex;justify-content:space-between;align-items:center;
                    margin-top:0.7rem;padding-top:0.5rem;border-top:1px solid #ede0d4;">
                    <span style="font-size:0.8rem;font-weight:600;color:#a07850;
                        text-transform:uppercase;letter-spacing:0.08em;">Total</span>
                    <span style="font-family:'Inter','DM Sans',sans-serif;font-size:1.15rem;
                        font-weight:700;color:#c8956c;font-variant-numeric:tabular-nums;">
                        S/ {fmt_precio(total)}</span>
                </div>
            </div>""",
            unsafe_allow_html=True,
        )


# ═══════════════════════════════════════════════════════════════════════════════
# PUNTO DE ENTRADA
# ═══════════════════════════════════════════════════════════════════════════════

@st.fragment
def mostrar_tab_venta(df: pd.DataFrame, n_pend: int = 0) -> None:
    """
    Orquestador principal del tab de ventas.
    @st.fragment permite re-renders aislados del resto de la app.
    n_pend se calcula una sola vez en app.py y se pasa aquí para evitar
    la llamada duplicada a cargar_ventas() en cada rerun del fragment.
    """
    st.markdown("### 📝 Registrar Nueva Venta")

    state = get_state()

    # Banner de pedidos pendientes (valor pre-calculado por app.py)
    if n_pend > 0:
        s = "s" if n_pend != 1 else ""
        st.markdown(
            f"<div style='background:#fff7ed;border-left:4px solid #f59e0b;"
            f"border-radius:8px;padding:0.5rem 0.9rem;margin-bottom:0.7rem;"
            f"font-size:0.85rem;color:#92400e;font-weight:600;'>"
            f"📦 {n_pend} pedido{s} pendiente{s} — revísalos en 📊 Estadísticas</div>",
            unsafe_allow_html=True,
        )

    # ── Post-venta ────────────────────────────────────────────────────────────
    if state["venta"]["guardada"]:
        _render_venta_guardada(state)
        return

    # ── Cotizaciones de hoy + sección de cotización ───────────────────────────
    _render_cotizaciones_hoy(df, state)
    mostrar_seccion_cotizacion(df)
    separador()

    # ── Wizard de venta directa ───────────────────────────────────────────────
    paso = state["venta"]["paso"]
    with st.expander("🛒 Registrar Venta Directa", expanded=paso > 1):
        _render_barra_progreso(paso)

        if paso == 1:
            _render_paso_1(df, state)
        elif paso == 2:
            _render_paso_2(df, state)
        elif paso == 3:
            _render_paso_3(state)
