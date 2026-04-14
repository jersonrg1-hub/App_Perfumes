def get_styles() -> str:
    return """
    <style>
    /* ─── Variables de color ───────────────────────────────────────────────── */
    :root {
        --cream:      #faf5f0;
        --cream-soft: #fdf6f0;
        --border:     #ede0d4;
        --accent:     #c8956c;
        --accent-mid: #a07850;
        --text-dark:  #2c1a0e;
        --text-muted: #8a6a50;
        --white:      #ffffff;
    }

    /* ─── Fondo general de la app ──────────────────────────────────────────── */
    [data-testid="stAppViewContainer"] {
        background: var(--cream) !important;
    }
    [data-testid="stHeader"] {
        background: transparent !important;
    }
    [data-testid="stMain"] {
        background: var(--cream) !important;
    }
    .main .block-container {
        padding-top: 1.5rem !important;
        padding-bottom: 3rem !important;
        max-width: 820px !important;
    }

    /* ─── Encabezado principal ─────────────────────────────────────────────── */
    .header-wrapper {
        text-align: center;
        padding: 2rem 1rem 1.5rem;
        margin-bottom: 0.5rem;
    }
    .header-ornamento {
        display: flex;
        justify-content: center;
        gap: 10px;
        margin-bottom: 1rem;
    }
    .header-ornamento-dot {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        background: var(--accent);
        opacity: 0.6;
    }
    .titulo-app {
        font-family: 'Playfair Display', serif;
        font-size: 2.6rem;
        font-weight: 700;
        color: var(--text-dark);
        letter-spacing: -0.02em;
        line-height: 1.1;
        margin-bottom: 0.4rem;
    }
    .subtitulo-app {
        font-family: 'Lato', sans-serif;
        font-size: 0.78rem;
        font-weight: 700;
        color: var(--accent-mid);
        letter-spacing: 0.35em;
        text-transform: uppercase;
        margin-bottom: 1.2rem;
    }
    .header-linea {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 12px;
    }
    .header-linea::before,
    .header-linea::after {
        content: '';
        display: block;
        width: 60px;
        height: 1px;
        background: linear-gradient(to right, transparent, var(--accent));
    }
    .header-linea::after {
        background: linear-gradient(to left, transparent, var(--accent));
    }
    .header-linea-symbol {
        font-size: 0.7rem;
        color: var(--accent);
        letter-spacing: 0.4em;
        opacity: 0.7;
    }

    /* ─── Tabs ─────────────────────────────────────────────────────────────── */
    [data-testid="stTabs"] [data-baseweb="tab-list"] {
        background: transparent !important;
        gap: 4px !important;
        border-bottom: 1.5px solid var(--border) !important;
        padding-bottom: 0 !important;
    }
    [data-testid="stTabs"] [data-baseweb="tab"] {
        font-family: 'Lato', sans-serif !important;
        font-size: 0.8rem !important;
        font-weight: 700 !important;
        letter-spacing: 0.06em !important;
        color: var(--text-muted) !important;
        padding: 0.5rem 0.9rem !important;
        border-radius: 8px 8px 0 0 !important;
        border: 1.5px solid transparent !important;
        border-bottom: none !important;
        transition: all 0.18s ease !important;
        background: transparent !important;
    }
    [data-testid="stTabs"] [data-baseweb="tab"]:hover {
        color: var(--accent) !important;
        background: var(--cream-soft) !important;
    }
    [data-testid="stTabs"] [aria-selected="true"][data-baseweb="tab"] {
        color: var(--text-dark) !important;
        background: var(--white) !important;
        border-color: var(--border) !important;
        border-bottom: 1.5px solid var(--white) !important;
        margin-bottom: -1.5px !important;
    }
    [data-testid="stTabs"] [data-baseweb="tab-highlight"] {
        display: none !important;
    }
    [data-testid="stTabsContent"] {
        background: var(--white) !important;
        border: 1.5px solid var(--border) !important;
        border-top: none !important;
        border-radius: 0 0 14px 14px !important;
        padding: 1.5rem 1.4rem !important;
    }

    /* ─── Tarjetas de perfume ──────────────────────────────────────────────── */
    .perfume-card {
        background: var(--white);
        border: 1px solid var(--border);
        border-radius: 14px;
        padding: 1rem 1.2rem;
        margin-bottom: 0.5rem;
        transition: box-shadow 0.18s ease, border-color 0.18s ease;
    }
    .perfume-card:hover {
        box-shadow: 0 4px 18px rgba(200, 149, 108, 0.13);
        border-color: var(--accent);
    }

    /* ─── Botones ──────────────────────────────────────────────────────────── */
    .stButton > button {
        font-family: 'Lato', sans-serif !important;
        font-weight: 700 !important;
        font-size: 0.88rem !important;
        letter-spacing: 0.04em !important;
        border-radius: 10px !important;
        padding: 0.55rem 1.2rem !important;
        transition: all 0.18s ease !important;
    }
    .stButton > button[kind="primary"] {
        background: var(--text-dark) !important;
        color: var(--white) !important;
        border: none !important;
    }
    .stButton > button[kind="primary"]:hover {
        background: var(--accent) !important;
        box-shadow: 0 4px 14px rgba(200, 149, 108, 0.35) !important;
    }
    .stButton > button[kind="secondary"],
    .stButton > button:not([kind="primary"]) {
        background: var(--white) !important;
        color: var(--text-dark) !important;
        border: 1.5px solid var(--border) !important;
    }
    .stButton > button[kind="secondary"]:hover,
    .stButton > button:not([kind="primary"]):hover {
        border-color: var(--accent) !important;
        color: var(--accent) !important;
    }

    /* ─── Inputs (selectbox, text, date) ──────────────────────────────────── */
    [data-testid="stSelectbox"] > div > div,
    [data-testid="stTextInput"] > div > div > input,
    [data-testid="stDateInput"] > div > div > input {
        border-radius: 10px !important;
        border-color: var(--border) !important;
        background: var(--white) !important;
        font-family: 'Lato', sans-serif !important;
        font-size: 0.92rem !important;
        color: var(--text-dark) !important;
        transition: border-color 0.15s ease !important;
    }
    [data-testid="stSelectbox"] > div > div:focus-within,
    [data-testid="stTextInput"] > div > div:focus-within,
    [data-testid="stDateInput"] > div > div:focus-within {
        border-color: var(--accent) !important;
        box-shadow: 0 0 0 2px rgba(200, 149, 108, 0.15) !important;
    }
    label[data-testid="stWidgetLabel"] p {
        font-family: 'Lato', sans-serif !important;
        font-size: 0.82rem !important;
        font-weight: 700 !important;
        color: var(--text-muted) !important;
        letter-spacing: 0.05em !important;
        text-transform: uppercase !important;
    }

    /* ─── Multiselect ──────────────────────────────────────────────────────── */
    [data-testid="stMultiSelect"] > div > div {
        border-radius: 10px !important;
        border-color: var(--border) !important;
        background: var(--white) !important;
    }
    [data-testid="stMultiSelect"] span[data-baseweb="tag"] {
        background: var(--cream-soft) !important;
        border: 1px solid var(--border) !important;
        border-radius: 20px !important;
        color: var(--accent-mid) !important;
        font-size: 0.78rem !important;
        font-family: 'Lato', sans-serif !important;
        font-weight: 700 !important;
    }

    /* ─── Mensajes (info, success, error, warning) ─────────────────────────── */
    [data-testid="stAlert"] {
        border-radius: 12px !important;
        font-family: 'Lato', sans-serif !important;
    }

    /* ─── Expander ─────────────────────────────────────────────────────────── */
    [data-testid="stExpander"] {
        border: 1px solid var(--border) !important;
        border-radius: 12px !important;
        background: var(--white) !important;
    }

    /* ─── Divisor (st.markdown "---") ─────────────────────────────────────── */
    hr {
        border: none !important;
        border-top: 1px solid var(--border) !important;
        margin: 1.2rem 0 !important;
    }

    /* ─── Spinner ──────────────────────────────────────────────────────────── */
    [data-testid="stSpinner"] p {
        font-family: 'Lato', sans-serif !important;
        color: var(--accent-mid) !important;
    }

    /* ─── Badge stock crítico (animación de pulso) ─────────────────────────── */
    @keyframes pulsoBadge {
        0%   { opacity: 1; }
        50%  { opacity: 0.55; }
        100% { opacity: 1; }
    }
    .stock-critico-badge {
        animation: pulsoBadge 1.6s ease-in-out infinite !important;
    }

    /* ─── Títulos Markdown ─────────────────────────────────────────────────── */
    h1, h2, h3 {
        font-family: 'Playfair Display', serif !important;
        color: var(--text-dark) !important;
    }
    h3 {
        font-size: 1.25rem !important;
        font-weight: 600 !important;
        letter-spacing: -0.01em !important;
    }
    p, li, .stMarkdown p {
        font-family: 'Lato', sans-serif !important;
        color: var(--text-dark) !important;
        font-size: 0.94rem !important;
    }

    /* ─── Scrollbar personalizado ──────────────────────────────────────────── */
    ::-webkit-scrollbar {
        width: 6px;
        height: 6px;
    }
    ::-webkit-scrollbar-track {
        background: var(--cream);
    }
    ::-webkit-scrollbar-thumb {
        background: var(--border);
        border-radius: 10px;
    }
    ::-webkit-scrollbar-thumb:hover {
        background: var(--accent);
    }
    </style>
    """
