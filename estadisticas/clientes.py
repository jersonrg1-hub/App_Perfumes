import streamlit as st
import pandas as pd
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

    resumen = _calcular_resumen_clientes(df)

    top = resumen.iloc[0] if not resumen.empty else None
    prom = resumen["Total_Gastado"].mean() if not resumen.empty else 0
    top_nombre = top["Nombre"] if top is not None else "—"

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

    st.markdown(f"**{len(df_mostrar)} cliente(s) encontrado(s)**")
    st.markdown("")

    catalogo_dict = {}
    if df_catalogo is not None:
        catalogo_dict = dict(
            zip(df_catalogo["ID_Perfume"].astype(str), df_catalogo["Nombre"])
        )

    def get_nombre_perfume(id_perfume):
        return catalogo_dict.get(str(id_perfume), f"ID: {id_perfume}")

    for _, cliente in df_mostrar.iterrows():
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
            col1, col2 = st.columns(2)
            with col1:
                st.markdown(
                    f"<span style='color:{badge_color}; font-weight:600'>{badge}</span>",
                    unsafe_allow_html=True
                )
                st.write(f"📱 **Celular:** {celular}")
                st.write(f"🛍️ **Compras:** {n_compras} pedidos / {n_items} items")
            with col2:
                st.write(f"💰 **Total gastado:** S/ {fmt_precio(total_gastado)}")
                st.write(f"📅 **Primera compra:** {primera}")
                st.write(f"📅 **Última compra:** {ultima}")

            st.markdown("---")
            st.markdown("**🧾 Historial de pedidos:**")

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

                st.markdown(
                    f"**{estado_icon} {id_compra}** — {fecha_pedido} — "
                    f"S/ {fmt_precio(total_pedido)} — {primera_fila.get('Tipo_Envio', '')} — "
                    f"{primera_fila.get('Metodo_Pago', '')}"
                )

                for _, item in grupo.iterrows():
                    nombre_perfume = get_nombre_perfume(item.get("ID_Perfume", ""))
                    st.markdown(
                        f"&nbsp;&nbsp;&nbsp;&nbsp;🌸 {nombre_perfume} "
                        f"— {item.get('Ml_Vendido', '')}ml "
                        f"— S/ {fmt_precio(item.get('Precio_Cobrado', 0))}",
                        unsafe_allow_html=True
                    )

            st.markdown("")
            wa_url = f"https://wa.me/51{celular}"
            st.markdown(
                f"""<a href="{wa_url}" target="_blank" style="text-decoration:none;">
                <div style="background:#25D366; color:white; padding:10px; border-radius:8px;
                text-align:center; font-weight:600; font-size:0.9rem;">
                    📲 Escribir por WhatsApp
                </div></a>""",
                unsafe_allow_html=True
            )
