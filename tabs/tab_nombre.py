import html
from pathlib import Path
import streamlit as st
from components import mostrar_placeholder_vacio
from config import PRECIOS_COLUMNAS, fmt_precio, stock_badge_html, stock_barra_html
from errores import mostrar_sin_precio


def _mostrar_todos_precios(perfume, precios_columnas):
    if hasattr(perfume, "to_dict"):
        perfume = perfume.to_dict()

    st.markdown("#### 💰 Precios por tamaño")
    cols = st.columns(len(precios_columnas))

    for i, (tamanio, columna) in enumerate(precios_columnas.items()):
        precio = perfume.get(columna, "")
        tamanio_safe = html.escape(str(tamanio))

        with cols[i]:
            if precio not in (0, "", None):
                st.markdown(
                    f'<div style="'
                    f'background:#ffffff; border:1px solid #ede0d4; border-radius:12px;'
                    f'padding:1.1rem 0.7rem; text-align:center; margin-bottom:0.6rem;'
                    f'transition:border-color 0.2s ease;">'
                    f'<div style="color:#a07850; font-size:0.9rem; letter-spacing:0.2em;'
                    f'text-transform:uppercase; font-weight:600; margin-bottom:0.4rem;">{tamanio_safe}</div>'
                    f'<div style="width:20px; height:1px; background:#ede0d4; margin:0 auto 0.5rem;"></div>'
                    f'<div style="color:#2c1a0e; font-family:\'Inter\',\'DM Sans\',sans-serif;'
                    f'font-size:1.7rem; font-weight:700; line-height:1; letter-spacing:-0.03em;'
                    f'font-variant-numeric:tabular-nums;">'
                    f'S/ {fmt_precio(precio)}</div>'
                    f'</div>',
                    unsafe_allow_html=True
                )
            else:
                st.markdown(
                    f'<div style="background:#fdf6f0; border-radius:12px; padding:1rem 0.7rem;'
                    f'text-align:center; border:1px dashed #e0c9b4; margin-bottom:0.6rem;">'
                    f'<div style="color:#c8956c; font-size:0.9rem; letter-spacing:0.2em;'
                    f'text-transform:uppercase; margin-bottom:0.3rem;">{tamanio_safe}</div>'
                    f'<div style="color:#d4b896; font-size:0.8rem; font-style:italic;">sin precio</div>'
                    f'</div>',
                    unsafe_allow_html=True
                )


def mostrar_tab_nombre(df):
    busqueda = st.text_input("🔍 Buscar perfume", placeholder="Escribe parte del nombre...", key="nombre_buscar")
    nombre_seleccionado = None
    if busqueda:
        mask = (
            df["Nombre"].str.contains(busqueda, case=False, na=False, regex=False) |
            df["Marca"].str.contains(busqueda, case=False, na=False, regex=False)
        )
        nombres_filtrados = sorted(
            df[mask]["Nombre"].dropna().unique().tolist()
        )
        if not nombres_filtrados:
            st.caption("Sin resultados.")
        elif len(nombres_filtrados) == 1:
            nombre_seleccionado = nombres_filtrados[0]
            st.caption(f"✓ {nombre_seleccionado}")
        else:
            nombre_seleccionado = st.selectbox(
                "Seleccionar",
                nombres_filtrados,
                index=None,
                placeholder=f"— {len(nombres_filtrados)} coincidencias —",
                key="nombre_sel",
            )

    if nombre_seleccionado is not None:
        perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]
        url_imagen = str(perfume.get("URL_imagen", "")).strip()

        tiene_notas = "Notas" in df.columns
        tiene_perfil = "Perfil_Olfativo" in df.columns
        notas_txt = (
            html.escape(str(perfume.get("Notas", "")))
            if tiene_notas and perfume.get("Notas") else ""
        )
        perfil_txt = (
            html.escape(str(perfume.get("Perfil_Olfativo", "")))
            if tiene_perfil and perfume.get("Perfil_Olfativo") else ""
        )
        marca_safe = html.escape(str(perfume.get("Marca", "")))
        nombre_safe = html.escape(str(perfume.get("Nombre", "")))

        col_info, col_notas = st.columns([1, 1])

        with col_info:
            stock_val = perfume.get("Stock_ml", None)
            badge = stock_badge_html(stock_val, size="lg")
            barra = stock_barra_html(stock_val)
            stock_html = (
                f"<div style='margin-top:0.6rem;'>{badge}{barra}</div>"
                if badge else ""
            )

            st.markdown(f"""
            <div style="
                background: #ffffff;
                border: 1px solid #ede0d4;
                border-radius: 14px;
                padding: 1.4rem 1.8rem 1.6rem;
                height: 100%;
            ">
                <div style="
                    font-size:0.65rem; letter-spacing:0.22em;
                    text-transform:uppercase; color:#c8956c;
                    font-weight:600; margin-bottom:0.35rem;
                ">{marca_safe}</div>
                <div style="
                    font-family:'Playfair Display',serif;
                    font-size:1.55rem; color:#2c1a0e;
                    font-weight:600; letter-spacing:-0.02em; line-height:1.15;
                ">{nombre_safe}</div>
                {stock_html}
            </div>
            """, unsafe_allow_html=True)

        with col_notas:
            if notas_txt or perfil_txt:
                st.markdown(f"""
                <div style="
                    background: #fdf6f0;
                    border: 1px solid #ede0d4;
                    border-radius: 14px;
                    padding: 1.2rem 1.4rem;
                    height: 100%;
                    box-sizing: border-box;
                ">
                    {"<div style='color:#a07850; font-size:0.92rem; margin-bottom:0.5rem;'>🎵 <strong>Notas:</strong> " + notas_txt + "</div>" if notas_txt else ""}
                    {"<div style='color:#c8956c; font-size:0.92rem;'>✨ <strong>Perfil:</strong> " + perfil_txt + "</div>" if perfil_txt else ""}
                </div>
                """, unsafe_allow_html=True)

        if url_imagen:
            imagen_path = Path(__file__).parent.parent / url_imagen
            if imagen_path.exists():
                col_img, _ = st.columns([1, 2])
                with col_img:
                    st.image(str(imagen_path), width=220)
            else:
                st.caption("📷 Imagen no disponible")

        st.markdown("---")
        _mostrar_todos_precios(perfume, PRECIOS_COLUMNAS)

        sin_precios = [t for t, c in PRECIOS_COLUMNAS.items() if not perfume.get(c)]
        if len(sin_precios) == len(PRECIOS_COLUMNAS):
            mostrar_sin_precio(perfume["Nombre"], "ningún tamaño")

    else:
        mostrar_placeholder_vacio(
            "🔍",
            "Busca un perfume",
            "Escribe parte del nombre para ver precios y detalles",
        )