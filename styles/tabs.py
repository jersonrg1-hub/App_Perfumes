TABS = """
    /* ── PESTAÑAS ── */
    .stTabs [data-baseweb="tab-list"] {
        background-color: #fdf6f0;
        border-radius: 10px;
        padding: 4px;
    }

    .stTabs [data-baseweb="tab"] {
        font-family: 'Lato', sans-serif;
        font-weight: 600;
        letter-spacing: 0.05em;
        color: #a07850 !important;
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

    .stTabs [data-baseweb="tab-panel"] {
        background-color: #fdf6f0 !important;
    }
"""