MOBILE = """

    /* ═══════════════════════════════════════════
       BASE GLOBAL — aplica en todos los tamaños
       Mejoras táctiles universales
    ═══════════════════════════════════════════ */

    * {
        -webkit-tap-highlight-color: transparent !important;
    }

    html {
        scroll-behavior: smooth;
        -webkit-text-size-adjust: 100%;
        overflow-x: hidden;
    }

    body {
        overflow-x: hidden;
    }

    /* Safe area para iPhone notch / barra de gestos */
    .main .block-container {
        padding-bottom: max(1.5rem, env(safe-area-inset-bottom)) !important;
    }

    /* Evita scroll horizontal en toda la app */
    .stApp, .main, .block-container {
        overflow-x: hidden !important;
        max-width: 100vw !important;
    }

    /* Hide Streamlit sidebar hamburger — no lo necesitamos en móvil */
    [data-testid="stSidebarCollapsedControl"],
    [data-testid="collapsedControl"] {
        display: none !important;
    }

    /* Smooth scroll en toda la app */
    * {
        scroll-behavior: smooth;
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT 768px — Tablets y móviles grandes
    ═══════════════════════════════════════════ */
    @media (max-width: 768px) {

        .main .block-container {
            padding-left: 0.9rem !important;
            padding-right: 0.9rem !important;
            padding-top: 0.5rem !important;
            max-width: 100% !important;
        }

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

        /* Tabs: sticky horizontal scroll en tablet */
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

        [data-testid="stHorizontalBlock"] {
            flex-wrap: wrap !important;
        }

        [data-testid="column"] {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        .perfume-card {
            padding: 0.75rem 0.9rem !important;
        }

        .perfume-card .nombre {
            font-size: 1.1rem !important;
        }

        .precio-box .valor {
            font-size: 2rem !important;
        }

        .precio-card {
            padding: 0.6rem !important;
        }

        .stTextInput input,
        .stNumberInput input,
        .stDateInput input {
            min-height: 48px !important;
            font-size: 16px !important;
            padding: 0.6rem 0.8rem !important;
        }

        div[data-baseweb="select"] {
            min-height: 48px !important;
        }

        div[data-baseweb="select"] span {
            font-size: 16px !important;
        }

        .stButton button {
            min-height: 48px !important;
            font-size: 0.95rem !important;
        }

        .stTextInput label,
        .stDateInput label,
        .stSelectbox label,
        .stNumberInput label {
            font-size: 0.8rem !important;
            letter-spacing: 0.03em !important;
            text-transform: none !important;
        }

        [data-testid="stExpanderHeader"] {
            padding: 0.85rem 1rem !important;
            font-size: 0.9rem !important;
            min-height: 52px !important;
        }

        hr {
            margin: 0.5rem 0 !important;
        }

        .element-container {
            margin-bottom: 0.4rem !important;
        }

        .stDataFrame {
            overflow-x: auto !important;
            -webkit-overflow-scrolling: touch !important;
        }

        div[data-testid="stAlert"] p {
            font-size: 0.9rem !important;
        }
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT 540px — Android medianos
    ═══════════════════════════════════════════ */
    @media (max-width: 540px) {

        .titulo-app {
            font-size: 1.85rem !important;
        }

        .header-wrapper {
            padding: 0.7rem 0.5rem 0.15rem !important;
        }

        .subtitulo-app {
            font-size: 0.68rem !important;
        }

        [data-testid="column"] {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        .stTabs [data-baseweb="tab"] {
            padding: 0.38rem 0.6rem !important;
            font-size: 0.8rem !important;
        }
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT 480px — Móviles estándar
    ═══════════════════════════════════════════ */
    @media (max-width: 480px) {

        .main .block-container {
            padding-left: 0.6rem !important;
            padding-right: 0.6rem !important;
            padding-top: 0.4rem !important;
        }

        .header-wrapper {
            padding: 0.6rem 0.5rem 0.1rem !important;
        }

        .titulo-app {
            font-size: 1.75rem !important;
        }

        .header-linea {
            margin: 0.2rem auto 0.7rem !important;
        }

        .stTabs [data-baseweb="tab"] {
            padding: 0.35rem 0.55rem !important;
            font-size: 0.82rem !important;
        }

        [data-testid="stHorizontalBlock"] {
            flex-wrap: wrap !important;
            gap: 0.4rem !important;
        }

        [data-testid="column"] {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        .perfume-card .nombre {
            font-size: 1rem !important;
        }

        .precio-card {
            padding: 0.5rem 0.3rem !important;
        }

        .wiz-step-label {
            font-size: 0.75rem !important;
            letter-spacing: 0.04em !important;
        }

        .cesta-item {
            flex-wrap: wrap !important;
            gap: 0.3rem !important;
        }

        .stButton button {
            min-height: 52px !important;
            font-size: 1rem !important;
            width: 100% !important;
            border-radius: 12px !important;
        }

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

        [data-testid="stExpanderDetails"] {
            padding: 0.65rem 0.5rem !important;
        }

        [data-testid="stExpanderHeader"] {
            min-height: 56px !important;
            padding: 0.9rem 0.75rem !important;
        }

        div[data-testid="stAlert"] {
            padding: 0.65rem 0.8rem !important;
        }

        div[data-testid="stAlert"] p {
            font-size: 0.85rem !important;
            line-height: 1.5 !important;
        }

        .stMetric [data-testid="stMetricValue"] {
            font-size: 1.35rem !important;
        }

        .stTextInput label,
        .stDateInput label,
        .stSelectbox label,
        .stNumberInput label {
            font-size: 0.85rem !important;
            text-transform: none !important;
            letter-spacing: 0.02em !important;
            margin-bottom: 2px !important;
        }

        .element-container {
            margin-bottom: 0.35rem !important;
        }

        .stToast {
            bottom: max(1rem, env(safe-area-inset-bottom)) !important;
        }

        [data-testid="stDownloadButton"] button {
            min-height: 52px !important;
            font-size: 1rem !important;
        }

        [data-testid="stSpinner"] {
            font-size: 0.9rem !important;
        }
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT 430px — iPhone Pro Max / Galaxy Ultra
       ★ BOTTOM NAVIGATION BAR ★ + FAB
       Mobile-first: convertimos tabs en nav inferior
    ═══════════════════════════════════════════ */
    @media (max-width: 430px) {

        /* ── Encabezado ultra-compacto ── */
        .header-wrapper {
            padding: 0.45rem 0.5rem 0 !important;
            margin-bottom: 0 !important;
        }

        .header-ornamento {
            margin-bottom: 0.3rem !important;
            gap: 4px !important;
        }

        .header-ornamento-dot {
            width: 3px !important;
            height: 3px !important;
        }

        .titulo-app {
            font-size: 1.55rem !important;
            margin-bottom: 0.1rem !important;
            letter-spacing: -0.04em !important;
        }

        .subtitulo-app {
            font-size: 0.58rem !important;
            letter-spacing: 0.16em !important;
            margin-bottom: 0.15rem !important;
        }

        .header-linea {
            margin: 0.1rem auto 0.4rem !important;
            gap: 8px !important;
        }

        .header-linea::before,
        .header-linea::after {
            width: 40px !important;
        }

        .header-linea-symbol {
            font-size: 0.55rem !important;
        }

        /* ── BOTTOM NAVIGATION BAR ──
           Reposicionamos la barra de tabs de Streamlit al fondo.
           position:fixed bottom:0 la saca del flujo normal y la
           ancla al viewport. El contenido recibe padding-bottom
           para no quedar tapado. */
        .stTabs [data-baseweb="tab-list"] {
            position: fixed !important;
            bottom: 0 !important;
            left: 0 !important;
            right: 0 !important;
            top: auto !important;
            width: 100% !important;
            z-index: 1001 !important;
            /* Glassmorphism */
            background: rgba(255, 249, 244, 0.96) !important;
            backdrop-filter: blur(20px) saturate(180%) !important;
            -webkit-backdrop-filter: blur(20px) saturate(180%) !important;
            border-radius: 20px 20px 0 0 !important;
            box-shadow:
                0 -2px 24px rgba(90, 50, 20, 0.14),
                0 -1px 0 rgba(200, 149, 108, 0.18) !important;
            /* Layout */
            display: flex !important;
            flex-direction: row !important;
            justify-content: space-around !important;
            align-items: stretch !important;
            gap: 0 !important;
            flex-wrap: nowrap !important;
            overflow: visible !important;
            -webkit-overflow-scrolling: unset !important;
            scrollbar-width: none !important;
            /* Safe area para barra de gestos de iPhone */
            padding: 6px 4px max(10px, env(safe-area-inset-bottom, 10px)) !important;
        }

        .stTabs [data-baseweb="tab-list"]::-webkit-scrollbar {
            display: none !important;
        }

        /* Cada tab = item de bottom nav */
        .stTabs [data-baseweb="tab"] {
            flex: 1 1 0 !important;
            min-width: 0 !important;
            display: flex !important;
            flex-direction: column !important;
            align-items: center !important;
            justify-content: center !important;
            padding: 7px 2px 5px !important;
            min-height: 60px !important;
            font-size: 0.65rem !important;
            white-space: normal !important;
            text-align: center !important;
            border-radius: 12px !important;
            background: transparent !important;
            box-shadow: none !important;
            transform: none !important;
            transition: background 0.15s ease, color 0.15s ease !important;
            letter-spacing: 0.005em !important;
        }

        .stTabs [data-baseweb="tab"] p,
        .stTabs [data-baseweb="tab"] span,
        .stTabs [data-baseweb="tab"] div {
            font-size: 0.65rem !important;
            line-height: 1.3 !important;
            text-align: center !important;
            white-space: normal !important;
            word-break: break-word !important;
        }

        /* Tab activa: acento terracota + indicador superior */
        .stTabs [aria-selected="true"] {
            background: rgba(184, 114, 74, 0.11) !important;
            box-shadow: none !important;
            transform: none !important;
        }

        /* Barra indicadora superior en tab activa */
        .stTabs [aria-selected="true"]::before {
            content: '' !important;
            display: block !important;
            width: 22px !important;
            height: 3px !important;
            background: var(--c-primary-light) !important;
            border-radius: 2px !important;
            margin: 0 auto 4px !important;
            flex-shrink: 0 !important;
        }

        .stTabs [aria-selected="true"] p,
        .stTabs [aria-selected="true"] span,
        .stTabs [aria-selected="true"] div {
            color: var(--c-primary) !important;
            font-weight: 700 !important;
            text-shadow: none !important;
        }

        /* Tab inactiva */
        .stTabs [aria-selected="false"] p,
        .stTabs [aria-selected="false"] span,
        .stTabs [aria-selected="false"] div {
            color: #9a7258 !important;
            font-weight: 500 !important;
        }

        .stTabs [aria-selected="false"]:hover {
            background: rgba(200, 149, 108, 0.07) !important;
            transform: none !important;
            box-shadow: none !important;
        }

        .stTabs [aria-selected="false"]:active {
            background: rgba(200, 149, 108, 0.14) !important;
            transform: scale(0.95) !important;
        }

        /* Sub-tabs internos (Estadísticas, etc.): NO convertir en nav inferior.
           Solo el .stTabs raíz debe ser fixed; los anidados quedan normales. */
        .stTabs .stTabs [data-baseweb="tab-list"] {
            position: relative !important;
            bottom: auto !important;
            left: auto !important;
            right: auto !important;
            width: auto !important;
            z-index: auto !important;
            background: transparent !important;
            backdrop-filter: none !important;
            -webkit-backdrop-filter: none !important;
            border-radius: 0 !important;
            box-shadow: none !important;
            overflow-x: auto !important;
            padding: 0 0 2px 0 !important;
            gap: 4px !important;
            border-bottom: 1px solid rgba(200, 149, 108, 0.25) !important;
            scrollbar-width: none !important;
        }

        .stTabs .stTabs [data-baseweb="tab-list"]::-webkit-scrollbar {
            display: none !important;
        }

        .stTabs .stTabs [data-baseweb="tab"] {
            flex: 0 0 auto !important;
            min-width: auto !important;
            flex-direction: row !important;
            padding: 7px 12px !important;
            min-height: 38px !important;
            font-size: 0.75rem !important;
            border-radius: 8px 8px 0 0 !important;
        }

        .stTabs .stTabs [data-baseweb="tab"] p,
        .stTabs .stTabs [data-baseweb="tab"] span,
        .stTabs .stTabs [data-baseweb="tab"] div {
            font-size: 0.75rem !important;
            white-space: nowrap !important;
        }

        .stTabs .stTabs [aria-selected="true"]::before {
            display: none !important;
        }

        .stTabs .stTabs [aria-selected="true"] {
            background: rgba(184, 114, 74, 0.13) !important;
            border-bottom: 2px solid var(--c-primary-light) !important;
        }

        .stTabs .stTabs [data-baseweb="tab-panel"] {
            padding-top: 0.7rem !important;
            animation: none !important;
        }

        /* Panel de contenido principal: sin gap superior extra */
        .stTabs [data-baseweb="tab-panel"] {
            padding-top: 0.4rem !important;
            animation: fadeIn 0.2s ease-out !important;
        }

        /* ── Contenido: padding-bottom para el nav + FAB ──
           Nav height ~68px + safe area + FAB clearance */
        .main .block-container {
            padding-left: 0.5rem !important;
            padding-right: 0.5rem !important;
            padding-top: 0.25rem !important;
            padding-bottom: calc(96px + max(18px, env(safe-area-inset-bottom, 18px))) !important;
        }

        /* Toast: por encima del bottom nav */
        .stToast {
            bottom: calc(84px + max(18px, env(safe-area-inset-bottom, 18px))) !important;
            left: 16px !important;
            right: 16px !important;
            max-width: none !important;
        }

        /* ── FAB (Floating Action Button) ──
           Estilos; el elemento lo inyecta el JS en app.py */
        #perfute-fab {
            position: fixed !important;
            bottom: calc(80px + max(22px, env(safe-area-inset-bottom, 22px))) !important;
            right: 16px !important;
            z-index: 1002 !important;
            width: 52px !important;
            height: 52px !important;
            border-radius: 50% !important;
            background: linear-gradient(140deg, #c8956c 0%, #9a4c22 100%) !important;
            color: #fff8f4 !important;
            font-size: 1.6rem !important;
            font-weight: 300 !important;
            line-height: 1 !important;
            border: none !important;
            cursor: pointer !important;
            box-shadow:
                0 4px 18px rgba(154, 76, 34, 0.50),
                0 1px 4px rgba(0,0,0,0.15) !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            transition: transform 0.16s ease, box-shadow 0.16s ease, opacity 0.2s ease !important;
            -webkit-tap-highlight-color: transparent !important;
            user-select: none !important;
        }

        #perfute-fab:active {
            transform: scale(0.90) !important;
            box-shadow: 0 2px 10px rgba(154, 76, 34, 0.40) !important;
        }

        #perfute-fab.fab-hidden {
            opacity: 0 !important;
            pointer-events: none !important;
            transform: scale(0.8) !important;
        }

        /* ── Streamlit Cloud: "Manage app" y barra de estado ──
           Los elevamos sobre el bottom nav para que no tapen los tabs.
           Cubre footer clásico, stBottom (1.35+), stStatusWidget y stDeployButton. */
        footer,
        [data-testid="stBottom"],
        [data-testid="stStatusWidget"],
        [data-testid="stDeployButton"] {
            bottom: calc(74px + max(22px, env(safe-area-inset-bottom, 22px))) !important;
            z-index: 1000 !important;
        }

        /* ── Columnas: permite 2-col y 3-col en pantallas estrechas ── */
        [data-testid="stHorizontalBlock"] {
            flex-wrap: wrap !important;
            gap: 0.45rem !important;
        }

        /* Columnas: flex-basis 30% permite hasta 3 en fila
           (chips de precio: 2ml / 5ml / 10ml) */
        [data-testid="column"] {
            min-width: 30% !important;
            flex: 1 1 30% !important;
        }

        /* ── Tarjetas de perfume: touch-friendly ── */
        .perfume-card {
            padding: 0.8rem 1rem !important;
            margin-bottom: 0.5rem !important;
            border-radius: 16px !important;
            border-left-width: 4px !important;
            /* La transición :active da feedback táctil inmediato */
            transition: transform 0.12s ease, background 0.12s ease, box-shadow 0.18s ease !important;
        }

        .perfume-card:active {
            transform: scale(0.985) !important;
            background: linear-gradient(160deg, #fff0e8 0%, #fde8da 100%) !important;
            box-shadow: 0 2px 8px rgba(184, 114, 74, 0.18) !important;
        }

        .perfume-card .marca {
            font-size: 0.6rem !important;
        }

        .perfume-card .nombre {
            font-size: 1.02rem !important;
        }

        /* ── Chips de precio ── */
        .precio-chip {
            padding: 0.45rem 0.3rem !important;
            border-radius: 12px !important;
            transition: transform 0.12s ease, background 0.12s ease !important;
        }

        .precio-chip:active {
            transform: scale(0.94) !important;
            background: var(--c-primary-pale) !important;
            border-color: var(--c-primary-light) !important;
        }

        .precio-chip .chip-valor {
            font-size: 1rem !important;
        }

        .precio-chip .chip-label {
            font-size: 0.6rem !important;
        }

        /* ── Inputs y selects: táctiles ── */
        .stTextInput input,
        .stNumberInput input,
        .stDateInput input {
            min-height: 52px !important;
            font-size: 16px !important;
            border-radius: 12px !important;
            padding: 0.7rem 1rem !important;
        }

        div[data-baseweb="select"] {
            min-height: 52px !important;
            border-radius: 12px !important;
        }

        /* ── Labels legibles sin uppercase ── */
        .stTextInput label,
        .stDateInput label,
        .stSelectbox label,
        .stNumberInput label,
        .stRadio label {
            font-size: 0.82rem !important;
            text-transform: none !important;
            font-weight: 600 !important;
            letter-spacing: 0.01em !important;
        }

        /* ── Botones: ancho completo, táctiles ── */
        .stButton button {
            min-height: 52px !important;
            width: 100% !important;
            border-radius: 14px !important;
            font-size: 0.92rem !important;
            /* Feedback táctil */
            transition: transform 0.12s ease, box-shadow 0.12s ease, background 0.18s ease !important;
        }

        .stButton button:active {
            transform: scale(0.96) !important;
        }

        /* Download button */
        [data-testid="stDownloadButton"] button {
            min-height: 52px !important;
            width: 100% !important;
            border-radius: 14px !important;
        }

        /* ── Expander: area táctil grande ── */
        [data-testid="stExpanderHeader"] {
            min-height: 56px !important;
            padding: 0.85rem 1rem !important;
            border-radius: 12px !important;
        }

        [data-testid="stExpanderDetails"] {
            padding: 0.6rem 0.75rem !important;
        }

        /* ── Wizard stepper ── */
        .wiz-step-label {
            font-size: 0.68rem !important;
        }

        /* ── Métricas: texto legible ── */
        .stMetric [data-testid="stMetricValue"] {
            font-size: 1.45rem !important;
        }

        .stMetric [data-testid="stMetricLabel"] {
            font-size: 0.78rem !important;
        }

        /* ── Alertas compactas ── */
        div[data-testid="stAlert"] {
            padding: 0.6rem 0.85rem !important;
            border-radius: 12px !important;
        }

        div[data-testid="stAlert"] p {
            font-size: 0.84rem !important;
            line-height: 1.5 !important;
        }

        /* ── Ítem de cesta (wizard venta) ── */
        .perfume-item {
            padding: 0.75rem 0.9rem !important;
        }

        /* ── Dataframe: scroll horizontal cómodo ── */
        .stDataFrame {
            overflow-x: auto !important;
            -webkit-overflow-scrolling: touch !important;
            border-radius: 12px !important;
        }

        /* ── Spinner ── */
        [data-testid="stSpinner"] {
            font-size: 0.88rem !important;
        }

        /* ── Espaciado vertical más denso ── */
        .element-container {
            margin-bottom: 0.32rem !important;
        }
    }


    /* ═══════════════════════════════════════════
       BREAKPOINT 360px — Móviles compactos
       Galaxy A, Moto G, teléfonos 5"
    ═══════════════════════════════════════════ */
    @media (max-width: 360px) {

        .main .block-container {
            padding-left: 0.35rem !important;
            padding-right: 0.35rem !important;
        }

        .titulo-app {
            font-size: 1.38rem !important;
        }

        .header-ornamento {
            display: none !important;
        }

        .header-linea {
            margin: 0.05rem auto 0.3rem !important;
        }

        .perfume-card .nombre {
            font-size: 0.95rem !important;
        }

        .stButton button {
            font-size: 0.88rem !important;
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

        /* Ocultar labels del stepper — hay muy poco espacio */
        .wiz-step-label {
            display: none !important;
        }

        /* Chips: ancho mínimo para no aplastarse */
        .precio-chip {
            min-width: 48px !important;
        }

        .precio-chip .chip-valor {
            font-size: 0.92rem !important;
        }

        /* Bottom nav: compacta pero legible */
        .stTabs [data-baseweb="tab"] {
            font-size: 0.58rem !important;
            min-height: 56px !important;
            padding: 6px 1px 4px !important;
        }

        .stTabs [data-baseweb="tab"] p,
        .stTabs [data-baseweb="tab"] span,
        .stTabs [data-baseweb="tab"] div {
            font-size: 0.58rem !important;
        }

        /* FAB un poco más pequeño */
        #perfute-fab {
            width: 48px !important;
            height: 48px !important;
            font-size: 1.45rem !important;
            right: 12px !important;
            bottom: calc(78px + max(20px, env(safe-area-inset-bottom, 20px))) !important;
        }

        .main .block-container {
            padding-bottom: calc(92px + max(14px, env(safe-area-inset-bottom, 14px))) !important;
        }
    }
"""
