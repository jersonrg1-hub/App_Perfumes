MOBILE = """
    @media (max-width: 768px) {

        /* ── Título ── */
        .titulo-app {
            font-size: 2rem !important;
        }

        .subtitulo-app {
            font-size: 0.8rem !important;
        }

        /* ── Pestañas scroll suave ── */
        .stTabs [data-baseweb="tab-list"] {
            overflow-x: auto !important;
            flex-wrap: nowrap !important;
            -webkit-overflow-scrolling: touch !important;
        }

        .stTabs [data-baseweb="tab"] {
            padding: 0.5rem 0.8rem !important;
            font-size: 0.8rem !important;
            white-space: nowrap !important;
        }

        /* ── Métricas 2x2 en móvil ── */
        [data-testid="column"] {
            min-width: 45% !important;
            flex: 1 1 45% !important;
        }

        /* ── Lista marca: nombre y precio en misma fila ── */
        [data-testid="column"] p {
            font-size: 0.95rem !important;
            padding: 0.2rem 0 !important;
        }

        /* ── Precio box compacto ── */
        .precio-box .valor {
            font-size: 2rem !important;
        }

        div[style*="linear-gradient(135deg, #2c1a0e"] {
            padding: 0.7rem !important;
        }

        div[style*="linear-gradient(135deg, #2c1a0e"] div:last-child {
            font-size: 1.1rem !important;
        }

        /* ── Tarjeta perfume ── */
        .perfume-card {
            padding: 0.8rem 1rem !important;
        }

        .perfume-card .nombre {
            font-size: 1.1rem !important;
        }

        /* ── Inputs más grandes para dedos ── */
        div[data-baseweb="select"] {
            min-height: 48px !important;
        }

        div[data-baseweb="select"] span {
            font-size: 1rem !important;
        }

        .stTextInput input,
        .stDateInput input {
            min-height: 48px !important;
            font-size: 1rem !important;
        }

        /* ── Botones más grandes ── */
        .stButton button {
            min-height: 48px !important;
            font-size: 1rem !important;
        }

        /* ── Más espacio ── */
        .stMarkdown {
            margin-bottom: 0.4rem !important;
        }

        hr {
            margin: 0.6rem 0 !important;
        }
    }
"""