import html
import streamlit as st
import pandas as pd
from config import fmt_precio, hoy_peru
from estadisticas.resumen import _metrica_card


@st.cache_data(ttl=120)
def _stats_mes(df_ventas, mes_str):
    periodo = pd.Period(mes_str, freq="M")
    fecha_valida = df_ventas["Fecha"].notna()
    df_mes = df_ventas[fecha_valida & (df_ventas.loc[fecha_valida, "Fecha"].dt.to_period("M") == periodo)]
    total = df_mes["Precio_Cobrado"].sum()
    num = len(df_mes)
    prom = total / num if num > 0 else 0
    return total, num, prom


def _col_mes(col, nombre_mes, total, num, prom):
    with col:
        st.markdown(
            f"<div style='font-size:0.8rem; font-weight:600; color:#a07850;"
            f"text-transform:uppercase; letter-spacing:0.08em;"
            f"margin-bottom:0.5rem;'>{html.escape(str(nombre_mes))}</div>",
            unsafe_allow_html=True
        )
        st.markdown(_metrica_card("Ventas", num), unsafe_allow_html=True)
        st.markdown("")
        st.markdown(_metrica_card("Total", f"S/ {fmt_precio(total)}"), unsafe_allow_html=True)
        st.markdown("")
        st.markdown(_metrica_card("Promedio", f"S/ {fmt_precio(prom)}"), unsafe_allow_html=True)


def mostrar_resumen_semanal(df_ventas, df_catalogo):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    df_ventas = df_ventas.copy()
    if df_ventas["Fecha"].dtype == object:
        df_ventas["Fecha"] = pd.to_datetime(df_ventas["Fecha"].astype(str).str.strip(), errors="coerce")

    hoy = pd.Timestamp(hoy_peru()).normalize()
    inicio_semana = hoy - pd.Timedelta(days=hoy.weekday())
    fin_semana = inicio_semana + pd.Timedelta(days=6)

    ventas_semana = df_ventas[
        (df_ventas["Fecha"].dt.normalize() >= inicio_semana.normalize()) &
        (df_ventas["Fecha"].dt.normalize() <= fin_semana.normalize())
    ]

    st.markdown("#### 📅 Resumen de esta semana")
    st.markdown(
        f"<div style='font-size:0.85rem; color:#a07850; font-weight:600; margin-bottom:0.5rem;'>"
        f"{inicio_semana.strftime('%d/%m/%Y')} — {fin_semana.strftime('%d/%m/%Y')}</div>",
        unsafe_allow_html=True
    )

    col1, col2, col3 = st.columns(3)
    total_semana = ventas_semana["Precio_Cobrado"].sum()
    num_ventas = len(ventas_semana)

    with col1:
        st.markdown(_metrica_card("Ventas semana", num_ventas), unsafe_allow_html=True)
    with col2:
        st.markdown(_metrica_card("Total semana", f"S/ {fmt_precio(total_semana)}"), unsafe_allow_html=True)
    with col3:
        promedio = total_semana / num_ventas if num_ventas > 0 else 0
        st.markdown(_metrica_card("Promedio", f"S/ {fmt_precio(promedio)}"), unsafe_allow_html=True)

    if not ventas_semana.empty and "ID_Perfume" in ventas_semana.columns:
        st.markdown("")

        top = (
            ventas_semana.assign(ID_Perfume=ventas_semana["ID_Perfume"].astype(str))
            .groupby("ID_Perfume")
            .size().reset_index(name="Cantidad")
            .sort_values("Cantidad", ascending=False)
            .iloc[0]
        )

        match = df_catalogo[df_catalogo["ID_Perfume"].astype(str) == top["ID_Perfume"]]
        nombre_top = match.iloc[0]["Nombre"] if not match.empty else top["ID_Perfume"]
        nombre_top = html.escape(str(nombre_top))

        st.markdown(f"""
        <div style="
            background:#ffffff; border:1px solid #ede0d4; border-radius:12px;
            padding:1rem; text-align:center; margin:0.5rem 0;
        ">
            <div style="color:#a07850; font-size:0.68rem; text-transform:uppercase;
                font-weight:600; letter-spacing:0.12em; margin-bottom:0.3rem;">
                🏆 Más vendido esta semana
            </div>
            <div style="font-family:'Playfair Display',serif; font-size:1.3rem;
                font-weight:600; color:#2c1a0e; margin-bottom:0.2rem;">{nombre_top}</div>
            <div style="
                display:inline-block; background:#fdf6f0; border:1px solid #ede0d4;
                border-radius:20px; padding:0.2rem 0.7rem;
                font-size:0.8rem; color:#a07850; font-weight:600;
            ">{top['Cantidad']} venta(s)</div>
        </div>
        """, unsafe_allow_html=True)
    else:
        st.info("Sin ventas esta semana aún")

    if not ventas_semana.empty:
        st.markdown("")
        st.markdown("**📊 Ventas por día:**")
        dias = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
        cols = st.columns(7)
        for i, dia in enumerate(dias):
            fecha_dia = inicio_semana + pd.Timedelta(days=i)
            ventas_dia = ventas_semana[ventas_semana["Fecha"].dt.normalize() == fecha_dia.normalize()]
            total_dia = ventas_dia["Precio_Cobrado"].sum()
            es_hoy = fecha_dia.normalize() == hoy

            borde = "border:1px solid #c8956c;" if es_hoy else "border:1px solid #ede0d4;"
            bg = "#fdf6f0" if es_hoy else "#ffffff"
            color_dia = "#c8956c" if es_hoy else "#a07850"

            with cols[i]:
                st.markdown(f"""
                <div style="text-align:center; padding:0.5rem 0.2rem;
                    background:{bg}; border-radius:10px; {borde}">
                    <div style="color:{color_dia}; font-size:0.68rem;
                        font-weight:600; text-transform:uppercase;">{dia}</div>
                    <div style="color:#2c1a0e; font-size:0.9rem; font-weight:700;
                        font-family:'Inter','DM Sans',sans-serif;
                        font-variant-numeric:tabular-nums;">{len(ventas_dia)}</div>
                    <div style="color:#a07850; font-size:0.65rem;
                        font-family:'Inter','DM Sans',sans-serif;">
                        S/{fmt_precio(total_dia)}</div>
                </div>
                """, unsafe_allow_html=True)

    st.markdown("---")
    st.markdown("#### 📆 Comparar meses")

    opciones_meses = [
        str(m) for m in sorted(
            df_ventas["Fecha"].dropna().dt.to_period("M").unique().tolist()
        )
    ]

    if len(opciones_meses) < 2:
        st.info("Se necesitan al menos 2 meses de datos para comparar")
        return

    col1, col2 = st.columns(2)
    with col1:
        mes1 = st.selectbox("📅 Mes 1", opciones_meses,
            index=len(opciones_meses) - 1, key="mes1_comp")
    with col2:
        mes2 = st.selectbox("📅 Mes 2", opciones_meses,
            index=max(0, len(opciones_meses) - 2), key="mes2_comp")

    total_m1, num_m1, prom_m1 = _stats_mes(df_ventas, mes1)
    total_m2, num_m2, prom_m2 = _stats_mes(df_ventas, mes2)

    st.markdown("")
    col1, col2 = st.columns(2)
    _col_mes(col1, mes1, total_m1, num_m1, prom_m1)
    _col_mes(col2, mes2, total_m2, num_m2, prom_m2)

    if total_m1 > 0 and total_m2 > 0:
        st.markdown("")
        diferencia = total_m2 - total_m1
        porcentaje = ((total_m2 - total_m1) / total_m1) * 100
        color = "#2d7a4f" if diferencia >= 0 else "#e53e3e"
        bg = "#f0faf4" if diferencia >= 0 else "#fff5f5"
        borde = "#b7e4c7" if diferencia >= 0 else "#fed7d7"
        simbolo = "📈" if diferencia >= 0 else "📉"

        st.markdown(f"""
        <div style="
            background:{bg}; border:1px solid {borde};
            border-radius:12px; padding:1rem;
            text-align:center; margin-top:0.5rem;
        ">
            <div style="color:#a07850; font-size:0.68rem; text-transform:uppercase;
                font-weight:600; letter-spacing:0.1em; margin-bottom:0.3rem;">Diferencia</div>
            <div style="color:{color}; font-size:1.4rem; font-weight:700;
                font-family:'Inter','DM Sans',sans-serif; font-variant-numeric:tabular-nums;">
                {simbolo} S/ {fmt_precio(abs(diferencia))} ({porcentaje:+.1f}%)
            </div>
            <div style="color:#a07850; font-size:0.8rem; margin-top:0.2rem;">
                {html.escape(mes2)} vs {html.escape(mes1)}
            </div>
        </div>
        """, unsafe_allow_html=True)