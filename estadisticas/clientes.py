import html
import streamlit as st
import pandas as pd
from components import construir_catalogo_dict, nombre_por_id
from config import fmt_precio, fmt_fecha


@st.cache_data(ttl=120)
def _calcular_resumen_clientes(df_ventas):
    """Agrupa ventas por cliente. Cacheado para no recalcular en cada render."""
    resumen = (
        df_ventas.groupby("Celular")
        .agg(
            Nombre=("Comprador", "first"),
            Total_Compras=("ID_Compra", "nunique"),
            Total_Items=("ID_Compra", "count"),
            Total_Gastado=("Precio_Cobrado", "sum"),
            Primera_Compra=("Fecha", "min"),
            Ultima_Compra=("Fecha", "max"),
        )
        .reset_index()
        .sort_values("Total_Gastado", ascending=False)
    )
    return resumen


def mostrar_clientes_frecuentes(df_ventas, df_catalogo=None):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    cols_necesarias = ["Comprador", "Celular", "Precio_Cobrado", "ID_Compra"]
    if not all(c in df_ventas.columns for c in cols_necesarias):
        st.warning("⚠️ Faltan columnas necesarias en la hoja de ventas")
        return

    df = df_ventas.copy()
    if df["Fecha"].dtype == object:
        df["Fecha"] = pd.to_datetime(df["Fecha"].astype(str).str.strip(), errors="coerce")

    resumen = _calcular_resumen_clientes(
        df[["Celular", "Comprador", "ID_Compra", "Precio_Cobrado", "Fecha"]]
    )

    top = resumen.iloc[0] if not resumen.empty else None
    prom = resumen["Total_Gastado"].mean() if not resumen.empty else 0

    top_nombre = html.escape(str(top["Nombre"])) if top is not None else "—"

    st.markdown(f"""
    <div style="display:flex; gap:1rem; flex-wrap:wrap; margin-bottom:0.5rem;">
        <div style="background:#f5ede6; border-radius:10px; padding:0.6rem 1rem; flex:1; min-width:120px; text-align:center;">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase; font-weight:600;">Total clientes</div>
            <div style="color:#2c1a0e; font-size:1.4rem; font-weight:700;">{len(resumen)}</div>
        </div>
        <div style="background:#f5ede6; border-radius:10px; padding:0.6rem 1rem; flex:2; min-width:160px; text-align:center;">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase; font-weight:600;">Cliente top</div>
            <div style="color:#2c1a0e; font-size:1.4rem; font-weight:700;">{top_nombre}</div>
        </div>
        <div style="background:#f5ede6; border-radius:10px; padding:0.6rem 1rem; flex:1; min-width:140px; text-align:center;">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase; font-weight:600;">Gasto promedio</div>
            <div style="color:#2c1a0e; font-size:1.4rem; font-weight:700;">S/ {fmt_precio(prom)}</div>
        </div>
    </div>
    <hr style="margin:0.4rem 0 0.5rem 0; border-color:#f0e0d0;">
    """, unsafe_allow_html=True)

    buscar = st.text_input(
        "🔍 Buscar cliente", placeholder="Nombre o celular...", key="cli_buscar"
    )

    df_mostrar = resumen.copy()
    if buscar:
        df_mostrar = df_mostrar[
            df_mostrar["Nombre"].astype(str).str.lower().str.contains(buscar.lower(), na=False) |
            df_mostrar["Celular"].astype(str).str.contains(buscar, na=False)
        ]

    if df_mostrar.empty:
        st.info("😔 No se encontró ningún cliente")
        return

    n_cl = len(df_mostrar)
    s = "s" if n_cl != 1 else ""
    st.markdown(
        f"<div style='font-size:0.68rem;color:#a07850;text-transform:uppercase;"
        f"font-weight:700;letter-spacing:0.12em;padding-bottom:0.35rem;"
        f"border-bottom:1px solid #ede0d4;margin-bottom:0.6rem;'>"
        f"👥 {n_cl} cliente{s}</div>",
        unsafe_allow_html=True,
    )

    catalogo_dict = construir_catalogo_dict(df_catalogo)

    for cliente in df_mostrar.to_dict("records"):
        celular = str(cliente["Celular"])
        nombre = cliente["Nombre"]
        total_gastado = cliente["Total_Gastado"]
        n_compras = int(cliente["Total_Compras"])
        n_items = int(cliente["Total_Items"])
        primera = fmt_fecha(cliente["Primera_Compra"]) if pd.notna(cliente["Primera_Compra"]) else "—"
        ultima = fmt_fecha(cliente["Ultima_Compra"]) if pd.notna(cliente["Ultima_Compra"]) else "—"

        if n_compras >= 5:
            badge = "⭐ Cliente VIP"
            badge_color = "#c8956c"
        elif n_compras >= 3:
            badge = "🔁 Cliente frecuente"
            badge_color = "#a07850"
        else:
            badge = "🆕 Cliente nuevo"
            badge_color = "#888"

        with st.expander(
            f"👤 {nombre} — {celular} | S/ {fmt_precio(total_gastado)} | {n_compras} compra(s)"
        ):
            nombre_esc = html.escape(str(nombre))
            celular_esc = html.escape(str(celular))
            st.markdown(
                f"""<div style="background:#fdf6f0;border:1px solid #ede0d4;border-radius:12px;
                    padding:0.85rem 1.1rem;margin-bottom:0.6rem;
                    display:grid;grid-template-columns:1fr 1fr;gap:0.45rem;
                    font-size:0.88rem;color:#2c1a0e;">
                    <div style="grid-column:1/-1;margin-bottom:0.2rem;">
                        <span style="background:{badge_color};color:white;border-radius:20px;
                        padding:0.15rem 0.65rem;font-size:0.72rem;font-weight:700;
                        letter-spacing:0.06em;">{badge}</span>
                    </div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">📱 Celular</span>
                        <br><strong>{celular_esc}</strong></div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">💰 Total gastado</span>
                        <br><strong style="color:#c8956c;font-family:Inter,sans-serif;
                        font-variant-numeric:tabular-nums;">S/ {fmt_precio(total_gastado)}</strong></div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">🛍️ Pedidos</span>
                        <br><strong>{n_compras} compra{"s" if n_compras != 1 else ""} · {n_items} items</strong></div>
                    <div><span style="color:#a07850;font-size:0.68rem;text-transform:uppercase;
                        font-weight:700;letter-spacing:0.08em;">📅 Primera / Última</span>
                        <br><strong>{primera}</strong>
                        <span style="color:#a07850;"> → </span>
                        <strong>{ultima}</strong></div>
                </div>""",
                unsafe_allow_html=True,
            )

            st.markdown(
                "<div style='font-size:0.68rem;color:#a07850;text-transform:uppercase;"
                "font-weight:700;letter-spacing:0.12em;padding-bottom:0.35rem;"
                "border-bottom:1px solid #ede0d4;margin-bottom:0.5rem;'>🧾 Historial de pedidos</div>",
                unsafe_allow_html=True,
            )

            pedidos_cliente = df[df["Celular"].astype(str) == celular]
            orden = (
                pedidos_cliente.groupby("ID_Compra")["Fecha"]
                .max()
                .sort_values(ascending=False)
                .index.tolist()
            )

            for id_compra in orden:
                grupo = pedidos_cliente[pedidos_cliente["ID_Compra"] == id_compra]
                primera_fila = grupo.iloc[0]
                total_pedido = grupo["Precio_Cobrado"].sum()
                fecha_pedido = fmt_fecha(primera_fila["Fecha"]) if pd.notna(primera_fila.get("Fecha")) else "—"
                estado = primera_fila.get("Estado", "—")
                estado_icon = "✅" if estado == "Entregado" else "📦"
                items_html = "".join([
                    f"<div style='display:flex;justify-content:space-between;"
                    f"padding:0.25rem 0;border-bottom:1px solid #f5ede6;font-size:0.82rem;'>"
                    f"<span style='color:#2c1a0e;'>🌸 {html.escape(str(nombre_por_id(catalogo_dict, it.get('ID_Perfume',''))))}"
                    f" · {it.get('Ml_Vendido','')}ml</span>"
                    f"<span style='color:#c8956c;font-weight:700;font-family:Inter,sans-serif;"
                    f"font-variant-numeric:tabular-nums;'>S/ {fmt_precio(it.get('Precio_Cobrado',0))}</span>"
                    f"</div>"
                    for it in grupo.to_dict("records")
                ])
                st.markdown(
                    f"<div style='background:white;border:1px solid #ede0d4;border-radius:10px;"
                    f"padding:0.55rem 0.9rem;margin-bottom:0.4rem;'>"
                    f"<div style='display:flex;justify-content:space-between;align-items:center;"
                    f"margin-bottom:0.3rem;'>"
                    f"<span style='font-weight:700;color:#2c1a0e;font-size:0.88rem;'>"
                    f"{estado_icon} {html.escape(str(id_compra))}</span>"
                    f"<span style='font-size:0.78rem;color:#a07850;'>{fecha_pedido} · "
                    f"{html.escape(str(primera_fila.get('Tipo_Envio','')))} · "
                    f"{html.escape(str(primera_fila.get('Metodo_Pago','')))}</span>"
                    f"<span style='font-weight:800;color:#c8956c;font-family:Inter,sans-serif;"
                    f"font-variant-numeric:tabular-nums;'>S/ {fmt_precio(total_pedido)}</span>"
                    f"</div>{items_html}</div>",
                    unsafe_allow_html=True,
                )

            wa_url = f"https://wa.me/51{celular}"
            st.markdown(
                f'<a href="{wa_url}" target="_blank" style="text-decoration:none;display:block;margin-top:0.6rem;">'
                f'<div style="background:#25D366;color:white;padding:11px;border-radius:10px;'
                f'text-align:center;font-weight:700;font-size:0.9rem;">'
                f'📲 Escribir a {nombre_esc} por WhatsApp</div></a>',
                unsafe_allow_html=True,
            )