import html
import streamlit as st
from urllib.parse import quote
from config import fmt_precio, ML_OPCIONES
from data import guardar_cotizacion


def _generar_mensaje_cotizacion(celular, cesta_cotizacion):
    total = sum(float(i["precio"]) for i in cesta_cotizacion)
    items = "\n".join([
        f"  🌸 *{i['marca']}* · {i['perfume']} · {i['ml']}ml · S/ {fmt_precio(i['precio'])}"
        if i.get('marca') else
        f"  🌸 {i['perfume']} · {i['ml']}ml · S/ {fmt_precio(i['precio'])}"
        for i in cesta_cotizacion
    ])
    mensaje = (
        f"🌸 *Perfuteca — Cotización*\n"
        f"────────────────────\n"
        f"📋 *Perfumes disponibles:*\n"
        f"{items}\n"
        f"────────────────────\n"
        f"💰 *Total: S/ {fmt_precio(total)}*\n\n"
        f"_¿Te interesa alguno? Con gusto te lo reservo 😊_"
    )
    return f"https://wa.me/51{celular}?text={quote(mensaje)}"


def mostrar_seccion_cotizacion(df):

    if "cesta_cotizacion" not in st.session_state:
        st.session_state.cesta_cotizacion = []
    if "cotizacion_enviada" not in st.session_state:
        st.session_state.cotizacion_enviada = False

    with st.expander("💰 Enviar Cotización por WhatsApp", expanded=False):

        celular_cot = st.text_input(
            "📱 Celular del cliente",
            max_chars=9,
            placeholder="9 dígitos",
            key="cel_cotizacion"
        )

        st.markdown("#### 🛒 Armar cotización")

        nombres_opciones = ["— Elige un perfume —"] + sorted(
            df["Nombre"].dropna().unique().tolist()
        )
        perfume_cot = st.selectbox(
            "🌸 Perfume", nombres_opciones, key="perf_cot_sel"
        )

        ml_cot = st.selectbox("📏 Tamaño", ML_OPCIONES, key="ml_cot_sel")

        if perfume_cot != nombres_opciones[0]:
            perfume_row = df[df["Nombre"] == perfume_cot].iloc[0]
            columna_precio = f"Precio_{ml_cot}ml"
            precio_catalogo = perfume_row.get(columna_precio, 0)

            if precio_catalogo not in (0, "", None):
                precio_final_cot = st.number_input(
                    "💰 Precio",
                    min_value=0.0,
                    value=float(precio_catalogo),
                    step=0.5,
                    format="%.2f",
                    key=f"precio_cot_{perfume_cot}_{ml_cot}",
                )

                if precio_final_cot != float(precio_catalogo):
                    st.markdown(
                        f'<div style="font-size:0.85rem; margin-bottom:0.3rem;">'
                        f'<span style="text-decoration:line-through; color:#e57373; font-weight:600;">'
                        f'S/ {fmt_precio(precio_catalogo)}</span>'
                        f'<span style="color:#a07850;"> → </span>'
                        f'<span style="color:#2c6e49; font-weight:700;">S/ {fmt_precio(precio_final_cot)}</span>'
                        f'</div>',
                        unsafe_allow_html=True,
                    )

                if st.button("➕ Agregar", key=f"add_cot_{perfume_cot}_{ml_cot}", use_container_width=True):
                    st.session_state.cesta_cotizacion.append({
                        "perfume": perfume_cot,
                        "marca": str(perfume_row.get("Marca", "")),
                        "ml": ml_cot,
                        "precio": precio_final_cot,
                    })
                    st.session_state.cotizacion_enviada = False
                    st.toast(f"Agregado: {perfume_cot}", icon="✅")
            else:
                st.warning("⚠️ Sin precio para ese tamaño")

        if st.session_state.cesta_cotizacion:
            st.markdown("---")
            st.markdown("**📋 Cotización:**")

            for i, item in enumerate(st.session_state.cesta_cotizacion):
                c1, c2, c3 = st.columns([3, 1, 0.5])
                c1.write(f"🌸 {item['perfume']} ({item['ml']}ml)")
                c2.write(f"**S/ {fmt_precio(item['precio'])}**")
                if c3.button("🗑️", key=f"del_cot_{i}"):
                    st.session_state.cesta_cotizacion.pop(i)
                    st.session_state.cotizacion_enviada = False
                    st.rerun()

            total_cot = sum(float(i["precio"]) for i in st.session_state.cesta_cotizacion)
            st.markdown(f"**Total: S/ {fmt_precio(total_cot)}**")

            col_wa, col_limpiar = st.columns([2, 1])

            with col_wa:
                if len(celular_cot) == 9 and celular_cot.isdigit():
                    url_wa = _generar_mensaje_cotizacion(
                        celular_cot, st.session_state.cesta_cotizacion
                    )

                    if not st.session_state.cotizacion_enviada:
                        if st.button(
                            "💾 Guardar cotización",
                            key="enviar_cotizacion",
                            type="primary",
                            use_container_width=True
                        ):
                            try:
                                id_cot = guardar_cotizacion(
                                    celular_cot,
                                    st.session_state.cesta_cotizacion,
                                    total_cot
                                )
                                st.session_state.cotizacion_enviada = True
                                st.session_state.ultimo_id_cotizacion = id_cot
                                st.session_state.url_wa_guardada = url_wa
                                st.rerun()
                            except Exception as e:
                                st.error(f"❌ Error al guardar: {e}")

                    if st.session_state.cotizacion_enviada:
                        id_mostrar = html.escape(str(st.session_state.get("ultimo_id_cotizacion", "")))
                        url_guardada = st.session_state.get("url_wa_guardada", url_wa)
                        st.markdown(
                            f"<div style='color:#38a169; font-weight:600; margin-bottom:0.5rem;'>"
                            f"✅ Cotización {id_mostrar} guardada</div>",
                            unsafe_allow_html=True
                        )
                        st.markdown(
                            f"""<a href="{url_guardada}" target="_blank" style="text-decoration:none;">
                            <div style="background:#25D366; color:white; padding:14px;
                            border-radius:10px; text-align:center; font-weight:700;
                            font-size:1rem;">
                                📲 Abrir WhatsApp y enviar
                            </div></a>""",
                            unsafe_allow_html=True
                        )
                else:
                    st.info("📱 Ingresa el celular para enviar")

            with col_limpiar:
                st.markdown("<br>", unsafe_allow_html=True)
                if not st.session_state.cotizacion_enviada:
                    if st.button("🗑️ Limpiar", key="limpiar_cotizacion", use_container_width=True):
                        st.session_state.cesta_cotizacion = []
                        st.session_state.cotizacion_enviada = False
                        st.session_state.url_wa_guardada = None
                        st.rerun()
                else:
                    if st.button("🆕 Nueva cotización", key="nueva_cotizacion", use_container_width=True):
                        st.session_state.cesta_cotizacion = []
                        st.session_state.cotizacion_enviada = False
                        st.session_state.url_wa_guardada = None
                        st.rerun()

        else:
            st.caption("Agrega perfumes para armar la cotización")

    st.markdown("")