import html
from pathlib import Path
import streamlit as st
from components import mostrar_placeholder_vacio, notas_pills_html
from config import PRECIOS_COLUMNAS, fmt_precio, stock_badge_html, stock_barra_html
from errores import mostrar_sin_precio
from costos import costo_total_item


def _mostrar_todos_precios(perfume, precios_columnas):
    if hasattr(perfume, "to_dict"):
        perfume = perfume.to_dict()

    st.markdown(
        '<div style="font-size:0.68rem; letter-spacing:0.2em; text-transform:uppercase;'
        'color:var(--c-text-muted); font-weight:700; margin:1.2rem 0 0.7rem;">Precios por tamaño</div>',
        unsafe_allow_html=True
    )
    cols = st.columns(len(precios_columnas))

    try:
        cb = float(perfume.get("Costo_Botella") or 0)
        mb = float(perfume.get("Ml_Botella") or 0)
    except (TypeError, ValueError):
        cb, mb = 0.0, 0.0

    for i, (tamanio, columna) in enumerate(precios_columnas.items()):
        precio = perfume.get(columna, "")
        tamanio_safe = html.escape(str(tamanio))

        with cols[i]:
            if precio not in (0, "", None):
                try:
                    ml = int(tamanio.replace(" ml", ""))
                    costo_est = costo_total_item(ml, cb, mb)
                    gan = float(precio) - costo_est
                    margen = (gan / float(precio) * 100) if float(precio) > 0 else 0
                    margen_html = (
                        f'<div style="text-align:center; margin-top:0.4rem; font-size:0.65rem;'
                        f'font-weight:700; letter-spacing:0.14em; text-transform:uppercase;'
                        f'color:#16a34a; line-height:1.4;">'
                        f'💰 {margen:.0f}% margen</div>'
                    )
                except Exception:
                    margen_html = ""
                st.markdown(
                    f'<div class="precio-box">'
                    f'<div class="label">{tamanio_safe}</div>'
                    f'<div class="separador-box"></div>'
                    f'<div class="valor"><span class="moneda">S/</span>{fmt_precio(precio)}</div>'
                    f'</div>'
                    f'{margen_html}',
                    unsafe_allow_html=True
                )
            else:
                st.markdown(
                    f'<div class="precio-box sin-precio-box">'
                    f'<div class="label">{tamanio_safe}</div>'
                    f'<div class="separador-box"></div>'
                    f'<div style="color:var(--c-text-faint); font-size:0.82rem; font-style:italic; margin-top:0.3rem;">sin precio</div>'
                    f'</div>',
                    unsafe_allow_html=True
                )


@st.fragment
def mostrar_tab_nombre(df):
    busqueda = st.text_input("🔍 Buscar perfume", placeholder="Escribe parte del nombre...", key="nombre_buscar")
    nombre_seleccionado = None
    if busqueda:
        t = busqueda.lower()
        if "Nombre_lower" in df.columns:
            mask = (
                df["Nombre_lower"].str.contains(t, na=False, regex=False) |
                df["Marca_lower"].str.contains(t, na=False, regex=False)
            )
        else:
            mask = (
                df["Nombre"].str.contains(t, case=False, na=False, regex=False) |
                df["Marca"].str.contains(t, case=False, na=False, regex=False)
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
        _matches = df[df["Nombre"] == nombre_seleccionado]
        if _matches.empty:
            st.warning("⚠️ El perfume ya no está en el catálogo. Recarga los datos.")
            return
        perfume = _matches.iloc[0]
        url_imagen = str(perfume.get("URL_imagen", "")).strip()

        tiene_notas = "Notas" in df.columns
        tiene_perfil = "Perfil_Olfativo" in df.columns
        tiene_ocasion = "ocasion" in df.columns
        tiene_estacion = "estacion" in df.columns
        tiene_hora = "hora" in df.columns
        tiene_palabras = "palabra_clave" in df.columns

        def _campo_valido(v):
            return bool(v) and str(v).strip().lower() not in ("", "nan", "none")

        notas_txt = (
            html.escape(str(perfume.get("Notas", "")))
            if tiene_notas and _campo_valido(perfume.get("Notas")) else ""
        )
        perfil_txt = (
            html.escape(str(perfume.get("Perfil_Olfativo", "")))
            if tiene_perfil and _campo_valido(perfume.get("Perfil_Olfativo")) else ""
        )
        ocasion_txt = perfume.get("ocasion", "") if tiene_ocasion else ""
        estacion_txt = perfume.get("estacion", "") if tiene_estacion else ""
        hora_txt = perfume.get("hora", "") if tiene_hora else ""
        palabras_txt = perfume.get("palabra_clave", "") if tiene_palabras else ""

        marca_safe = html.escape(str(perfume.get("Marca", "")))
        nombre_safe = html.escape(str(perfume.get("Nombre", "")))

        stock_val = perfume.get("Stock_ml", None)
        badge = stock_badge_html(stock_val, size="lg")
        barra = stock_barra_html(stock_val)
        stock_html = f"<div style='margin-top:0.7rem;'>{badge}{barra}</div>" if badge else ""

        notas_seccion = (
            f"<div style='font-size:0.68rem; letter-spacing:0.18em; text-transform:uppercase;"
            f"color:var(--c-primary-light); font-weight:700; margin-bottom:0.25rem;'>Notas</div>"
            f"{notas_pills_html(perfume.get('Notas', ''))}"
            if notas_txt else ""
        )
        perfil_seccion = (
            f"<div style='font-size:0.68rem; letter-spacing:0.18em; text-transform:uppercase;"
            f"color:var(--c-gold); font-weight:700; margin:0.55rem 0 0.2rem;'>Perfil olfativo</div>"
            f"{notas_pills_html(perfume.get('Perfil_Olfativo', ''), color_bg='#fdf8ee', color_border='#e8d5a8', color_text='#7a6020')}"
            if perfil_txt else ""
        )
        _lbl = "font-size:0.65rem; letter-spacing:0.15em; text-transform:uppercase; font-weight:700; margin-bottom:0.1rem;"
        _extras = []
        if _campo_valido(ocasion_txt):
            _extras.append((f"<div style='{_lbl} color:#4a7a5a;'>Ocasión</div>", notas_pills_html(ocasion_txt, color_bg='#eef4f0', color_border='#a8c8b8', color_text='#2a5a3a')))
        if _campo_valido(estacion_txt):
            _extras.append((f"<div style='{_lbl} color:#4a5a8a;'>Estación</div>", notas_pills_html(estacion_txt, color_bg='#eceef8', color_border='#b0b8d8', color_text='#2a3a6a')))
        if _campo_valido(hora_txt):
            _extras.append((f"<div style='{_lbl} color:#7a4a8a;'>Hora</div>", notas_pills_html(hora_txt, color_bg='#f4eef8', color_border='#c8b0d8', color_text='#5a2a7a')))
        if _campo_valido(palabras_txt):
            _extras.append((f"<div style='{_lbl} color:#6a5a4a;'>Palabras clave</div>", notas_pills_html(palabras_txt, color_bg='#f4f0ec', color_border='#c8b8a8', color_text='#4a3a2a')))

        if _extras:
            _cells = "".join(
                f"<div style='min-width:0;'>{lbl}{pills}</div>"
                for lbl, pills in _extras
            )
            extras_seccion = (
                f"<div style='margin-top:0.5rem; padding-top:0.45rem; border-top:1px solid #f0e4d8;"
                f"display:grid; grid-template-columns:1fr 1fr; gap:0.25rem 0.8rem;'>{_cells}</div>"
            )
        else:
            extras_seccion = ""

        tiene_imagen = False
        imagen_path = None
        if url_imagen:
            imagen_path = Path(__file__).parent.parent / url_imagen
            tiene_imagen = imagen_path.exists()

        hay_extra = bool(notas_txt or perfil_txt or extras_seccion)

        if tiene_imagen:
            st.image(str(imagen_path), use_container_width=True)
            st.markdown(f"""
            <div style="background:var(--c-bg-card); border:1px solid var(--c-border-light);
                border-left:3px solid var(--c-primary-light); border-radius:var(--radius-lg);
                padding:1.3rem 1.6rem 1.5rem; box-sizing:border-box; margin-top:0.5rem;">
                <div style="font-size:0.63rem; letter-spacing:0.26em; text-transform:uppercase;
                    color:var(--c-primary-light); font-weight:700; margin-bottom:0.3rem;">{marca_safe}</div>
                <div style="font-family:'Playfair Display',serif; font-size:1.65rem;
                    color:var(--c-text); font-weight:600; letter-spacing:-0.02em; line-height:1.15;">{nombre_safe}</div>
                {stock_html}
                {'<hr style="border:none;border-top:1px solid var(--c-border-light);margin:0.8rem 0;">' if hay_extra else ""}
                {notas_seccion}{perfil_seccion}{extras_seccion}
            </div>
            """, unsafe_allow_html=True)
        else:
            st.markdown(f"""
            <div style="background:var(--c-bg-card); border:1px solid var(--c-border-light);
                border-left:3px solid var(--c-primary-light); border-radius:var(--radius-lg);
                padding:1.3rem 1.6rem 1.5rem;">
                <div style="font-size:0.63rem; letter-spacing:0.26em; text-transform:uppercase;
                    color:var(--c-primary-light); font-weight:700; margin-bottom:0.3rem;">{marca_safe}</div>
                <div style="font-family:'Playfair Display',serif; font-size:1.65rem;
                    color:var(--c-text); font-weight:600; letter-spacing:-0.02em; line-height:1.15;">{nombre_safe}</div>
                {stock_html}
            </div>
            """, unsafe_allow_html=True)
            if hay_extra:
                st.markdown(f"""
                <div style="background:linear-gradient(160deg,#fff9f5,#fdf3eb);
                    border:1px solid var(--c-border-light); border-radius:var(--radius-lg);
                    padding:1.2rem 1.4rem; margin-top:0.5rem; box-sizing:border-box;">
                    {notas_seccion}{perfil_seccion}{extras_seccion}
                </div>
                """, unsafe_allow_html=True)

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