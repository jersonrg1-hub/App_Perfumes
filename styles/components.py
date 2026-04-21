COMPONENTS = """
/* ══════════════════════════════════════
   TARJETA DE PERFUME (lista en tab_marca)
══════════════════════════════════════ */
.perfume-card {
    background: var(--c-bg-card);
    border: 1px solid var(--c-border-light);
    border-left: 3px solid var(--c-primary-light);
    border-radius: var(--radius-lg);
    padding: 1rem 1.4rem 1rem 1.2rem;
    margin-bottom: 0.65rem;
    box-shadow: var(--shadow-xs);
    transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease,
                border-left-color 0.25s ease, background 0.25s ease;
    cursor: default;
    position: relative;
}

.perfume-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(200, 149, 108, 0.15);
    border-color: var(--c-primary-pale);
    border-left-color: var(--c-primary);
    background: linear-gradient(160deg, #fffaf7 0%, #fdf4ed 100%);
}

.perfume-card .marca {
    font-size: 0.65rem;
    letter-spacing: 0.24em;
    text-transform: uppercase;
    color: var(--c-primary-light);
    font-weight: 700;
    margin-bottom: 0.3rem;
    font-family: 'Lato', sans-serif;
}

.perfume-card .nombre {
    font-family: 'Playfair Display', serif;
    font-size: 1.15rem;
    color: var(--c-text);
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.2;
}

/* ── Chips de precio en tarjeta ── */
.precio-chip {
    background: var(--c-bg);
    border: 1px solid var(--c-border-light);
    border-radius: 14px;
    padding: 0.55rem 0.5rem 0.5rem;
    display: flex;
    flex-direction: column;
    align-items: center;
    flex: 1;
    min-width: 0;
    transition: border-color 0.2s ease, background 0.2s ease, transform 0.15s ease, box-shadow 0.2s ease;
}

.precio-chip:hover {
    border-color: var(--c-primary-light);
    background: var(--c-primary-pale);
    transform: translateY(-2px);
    box-shadow: var(--shadow-sm);
}

.precio-chip .chip-label {
    color: var(--c-text-muted);
    font-size: 0.65rem;
    text-transform: uppercase;
    font-weight: 700;
    letter-spacing: 0.14em;
    line-height: 1.4;
    margin-bottom: 0.15rem;
}

.precio-chip .chip-valor {
    color: var(--c-text);
    font-family: 'Inter', sans-serif;
    font-size: 1.15rem;
    font-weight: 800;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
    line-height: 1.2;
    letter-spacing: -0.02em;
}

.precio-chip .chip-valor.sin-precio {
    color: var(--c-text-faint);
    font-size: 0.85rem;
    font-style: italic;
    font-weight: 400;
}

/* ══════════════════════════════════════
   CAJA DE PRECIO GRANDE (tab_nombre)
══════════════════════════════════════ */
.precio-box {
    background: linear-gradient(160deg, #ffffff 0%, #fdf6f0 100%);
    border: 1px solid var(--c-border-light);
    border-radius: var(--radius-lg);
    padding: 1.6rem 1.2rem;
    text-align: center;
    margin: 1rem 0;
    transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
    box-shadow: var(--shadow-xs);
}

.precio-box:hover {
    transform: translateY(-3px);
    border-color: var(--c-primary-light);
    box-shadow: var(--shadow-sm);
}

.precio-box .label {
    color: var(--c-text-muted);
    font-size: 0.82rem;
    letter-spacing: 0.22em;
    text-transform: uppercase;
    margin-bottom: 0.5rem;
    font-weight: 700;
}

.precio-box .separador-box {
    width: 24px;
    height: 1.5px;
    background: linear-gradient(to right, transparent, var(--c-gold), transparent);
    margin: 0 auto 0.55rem;
}

.precio-box .valor {
    color: var(--c-text);
    font-family: 'Inter', sans-serif;
    font-size: 2.6rem;
    font-weight: 800;
    line-height: 1;
    font-variant-numeric: tabular-nums;
    letter-spacing: -0.03em;
}

.precio-box .moneda {
    color: var(--c-primary-light);
    font-size: 1.1rem;
    font-weight: 600;
    vertical-align: super;
    margin-right: 2px;
}

.precio-box .tamanio {
    color: var(--c-text-faint);
    font-size: 0.8rem;
    margin-top: 0.5rem;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    font-weight: 600;
}

.precio-box.sin-precio-box {
    background: var(--c-bg) !important;
    border-style: dashed !important;
    opacity: 0.7;
}

/* ══════════════════════════════════════
   ÍTEM DE CESTA (wizard de venta)
══════════════════════════════════════ */
.perfume-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.85rem 1.2rem;
    border-radius: var(--radius-md);
    margin-bottom: 0.5rem;
    background: var(--c-bg-card);
    border: 1px solid var(--c-border-light);
    border-left: 3px solid var(--c-primary-pale);
    transition: all 0.2s ease;
}

.perfume-item:hover {
    border-left-color: var(--c-primary-light);
    transform: translateY(-1px);
    box-shadow: var(--shadow-sm);
}

.perfume-item .pf-nombre {
    color: var(--c-text);
    font-weight: 600;
    font-size: 0.95rem;
}

.perfume-item .pf-precio {
    color: var(--c-primary);
    font-weight: 700;
    font-size: 1.05rem;
    font-family: 'Playfair Display', serif;
}

.sin-precio {
    color: var(--c-text-faint);
    font-size: 0.85rem;
    font-style: italic;
}

.divider {
    border: none;
    border-top: 1px solid var(--c-border-light);
    margin: 1.5rem 0;
}

/* Botón secundario — outlined sutil */
.stButton button {
    border-radius: 10px !important;
    font-family: 'Lato', sans-serif !important;
    font-weight: 600 !important;
    transition: all 0.18s ease !important;
    background-color: transparent !important;
    color: #2c1a0e !important;
    border: 1.5px solid #d4b896 !important;
}

.stButton button p,
.stButton button span {
    color: #2c1a0e !important;
    font-weight: 600 !important;
}

.stButton button:hover {
    background-color: #f5e6d8 !important;
    border-color: #c8956c !important;
    transform: translateY(-1px) !important;
    box-shadow: 0 4px 14px rgba(200, 149, 108, 0.2) !important;
}

.stButton button:active {
    transform: scale(0.97) !important;
    background-color: #fdf0e8 !important;
}

/* Botón primario — terracota */
.stButton button[kind="primary"] {
    background: linear-gradient(135deg, #c8956c 0%, #b8845c 100%) !important;
    color: white !important;
    border: none !important;
}

.stButton button[kind="primary"] p,
.stButton button[kind="primary"] span {
    color: white !important;
    font-weight: 600 !important;
}

.stButton button[kind="primary"]:hover {
    background: linear-gradient(135deg, #b8845c 0%, #a8744c 100%) !important;
    transform: translateY(-2px) !important;
    box-shadow: 0 6px 20px rgba(200, 149, 108, 0.35) !important;
}

[data-testid="stExpanderHeader"] {
    background: #f5e6d8 !important;
    border-radius: 10px !important;
    color: #2c1a0e !important;
    font-family: 'Lato', sans-serif !important;
    font-weight: 600 !important;
    transition: background 0.18s ease !important;
}

[data-testid="stExpanderHeader"]:hover {
    background: #ead5c0 !important;
}

[data-testid="stExpanderHeader"] p,
[data-testid="stExpanderHeader"] span,
[data-testid="stExpanderHeader"] div {
    color: #2c1a0e !important;
}

[data-testid="stExpanderDetails"] {
    background: white !important;
    padding: 1rem !important;
    border: 1px solid #e8d5c4 !important;
    border-top: none !important;
    border-radius: 0 0 12px 12px !important;
}

[data-testid="stExpanderDetails"] p,
[data-testid="stExpanderDetails"] strong,
[data-testid="stExpanderDetails"] li {
    color: #2c1a0e !important;
}

.stMultiSelect > div > div,
.stMultiSelect [data-baseweb="select"] {
    background-color: #ffffff !important;
    border-color: #e0c9b4 !important;
    min-height: 48px !important;
    border-radius: 8px !important;
}

.stMultiSelect [data-baseweb="tag"],
.stMultiSelect span[data-baseweb="tag"] {
    background-color: #2c1a0e !important;
    color: white !important;
    border-radius: 6px !important;
}

.stMultiSelect [data-baseweb="tag"] *,
.stMultiSelect span[data-baseweb="tag"] span {
    color: white !important;
    background-color: transparent !important;
}

div[data-testid="stAlert"] {
    border-radius: 12px !important;
    border: none !important;
    padding: 1rem 1.2rem !important;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important;
}

.stWarning {
    background: linear-gradient(135deg, #fffbeb, #fef3c7) !important;
    border-left: 4px solid #d69e2e !important;
}
.stWarning p, .stWarning strong { color: #744210 !important; font-size: 0.95rem !important; }

.stInfo {
    background: linear-gradient(135deg, #ebf8ff, #bee3f8) !important;
    border-left: 4px solid #3182ce !important;
}
.stInfo p { color: #2c5282 !important; font-size: 0.95rem !important; }

.stSuccess {
    background: linear-gradient(135deg, #ecfdf5, #d1fae5) !important;
    border-left: 4px solid #059669 !important;
}

.stSuccess p,
.stSuccess strong,
.stSuccess span {
    color: #064e3b !important;
}

.stSuccess p, .stSuccess strong, .stSuccess span {
    color: #0f3d22 !important;
    font-size: 0.95rem !important;
    font-weight: 700 !important;
}

.stError {
    background: linear-gradient(135deg, #fff5f5, #fed7d7) !important;
    border-left: 4px solid #e53e3e !important;
}
.stError p { color: #742a2a !important; font-size: 0.95rem !important; }

[data-testid="stStatusWidget"] {
    border-radius: 12px !important;
    border-color: #c8956c !important;
    background: #fffaf7 !important;
    font-family: 'Lato', sans-serif !important;
}

@media (max-width: 640px) {
    .titulo-app { font-size: 2rem; }
    .precio-box .valor { font-size: 2.2rem; }
    .perfume-card .nombre { font-size: 1.2rem; }
    .perfume-item { padding: 0.7rem 0.9rem; }
}

/* ── Skeleton loader (efecto shimmer mientras carga) ── */
@keyframes shimmer {
    0%   { background-position: -400px 0; }
    100% { background-position: 400px 0; }
}

.skeleton {
    background: linear-gradient(90deg, #f5ede6 25%, #ede0d4 50%, #f5ede6 75%);
    background-size: 800px 100%;
    animation: shimmer 1.4s ease-in-out infinite;
    border-radius: 8px;
    height: 18px;
    margin-bottom: 0.4rem;
}

/* ── Fade entre tabs ── */
.stTabs [data-baseweb="tab-panel"] {
    animation: fadeIn 0.3s ease-out !important;
}

/* ── Hover en expanders más suave ── */
[data-testid="stExpanderHeader"] {
    transition: background 0.2s ease, transform 0.15s ease !important;
}
[data-testid="stExpanderHeader"]:hover {
    transform: translateX(2px) !important;
}

/* ── Inputs: transición en focus ── */
.stTextInput input,
.stNumberInput input,
.stDateInput input {

    border: 1px solid #e0c9b4 !important;
    border-radius: 8px !important;
}

/* ── Selectbox: transición ── */
div[data-baseweb="select"] {
    transition: border-color 0.2s ease, box-shadow 0.2s ease !important;
}

/* ── Botones de formulario (form_submit_button) ── */
.stFormSubmitButton > button {
    background: linear-gradient(135deg, #c8956c 0%, #b8845c 100%) !important;
    color: white !important;
    border: none !important;
    border-radius: 10px !important;
    font-weight: 600 !important;
    font-size: 0.95rem !important;
    min-height: 48px !important;
    transition: transform 0.18s ease, box-shadow 0.18s ease !important;
}

.stFormSubmitButton > button p,
.stFormSubmitButton > button span,
.stFormSubmitButton > button div {
    color: white !important;
    font-weight: 600 !important;
}

.stFormSubmitButton > button:hover {
    background: linear-gradient(135deg, #b8845c 0%, #a8744c 100%) !important;
    transform: translateY(-1px) !important;
    box-shadow: 0 4px 14px rgba(200, 149, 108, 0.3) !important;
}

/* ── Forzar color blanco en botones HTML dentro de links ── */
.stMarkdown a div,
.stMarkdown a div span,
.stMarkdown a div p {
    color: white !important;
    text-decoration: none !important;
}

.stMarkdown a {
    text-decoration: none !important;
}

/* ===== FIX INPUT UX ===== */

.stTextInput input,
.stNumberInput input,
.stDateInput input,
textarea {
    caret-color: #2c1a0e !important;
    border: 1px solid #e0c9b4 !important;
    border-radius: 8px !important;
    padding: 10px 12px !important;
}

.stTextInput input:focus,
.stNumberInput input:focus,
.stDateInput input:focus,
textarea:focus {
    border-color: #c8956c !important;
    box-shadow: 0 0 0 2px rgba(200,149,108,0.25) !important;
    outline: none !important;
}

/* ===== FIX BOTON WHATSAPP ===== */

.stMarkdown a {
    color: white !important;
    text-decoration: none !important;
}

.stMarkdown a:visited {
    color: white !important;
}

.stMarkdown a:hover {
    color: white !important;
}

.stMarkdown a:active {
    color: white !important;
}

.stMarkdown a[href*="wa.me"] {
    display: block;
    background: #25D366;
    padding: 10px;
    border-radius: 10px;
    text-align: center;
    font-weight: 600;
    transition: transform 0.15s ease, filter 0.15s ease;
}

.stMarkdown a[href*="wa.me"]:hover {
    filter: brightness(0.92);
    transform: translateY(-1px);
}
"""