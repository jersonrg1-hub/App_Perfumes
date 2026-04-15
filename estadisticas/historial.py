import streamlit as st
import pandas as pd

from components import separador
from config import fmt_precio, fmt_fecha

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

    df_filtrado = entregadas.copy()

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

    separador()

    if grupos is None or grupos.ngroups == 0:
        st.info("😔 No hay ventas que coincidan con los filtros")
        return

    catalogo_dict = {}
    if df_catalogo is not None:
        catalogo_dict = dict(
            zip(df_catalogo["ID_Perfume"].astype(str), df_catalogo["Nombre"])
        )

    def get_nombre_perfume(id_perfume):
        return catalogo_dict.get(str(id_perfume), f"ID: {id_perfume}")

    orden_ids = (
        df_filtrado.groupby("ID_Compra")["Fecha"]
        .max()
        .sort_values(ascending=False)
        .index.tolist()
    )

    for id_compra in orden_ids:
        grupo = df_filtrado[df_filtrado["ID_Compra"] == id_compra]
        primera = grupo.iloc[0]
        total_compra = grupo["Precio_Cobrado"].sum()
        fecha_str = fmt_fecha(primera.get("Fecha", "")) if pd.notna(primera.get("Fecha")) else "—"

        with st.expander(
            f"✅ {id_compra} — {primera.get('Comprador', '')} | "
            f"{fecha_str} | S/ {fmt_precio(total_compra)}"
        ):
            col1, col2 = st.columns(2)
            with col1:
                st.write(f"📅 **Fecha:** {fecha_str}")
                st.write(f"📱 **Celular:** {primera.get('Celular', '')}")
                st.write(f"🚚 **Envío:** {primera.get('Tipo_Envio', '')}")
            with col2:
                st.write(f"📍 **Dirección:** {primera.get('Direccion', '')}")
                st.write(f"💳 **Pago:** {primera.get('Metodo_Pago', '')}")
                st.write(f"📦 **Estado:** ✅ Entregado")

            st.markdown("**🛍️ Productos:**")
            for item in grupo.to_dict("records"):
                nombre = get_nombre_perfume(item.get("ID_Perfume", ""))
                st.markdown(
                    f"- 🌸 **{nombre}** — "
                    f"{item.get('Ml_Vendido', '')}ml "
                    f"| S/ {fmt_precio(item.get('Precio_Cobrado', 0))}"
                )