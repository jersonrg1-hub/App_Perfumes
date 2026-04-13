TABS = """
    /* ── PESTAÑAS PRINCIPALES ── */
    .stTabs [data-baseweb="tab-list"] {
        background-color: #f5e6d8;
        border-radius: 14px;
        padding: 5px;
        gap: 3px;
        border-bottom: none !important;
        box-shadow: inset 0 1px 3px rgba(44, 26, 14, 0.08);
    }

    .stTabs [data-baseweb="tab"] {
        font-family: 'Lato', sans-serif;
        font-weight: 600;
        font-size: 0.85rem;
        letter-spacing: 0.03em;
        color: #a07850 !important;
        border-radius: 10px;
        border: none !important;
        padding: 0.45rem 0.9rem;
        transition: background 0.18s ease, color 0.18s ease, transform 0.15s ease;
        white-space: nowrap;
    }

    /* Tab activo: pill marrón oscura con texto crema */
    .stTabs [aria-selected="true"] {
        background-color: #2c1a0e !important;
        border-radius: 10px;
        box-shadow: 0 2px 6px rgba(44, 26, 14, 0.25);
    }

    .stTabs [aria-selected="true"] p,
    .stTabs [aria-selected="true"] span,
    .stTabs [aria-selected="true"] div {
        color: #e8c9a8 !important;
    }

    /* Tab inactivo: texto marrón claro */
    .stTabs [aria-selected="false"] p,
    .stTabs [aria-selected="false"] span {
        color: #a07850 !important;
    }

    /* Hover en tabs inactivos */
    .stTabs [aria-selected="false"]:hover {
        background-color: #ead5c0 !important;
        color: #2c1a0e !important;
        transform: translateY(-1px);
    }

    .stTabs [aria-selected="false"]:hover p,
    .stTabs [aria-selected="false"]:hover span {
        color: #2c1a0e !important;
    }

    /* Panel con animación de entrada */
    .stTabs [data-baseweb="tab-panel"] {
        background-color: #fdf6f0;
        padding-top: 1rem;
        animation: fadeIn 0.25s ease-in-out;
    }

    /* Forzar Playfair Display en títulos h4 dentro de tabs */
    .stTabs h4,
    .stTabs [data-baseweb="tab-panel"] h4,
    .stMarkdown h4 {
        font-family: 'Playfair Display', serif !important;
        color: #2c1a0e !important;
        letter-spacing: -0.01em !important;
    }

    /* Scroll suave en móvil */
    .stTabs [data-baseweb="tab-list"] {
        overflow-x: auto !important;
        -webkit-overflow-scrolling: touch !important;
        scrollbar-width: none;
    }

    .stTabs [data-baseweb="tab-list"]::-webkit-scrollbar {
        display: none;
    }
"""