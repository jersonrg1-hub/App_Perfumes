import html
import streamlit as st
import pandas as pd
from config import fmt_precio, stock_badge_html, stock_barra_html, STOCK_CRITICO, STOCK_BAJO


def mostrar_panel_stock(df_catalogo):
    if df_catalogo.empty:
        st.info("📭 No hay perfumes en el catálogo")
        return

    if "Stock_ml" not in df_catalogo.columns:
        st.warning("⚠️ Agrega la columna **Stock_ml** en tu hoja Catalogo")
        return

    df = df_catalogo.copy()
    df["Stock_ml"] = pd.to_numeric(df["Stock_ml"], errors="coerce").fillna(0)

    total = len(df)
    criticos = len(df[df["Stock_ml"] <= STOCK_CRITICO])
    bajos = len(df[(df["Stock_ml"] > STOCK_CRITICO) & (df["Stock_ml"] <= STOCK_BAJO)])
    ok = len(df[df["Stock_ml"] > STOCK_BAJO])

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.markdown(f"""
        <div style="background:#f5ede6; border-radius:10px; padding:0.6rem 1rem; text-align:center;">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase; font-weight:600;">Total</div>
            <div style="color:#2c1a0e; font-size:1.4rem; font-weight:700;">{total}</div>
        </div>""", unsafe_allow_html=True)
    with col2:
        st.markdown(f"""
        <div style="background:#fee2e2; border-radius:10px; padding:0.6rem 1rem; text-align:center;">
            <div style="color:#991b1b; font-size:0.75rem; text-transform:uppercase; font-weight:600;">🔴 Crítico</div>
            <div style="color:#7f1d1d; font-size:1.4rem; font-weight:700;">{criticos}</div>
        </div>""", unsafe_allow_html=True)
    with col3:
        st.markdown(f"""
        <div style="background:#fef9c3; border-radius:10px; padding:0.6rem 1rem; text-align:center;">
            <div style="color:#854d0e; font-size:0.75rem; text-transform:uppercase; font-weight:600;">🟡 Bajo</div>
            <div style="color:#713f12; font-size:1.4rem; font-weight:700;">{bajos}</div>
        </div>""", unsafe_allow_html=True)
    with col4:
        st.markdown(f"""
        <div style="background:#dcfce7; border-radius:10px; padding:0.6rem 1rem; text-align:center;">
            <div style="color:#166534; font-size:0.75rem; text-transform:uppercase; font-weight:600;">🟢 OK</div>
            <div style="color:#14532d; font-size:1.4rem; font-weight:700;">{ok}</div>
        </div>""", unsafe_allow_html=True)

    st.markdown("")

    col_filtro, col_orden = st.columns([2, 1])
    with col_filtro:
        filtro = st.selectbox(
            "Mostrar",
            ["Todos", "🔴 Solo críticos", "🟡 Solo bajos", "🟢 Solo OK"],
            key="stock_filtro"
        )
    with col_orden:
        orden = st.selectbox(
            "Ordenar por",
            ["Stock (menor primero)", "Stock (mayor primero)", "Nombre A-Z"],
            key="stock_orden"
        )

    if filtro == "🔴 Solo críticos":
        df = df[df["Stock_ml"] <= STOCK_CRITICO]
    elif filtro == "🟡 Solo bajos":
        df = df[(df["Stock_ml"] > STOCK_CRITICO) & (df["Stock_ml"] <= STOCK_BAJO)]
    elif filtro == "🟢 Solo OK":
        df = df[df["Stock_ml"] > STOCK_BAJO]

    if orden == "Stock (menor primero)":
        df = df.sort_values("Stock_ml", ascending=True)
    elif orden == "Stock (mayor primero)":
        df = df.sort_values("Stock_ml", ascending=False)
    else:
        df = df.sort_values("Nombre", ascending=True)

    st.markdown(f"**{len(df)} perfume(s)**")
    st.markdown("")

    max_stock = df["Stock_ml"].max() if not df.empty else 100

    for row in df.to_dict("records"):
        nombre = html.escape(str(row.get("Nombre", "")))
        marca = html.escape(str(row.get("Marca", "")))
        stock = row.get("Stock_ml", 0)
        badge = stock_badge_html(stock, size="sm")
        pct = min(100, int((float(stock) / max(max_stock, 1)) * 100))

        if stock <= STOCK_CRITICO:
            bar_color = "#ef4444"
        elif stock <= STOCK_BAJO:
            bar_color = "#eab308"
        else:
            bar_color = "#22c55e"

        st.markdown(f"""
        <div style="background:white; border:1px solid #f0e0d0; border-radius:12px;
            padding:0.8rem 1.2rem; margin-bottom:0.5rem;">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.4rem;">
                <div>
                    <span style="font-size:0.72rem; color:#a07850; text-transform:uppercase;
                        font-weight:600; margin-right:6px;">{marca}</span>
                    <span style="font-size:1rem; color:#2c1a0e; font-weight:600;">🌸 {nombre}</span>
                </div>
                <div>{badge}</div>
            </div>
            <div style="background:#f0e0d0; border-radius:4px; height:6px; overflow:hidden;">
                <div style="width:{pct}%; height:100%; background:{bar_color};
                    border-radius:4px;"></div>
            </div>
        </div>
        """, unsafe_allow_html=True)