TABS = """
    /* ── BARRA DE PESTAÑAS ── */
    .stTabs [data-baseweb="tab-list"] {
        background: linear-gradient(to bottom, #f5e8da, #eddccc);
        border-radius: 14px;
        padding: 5px;
        gap: 3px;
        border-bottom: none !important;
        box-shadow:
            inset 0 1px 0 rgba(255,255,255,0.6),
            inset 0 -1px 3px rgba(90,50,20,0.08),
            0 2px 8px rgba(90,50,20,0.07);
        overflow-x: auto !important;
        -webkit-overflow-scrolling: touch !important;
        scrollbar-width: none !important;
    }

    .stTabs [data-baseweb="tab-list"]::-webkit-scrollbar {
        display: none !important;
    }

    /* ── PESTAÑA BASE ── */
    .stTabs [data-baseweb="tab"] {
        font-family: 'Lato', sans-serif;
        font-weight: 600;
        font-size: 0.84rem;
        letter-spacing: 0.025em;
        color: #8b6640 !important;
        border-radius: 10px;
        border: none !important;
        padding: 0.45rem 0.95rem;
        transition: background 0.2s ease, color 0.2s ease, box-shadow 0.2s ease, transform 0.15s ease;
        white-space: nowrap;
        position: relative;
    }

    /* ── PESTAÑA ACTIVA — gradiente terracota ── */
    .stTabs [aria-selected="true"] {
        background: linear-gradient(135deg, #c8956c 0%, #a0603a 100%) !important;
        border-radius: 10px !important;
        box-shadow:
            0 3px 10px rgba(160,96,58,0.35),
            inset 0 1px 0 rgba(255,255,255,0.18) !important;
        transform: translateY(-0.5px) !important;
    }

    .stTabs [aria-selected="true"] p,
    .stTabs [aria-selected="true"] span,
    .stTabs [aria-selected="true"] div {
        color: #fff8f2 !important;
        font-weight: 700 !important;
        text-shadow: 0 1px 2px rgba(90,40,10,0.25) !important;
    }

    /* ── PESTAÑA INACTIVA ── */
    .stTabs [aria-selected="false"] p,
    .stTabs [aria-selected="false"] span {
        color: #8b6640 !important;
    }

    .stTabs [aria-selected="false"]:hover {
        background: rgba(200,149,108,0.15) !important;
        transform: translateY(-1px) !important;
        box-shadow: 0 2px 6px rgba(160,96,58,0.12) !important;
    }

    .stTabs [aria-selected="false"]:hover p,
    .stTabs [aria-selected="false"]:hover span {
        color: #5a2e10 !important;
    }

    /* ── PANEL DE CONTENIDO ── */
    .stTabs [data-baseweb="tab-panel"] {
        background-color: transparent;
        padding-top: 1.1rem;
        animation: fadeIn 0.25s ease-out;
    }

    /* Títulos dentro de tabs */
    .stTabs h4,
    .stTabs [data-baseweb="tab-panel"] h4,
    .stMarkdown h4 {
        font-family: 'Playfair Display', serif !important;
        color: var(--c-text) !important;
        letter-spacing: -0.01em !important;
    }
"""