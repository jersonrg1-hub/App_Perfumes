BASE = """
    @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;600;700&family=Lato:wght@300;400;600&display=swap');

    /* ── FONDO Y TEXTO BASE ── */
    .stApp {
        background-color: #fdf6f0 !important;
    }

    .main { background-color: #fdf6f0; }

    section[data-testid="stSidebar"] {
        background-color: #f5e6d8 !important;
    }

    /* CORRECCIÓN #1: reemplazar [class*="css"] por selectores estables */
    html, body, .stApp {
        font-family: 'Lato', sans-serif;
        color: #2c1a0e;
    }

    /* ── FORZAR TEXTO OSCURO ── */
    .stMarkdown p,
    .stMarkdown strong,
    .stMarkdown span,
    [data-testid="column"] p,
    [data-testid="column"] strong,
    [data-testid="stText"] {
        color: #2c1a0e !important;
    }

    .stCaptionContainer p {
        color: #a07850 !important;
    }

    h1, h2, h3 {
        font-family: 'Playfair Display', serif !important;
        color: #2c1a0e !important;
    }

    /* ── TÍTULOS ── */
    .titulo-app {
        font-family: 'Playfair Display', serif;
        font-size: 2.8rem;
        font-weight: 700;
        color: #2c1a0e;
        text-align: center;
        margin-bottom: 0.2rem;
    }

    .subtitulo-app {
        text-align: center;
        color: #a07850;
        font-size: 0.95rem;
        letter-spacing: 0.15em;
        text-transform: uppercase;
        margin-bottom: 2rem;
        font-weight: 300;
    }

    /* MEJORA #2: TABS ── */
    .stTabs [data-baseweb="tab-list"] {
        background-color: #f5e6d8;
        border-radius: 12px;
        padding: 4px;
        gap: 4px;
        border-bottom: none !important;
    }

    .stTabs [data-baseweb="tab"] {
        border-radius: 8px;
        color: #a07850;
        font-family: 'Lato', sans-serif;
        font-weight: 600;
        font-size: 0.85rem;
        padding: 0.4rem 0.8rem;
        border: none !important;
        transition: background 0.2s ease, color 0.2s ease;
    }

    .stTabs [aria-selected="true"] {
        background-color: #2c1a0e !important;
        color: white !important;
    }

    .stTabs [data-baseweb="tab"]:hover:not([aria-selected="true"]) {
        background-color: #e8d5c4;
        color: #2c1a0e;
    }

    /* MEJORA #3: BOTONES ── */
    .stButton > button {
        border-radius: 10px !important;
        font-family: 'Lato', sans-serif !important;
        font-weight: 600 !important;
        transition: transform 0.2s ease, box-shadow 0.2s ease !important;
    }

    .stButton > button[kind="primary"] {
        background: linear-gradient(135deg, #2c1a0e, #5c3a1e) !important;
        color: white !important;
        border: none !important;
    }

    .stButton > button[kind="primary"]:hover {
        transform: translateY(-2px) !important;
        box-shadow: 0 6px 20px rgba(44, 26, 14, 0.3) !important;
    }

    .stButton > button[kind="secondary"] {
        border-color: #c8956c !important;
        color: #2c1a0e !important;
    }

    .stButton > button[kind="secondary"]:hover {
        background-color: #f5e6d8 !important;
        transform: translateY(-1px) !important;
    }

    /* MEJORA #4: INPUTS Y SELECTS ── */
    .stTextInput > div > div > input {
        border-radius: 8px !important;
        border-color: #e0c9b4 !important;
        font-family: 'Lato', sans-serif !important;
        background-color: #fffaf7 !important;
        color: #2c1a0e !important;
    }

    .stTextInput > div > div > input:focus {
        border-color: #c8956c !important;
        box-shadow: 0 0 0 2px rgba(200, 149, 108, 0.2) !important;
    }

    .stSelectbox > div > div {
        border-radius: 8px !important;
        border-color: #e0c9b4 !important;
        font-family: 'Lato', sans-serif !important;
        background-color: #fffaf7 !important;
    }

    .stSelectbox > div > div:focus-within {
        border-color: #c8956c !important;
        box-shadow: 0 0 0 2px rgba(200, 149, 108, 0.2) !important;
    }

    .stMultiSelect > div > div {
        border-radius: 8px !important;
        border-color: #e0c9b4 !important;
        background-color: #fffaf7 !important;
    }

    /* ── DATE INPUT ── */
    .stDateInput > div > div > input {
        border-radius: 8px !important;
        border-color: #e0c9b4 !important;
        font-family: 'Lato', sans-serif !important;
    }

    /* ── EXPANDERS ── */
    .streamlit-expanderHeader {
        background-color: #f5e6d8 !important;
        border-radius: 10px !important;
        font-family: 'Lato', sans-serif !important;
        font-weight: 600 !important;
        color: #2c1a0e !important;
        border: none !important;
    }

    .streamlit-expanderHeader:hover {
        background-color: #ead5c0 !important;
    }

    .streamlit-expanderContent {
        border: 1px solid #f0e0d0 !important;
        border-top: none !important;
        border-radius: 0 0 10px 10px !important;
        background-color: #fffaf7 !important;
    }

    /* ── DIVIDER ── */
    hr {
        border-color: #f0e0d0 !important;
    }

    /* ── TOAST ── */
    .stToast {
        background-color: #2c1a0e !important;
        color: white !important;
        border-radius: 10px !important;
    }

    /* ── DATAFRAME ── */
    .stDataFrame {
        border: 1px solid #f0e0d0 !important;
        border-radius: 10px !important;
        overflow: hidden;
    }
"""