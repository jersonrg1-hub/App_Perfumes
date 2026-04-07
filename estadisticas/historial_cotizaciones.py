import html
import streamlit as st
import pandas as pd
from urllib.parse import quote
from config import fmt_precio, hoy_peru, WORKSHEET_COTIZACIONES
from data import get_hoja
from components import separador


@st.cache_data(ttl=120)
def _cargar_cotizaciones():
    try:
        hoja = get_hoja(WORKSHEET_COTIZACIONES)
        valores = hoja.get_all_values()
        if not valores or len(valores) < 2:
            return pd.DataFrame()
        headers = valores[0]
        filas = valores[1:]
        df = pd.DataFrame(filas, columns=headers)
        if "Fecha" in df.columns:
            df["Fecha"] = pd.to_datetime(df["Fecha"].astype(str).str.strip(), errors="coerce")
        if "Total" in df.columns:
            df["Total"] = pd.to_numeric(df["Total"], errors="coerce").fillna(0)
        return df
    except Exception:
        return pd.DataFrame()


def _limpiar_cache():
    _cargar_cotizaciones.clear()


def mostrar_historial_cotizaciones():
    df = _cargar_cotizaciones()

    if df.empty:
        st.info("📭 No hay cotizaciones registradas todavía")
        return

    total_cot = len(df)
    total_monto = df["Total"].sum() if "Total" in df.columns else 0
    esta_semana = 0
    if "Fecha" in df.columns:
        hoy = pd.Timestamp(hoy_peru()).normalize()
        inicio_semana = hoy - pd.Timedelta(days=hoy.weekday())
        esta_semana = len(df[df["Fecha"].dt.normalize() >= inicio_semana])

    col1, col2, col3 = st.columns(3)
    for col, valor, label, bg, color in [
        (col1, total_cot, "Total enviadas", "#f5ede6", "#2c1a0e"),
        (col2, f"S/ {fmt_precio(total_monto)}", "Monto cotizado", "#fef9c3", "#713f12"),
        (col3, esta_semana, "Esta semana", "#dcfce7", "#166534"),
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

    col_bus, col_est = st.columns([2, 1])
    with col_bus:
        buscar = st.text_input("🔍 Buscar por celular o ID", key="cot_buscar", placeholder="Ej: 987654321")
    with col_est:
        estados = ["Todos"] + sorted(df["Estado"].dropna().unique().tolist()) if "Estado" in df.columns else ["Todos"]
        filtro_estado = st.selectbox("Estado", estados, key="cot_estado")

    df_mostrar = df.copy()
    if buscar:
        mask = pd.Series(False, index=df_mostrar.index)
        if "Celular" in df_mostrar.columns:
            mask |= df_mostrar["Celular"].astype(str).str.contains(buscar, na=False)
        if "ID_Cotizacion" in df_mostrar.columns:
            mask |= df_mostrar["ID_Cotizacion"].astype(str).str.contains(buscar, na=False)
        df_mostrar = df_mostrar[mask]

    if filtro_estado != "Todos":
        df_mostrar = df_mostrar[df_mostrar["Estado"] == filtro_estado]

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
            badge_bg, badge_color = "#dcfce7", "#166534"
            badge_icon = "✅"
        elif estado == "Convertido":
            badge_bg, badge_color = "#dbeafe", "#1e40af"
            badge_icon = "🛒"
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
                f"- {item.strip()}"
                for item in str(row.get("Perfumes", "")).split(" | ")
                if item.strip()
            ])
            mensaje_wa = (
                f"🌸 *COTIZACIÓN {id_cot}*\n"
                f"━━━━━━━━━━━━━━━━\n"
                f"{items_wa}\n"
                f"━━━━━━━━━━━━━━━━\n"
                f"💰 *Total: S/ {fmt_precio(total)}*\n\n"
                f"¿Te interesa alguno? 😊"
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