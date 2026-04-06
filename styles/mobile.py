MOBILE = """

    /* ═══════════════════════════════════════════
       BREAKPOINT PRINCIPAL — 768px
       Tablets y móviles grandes
    ═══════════════════════════════════════════ */
    @media (max-width: 768px) {

        /* ── Reducir padding lateral de Streamlit ── */
        .main .block-container {
            padding-left: 1rem !important;
            padding-right: 1rem !important;
            padding-top: 1rem !important;
        }

        /* ── Título ── */
        .titulo-app {
            font-size: 2.2rem !important;
        }

        .subtitulo-app {
            font-size: 0.75rem !important;
            letter-spacing: 0.25em !important;
        }

        /* ── Pestañas: scroll horizontal sin saltos ── */
        .stTabs [data-baseweb="tab-list"] {
            overflow-x: auto !important;
            flex-wrap: nowrap !important;
            -webkit-overflow-scrolling: touch !important;
            padding: 4px !important;
            gap: 2px !important;
        }

        .stTabs [data-baseweb="tab"] {
            padding: 0.4rem 0.7rem !important;
            font-size: 0.78rem !important;
            white-space: nowrap !important;
        }

        /* ── Métricas: 2 columnas en vez de 4 ── */
        [data-testid="column"] {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        /* ── Tarjeta perfume ── */
        .perfume-card {
            padding: 0.8rem 1rem !important;
        }

        .perfume-card .nombre {
            font-size: 1.15rem !important;
        }

        /* ── Precio box (tab_nombre) ── */
        .precio-box .valor {
            font-size: 2rem !important;
        }

        .precio-card {
            padding: 0.6rem !important;
        }

        /* ── Inputs y selects táctiles ── */
        div[data-baseweb="select"] {
            min-height: 48px !important;
        }

        div[data-baseweb="select"] span {
            font-size: 1rem !important;
        }

        .stTextInput input,
        .stNumberInput input,
        .stDateInput input {
            min-height: 48px !important;
            font-size: 1rem !important;
        }

        /* ── Botones táctiles ── */
        .stButton button {
            min-height: 48px !important;
            font-size: 0.95rem !important;
        }

        /* ── Expander header más cómodo ── */
        [data-testid="stExpanderHeader"] {
            padding: 0.8rem 1rem !important;
            font-size: 0.9rem !important;
        }

        /* ── Separadores más compactos ── */
        hr {
            margin: 0.5rem 0 !important;
        }

        /* ── Dataframe: scroll horizontal visible ── */
        .stDataFrame {
            overflow-x: auto !important;
        }
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT MÓVIL — 480px
       Móviles estándar (iPhone, Android)
    ═══════════════════════════════════════════ */
    @media (max-width: 480px) {

        /* ── Padding mínimo ── */
        .main .block-container {
            padding-left: 0.6rem !important;
            padding-right: 0.6rem !important;
        }

        /* ── Título compacto ── */
        .titulo-app {
            font-size: 1.8rem !important;
        }

        /* ── Tabs más pequeñas ── */
        .stTabs [data-baseweb="tab"] {
            padding: 0.35rem 0.55rem !important;
            font-size: 0.72rem !important;
        }

        /* ── Columnas: forzar stack vertical
           excepto cuando son exactamente 2 ── */
        [data-testid="column"]:nth-child(n+3) {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        /* ── Tarjetas de perfume: separar precio
           del nombre en columna vertical ── */
        .perfume-card .nombre {
            font-size: 1rem !important;
        }

        /* ── Chips de precio (3 columnas): más compactos ── */
        .precio-card {
            padding: 0.5rem 0.3rem !important;
        }

        /* ── Stepper de venta: texto más pequeño ── */
        .wiz-step-label {
            font-size: 0.62rem !important;
        }

        /* ── Cesta de items: precio en línea nueva si es necesario ── */
        .cesta-item {
            flex-wrap: wrap !important;
            gap: 0.3rem !important;
        }

        /* ── 7 columnas de días: fuente mínima ── */
        [data-testid="column"] > div > div > div > div {
            font-size: 0.6rem !important;
        }

        /* ── Métricas: ambas columnas al 100% si son 4 ──
           Logrado con flex-wrap en el padre            ── */
        [data-testid="stHorizontalBlock"] {
            flex-wrap: wrap !important;
        }

        [data-testid="column"] {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        /* ── Botones: ancho completo ── */
        .stButton button {
            min-height: 52px !important;
            font-size: 1rem !important;
            width: 100% !important;
        }

        /* ── Inputs: más altos para dedos ── */
        .stTextInput input,
        .stNumberInput input,
        .stDateInput input {
            min-height: 52px !important;
            font-size: 1rem !important;
        }

        div[data-baseweb="select"] {
            min-height: 52px !important;
        }

        /* ── Expanders: padding interno reducido ── */
        [data-testid="stExpanderDetails"] {
            padding: 0.7rem !important;
        }

        /* ── Alertas más compactas ── */
        div[data-testid="stAlert"] {
            padding: 0.7rem 0.9rem !important;
        }

        div[data-testid="stAlert"] p {
            font-size: 0.88rem !important;
        }

        /* ── Métricas: valores más pequeños en 4-grid ── */
        .stMetric [data-testid="stMetricValue"] {
            font-size: 1.4rem !important;
        }
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT MUY PEQUEÑO — 360px
       Móviles compactos
    ═══════════════════════════════════════════ */
    @media (max-width: 360px) {

        .main .block-container {
            padding-left: 0.4rem !important;
            padding-right: 0.4rem !important;
        }

        .titulo-app {
            font-size: 1.5rem !important;
        }

        .stTabs [data-baseweb="tab"] {
            padding: 0.3rem 0.45rem !important;
            font-size: 0.68rem !important;
        }

        .perfume-card .nombre {
            font-size: 0.95rem !important;
        }

        .stButton button {
            font-size: 0.9rem !important;
        }
    }
"""