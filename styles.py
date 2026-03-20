def get_styles():
    return """
<style>
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

    /* ── FORZAR TEXTO OSCURO EN TODA LA APP ── */
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

    /* ── SELECTBOX ── */
    .stSelectbox div[data-baseweb="select"],
    div[data-baseweb="select"] {
        background-color: #ffffff !important;
        border-color: #e0c9b4 !important;
    }

    div[data-baseweb="select"] *,
    .stSelectbox div[data-baseweb="select"] span,
    .stSelectbox div[data-baseweb="select"] div,
    .stSelectbox [data-baseweb="select"] input {
        color: #2c1a0e !important;
        background-color: #ffffff !important;
    }

    .stSelectbox label {
        font-weight: 600;
        color: #2c1a0e !important;
        font-size: 0.85rem;
        letter-spacing: 0.05em;
        text-transform: uppercase;
    }

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

    /* ── TARJETA PERFUME ── */
    .perfume-card {
        background: linear-gradient(135deg, #fff8f3, #fdeee4);
        border-left: 4px solid #c8956c;
        border-radius: 12px;
        padding: 1.2rem 1.5rem;
        margin: 1rem 0;
        box-shadow: 0 2px 12px rgba(160, 120, 80, 0.12);
    }

    .perfume-card .marca {
        font-size: 0.8rem;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        color: #a07850;
        font-weight: 600;
        margin-bottom: 0.2rem;
    }

    .perfume-card .nombre {
        font-family: 'Playfair Display', serif;
        font-size: 1.4rem;
        color: #2c1a0e;
        font-weight: 600;
    }

    /* ── PRECIO BOX ── */
    .precio-box {
        background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
        border-radius: 16px;
        padding: 1.8rem;
        text-align: center;
        margin: 1.5rem 0;
        box-shadow: 0 4px 20px rgba(44, 26, 14, 0.25);
    }

    .precio-box .label {
        color: #e8c9a8;
        font-size: 0.8rem;
        letter-spacing: 0.18em;
        text-transform: uppercase;
        margin-bottom: 0.4rem;
        font-weight: 300;
    }

    .precio-box .valor {
        color: #ffffff;
        font-family: 'Playfair Display', serif;
        font-size: 3rem;
        font-weight: 700;
        line-height: 1;
    }

    .precio-box .tamanio {
        color: #c8956c;
        font-size: 0.85rem;
        margin-top: 0.5rem;
        letter-spacing: 0.1em;
    }

    /* ── LISTA PERFUMES ── */
    .perfume-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 0.8rem 1rem;
        border-radius: 8px;
        margin-bottom: 0.5rem;
        background: white;
        border: 1px solid #f0e0d0;
        transition: all 0.2s;
    }

    .perfume-item:hover {
        background: #fff3eb;
        border-color: #c8956c;
    }

    .perfume-item .pf-nombre {
        color: #2c1a0e;
        font-weight: 600;
        font-size: 0.95rem;
    }

    .perfume-item .pf-precio {
        color: #c8956c;
        font-weight: 700;
        font-size: 1rem;
        font-family: 'Playfair Display', serif;
    }

    .sin-precio {
        color: #bbb;
        font-size: 0.85rem;
        font-style: italic;
    }

    .divider {
        border: none;
        border-top: 1px solid #e8d5c4;
        margin: 1.5rem 0;
    }

    .contador {
        font-size: 0.8rem;
        color: #a07850;
        margin-bottom: 1rem;
        font-style: italic;
    }
    
    /* ── ANIMACIONES ── */

    /* Entrada suave de toda la app */
    .stApp {
        animation: fadeIn 0.6s ease-in-out;
    }

    /* Entrada de las tarjetas de precio */
    .precio-box {
        animation: slideUp 0.5s ease-out;
    }

    /* Entrada de la tarjeta de perfume */
    .perfume-card {
        animation: slideUp 0.4s ease-out;
    }

    /* Entrada de cada item de la lista */
    .perfume-item {
        animation: fadeIn 0.3s ease-in-out;
    }

    /* Definición de animaciones */
    @keyframes fadeIn {
        from {
            opacity: 0;
        }
        to {
            opacity: 1;
        }
    }

    @keyframes slideUp {
        from {
            opacity: 0;
            transform: translateY(20px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    /* Hover suave en items de marca */
    [data-testid="column"] {
        transition: all 0.2s ease;
    }

    /* Animación en las cajas de precio por tamaño */
    div[style*="linear-gradient(135deg, #2c1a0e"] {
        animation: slideUp 0.4s ease-out;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    div[style*="linear-gradient(135deg, #2c1a0e"]:hover {
        transform: translateY(-3px);
        box-shadow: 0 8px 25px rgba(44, 26, 14, 0.35) !important;
    }
    
    /* ── OPTIMIZACIÓN MÓVIL ── */
    @media (max-width: 768px) {

        /* Título más pequeño en móvil */
        .titulo-app {
            font-size: 2rem !important;
        }

        .subtitulo-app {
            font-size: 0.8rem !important;
        }

        /* Precio box más compacto */
        .precio-box .valor {
            font-size: 2.2rem !important;
        }

        /* Cajas de precio por tamaño más compactas */
        div[style*="linear-gradient(135deg, #2c1a0e"] {
            padding: 0.7rem !important;
        }

        div[style*="linear-gradient(135deg, #2c1a0e"] div:last-child {
            font-size: 1.1rem !important;
        }

        /* Tarjeta perfume más compacta */
        .perfume-card {
            padding: 0.9rem 1rem !important;
        }

        .perfume-card .nombre {
            font-size: 1.2rem !important;
        }

        /* Pestañas más grandes para dedos */
        .stTabs [data-baseweb="tab"] {
            padding: 0.6rem 1rem !important;
            font-size: 0.9rem !important;
        }

        /* Selectbox más grande para dedos */
        div[data-baseweb="select"] {
            min-height: 48px !important;
        }

        div[data-baseweb="select"] span {
            font-size: 1rem !important;
        }

        /* Items de lista más grandes */
        [data-testid="column"] p {
            font-size: 1rem !important;
            padding: 0.3rem 0 !important;
        }

        /* Más espacio entre elementos */
        .stMarkdown {
            margin-bottom: 0.5rem !important;
        }

        /* Divisor más visible */
        hr {
            margin: 0.8rem 0 !important;
        }
    }
    
    /* ── INPUTS DE TEXTO ── */
    .stTextInput input,
    .stNumberInput input {
        background-color: #ffffff !important;
        color: #2c1a0e !important;
        border-color: #e0c9b4 !important;
    }

    .stTextInput input::placeholder {
        color: #a07850 !important;
        opacity: 1 !important;
    }

    /* Date input */
    .stDateInput input {
        background-color: #ffffff !important;
        color: #2c1a0e !important;
        border-color: #e0c9b4 !important;
    }
    
    /* ── LABELS DEL FORM ── */
    .stTextInput label,
    .stDateInput label,
    .stSelectbox label,
    .stNumberInput label {
        color: #2c1a0e !important;
        font-weight: 600 !important;
        font-size: 0.85rem !important;
        letter-spacing: 0.05em !important;
        text-transform: uppercase !important;
    }
</style>
"""