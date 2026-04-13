BASE = """
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&family=Lato:wght@300;400;600&family=Inter:wght@400;600;700&family=DM+Sans:wght@400;600;700&display=swap');

html, body, .stApp {
    font-family: 'Lato', sans-serif;
    color: #2c1a0e;
    font-size: 16px;
    line-height: 1.7;
}

.stApp {
    background-color: #fdf6f0 !important;
    background-image:
        radial-gradient(circle at 15% 20%, rgba(200,149,108,0.06) 0%, transparent 50%),
        radial-gradient(circle at 85% 80%, rgba(160,120,80,0.05) 0%, transparent 50%);
}

.main { background-color: transparent; }

section[data-testid="stSidebar"] {
    background-color: #f5e6d8 !important;
}

.stMarkdown p,
.stMarkdown strong,
.stMarkdown span,
[data-testid="column"] p,
[data-testid="column"] strong,
[data-testid="stText"] {
    color: #2c1a0e !important;
    line-height: 1.7;
}

.stCaptionContainer p {
    color: #a07850 !important;
    font-size: 0.85rem;
    letter-spacing: 0.03em;
}

h1, h2, h3, h4 {
    font-family: 'Playfair Display', serif !important;
    color: #2c1a0e !important;
    letter-spacing: -0.01em;
    line-height: 1.3;
}

.header-wrapper {
    text-align: center;
    padding: 1.5rem 1rem 0.5rem;
    margin-bottom: 0.5rem;
}

.header-ornamento {
    display: none;
}

.header-ornamento::before,
.header-ornamento::after {
    content: '';
    width: 48px;
    height: 0.5px;
    background: #c8956c;
}

.header-ornamento-dot {
    width: 4px;
    height: 4px;
    background: #c8956c;
    border-radius: 50%;
}

.titulo-app {
    font-family: 'Playfair Display', serif;
    font-size: 3.2rem;
    font-weight: 700;
    color: #2c1a0e;
    text-align: center;
    letter-spacing: -0.03em;
    margin-bottom: 0.5rem;
    line-height: 1;
}

.subtitulo-app {
    text-align: center;
    color: #a07850;
    font-size: 0.78rem;
    letter-spacing: 0.22em;
    text-transform: uppercase;
    margin-bottom: 0.8rem;
    font-weight: 300;
}

.header-linea {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    margin: 0.6rem auto 2rem;
    width: fit-content;
}

.header-linea::before,
.header-linea::after {
    content: '';
    width: 60px;
    height: 1px;
    background: linear-gradient(to right, transparent, #c8956c);
}

.header-linea::after {
    background: linear-gradient(to left, transparent, #c8956c);
}

.header-linea-symbol {
    color: #c8956c;
    font-size: 0.7rem;
    letter-spacing: 0.15em;
}

/* Botón secundario — outlined sutil */
.stButton > button {
    border-radius: 10px !important;
    font-family: 'Lato', sans-serif !important;
    font-weight: 600 !important;
    font-size: 0.95rem !important;
    letter-spacing: 0.02em !important;
    padding: 0.55rem 1.2rem !important;
    transition: transform 0.18s ease, box-shadow 0.18s ease, background 0.18s ease, border-color 0.18s ease !important;
    background-color: transparent !important;
    color: #2c1a0e !important;
    border: 1.5px solid #d4b896 !important;
}

.stButton > button p,
.stButton > button span,
.stButton > button div {
    color: #2c1a0e !important;
    font-weight: 600 !important;
}

.stButton > button:hover {
    background-color: #f5e6d8 !important;
    border-color: #c8956c !important;
    transform: translateY(-1px) !important;
    box-shadow: 0 4px 14px rgba(200, 149, 108, 0.2) !important;
}

/* Botón primario — terracota */
.stButton > button[kind="primary"] {
    background: linear-gradient(135deg, #c8956c 0%, #b8845c 100%) !important;
    color: white !important;
    border: none !important;
}

.stButton > button[kind="primary"] p,
.stButton > button[kind="primary"] span,
.stButton > button[kind="primary"] div {
    color: white !important;
    font-weight: 600 !important;
}

.stButton > button[kind="primary"]:hover {
    background: linear-gradient(135deg, #b8845c 0%, #a8744c 100%) !important;
    transform: translateY(-2px) !important;
    box-shadow: 0 6px 20px rgba(200, 149, 108, 0.35) !important;
}

.stButton > button:active {
    transform: scale(0.97) !important;
}

[data-testid="stVerticalBlockBorderWrapper"] {
    border-color: #e0c9b4 !important;
    border-radius: 16px !important;
    background: rgba(255,250,247,0.9) !important;
    padding: 1rem !important;
    box-shadow: 0 2px 12px rgba(160, 120, 80, 0.08) !important;
}

div[data-testid="stAlert"] {
    border-radius: 12px !important;
    border: none !important;
    padding: 0.9rem 1.1rem !important;
    box-shadow: 0 2px 8px rgba(0,0,0,0.05) !important;
}

.stSuccess {
    background: linear-gradient(135deg, #d4edda, #a8d5b5) !important;
    border-left: 4px solid #276749 !important;
}
.stSuccess p, .stSuccess strong, .stSuccess span {
    color: #0f3d22 !important;
    font-weight: 700 !important;
}

.stWarning {
    background: linear-gradient(135deg, #fffbeb, #fef3c7) !important;
    border-left: 4px solid #d69e2e !important;
}
.stWarning p, .stWarning strong { color: #744210 !important; }

.stInfo {
    background: linear-gradient(135deg, #ebf8ff, #bee3f8) !important;
    border-left: 4px solid #3182ce !important;
}
.stInfo p { color: #2c5282 !important; }

.stError {
    background: linear-gradient(135deg, #fff5f5, #fed7d7) !important;
    border-left: 4px solid #e53e3e !important;
}
.stError p { color: #742a2a !important; }

hr {
    border: none !important;
    border-top: 1px solid #e8d5c4 !important;
    margin: 1.5rem 0 !important;
}

.stDataFrame {
    border: 1px solid #f0e0d0 !important;
    border-radius: 12px !important;
    overflow: hidden;
}

.stToast {
    background-color: #2c1a0e !important;
    color: white !important;
    border-radius: 12px !important;
    font-family: 'Lato', sans-serif !important;
}

[data-testid="stStatusWidget"] {
    border-radius: 12px !important;
    border-color: #c8956c !important;
    background: #fffaf7 !important;
}

html {
    scroll-behavior: smooth;
}

/* Entrada suave de todo el contenido al cargar */
.main .block-container {
    animation: fadeIn 0.4s ease-out;
}

/* Pulso para stock crítico */
@keyframes pulse-red {
    0%, 100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
    50%       { box-shadow: 0 0 0 6px rgba(239, 68, 68, 0); }
}

.stock-critico-badge {
    animation: pulse-red 2s ease-in-out infinite;
}

/* Entrada de tarjetas con stagger */
@keyframes slideUpFade {
    from { opacity: 0; transform: translateY(12px); }
    to   { opacity: 1; transform: translateY(0); }
}

.perfume-card {
    animation: slideUpFade 0.3s ease-out both;
}

"""