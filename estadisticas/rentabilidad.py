import html as _html
import streamlit as st
import pandas as pd
from config import fmt_precio, PRECIOS_COLUMNAS
from costos import costo_total_item
from components import separador


def _calcular_rentabilidad(df_ventas, df_catalogo):
    if df_ventas.empty or df_catalogo.empty:
        return pd.DataFrame()

    ventas = df_ventas[df_ventas.get("Estado", pd.Series(dtype=str)).ne("Anulado")].copy() \
        if "Estado" in df_ventas.columns else df_ventas.copy()

    try:
        ventas["Precio_Cobrado"] = pd.to_numeric(ventas["Precio_Cobrado"], errors="coerce").fillna(0)
        ventas["Ml_Vendido"] = pd.to_numeric(ventas["Ml_Vendido"], errors="coerce").fillna(0)
    except Exception:
        return pd.DataFrame()

    catalogo = df_catalogo.copy()
    catalogo["ID_Perfume"] = catalogo["ID_Perfume"].astype(str)
    ventas["ID_Perfume"] = ventas["ID_Perfume"].astype(str)

    merged = ventas.merge(
        catalogo[["ID_Perfume", "Marca", "Nombre", "Costo_Botella", "Ml_Botella"]],
        on="ID_Perfume", how="left"
    )

    filas = []
    for _, row in merged.iterrows():
        try:
            ml = int(row["Ml_Vendido"])
            precio = float(row["Precio_Cobrado"])
            cb = float(row.get("Costo_Botella") or 0)
            mb = float(row.get("Ml_Botella") or 0)
            costo = costo_total_item(ml, cb, mb)
            ganancia = precio - costo
            filas.append({
                "ID_Perfume": row["ID_Perfume"],
                "Marca": row.get("Marca", ""),
                "Nombre": row.get("Nombre", ""),
                "precio": precio,
                "costo": costo,
                "ganancia": ganancia,
                "ventas": 1,
            })
        except Exception:
            continue

    if not filas:
        return pd.DataFrame()

    df = pd.DataFrame(filas)
    agg = df.groupby(["ID_Perfume", "Marca", "Nombre"], as_index=False).agg(
        total_ventas=("ventas", "sum"),
        total_ingresos=("precio", "sum"),
        total_costo=("costo", "sum"),
        total_ganancia=("ganancia", "sum"),
    )
    agg["margen_pct"] = (agg["total_ganancia"] / agg["total_ingresos"] * 100).where(
        agg["total_ingresos"] > 0, 0
    ).round(1)
    return agg.sort_values("total_ganancia", ascending=False).reset_index(drop=True)


def _medalla(pos):
    return {0: "🥇", 1: "🥈", 2: "🥉"}.get(pos, f"{pos + 1}.")


def mostrar_rentabilidad(df_ventas, df_catalogo):
    separador("🏆 Ranking de Rentabilidad")

    if df_ventas.empty:
        st.info("📭 Sin ventas registradas aún.")
        return

    required = {"Costo_Botella", "Ml_Botella"}
    if not required.issubset(df_catalogo.columns):
        st.warning("⚠️ Agrega las columnas **Costo_Botella** y **Ml_Botella** en la hoja Catálogo para ver el ranking.")
        return

    df = _calcular_rentabilidad(df_ventas, df_catalogo)
    if df.empty:
        st.info("📭 No hay datos suficientes para calcular rentabilidad.")
        return

    col_orden, col_top = st.columns([2, 1])
    with col_orden:
        orden = st.radio(
            "Ordenar por",
            ["💰 Mayor ganancia total", "📈 Mayor margen %"],
            horizontal=True,
            label_visibility="collapsed",
            key="rent_orden",
        )
    with col_top:
        top_n = st.selectbox("Mostrar", [10, 20, 50, "Todos"], index=0, key="rent_top")

    if orden == "📈 Mayor margen %":
        df = df.sort_values("margen_pct", ascending=False).reset_index(drop=True)

    df_show = df if top_n == "Todos" else df.head(int(top_n))

    st.markdown("")
    for i, row in df_show.iterrows():
        marca_safe = _html.escape(str(row["Marca"]))
        nombre_safe = _html.escape(str(row["Nombre"]))
        ganancia = row["total_ganancia"]
        margen = row["margen_pct"]
        n_ventas = int(row["total_ventas"])
        ingresos = row["total_ingresos"]

        color_margen = "#16a34a" if margen >= 50 else "#ca8a04" if margen >= 35 else "#dc2626"
        medalla = _medalla(i)

        st.markdown(f"""
        <div style="background:white; border:1px solid #ede0d4; border-radius:14px;
            padding:0.8rem 1rem; margin-bottom:0.5rem;
            display:flex; align-items:center; gap:0.8rem;">
            <div style="font-size:1.4rem; min-width:2rem; text-align:center;">{medalla}</div>
            <div style="flex:1; min-width:0;">
                <div style="font-size:0.62rem; letter-spacing:0.2em; text-transform:uppercase;
                    color:#c8956c; font-weight:700;">{marca_safe}</div>
                <div style="font-family:'Playfair Display',serif; font-size:1rem;
                    color:#1e1209; font-weight:600; line-height:1.2;">{nombre_safe}</div>
                <div style="font-size:0.72rem; color:#8b6640; margin-top:0.15rem;">
                    {n_ventas} venta{"s" if n_ventas != 1 else ""} · S/ {fmt_precio(ingresos)} ingresados
                </div>
            </div>
            <div style="text-align:right; white-space:nowrap;">
                <div style="font-family:'Inter',sans-serif; font-size:1.25rem;
                    font-weight:800; color:#2c1a0e;">S/ {fmt_precio(ganancia)}</div>
                <div style="font-size:0.72rem; font-weight:700; color:{color_margen};
                    letter-spacing:0.05em;">{margen:.1f}% margen</div>
            </div>
        </div>""", unsafe_allow_html=True)

    st.markdown("")
    total_gan = df["total_ganancia"].sum()
    total_ing = df["total_ingresos"].sum()
    margen_global = (total_gan / total_ing * 100) if total_ing > 0 else 0
    c1, c2, c3 = st.columns(3)
    with c1:
        st.metric("Ganancia total", f"S/ {fmt_precio(total_gan)}")
    with c2:
        st.metric("Ingresos totales", f"S/ {fmt_precio(total_ing)}")
    with c3:
        st.metric("Margen global", f"{margen_global:.1f}%")
