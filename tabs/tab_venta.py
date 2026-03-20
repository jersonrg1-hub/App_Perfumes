import streamlit as st
from config import PRECIOS_COLUMNAS, ML_OPCIONES, METODOS_PAGO, TIPOS_ENVIO
from data import guardar_venta, obtener_ultimo_id_compra
from components import generar_url_whatsapp

def mostrar_tab_venta(df):
    st.markdown("### 📝 Registrar Nueva Venta")
    st.markdown("---")

    if "cesta" not in st.session_state:
        st.session_state.cesta = []

    # ── Datos del comprador ───────────────────────────────
    st.markdown("#### 👤 Datos del Comprador")

    col_fecha, col_envio = st.columns(2)
    with col_fecha:
        fecha = st.date_input("📅 Fecha", key="fecha_venta")
    with col_envio:
        tipo_envio = st.selectbox("🚚 Tipo de Envío", TIPOS_ENVIO, key="tipo_envio")

    col_comp, col_cel = st.columns(2)
    with col_comp:
        comprador = st.text_input("👤 Comprador",
            placeholder="Nombre del comprador",
            key="comprador_input")
    with col_cel:
        celular = st.text_input("📱 Celular",
            placeholder="Ej: 999888777",
            max_chars=9,
            key="celular_input")

    direccion = st.text_input("📍 Dirección",
        placeholder="Ej: Av. Lima 123, Miraflores",
        key="direccion_input")

    st.markdown("---")

    # ── Agregar perfume ───────────────────────────────────
    st.markdown("#### 🛒 Agregar Perfume")

    nombres_opciones = ["— Elige un perfume —"] + sorted(df["Nombre"].unique().tolist())
    perfume_venta = st.selectbox("🌸 Perfume", nombres_opciones, key="perfume_venta")

    col_ml, col_pago = st.columns(2)
    with col_ml:
        ml_vendido = st.selectbox("📏 ML", ML_OPCIONES, key="ml_venta")
    with col_pago:
        metodo_pago = st.selectbox("💳 Método de Pago", METODOS_PAGO, key="metodo_venta")

    # ── Precio automático ─────────────────────────────────
    if perfume_venta != "— Elige un perfume —":
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
    else:
        st.info("👆 Elige un perfume para ver el precio")

    # ── Cesta actual ──────────────────────────────────────
    if st.session_state.cesta:
        st.markdown("---")
        st.markdown("#### 🛍️ Cesta actual")

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

        total = sum(float(i['precio']) for i in st.session_state.cesta)

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
                    id_compra = obtener_ultimo_id_compra()
                    for item in st.session_state.cesta:
                        guardar_venta([
                            id_compra, str(fecha), comprador, celular,
                            str(item["id_perfume"]), str(item["ml"]),
                            str(item["precio"]), item["metodo"],
                            tipo_envio, direccion, "Pendiente"
                        ])

                    url_whatsapp = generar_url_whatsapp(
                        id_compra, comprador, celular,
                        direccion, tipo_envio,
                        st.session_state.cesta, total
                    )

                    st.success(f"✅ Venta **{id_compra}** guardada — {len(st.session_state.cesta)} item(s) para {comprador}")
                    st.markdown(f"""
                    <a href="{url_whatsapp}" target="_blank" style="
                        display: block; background: #25D366;
                        color: white; text-align: center;
                        padding: 0.8rem; border-radius: 10px;
                        text-decoration: none; font-weight: 700;
                        margin-top: 0.5rem;
                    ">📲 Compartir por WhatsApp</a>
                    """, unsafe_allow_html=True)
                    st.balloons()
                    st.session_state.cesta = []
                except Exception as e:
                    st.error(f"❌ No se pudo guardar: {e}")
    else:
        st.markdown("")
        st.info("🛒 La cesta está vacía — agrega perfumes arriba")