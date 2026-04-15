import html
import streamlit as st
import pandas as pd
from urllib.parse import quote
from config import fmt_precio, hoy_peru
from data import cargar_cotizaciones, actualizar_estado_cotizacion
from components import separador


def mostrar_historial_cotizaciones():
    df = cargar_cotizaciones()

    if df.empty:
        st.info("📭 No hay cotizaciones registradas todavía")
        return

    total_cot = len(df)
    total_monto = df["Total"].sum() if "Total" in df.columns else 0
    aceptadas = len(df[df["Estado"] == "Aceptada"]) if "Estado" in df.columns else 0
    rechazadas = len(df[df["Estado"] == "Rechazada"]) if "Estado" in df.columns else 0

    col1, col2, col3, col4 = st.columns(4)
    for col, valor, label, bg, color in [
        (col1, total_cot, "Total", "#f5ede6", "#2c1a0e"),
        (col2, f"S/ {fmt_precio(total_monto)}", "Monto", "#fef9c3", "#713f12"),
        (col3, aceptadas, "Aceptadas", "#dcfce7", "#166534"),
        (col4, rechazadas, "Rechazadas", "#fee2e2", "#991b1b"),
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
            ["Todos", "Enviado", "Aceptada", "Rechazada"],
            key="cot_estado_filtro"
        )

    df_mostrar = df.copy()
    if filtro_estado != "Todos" and "Estado" in df_mostrar.columns:
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
        id_cot = html.escape(str(row.get("ID_Cotizacion", "—")))
        celular = html.escape(str(row.get("Celular", "—")))
        fecha = row.get("Fecha")
        fecha_str = fecha.strftime("%d/%m/%Y") if pd.notna(fecha) else "—"
        total = row.get("Total", 0)
        perfumes = html.escape(str(row.get("Perfumes", "—")))
        estado = html.escape(str(row.get("Estado", "—")))

        if estado == "Enviado":
            badge_bg, badge_color = "#fef9c3", "#713f12"
            badge_icon = "📤"
        elif estado == "Aceptada":
            badge_bg, badge_color = "#dcfce7", "#166534"
            badge_icon = "✅"
        elif estado == "Rechazada":
            badge_bg, badge_color = "#fee2e2", "#991b1b"
            badge_icon = "❌"
        else:
            badge_bg, badge_color = "#f5ede6", "#a07850"
            badge_icon = "📋"

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
            wa_celular = str(row.get("Celular", ""))
            items_wa = "\n".join([
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
                f"""
                <a href="{wa_url}" target="_blank"
                   style="
                       text-decoration:none;
                       display:block;
                       background:#25D366;
                       color:white !important;
                       padding:8px;
                       border-radius:8px;
                       text-align:center;
                       font-weight:600;
                       font-size:0.85rem;
                   ">
                   📲 Escribir por WhatsApp
                </a>
                """,
                unsafe_allow_html=True
            )

            id_cot_raw = str(row.get("ID_Cotizacion", ""))
            fila_cot = int(row.get("fila_sheet", 0))
            if estado not in ("Aceptada", "Rechazada"):
                separador()
                col_ac, col_rech = st.columns(2)
                with col_ac:
                    if st.button("✅ Aceptada", key=f"ac_{id_cot_raw}", use_container_width=True, type="primary"):
                        try:
                            actualizar_estado_cotizacion(id_cot_raw, "Aceptada", fila_sheet=fila_cot)
                            st.success("✅ Marcada como Aceptada")
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error: {e}")
                with col_rech:
                    if st.button("❌ Rechazada", key=f"rech_{id_cot_raw}", use_container_width=True):
                        try:
                            actualizar_estado_cotizacion(id_cot_raw, "Rechazada", fila_sheet=fila_cot)
                            st.success("❌ Marcada como Rechazada")
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error: {e}")