MOBILE = """

    /* ═══════════════════════════════════════════
       BASE MÓVIL — aplica en todos los tamaños
       Mejoras táctiles globales
    ═══════════════════════════════════════════ */

    /* Elimina el flash gris al tocar en Android/iOS */
    * {
        -webkit-tap-highlight-color: transparent !important;
    }

    /* Scroll suave en toda la app */
    html {
        scroll-behavior: smooth;
        -webkit-text-size-adjust: 100%;
    }

    /* Safe area para iPhone con notch y barra de gestos */
    .main .block-container {
        padding-bottom: max(1.5rem, env(safe-area-inset-bottom)) !important;
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT PRINCIPAL — 768px
       Tablets y móviles grandes
    ═══════════════════════════════════════════ */
    @media (max-width: 768px) {

        /* ── Contenedor principal ── */
        .main .block-container {
            padding-left: 0.9rem !important;
            padding-right: 0.9rem !important;
            padding-top: 0.5rem !important;
            max-width: 100% !important;
        }

        /* ── Encabezado más compacto ── */
        .header-wrapper {
            padding: 0.8rem 0.5rem 0.2rem !important;
            margin-bottom: 0.2rem !important;
        }

        .titulo-app {
            font-size: 2rem !important;
            margin-bottom: 0.2rem !important;
        }

        .subtitulo-app {
            font-size: 0.7rem !important;
            letter-spacing: 0.22em !important;
            margin-bottom: 0.4rem !important;
        }

        .header-linea {
            margin: 0.3rem auto 1rem !important;
        }

        /* ── Pestañas fijas al hacer scroll ── */
        .stTabs [data-baseweb="tab-list"] {
            position: sticky !important;
            top: 0 !important;
            z-index: 100 !important;
            overflow-x: auto !important;
            flex-wrap: nowrap !important;
            -webkit-overflow-scrolling: touch !important;
            scrollbar-width: none !important;
            padding: 4px !important;
            gap: 2px !important;
            background-color: #f5e6d8 !important;
        }

        .stTabs [data-baseweb="tab-list"]::-webkit-scrollbar {
            display: none !important;
        }

        .stTabs [data-baseweb="tab"] {
            padding: 0.4rem 0.65rem !important;
            font-size: 0.78rem !important;
            white-space: nowrap !important;
            min-height: 44px !important;
        }

        /* ── Métricas: 2 columnas en vez de 4 ── */
        [data-testid="stHorizontalBlock"] {
            flex-wrap: wrap !important;
        }

        [data-testid="column"] {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        /* ── Tarjeta perfume ── */
        .perfume-card {
            padding: 0.75rem 0.9rem !important;
        }

        .perfume-card .nombre {
            font-size: 1.1rem !important;
        }

        /* ── Precio box ── */
        .precio-box .valor {
            font-size: 2rem !important;
        }

        .precio-card {
            padding: 0.6rem !important;
        }

        /* ── Inputs táctiles — mínimo 48px para dedos ── */
        .stTextInput input,
        .stNumberInput input,
        .stDateInput input {
            min-height: 48px !important;
            font-size: 16px !important;   /* evita zoom en iOS */
            padding: 0.6rem 0.8rem !important;
        }

        div[data-baseweb="select"] {
            min-height: 48px !important;
        }

        div[data-baseweb="select"] span {
            font-size: 16px !important;
        }

        /* ── Botones táctiles ── */
        .stButton button {
            min-height: 48px !important;
            font-size: 0.95rem !important;
        }

        /* ── Labels más legibles ── */
        .stTextInput label,
        .stDateInput label,
        .stSelectbox label,
        .stNumberInput label {
            font-size: 0.8rem !important;
            letter-spacing: 0.03em !important;
            text-transform: none !important;
        }

        /* ── Expander header cómodo al tacto ── */
        [data-testid="stExpanderHeader"] {
            padding: 0.85rem 1rem !important;
            font-size: 0.9rem !important;
            min-height: 52px !important;
        }

        /* ── Menos margen vertical entre elementos ── */
        hr {
            margin: 0.5rem 0 !important;
        }

        .element-container {
            margin-bottom: 0.4rem !important;
        }

        /* ── Dataframe: scroll horizontal visible ── */
        .stDataFrame {
            overflow-x: auto !important;
            -webkit-overflow-scrolling: touch !important;
        }

        /* ── Alertas ── */
        div[data-testid="stAlert"] p {
            font-size: 0.9rem !important;
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
            padding-top: 0.4rem !important;
        }

        /* ── Encabezado muy compacto ── */
        .header-wrapper {
            padding: 0.6rem 0.5rem 0.1rem !important;
        }

        .titulo-app {
            font-size: 1.75rem !important;
        }

        .header-linea {
            margin: 0.2rem auto 0.7rem !important;
        }

        /* ── Tabs más pequeñas pero cómodas ── */
        .stTabs [data-baseweb="tab"] {
            padding: 0.35rem 0.55rem !important;
            font-size: 0.82rem !important;
        }

        /* ── 4 métricas → 2×2, 3 métricas → todas al 100% o 2+1 ── */
        [data-testid="stHorizontalBlock"] {
            flex-wrap: wrap !important;
            gap: 0.4rem !important;
        }

        [data-testid="column"] {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        /* ── Tarjetas de perfume ── */
        .perfume-card .nombre {
            font-size: 1rem !important;
        }

        /* ── Chips de precio: más compactos ── */
        .precio-card {
            padding: 0.5rem 0.3rem !important;
        }

        /* ── Stepper del wizard de venta ── */
        .wiz-step-label {
            font-size: 0.75rem !important;
            letter-spacing: 0.04em !important;
        }

        /* ── Items de cesta ── */
        .cesta-item {
            flex-wrap: wrap !important;
            gap: 0.3rem !important;
        }

        /* ── Botones: ancho completo, altura cómoda para dedos ── */
        .stButton button {
            min-height: 52px !important;
            font-size: 1rem !important;
            width: 100% !important;
            border-radius: 12px !important;
        }

        /* ── Inputs: altura mayor para dedos ── */
        .stTextInput input,
        .stNumberInput input,
        .stDateInput input {
            min-height: 52px !important;
            font-size: 16px !important;
            border-radius: 10px !important;
        }

        div[data-baseweb="select"] {
            min-height: 52px !important;
            border-radius: 10px !important;
        }

        /* ── Expanders: padding interno reducido ── */
        [data-testid="stExpanderDetails"] {
            padding: 0.65rem 0.5rem !important;
        }

        /* ── Header del expander: más tap-friendly ── */
        [data-testid="stExpanderHeader"] {
            min-height: 56px !important;
            padding: 0.9rem 0.75rem !important;
        }

        /* ── Alertas más compactas ── */
        div[data-testid="stAlert"] {
            padding: 0.65rem 0.8rem !important;
        }

        div[data-testid="stAlert"] p {
            font-size: 0.85rem !important;
            line-height: 1.5 !important;
        }

        /* ── Métricas: fuente más pequeña ── */
        .stMetric [data-testid="stMetricValue"] {
            font-size: 1.35rem !important;
        }

        /* ── Labels legibles sin uppercase agresivo ── */
        .stTextInput label,
        .stDateInput label,
        .stSelectbox label,
        .stNumberInput label {
            font-size: 0.85rem !important;
            text-transform: none !important;
            letter-spacing: 0.02em !important;
            margin-bottom: 2px !important;
        }

        /* ── Espaciado vertical entre bloques ── */
        .element-container {
            margin-bottom: 0.35rem !important;
        }

        /* ── Toast notifications ── */
        .stToast {
            bottom: max(1rem, env(safe-area-inset-bottom)) !important;
        }

        /* ── Botón de descarga ── */
        [data-testid="stDownloadButton"] button {
            min-height: 52px !important;
            font-size: 1rem !important;
        }

        /* ── Spinner ── */
        [data-testid="stSpinner"] {
            font-size: 0.9rem !important;
        }
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT MUY PEQUEÑO — 360px
       Móviles compactos (Galaxy A, Moto G, etc.)
    ═══════════════════════════════════════════ */
    @media (max-width: 360px) {

        .main .block-container {
            padding-left: 0.4rem !important;
            padding-right: 0.4rem !important;
        }

        .titulo-app {
            font-size: 1.5rem !important;
        }

        .header-ornamento {
            display: none !important;
        }

        .stTabs [data-baseweb="tab"] {
            padding: 0.3rem 0.45rem !important;
            font-size: 0.75rem !important;
        }

        /* ── Recortar espacio del header en pantallas muy pequeñas ── */
        .header-linea {
            margin: 0.1rem auto 0.4rem !important;
        }

        .perfume-card .nombre {
            font-size: 0.95rem !important;
        }

        .stButton button {
            font-size: 0.9rem !important;
            min-height: 50px !important;
        }

        .stTextInput input,
        .stNumberInput input,
        .stDateInput input {
            font-size: 16px !important;
        }

        [data-testid="stExpanderHeader"] {
            font-size: 0.82rem !important;
            min-height: 50px !important;
        }

        /* ── Stepper: ocultar labels en pantallas muy pequeñas ── */
        .wiz-step-label {
            display: none !important;
        }

        /* ── Chips de precio: ancho mínimo para no aplastarse ── */
        .precio-chip {
            min-width: 56px !important;
        }
    }
"""
