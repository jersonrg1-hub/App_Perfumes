COMPONENTS = """
    /* ── TARJETA PERFUME ── */
    .perfume-card {
        background: linear-gradient(135deg, #fff8f3, #fdeee4);
        border-left: 4px solid #c8956c;
        border-radius: 12px;
        padding: 1.2rem 1.5rem;
        margin: 1rem 0;
        box-shadow: 0 2px 12px rgba(160, 120, 80, 0.12);
    }

    .perfume-card .marca {
        font-size: 0.8rem;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        color: #a07850;
        font-weight: 600;
        margin-bottom: 0.2rem;
    }

    .perfume-card .nombre {
        font-family: 'Playfair Display', serif;
        font-size: 1.4rem;
        color: #2c1a0e;
        font-weight: 600;
    }

    /* ── PRECIO BOX ── */
    .precio-box {
        background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
        border-radius: 16px;
        padding: 1.8rem;
        text-align: center;
        margin: 1.5rem 0;
        box-shadow: 0 4px 20px rgba(44, 26, 14, 0.25);
    }

    .precio-box .label {
        color: #e8c9a8;
        font-size: 0.8rem;
        letter-spacing: 0.18em;
        text-transform: uppercase;
        margin-bottom: 0.4rem;
        font-weight: 300;
    }

    .precio-box .valor {
        color: #ffffff;
        font-family: 'Playfair Display', serif;
        font-size: 3rem;
        font-weight: 700;
        line-height: 1;
    }

    .precio-box .tamanio {
        color: #c8956c;
        font-size: 0.85rem;
        margin-top: 0.5rem;
        letter-spacing: 0.1em;
    }

    /* ── LISTA PERFUMES ── */
    .perfume-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 0.8rem 1rem;
        border-radius: 8px;
        margin-bottom: 0.5rem;
        background: white;
        border: 1px solid #f0e0d0;
        transition: all 0.2s;
    }

    .perfume-item:hover {
        background: #fff3eb;
        border-color: #c8956c;
    }

    .perfume-item .pf-nombre {
        color: #2c1a0e;
        font-weight: 600;
        font-size: 0.95rem;
    }

    .perfume-item .pf-precio {
        color: #c8956c;
        font-weight: 700;
        font-size: 1rem;
        font-family: 'Playfair Display', serif;
    }

    .sin-precio {
        color: #bbb;
        font-size: 0.85rem;
        font-style: italic;
    }

    .divider {
        border: none;
        border-top: 1px solid #e8d5c4;
        margin: 1.5rem 0;
    }

    .contador {
        font-size: 0.8rem;
        color: #a07850;
        margin-bottom: 1rem;
        font-style: italic;
    }
    
    /* ── BOTONES ── */
    .stButton button {
        background-color: #2c1a0e !important;
        color: white !important;
        border: none !important;
        border-radius: 8px !important;
        font-weight: 600 !important;
        transition: all 0.2s ease !important;
    }

    .stButton button:hover {
        background-color: #5c3a1e !important;
        color: white !important;
        transform: translateY(-1px) !important;
        box-shadow: 0 4px 12px rgba(44, 26, 14, 0.3) !important;
    }

    .stButton button:active {
        transform: translateY(0) !important;
        background-color: #1a0f08 !important;
    }

    /* Botón primario (Guardar Venta) */
    .stButton button[kind="primary"] {
        background-color: #c8956c !important;
    }

    .stButton button[kind="primary"]:hover {
        background-color: #a07850 !important;
    }

    /* Botón WhatsApp */
    a[href*="wa.me"]:hover {
        opacity: 0.85 !important;
        transform: translateY(-1px) !important;
    }

    /* Botón Marcar entregado */
    .stExpander .stButton button {
        background-color: #2c1a0e !important;
    }

    .stExpander .stButton button:hover {
        background-color: #5c3a1e !important;
        color: white !important;
    }
    
    /* ── EXPANDER ── */
    .stExpander {
        border: 1px solid #e8d5c4 !important;
        border-radius: 12px !important;
        background: white !important;
    }

    .stExpander summary {
        background: #2c1a0e !important;
        border-radius: 10px !important;
        color: white !important;
    }

    .stExpander summary span,
    .stExpander summary p {
        color: white !important;
    }

    .stExpander summary:hover {
        background: #5c3a1e !important;
    }

    /* Contenido dentro del expander */
    .stExpander [data-testid="stExpanderDetails"] {
        background: white !important;
        padding: 1rem !important;
    }

    .stExpander [data-testid="stExpanderDetails"] p,
    .stExpander [data-testid="stExpanderDetails"] strong {
        color: #2c1a0e !important;
    }
    
    /* ── BOTÓN MARCAR ENTREGADO ── */
    .stExpander .stButton button {
        background-color: #2c1a0e !important;
        color: white !important;
    }

    .stExpander .stButton button p,
    .stExpander .stButton button span {
        color: white !important;
    }

    .stExpander .stButton button:hover {
        background-color: #5c3a1e !important;
        color: white !important;
    }
    
    /* Texto productos en expander */
    .stExpander [data-testid="stExpanderDetails"] li,
    .stExpander [data-testid="stExpanderDetails"] ul {
        color: #2c1a0e !important;
    }
    
    /* ── MULTISELECT ── */
    .stMultiSelect [data-baseweb="select"] {
        background-color: #ffffff !important;
        border-color: #e0c9b4 !important;
        min-height: 48px !important;
    }

    .stMultiSelect [data-baseweb="select"] span,
    .stMultiSelect [data-baseweb="select"] div {
        color: #2c1a0e !important;
        background-color: #ffffff !important;
        font-size: 1rem !important;
    }

    /* Tags seleccionados */
    .stMultiSelect [data-baseweb="tag"] {
        background-color: #2c1a0e !important;
        color: white !important;
    }

    .stMultiSelect [data-baseweb="tag"] span {
        color: white !important;
        background-color: transparent !important;
    }
    
    /* ── MULTISELECT ── */
    .stMultiSelect > div > div {
        background-color: #ffffff !important;
        border-color: #e0c9b4 !important;
    }

    /* Texto del placeholder */
    .stMultiSelect input {
        color: #2c1a0e !important;
    }

    /* Tags/chips seleccionados */
    .stMultiSelect span[data-baseweb="tag"] {
        background-color: #2c1a0e !important;
        color: white !important;
    }

    .stMultiSelect span[data-baseweb="tag"] span {
        color: white !important;
    }

    .stMultiSelect [data-baseweb="tag"] {
        background-color: #2c1a0e !important;
    }

    .stMultiSelect [data-baseweb="tag"] * {
        color: white !important;
        background-color: transparent !important;
    }

    /* Texto dentro del multiselect cuando hay selección */
    .stMultiSelect div[data-baseweb="select"] > div {
        background-color: #ffffff !important;
    }

    .stMultiSelect div[data-baseweb="select"] > div > div {
        color: #2c1a0e !important;
    }

    /* Forzar color en todos los spans del multiselect */
    .stMultiSelect li span,
    .stMultiSelect [role="option"] span {
        color: #2c1a0e !important;
    }
    
    /* ── MENSAJES WARNING, INFO, SUCCESS ── */
    .stWarning,
    .stWarning p,
    .stWarning strong,
    [data-testid="stNotification"] p,
    [data-testid="stNotification"] strong {
        color: #744210 !important;
    }

    .stInfo,
    .stInfo p {
        color: #2c5282 !important;
    }

    .stSuccess,
    .stSuccess p {
        color: #276749 !important;
    }

    /* Forzar texto visible en alertas */
    div[data-baseweb="notification"] p,
    div[data-baseweb="notification"] strong {
        color: #2c1a0e !important;
    }
    
    /* ── NOTAS Y PERFIL EN LISTAS ── */
    .stCaptionContainer p {
        color: #a07850 !important;
        font-size: 0.95rem !important;
    }
"""