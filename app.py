import streamlit as st
from config import PRECIOS_COLUMNAS
from styles import get_styles
from data import cargar_catalogo, guardar_venta
from components import (
    mostrar_encabezado,
    mostrar_perfume_card,
    mostrar_todos_precios
)
from errores import (
    mostrar_error_conexion,
    mostrar_error_datos_vacios,
    mostrar_sin_precio,
    mostrar_error_columna,
    validar_dataframe
)

st.set_page_config(page_title="Perfumes 🌸", page_icon="🌸", layout="centered")
st.markdown("""
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
""", unsafe_allow_html=True)
st.markdown(get_styles(), unsafe_allow_html=True)
mostrar_encabezado()

try:
    df = cargar_catalogo()

    if df.empty:
        mostrar_error_datos_vacios()
        st.stop()

    columnas_faltantes = validar_dataframe(df)
    if columnas_faltantes:
        for col in columnas_faltantes:
            mostrar_error_columna(col)
        st.stop()

    tab1, tab2, tab3 = st.tabs(["🏷️  Por Marca", "🔍  Por Nombre", "📝  Nueva Venta"])

    # ── Pestaña 1: Por Marca ──────────────────────────────
    with tab1:
        col1, col2 = st.columns(2)
        with col1:
            marcas = ["— Elige una marca —"] + sorted(df["Marca"].unique().tolist())
            marca_seleccionada = st.selectbox("Marca", marcas, key="marca")
        with col2:
            tamanio1 = st.selectbox("Tamaño", list(PRECIOS_COLUMNAS.keys()), key="tamanio1")

        if marca_seleccionada != "— Elige una marca —":
            df_filtrado = df[df["Marca"] == marca_seleccionada]
            columna1 = PRECIOS_COLUMNAS[tamanio1]

            st.markdown("---")
            st.markdown(f"**✨ {len(df_filtrado)} perfume(s) — precios para {tamanio1}**")
            st.markdown("")

            for _, row in df_filtrado.iterrows():
                precio = row[columna1]
                col_nombre, col_precio = st.columns([4, 2])
                with col_nombre:
                    st.markdown(f"🌸 **{row['Nombre']}**")
                with col_precio:
                    if precio:
                        st.markdown(f"**S/ {precio}**")
                    else:
                        st.markdown("*Sin precio*")
                st.divider()
        else:
            st.markdown("")
            st.info("👆 Selecciona una marca para ver sus perfumes")

    # ── Pestaña 2: Por Nombre ─────────────────────────────
    with tab2:
        nombres = ["— Elige un perfume —"] + sorted(df["Nombre"].unique().tolist())
        nombre_seleccionado = st.selectbox("Perfume", nombres, key="nombre")

        if nombre_seleccionado != "— Elige un perfume —":
            perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]
            url_imagen = str(perfume.get("URL_imagen", "")).strip()
            mostrar_perfume_card(perfume["Marca"], perfume["Nombre"], url_imagen)

            st.markdown("---")
            mostrar_todos_precios(perfume, PRECIOS_COLUMNAS)

            for tamanio, columna in PRECIOS_COLUMNAS.items():
                if not perfume.get(columna):
                    mostrar_sin_precio(perfume["Nombre"], tamanio)
        else:
            st.markdown("")
            st.info("👆 Selecciona un perfume para ver sus precios")

        # ── Pestaña 3: Nueva Venta ────────────────────────────
        with tab3:
            st.markdown("### 📝 Registrar Nueva Venta")
            st.markdown("---")

            # ── Inicializar cesta en session_state ────────────
            if "cesta" not in st.session_state:
                st.session_state.cesta = []
            if "comprador_actual" not in st.session_state:
                st.session_state.comprador_actual = ""
            if "celular_actual" not in st.session_state:
                st.session_state.celular_actual = ""
            if "fecha_actual" not in st.session_state:
                st.session_state.fecha_actual = None

            # ── Datos del comprador ───────────────────────────
            st.markdown("#### 👤 Datos del Comprador")
            col1, col2, col3 = st.columns(3)
            with col1:
                fecha = st.date_input("📅 Fecha", key="fecha_venta")
            with col2:
                comprador = st.text_input("👤 Comprador",
                                          placeholder="Nombre del comprador",
                                          key="comprador_input")
            with col3:
                celular = st.text_input("📱 Celular",
                                        placeholder="Ej: 999888777",
                                        max_chars=9,
                                        key="celular_input")

            st.markdown("---")

            # ── Agregar item a la cesta ───────────────────────
            st.markdown("#### 🛒 Agregar Perfume")
            col1, col2, col3 = st.columns(3)
            with col1:
                nombres_catalogo = sorted(df["Nombre"].unique().tolist())
                perfume_venta = st.selectbox("🌸 Perfume", nombres_catalogo, key="perfume_venta")
            with col2:
                ml_vendido = st.selectbox("📏 ML", [2, 5, 10], key="ml_venta")
            with col3:
                metodo_pago = st.selectbox("💳 Pago", [
                    "Efectivo", "Yape", "Plin", "Transferencia", "Tarjeta"
                ], key="metodo_venta")

            # Precio automático
            perfume_row = df[df["Nombre"] == perfume_venta].iloc[0]
            id_perfume = perfume_row["ID_Perfume"]
            columna_precio = f"Precio_{ml_vendido}ml"
            precio_item = perfume_row.get(columna_precio, 0)

            if precio_item:
                st.markdown(f"""
                <div style="
                    background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
                    border-radius: 10px; padding: 0.8rem;
                    text-align: center; margin: 0.5rem 0;
                ">
                    <div style="color:#e8c9a8; font-size:0.75rem; text-transform:uppercase;">Precio</div>
                    <div style="color:white; font-size:1.5rem; font-weight:700;">S/ {precio_item}</div>
                    <div style="color:#c8956c; font-size:0.75rem;">{perfume_venta} — {ml_vendido}ml</div>
                </div>
                """, unsafe_allow_html=True)
            else:
                st.warning(f"⚠️ Sin precio para {ml_vendido}ml")

            if st.button("➕ Agregar a cesta", use_container_width=True, disabled=not precio_item):
                if not comprador:
                    st.error("❌ Ingresa el nombre del comprador primero")
                elif len(celular) != 9 or not celular.isdigit():
                    st.error("❌ El celular debe tener exactamente 9 números")
                else:
                    st.session_state.cesta.append({
                        "perfume": perfume_venta,
                        "id_perfume": id_perfume,
                        "ml": ml_vendido,
                        "precio": precio_item,
                        "metodo": metodo_pago
                    })
                    st.success(f"✅ {perfume_venta} agregado a la cesta")

            # ── Mostrar cesta ─────────────────────────────────
            if st.session_state.cesta:
                st.markdown("---")
                st.markdown("#### 🛍️ Cesta actual")

                total = 0
                for i, item in enumerate(st.session_state.cesta):
                    col1, col2, col3, col4 = st.columns([3, 1, 1, 1])
                    with col1:
                        st.markdown(f"🌸 **{item['perfume']}**")
                    with col2:
                        st.markdown(f"{item['ml']}ml")
                    with col3:
                        st.markdown(f"**S/ {item['precio']}**")
                    with col4:
                        if st.button("🗑️", key=f"del_{i}"):
                            st.session_state.cesta.pop(i)
                            st.rerun()
                    total += float(item['precio'])

                st.markdown("---")
                st.markdown(f"""
                <div style="
                    background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
                    border-radius: 12px; padding: 1rem;
                    text-align: center; margin: 0.5rem 0;
                ">
                    <div style="color:#e8c9a8; font-size:0.8rem; text-transform:uppercase;">Total a cobrar</div>
                    <div style="color:white; font-family:'Playfair Display',serif; font-size:2.5rem; font-weight:700;">S/ {total:.1f}</div>
                    <div style="color:#c8956c; font-size:0.8rem;">{len(st.session_state.cesta)} item(s)</div>
                </div>
                """, unsafe_allow_html=True)

                st.markdown("")
                if st.button("✅ Guardar Venta Completa", use_container_width=True, type="primary"):
                    if not comprador:
                        st.error("❌ El nombre del comprador es obligatorio")
                    elif len(celular) != 9 or not celular.isdigit():
                        st.error("❌ El celular debe tener exactamente 9 números")
                    else:
                        try:
                            from data import obtener_ultimo_id_compra

                            id_compra = obtener_ultimo_id_compra()
                            for item in st.session_state.cesta:
                                guardar_venta([
                                    id_compra,
                                    str(fecha),
                                    comprador,
                                    celular,
                                    str(item["id_perfume"]),
                                    str(item["ml"]),
                                    str(item["precio"]),
                                    item["metodo"]
                                ])
                            st.success(
                                f"✅ Venta **{id_compra}** guardada — {len(st.session_state.cesta)} item(s) para {comprador}")
                            st.balloons()
                            st.session_state.cesta = []
                        except Exception as e:
                            st.error(f"❌ No se pudo guardar: {e}")
            else:
                st.markdown("")
                st.info("🛒 La cesta está vacía — agrega perfumes arriba")

except Exception as e:
    mostrar_error_conexion()
    with st.expander("🔍 Ver detalle del error"):
        st.code(str(e))