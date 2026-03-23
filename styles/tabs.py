TABS = """
    /* ── PESTAÑAS ── */
    /* CORRECCIÓN #1: tabs.py es la fuente única de verdad para tabs
       se eliminaron los estilos de tabs de base.py para evitar conflictos */
    .stTabs [data-baseweb="tab-list"] {
        background-color: #f5e6d8;
        border-radius: 12px;
        padding: 4px;
        gap: 4px;
        border-bottom: none !important;
    }

    .stTabs [data-baseweb="tab"] {
        font-family: 'Lato', sans-serif;
        font-weight: 600;
        letter-spacing: 0.05em;
        color: #a07850 !important;
        border-radius: 8px;
        border: none !important;
        padding: 0.4rem 0.8rem;
        transition: background 0.2s ease, color 0.2s ease;
    }

    .stTabs [aria-selected="true"] {
        background-color: #2c1a0e !important;
        border-radius: 8px;
    }

    .stTabs [aria-selected="true"] p,
    .stTabs [aria-selected="true"] span {
        color: white !important;
    }

    .stTabs [aria-selected="false"] p,
    .stTabs [aria-selected="false"] span {
        color: #a07850 !important;
    }

    .stTabs [aria-selected="false"]:hover {
        background-color: #e8d5c4;
        color: #2c1a0e !important;
    }

    .stTabs [aria-selected="false"]:hover p,
    .stTabs [aria-selected="false"]:hover span {
        color: #2c1a0e !important;
    }

    /* CORRECCIÓN #2: quitar !important del panel para no tapar
       los fondos blancos de las tarjetas internas */
    .stTabs [data-baseweb="tab-panel"] {
        background-color: #fdf6f0;
        padding-top: 1rem;
        animation: fadeIn 0.3s ease-in-out;
    }
"""