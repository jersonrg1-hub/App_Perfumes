import html
import streamlit as st
import pandas as pd

from components import separador, construir_catalogo_dict, nombre_por_id
from config import fmt_precio, fmt_fecha
from costos import construir_costo_ml_dict, costo_por_item, COSTO_VIAL, COSTO_EMPAQUE, calcular_costo_ventas_df


def _card_hist(titulo, valor, color="#c8956c"):
    t = html.escape(str(titulo))
    v = html.escape(str(valor))
    return f"""
    <div style="background:white; border-radius:12px; padding:1rem;
        text-align:center; border:1px solid #ede0d4;
        border-top:3px solid {color};
        box-shadow:0 2px 8px rgba(200,149,108,0.08);">
        <div style="color:#a07850; font-size:0.68rem; text-transform:uppercase;
            font-weight:600; letter-spacing:0.1em; margin-bottom:0.3rem;">{t}</div>
        <div style="color:{color}; font-size:1.5rem; font-weight:700;
            font-family:Inter,sans-serif;
            font-variant-numeric:tabular-nums;
            white-space:nowrap;">{v}</div>
    </div>
    """


def _mostrar_resumen_total(entregadas, df_catalogo):
    st.markdown("#### 📈 Resumen histórico total")

    total_compras = entregadas["ID_Compra"].nunique() if "ID_Compra" in entregadas.columns else len(entregadas)
    total_facturado = float(entregadas["Precio_Cobrado"].sum()) if "Precio_Cobrado" in entregadas.columns else 0.0
    total_costo = calcular_costo_ventas_df(entregadas, df_catalogo)
    total_ganancia = total_facturado - total_costo
    ticket_prom = total_facturado / total_compras if total_compras > 0 else 0.0
    total_ml = int(pd.to_numeric(entregadas.get("Ml_Vendido", pd.Series(dtype=float)), errors="coerce").fillna(0).sum())
    margen = (total_ganancia / total_facturado * 100) if total_facturado > 0 else 0.0

    mejor_mes = "—"
    if "Fecha" in entregadas.columns and "Precio_Cobrado" in entregadas.columns:
        fechas_ok = entregadas["Fecha"].dropna()
        if not fechas_ok.empty:
            por_mes = entregadas.loc[fechas_ok.index].groupby(
                entregadas.loc[fechas_ok.index, "Fecha"].dt.to_period("M")
            )["Precio_Cobrado"].sum()
            if not por_mes.empty:
                mejor_mes = str(por_mes.idxmax())

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.markdown(_card_hist("Total compras", total_compras), unsafe_allow_html=True)
    with col2:
        st.markdown(_card_hist("Total facturado", f"S/ {fmt_precio(total_facturado)}"), unsafe_allow_html=True)
    with col3:
        st.markdown(_card_hist("Total costo", f"S/ {fmt_precio(total_costo)}"), unsafe_allow_html=True)
    with col4:
        st.markdown(_card_hist("Total ganancia", f"S/ {fmt_precio(total_ganancia)}", color="#16a34a"), unsafe_allow_html=True)

    st.markdown("")
    col5, col6, col7, col8 = st.columns(4)
    with col5:
        st.markdown(_card_hist("Ticket promedio", f"S/ {fmt_precio(ticket_prom)}"), unsafe_allow_html=True)
    with col6:
        st.markdown(_card_hist("Total ml vendidos", f"{total_ml} ml"), unsafe_allow_html=True)
    with col7:
        st.markdown(_card_hist("Margen promedio", f"{margen:.1f}%"), unsafe_allow_html=True)
    with col8:
        st.markdown(_card_hist("Mejor mes", mejor_mes), unsafe_allow_html=True)

    st.markdown("")

def mostrar_historial_ventas(df_ventas, df_catalogo=None):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    if "Estado" not in df_ventas.columns:
        st.warning("⚠️ Agrega la columna Estado en tu Sheets")
        return

    entregadas = df_ventas[df_ventas["Estado"] == "Entregado"].copy()

    if entregadas.empty:
        st.info("📭 No hay ventas entregadas todavía")
        return

    if entregadas["Fecha"].dtype == object:
        entregadas["Fecha"] = pd.to_datetime(
            entregadas["Fecha"].astype(str).str.strip(), errors="coerce"
        )

    _mostrar_resumen_total(entregadas, df_catalogo)
    separador()

    col1, col2, col3 = st.columns(3)

    with col1:
        buscar = st.text_input("🔍 Buscar comprador", placeholder="Nombre...", key="hist_buscar")
    with col2:
        fechas_disponibles = sorted(
            entregadas["Fecha"].dropna().dt.to_period("M").unique().tolist(),
            reverse=True
        )
        opciones_mes = ["Todos los meses"] + [str(m) for m in fechas_disponibles]
        mes_filtro = st.selectbox("📅 Mes", opciones_mes, key="hist_mes")
    with col3:
        metodos = ["Todos"] + sorted(entregadas["Metodo_Pago"].dropna().unique().tolist()) \
            if "Metodo_Pago" in entregadas.columns else ["Todos"]
        metodo_filtro = st.selectbox("💳 Pago", metodos, key="hist_pago")

    df_filtrado = entregadas

    if buscar:
        df_filtrado = df_filtrado[
            df_filtrado["Comprador"].astype(str).str.lower().str.contains(buscar.lower(), na=False, regex=False)
        ]

    if mes_filtro != "Todos los meses":
        periodo = pd.Period(mes_filtro, freq="M")
        fecha_valida = df_filtrado["Fecha"].notna()
        df_filtrado = df_filtrado[
            fecha_valida &
            (df_filtrado.loc[fecha_valida, "Fecha"].dt.to_period("M") == periodo)
        ]

    if metodo_filtro != "Todos" and "Metodo_Pago" in df_filtrado.columns:
        df_filtrado = df_filtrado[df_filtrado["Metodo_Pago"] == metodo_filtro]

    total_filtrado = df_filtrado["Precio_Cobrado"].sum() \
        if "Precio_Cobrado" in df_filtrado.columns else 0
    grupos = df_filtrado.groupby("ID_Compra") if "ID_Compra" in df_filtrado.columns else None

    st.markdown("")
    col_a, col_b = st.columns(2)
    with col_a:
        n_compras = grupos.ngroups if grupos else 0
        st.markdown(f"**{n_compras} compra(s) entregada(s)**")
    with col_b:
        st.markdown(f"**Total: S/ {fmt_precio(total_filtrado)}**")
    costo_ml_dict = construir_costo_ml_dict(df_catalogo)

    separador()

    if grupos is None or grupos.ngroups == 0:
        st.info("😔 No hay ventas que coincidan con los filtros")
        return

    catalogo_dict = construir_catalogo_dict(df_catalogo)

    orden_ids = (
        df_filtrado.groupby("ID_Compra")["Fecha"]
        .max()
        .sort_values(ascending=False)
        .index.tolist()
    )

    _PAGE = 20
    _key = f"hist_pag_{buscar}_{mes_filtro}_{metodo_filtro}"
    if st.session_state.get("_hist_filtro_prev") != _key:
        st.session_state["_hist_filtro_prev"] = _key
        st.session_state["hist_mostrados"] = _PAGE
    mostrados = st.session_state.get("hist_mostrados", _PAGE)
    ids_pagina = orden_ids[:mostrados]

    for id_compra in ids_pagina:
        grupo = df_filtrado[df_filtrado["ID_Compra"] == id_compra]
        primera = grupo.iloc[0]
        total_compra = grupo["Precio_Cobrado"].sum()
        fecha_str = fmt_fecha(primera.get("Fecha", "")) if pd.notna(primera.get("Fecha")) else "—"

        # Calcular ganancia total de la compra (vectorizado)
        ganancia_compra = None
        try:
            ml_s = pd.to_numeric(grupo["Ml_Vendido"], errors="coerce").fillna(0).astype(int)
            costo_perf_s = grupo["ID_Perfume"].astype(str).map(costo_ml_dict).fillna(0.0) * ml_s
            costo_vial_s = ml_s.map(COSTO_VIAL).fillna(0.0)
            costo_compra = float((costo_perf_s + costo_vial_s + (ml_s > 0).astype(float) * COSTO_EMPAQUE).sum())
            ganancia_compra = total_compra - costo_compra
        except Exception:
            pass

        gan_header = f" | 💰 gan. S/ {fmt_precio(ganancia_compra)}" if ganancia_compra is not None else ""

        with st.expander(
            f"✅ {id_compra} — {primera.get('Comprador', '')} | "
            f"{fecha_str} | S/ {fmt_precio(total_compra)}{gan_header}"
        ):
            celular_h  = html.escape(str(primera.get("Celular", "")))
            envio_h    = html.escape(str(primera.get("Tipo_Envio", "")))
            dir_h      = html.escape(str(primera.get("Direccion", "") or "—"))
            pago_h     = html.escape(str(primera.get("Metodo_Pago", "")))
            comp_h     = html.escape(str(primera.get("Comprador", "")))

            st.markdown(
                f"""<div style="background:#fdf6f0;border:1px solid #ede0d4;border-radius:12px;
                    padding:0.85rem 1.1rem;margin-bottom:0.6rem;
                    display:grid;grid-template-columns:1fr 1fr;gap:0.45rem;
                    font-size:0.88rem;color:#2c1a0e;">
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">👤 Comprador</span>
                        <br><strong>{comp_h}</strong></div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">📱 Celular</span>
                        <br><strong>{celular_h}</strong></div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">📅 Fecha</span>
                        <br><strong>{fecha_str}</strong></div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">💳 Pago</span>
                        <br><strong>{pago_h}</strong></div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">🚚 Envío</span>
                        <br><strong>{envio_h}</strong></div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">📍 Dirección</span>
                        <br><strong>{dir_h}</strong></div>
                </div>""",
                unsafe_allow_html=True,
            )

            st.markdown(
                "<div style='font-size:0.68rem;color:#a07850;text-transform:uppercase;"
                "font-weight:700;letter-spacing:0.12em;padding-bottom:0.35rem;"
                "border-bottom:1px solid #ede0d4;margin-bottom:0.4rem;'>🛍️ Productos</div>",
                unsafe_allow_html=True,
            )
            items_rows = []
            for item in grupo.to_dict("records"):
                nombre = html.escape(str(nombre_por_id(catalogo_dict, item.get("ID_Perfume", ""))))
                precio_cob = float(item.get("Precio_Cobrado", 0))
                gan_html = ""
                try:
                    ml = int(item.get("Ml_Vendido", 0))
                    costo_ml = costo_ml_dict.get(str(item.get("ID_Perfume", "")), 0.0)
                    costo_est = costo_por_item(ml) + costo_ml * ml
                    gan = precio_cob - costo_est
                    gan_html = (
                        f"<span style='font-size:0.75rem;color:#16a34a;font-weight:600;"
                        f"margin-left:0.5rem;'>+S/ {fmt_precio(gan)}</span>"
                    )
                except Exception:
                    pass
                items_rows.append(
                    f"<div style='display:flex;justify-content:space-between;align-items:center;"
                    f"padding:0.35rem 0;border-bottom:1px solid #f5ede6;font-size:0.88rem;'>"
                    f"<span style='color:#2c1a0e;font-weight:500;'>"
                    f"🌸 {nombre} · {item.get('Ml_Vendido','')}ml</span>"
                    f"<span style='display:flex;align-items:center;gap:0.3rem;'>"
                    f"<span style='font-weight:700;color:#c8956c;font-family:Inter,sans-serif;"
                    f"font-variant-numeric:tabular-nums;'>S/ {fmt_precio(precio_cob)}</span>"
                    f"{gan_html}</span></div>"
                )
            total_gan_html = ""
            if ganancia_compra is not None:
                total_gan_html = (
                    f"<span style='color:#16a34a;font-weight:700;font-family:Inter,sans-serif;"
                    f"font-variant-numeric:tabular-nums;margin-left:0.8rem;'>"
                    f"💰 S/ {fmt_precio(ganancia_compra)}</span>"
                )
            st.markdown(
                f"<div style='background:white;border:1px solid #ede0d4;border-radius:10px;"
                f"padding:0.6rem 1rem;margin-bottom:0.4rem;'>"
                f"{''.join(items_rows)}"
                f"<div style='display:flex;justify-content:flex-end;align-items:center;"
                f"margin-top:0.5rem;padding-top:0.4rem;border-top:1px solid #ede0d4;'>"
                f"<span style='font-size:0.8rem;color:#a07850;font-weight:600;'>"
                f"Total</span>"
                f"<span style='font-weight:800;color:#2c1a0e;font-family:Inter,sans-serif;"
                f"font-variant-numeric:tabular-nums;margin-left:0.5rem;'>"
                f"S/ {fmt_precio(total_compra)}</span>"
                f"{total_gan_html}</div></div>",
                unsafe_allow_html=True,
            )

    if mostrados < len(orden_ids):
        restantes = len(orden_ids) - mostrados
        if st.button(f"Ver más ({restantes} restantes)", key="hist_ver_mas"):
            st.session_state["hist_mostrados"] = mostrados + _PAGE
            st.rerun()