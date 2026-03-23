ANIMATIONS = """
    /* ── ANIMACIONES ── */
    .stApp {
        animation: fadeIn 0.6s ease-in-out;
    }

    /* CORRECCIÓN #5: usar clases CSS en lugar de selector de inline style frágil */
    /* Las tarjetas de precio usan class="precio-card" en el HTML */
    .precio-card {
        animation: slideUp 0.5s ease-out;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .precio-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 8px 25px rgba(44, 26, 14, 0.35) !important;
    }

    .perfume-card {
        animation: slideUp 0.4s ease-out;
    }

    .perfume-item {
        animation: fadeIn 0.3s ease-in-out;
    }

    /* MEJORA #6: expanders con transición suave */
    .streamlit-expanderHeader {
        transition: background-color 0.2s ease !important;
    }

    /* ── STAGGERED ANIMATIONS para listas de perfumes ── */
    .perfume-item:nth-child(1) { animation-delay: 0.05s; }
    .perfume-item:nth-child(2) { animation-delay: 0.10s; }
    .perfume-item:nth-child(3) { animation-delay: 0.15s; }
    .perfume-item:nth-child(4) { animation-delay: 0.20s; }
    .perfume-item:nth-child(5) { animation-delay: 0.25s; }

    /* ── TABS con transición suave ── */
    .stTabs [data-baseweb="tab-panel"] {
        animation: fadeIn 0.3s ease-in-out;
    }

    /* ── COLUMNAS con transición ── */
    [data-testid="column"] {
        transition: all 0.2s ease;
    }

    /* ── KEYFRAMES ── */
    @keyframes fadeIn {
        from { opacity: 0; }
        to   { opacity: 1; }
    }

    @keyframes slideUp {
        from { opacity: 0; transform: translateY(20px); }
        to   { opacity: 1; transform: translateY(0);    }
    }

    @keyframes slideIn {
        from { opacity: 0; transform: translateX(-10px); }
        to   { opacity: 1; transform: translateX(0);     }
    }

    /* ── BOTONES con efecto de escala al hacer click ── */
    .stButton > button:active {
        transform: scale(0.97) !important;
    }

    /* ── SUCCESS / ERROR / WARNING con entrada suave ── */
    .stSuccess, .stError, .stWarning, .stInfo {
        animation: slideIn 0.3s ease-out;
        border-radius: 10px !important;
    }
"""