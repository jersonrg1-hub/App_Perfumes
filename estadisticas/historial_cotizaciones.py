import html
import re
import streamlit as st
import pandas as pd
from urllib.parse import quote
from config import fmt_precio, hoy_peru, METODOS_PAGO, TIPOS_ENVIO
from data import (
    cargar_cotizaciones, actualizar_estado_cotizacion, cargar_catalogo,
    guardar_venta, obtener_proximo_id, actualizar_stock_perfumes_batch,
    limpiar_cache_ventas,
)
from components import separador


def _parsear_items_cotizacion(perfumes_txt, df_catalogo):
    """
    Convierte texto de cotización a lista de dicts usable por guardar_venta.
    Formato esperado: "Nombre 5ml S/25.00 | Nombre2 10ml S/45.00"
    """
    items, errores = [], []
    for parte in str(perfumes_txt).split(" | "):
        parte = parte.strip()
        if not parte:
            continue
        m = re.match(r"^(.+?)\s+(\d+)\s*ml\s+S/\s*(\d+(?:\.\d+)?)$", parte)
        if not m:
            errores.append(f"No se pudo leer: «{parte}»")
            continue
        nombre_perf = m.group(1).strip()
        ml = int(m.group(2))
        precio = float(m.group(3))

        match_cat = df_catalogo[df_catalogo["Nombre"] == nombre_perf]
        if match_cat.empty:
            errores.append(f"Perfume no encontrado en catálogo: «{nombre_perf}»")
            continue

        row_cat = match_cat.iloc[0]
        items.append({
            "id_perfume": str(row_cat["ID_Perfume"]),
            "perfume":    nombre_perf,
            "marca":      str(row_cat.get("Marca", "")),
            "ml":         ml,
            "precio":     precio,
            "metodo":     "",
        })
    return items, errores


def mostrar_historial_cotizaciones():
    df = cargar_cotizaciones()
    df_catalogo = cargar_catalogo()

    if df.empty:
        st.info("📭 No hay cotizaciones registradas todavía")
        return

    total_cot = len(df)
    total_monto = df["Total"].sum() if "Total" in df.columns else 0
    aceptadas = len(df[df["Estado"] == "Aceptada"]) if "Estado" in df.columns else 0
    rechazadas = len(df[df["Estado"] == "Rechazada"]) if "Estado" in df.columns else 0

    col1, col2, col3, col4 = st.columns(4)
    for col, valor, label, bg, color in [
        (col1, total_cot,                  "Total",     "#f5ede6", "#2c1a0e"),
        (col2, f"S/ {fmt_precio(total_monto)}", "Monto", "#fef9c3", "#713f12"),
        (col3, aceptadas,                  "Aceptadas", "#dcfce7", "#166534"),
        (col4, rechazadas,                 "Rechazadas","#fee2e2", "#991b1b"),
    ]:
        with col:
            st.markdown(
                f'<div style="background:{bg};border-radius:10px;padding:0.6rem 1rem;text-align:center;">'
                f'<div style="color:{color};font-size:0.75rem;text-transform:uppercase;font-weight:600;">{label}</div>'
                f'<div style="color:{color};font-size:1.4rem;font-weight:700;">{valor}</div>'
                f'</div>',
                unsafe_allow_html=True
            )

    st.markdown("")

    col_buscar, col_filtro = st.columns([2, 1])
    with col_buscar:
        buscar = st.text_input("🔍 Buscar por celular o ID", key="cot_buscar", placeholder="Ej: 987654321")
    with col_filtro:
        filtro_estado = st.selectbox(
            "Estado",
            ["Activas", "Todos", "Enviado", "Aceptada", "Rechazada"],
            key="cot_estado_filtro"
        )

    df_mostrar = df.copy()
    if filtro_estado == "Activas" and "Estado" in df_mostrar.columns:
        df_mostrar = df_mostrar[~df_mostrar["Estado"].isin(["Aceptada", "Rechazada"])]
    elif filtro_estado != "Todos" and "Estado" in df_mostrar.columns:
        df_mostrar = df_mostrar[df_mostrar["Estado"] == filtro_estado]
    if buscar:
        mask = pd.Series(False, index=df_mostrar.index)
        if "Celular" in df_mostrar.columns:
            mask |= df_mostrar["Celular"].astype(str).str.contains(buscar, na=False)
        if "ID_Cotizacion" in df_mostrar.columns:
            mask |= df_mostrar["ID_Cotizacion"].astype(str).str.contains(buscar, na=False)
        df_mostrar = df_mostrar[mask]

    df_mostrar = df_mostrar.sort_values("Fecha", ascending=False) if "Fecha" in df_mostrar.columns else df_mostrar

    separador()
    st.markdown(f"**{len(df_mostrar)} cotización(es)**")
    st.markdown("")

    for row in df_mostrar.to_dict("records"):
        id_cot     = html.escape(str(row.get("ID_Cotizacion", "—")))
        id_cot_raw = str(row.get("ID_Cotizacion", ""))
        celular    = html.escape(str(row.get("Celular", "—")))
        fecha      = row.get("Fecha")
        fecha_str  = fecha.strftime("%d/%m/%Y") if pd.notna(fecha) else "—"
        total      = row.get("Total", 0)
        perfumes   = html.escape(str(row.get("Perfumes", "—")))
        estado     = html.escape(str(row.get("Estado", "—")))
        fila_cot   = int(row.get("fila_sheet", 0))

        if estado == "Enviado":
            badge_bg, badge_color, badge_icon = "#fef9c3", "#713f12", "📤"
        elif estado == "Aceptada":
            badge_bg, badge_color, badge_icon = "#dcfce7", "#166534", "✅"
        elif estado == "Rechazada":
            badge_bg, badge_color, badge_icon = "#fee2e2", "#991b1b", "❌"
        else:
            badge_bg, badge_color, badge_icon = "#f5ede6", "#a07850", "📋"

        header = f"{id_cot} · 📱 {celular} · {fecha_str} · S/ {fmt_precio(total)}"

        with st.expander(header):
            col_a, col_b = st.columns([3, 1])
            with col_a:
                st.markdown(f"**📱 Celular:** {celular}")
                st.markdown(f"**📅 Fecha:** {fecha_str}")
                st.markdown(f"**🛍️ Perfumes:**")
                for item in perfumes.split(" | "):
                    if item.strip():
                        st.markdown(f"&nbsp;&nbsp;&nbsp;&nbsp;🌸 {item.strip()}", unsafe_allow_html=True)
            with col_b:
                st.markdown(
                    f'<div style="background:{badge_bg};color:{badge_color};'
                    f'padding:4px 10px;border-radius:20px;font-size:0.8rem;'
                    f'font-weight:600;text-align:center;margin-bottom:0.5rem;">'
                    f'{badge_icon} {estado}</div>',
                    unsafe_allow_html=True
                )
                st.markdown(
                    f'<div style="background:#1a0f08;border-top:2px solid #c8956c;'
                    f'border-radius:12px;padding:0.7rem;text-align:center;">'
                    f'<div style="color:#c8956c;font-size:0.7rem;letter-spacing:0.15em;">TOTAL</div>'
                    f'<div style="color:#f5e6d8;font-family:Playfair Display,serif;'
                    f'font-size:1.3rem;font-weight:700;">S/ {fmt_precio(total)}</div>'
                    f'</div>',
                    unsafe_allow_html=True
                )

            st.markdown("")
            wa_celular  = str(row.get("Celular", ""))
            items_wa    = "\n".join([
                f"  🌸 {item.strip()}"
                for item in str(row.get("Perfumes", "")).split(" | ")
                if item.strip()
            ])
            mensaje_wa = (
                f"🌸 *Perfuteca — Cotización {id_cot}*\n"
                f"────────────────────\n"
                f"📋 *Perfumes disponibles:*\n"
                f"{items_wa}\n"
                f"────────────────────\n"
                f"💰 *Total: S/ {fmt_precio(total)}*\n\n"
                f"_¿Te interesa alguno? Con gusto te lo reservo 😊_"
            )
            wa_url = f"https://wa.me/51{wa_celular}?text={quote(mensaje_wa)}"
            st.markdown(
                f"""<a href="{wa_url}" target="_blank"
                   style="text-decoration:none;display:block;background:#25D366;
                       color:white !important;padding:8px;border-radius:8px;
                       text-align:center;font-weight:600;font-size:0.85rem;">
                   📲 Escribir por WhatsApp
                </a>""",
                unsafe_allow_html=True
            )

            # ── Acciones según estado ───────────────────────────────────────
            if estado not in ("Aceptada", "Rechazada"):
                separador()
                # Usamos fila_cot como key única (id_cot_raw puede repetirse en el Sheet)
                uid = fila_cot
                converting_key = f"converting_cot_{uid}"

                if not st.session_state.get(converting_key):
                    col_ac, col_rech = st.columns(2)
                    with col_ac:
                        if st.button(
                            "✅ Convertir a Venta",
                            key=f"ac_{uid}",
                            use_container_width=True,
                            type="primary",
                        ):
                            st.session_state[converting_key] = True
                            st.rerun()
                    with col_rech:
                        if st.button(
                            "❌ Rechazada",
                            key=f"rech_{uid}",
                            use_container_width=True,
                        ):
                            try:
                                actualizar_estado_cotizacion(id_cot_raw, "Rechazada", fila_sheet=fila_cot)
                                st.success("❌ Marcada como Rechazada")
                                st.rerun()
                            except Exception as e:
                                st.error(f"Error: {e}")

                else:
                    # ── Formulario de conversión ────────────────────────────
                    st.markdown(
                        '<div style="background:#f5ede6;border-left:3px solid #c8956c;'
                        'border-radius:10px;padding:0.8rem 1rem;margin-bottom:0.7rem;">'
                        '<div style="font-size:0.8rem;font-weight:700;color:#2c1a0e;">📝 Completar datos para registrar la venta</div>'
                        '</div>',
                        unsafe_allow_html=True,
                    )

                    comprador_raw = st.text_input(
                        "👤 Nombre del comprador",
                        placeholder="Nombre completo",
                        key=f"comp_{uid}",
                    )
                    comprador = comprador_raw.title() if comprador_raw else ""
                    tipo_envio  = st.selectbox("🚚 Tipo de Envío", TIPOS_ENVIO, key=f"envio_{uid}")
                    direccion   = st.text_input("📍 Dirección", placeholder="Distrito / Referencia", key=f"dir_{uid}")
                    metodo_pago = st.selectbox("💳 Método de pago", METODOS_PAGO, key=f"pago_{uid}")
                    fecha_venta = st.date_input("📅 Fecha", value=hoy_peru(), format="DD/MM/YYYY", key=f"fecha_{uid}")

                    col_confirm, col_cancel = st.columns(2)
                    with col_confirm:
                        if st.button(
                            "✅ Confirmar y guardar venta",
                            key=f"confirm_{uid}",
                            type="primary",
                            use_container_width=True,
                        ):
                            if not comprador:
                                st.error("⚠️ Ingresa el nombre del comprador")
                            elif tipo_envio != "Contraentrega" and not direccion.strip():
                                st.error(f"⚠️ La dirección es requerida para {tipo_envio}")
                            else:
                                perfumes_txt = str(row.get("Perfumes", ""))
                                items_venta, errores = _parsear_items_cotizacion(perfumes_txt, df_catalogo)

                                if errores:
                                    st.error("❌ " + " · ".join(errores))
                                else:
                                    for it in items_venta:
                                        it["metodo"] = metodo_pago

                                    try:
                                        id_compra = obtener_proximo_id()
                                        filas = [
                                            [
                                                id_compra,
                                                str(fecha_venta),
                                                comprador,
                                                str(row.get("Celular", "")),
                                                it["id_perfume"],
                                                str(it["ml"]),
                                                round(float(it["precio"]), 2),
                                                metodo_pago,
                                                tipo_envio,
                                                direccion,
                                                "Pendiente",
                                            ]
                                            for it in items_venta
                                        ]
                                        guardar_venta(filas)
                                        try:
                                            actualizar_stock_perfumes_batch(items_venta)
                                        except Exception:
                                            st.warning("⚠️ Venta guardada pero el stock no pudo actualizarse. Corrígelo manualmente.")
                                        actualizar_estado_cotizacion(id_cot_raw, "Aceptada", fila_sheet=fila_cot)
                                        limpiar_cache_ventas()
                                        st.session_state[converting_key] = False

                                        items_lineas = "\n".join([
                                            f"  • {it['perfume']} {it['ml']}ml — S/ {fmt_precio(it['precio'])}"
                                            for it in items_venta
                                        ])
                                        dir_linea = f"\n📍 *Dirección:* {direccion}" if direccion.strip() else ""
                                        mensaje_comunidad = (
                                            f"📦 *Pedido Nuevo — {id_compra}*\n"
                                            f"────────────────────\n"
                                            f"👤 *Cliente:* {comprador}\n"
                                            f"📱 *Celular:* {row.get('Celular', '')}\n"
                                            f"🚚 *Envío:* {tipo_envio}"
                                            f"{dir_linea}\n"
                                            f"────────────────────\n"
                                            f"🌸 *Perfumes:*\n"
                                            f"{items_lineas}\n"
                                            f"────────────────────\n"
                                            f"💰 *Total: S/ {fmt_precio(total)}*\n"
                                            f"💳 *Pago:* {metodo_pago}"
                                        )
                                        wa_comunidad_url = f"https://wa.me/?text={quote(mensaje_comunidad)}"

                                        st.success(f"✅ Venta {id_compra} registrada correctamente")
                                        st.markdown(
                                            f"""<a href="{wa_comunidad_url}" target="_blank"
                                               style="text-decoration:none;display:block;background:#25D366;
                                                   color:white !important;padding:10px;border-radius:8px;
                                                   text-align:center;font-weight:700;font-size:0.9rem;
                                                   margin:8px 0;">
                                               📲 Enviar pedido a comunidad de WhatsApp
                                            </a>""",
                                            unsafe_allow_html=True,
                                        )
                                        if st.button("✖ Cerrar", key=f"cerrar_{uid}", use_container_width=True):
                                            st.rerun()
                                    except Exception as e:
                                        st.error(f"Error al guardar: {e}")

                    with col_cancel:
                        if st.button("✖ Cancelar", key=f"cancel_{uid}", use_container_width=True):
                            st.session_state[converting_key] = False
                            st.rerun()
