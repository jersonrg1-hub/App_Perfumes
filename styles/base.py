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

    html, body, [class*="css"] {
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
"""