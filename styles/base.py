BASE = """
:root {
    --c-primary:       #b8724a;
    --c-primary-light: #c8956c;
    --c-primary-pale:  #f0ddd0;
    --c-gold:          #c9a96e;
    --c-bg:            #faf4ed;
    --c-bg-card:       #ffffff;
    --c-border:        #e5cdb8;
    --c-border-light:  #ede0d4;
    --c-text:          #1e1209;
    --c-text-mid:      #4a2e18;
    --c-text-muted:    #8b6640;
    --c-text-faint:    #b89878;
    --shadow-xs:  0 1px 3px rgba(90,50,20,0.07);
    --shadow-sm:  0 2px 8px rgba(90,50,20,0.09);
    --shadow-md:  0 6px 20px rgba(90,50,20,0.12);
    --shadow-lg:  0 12px 36px rgba(90,50,20,0.16);
    --radius-sm:  8px;
    --radius-md:  12px;
    --radius-lg:  16px;
    --radius-xl:  20px;
}

html, body, .stApp {
    font-family: 'Lato', sans-serif;
    color: var(--c-text);
    font-size: 16px;
    line-height: 1.7;
}

.stApp {
    background-color: var(--c-bg) !important;
    background-image:
        radial-gradient(ellipse at 10% 0%,   rgba(200,149,108,0.09) 0%, transparent 55%),
        radial-gradient(ellipse at 90% 100%, rgba(180,120,70,0.07)  0%, transparent 55%),
        radial-gradient(ellipse at 50% 50%,  rgba(250,244,237,0)    0%, transparent 100%);
}

.main { background-color: transparent; }

section[data-testid="stSidebar"] {
    background-color: #f2e4d6 !important;
    border-right: 1px solid var(--c-border) !important;
}

.stMarkdown p,
.stMarkdown strong,
.stMarkdown span,
[data-testid="column"] p,
[data-testid="column"] strong,
[data-testid="stText"] {
    color: var(--c-text) !important;
    line-height: 1.7;
}

.stCaptionContainer p {
    color: var(--c-text-muted) !important;
    font-size: 0.85rem;
    letter-spacing: 0.03em;
}

h1, h2, h3, h4 {
    font-family: 'Playfair Display', serif !important;
    color: var(--c-text) !important;
    letter-spacing: -0.01em;
    line-height: 1.3;
}

/* ── ENCABEZADO ── */
.header-wrapper {
    text-align: center;
    padding: 1.8rem 1rem 0.6rem;
    margin-bottom: 0.5rem;
    position: relative;
    /* Sticky top-bar en móvil para tener siempre el nombre visible */
    background: var(--c-bg);
}

.header-ornamento {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    margin-bottom: 1rem;
}

.header-ornamento-dot {
    width: 4px;
    height: 4px;
    background: var(--c-gold);
    border-radius: 50%;
    opacity: 0.7;
}

.titulo-app {
    font-family: 'Playfair Display', serif;
    font-size: 3.2rem;
    font-weight: 700;
    background: linear-gradient(135deg, #2c1a0e 0%, #7a4020 60%, #c8956c 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    text-align: center;
    letter-spacing: -0.03em;
    margin-bottom: 0.5rem;
    line-height: 1;
}

.subtitulo-app {
    text-align: center;
    color: var(--c-text-muted);
    font-size: 0.75rem;
    letter-spacing: 0.28em;
    text-transform: uppercase;
    margin-bottom: 0.8rem;
    font-weight: 400;
}

.header-linea {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    margin: 0.5rem auto 2rem;
    width: fit-content;
}

.header-linea::before,
.header-linea::after {
    content: '';
    width: 72px;
    height: 1px;
    background: linear-gradient(to right, transparent, var(--c-gold));
}

.header-linea::after {
    background: linear-gradient(to left, transparent, var(--c-gold));
}

.header-linea-symbol {
    color: var(--c-gold);
    font-size: 0.65rem;
    letter-spacing: 0.2em;
    opacity: 0.85;
}

/* ── BOTONES ── */
.stButton > button {
    border-radius: var(--radius-md) !important;
    font-family: 'Lato', sans-serif !important;
    font-weight: 600 !important;
    font-size: 0.92rem !important;
    letter-spacing: 0.03em !important;
    padding: 0.55rem 1.3rem !important;
    transition: transform 0.18s ease, box-shadow 0.18s ease, background 0.2s ease, border-color 0.2s ease !important;
    background-color: transparent !important;
    color: var(--c-text-mid) !important;
    border: 1.5px solid var(--c-border) !important;
    box-shadow: var(--shadow-xs) !important;
}

.stButton > button p,
.stButton > button span,
.stButton > button div {
    color: var(--c-text-mid) !important;
    font-weight: 600 !important;
}

.stButton > button:hover {
    background-color: var(--c-primary-pale) !important;
    border-color: var(--c-primary-light) !important;
    transform: translateY(-1px) !important;
    box-shadow: 0 4px 16px rgba(184,114,74,0.18) !important;
}

.stButton > button[kind="primary"] {
    background: linear-gradient(135deg, #c8956c 0%, #a8643c 100%) !important;
    color: #fff8f4 !important;
    border: none !important;
    box-shadow: 0 3px 12px rgba(184,114,74,0.3) !important;
}

.stButton > button[kind="primary"] p,
.stButton > button[kind="primary"] span,
.stButton > button[kind="primary"] div {
    color: #fff8f4 !important;
    font-weight: 600 !important;
}

.stButton > button[kind="primary"]:hover {
    background: linear-gradient(135deg, #b8845c 0%, #984030 100%) !important;
    transform: translateY(-2px) !important;
    box-shadow: 0 7px 22px rgba(184,114,74,0.38) !important;
}

.stButton > button:active {
    transform: scale(0.97) !important;
    box-shadow: none !important;
    transition: transform 0.13s cubic-bezier(0.23, 1, 0.32, 1) !important;
}

[data-testid="stVerticalBlockBorderWrapper"] {
    border-color: var(--c-border) !important;
    border-radius: var(--radius-lg) !important;
    background: rgba(255,252,249,0.92) !important;
    padding: 1rem !important;
    box-shadow: var(--shadow-sm) !important;
}

div[data-testid="stAlert"] {
    border-radius: var(--radius-md) !important;
    border: none !important;
    padding: 0.9rem 1.1rem !important;
    box-shadow: var(--shadow-xs) !important;
}

.stSuccess {
    background: linear-gradient(135deg, #edfaf3, #d1f5e3) !important;
    border-left: 3px solid #2e9e65 !important;
}
.stSuccess p, .stSuccess strong, .stSuccess span {
    color: #0e4028 !important;
    font-weight: 700 !important;
}

.stWarning {
    background: linear-gradient(135deg, #fffbeb, #fef3c7) !important;
    border-left: 3px solid #d69e2e !important;
}
.stWarning p, .stWarning strong { color: #744210 !important; }

.stInfo {
    background: linear-gradient(135deg, #f0f7ff, #dbeafe) !important;
    border-left: 3px solid #3b82f6 !important;
}
.stInfo p { color: #1e3a6e !important; }

.stError {
    background: linear-gradient(135deg, #fff5f5, #ffe4e4) !important;
    border-left: 3px solid #e53e3e !important;
}
.stError p { color: #742a2a !important; }

hr {
    border: none !important;
    border-top: 1px solid var(--c-border-light) !important;
    margin: 1.5rem 0 !important;
}

.stDataFrame {
    border: 1px solid var(--c-border-light) !important;
    border-radius: var(--radius-md) !important;
    overflow: hidden;
    box-shadow: var(--shadow-xs) !important;
}

.stToast {
    background-color: #1e1209 !important;
    color: #f5e6d8 !important;
    border-radius: var(--radius-md) !important;
    font-family: 'Lato', sans-serif !important;
    box-shadow: var(--shadow-md) !important;
}

[data-testid="stStatusWidget"] {
    border-radius: var(--radius-md) !important;
    border-color: var(--c-primary-light) !important;
    background: #fffaf7 !important;
}

html {
    scroll-behavior: smooth;
}

@keyframes fadeIn {
    from { opacity: 0; transform: translateY(6px); }
    to   { opacity: 1; transform: translateY(0); }
}

.main .block-container {
    animation: fadeIn 0.35s ease-out;
}

@keyframes pulse-red {
    0%, 100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
    50%       { box-shadow: 0 0 0 6px rgba(239, 68, 68, 0); }
}

.stock-critico-badge {
    animation: pulse-red 2s ease-in-out infinite;
}

@keyframes slideUpFade {
    from { opacity: 0; transform: translateY(14px); }
    to   { opacity: 1; transform: translateY(0); }
}

.perfume-card {
    animation: slideUpFade 0.28s ease-out both;
}

@keyframes fadeInUp {
    from { opacity: 0; transform: translateY(8px); }
    to   { opacity: 1; transform: translateY(0); }
}

@keyframes celebrarEntrada {
    from { opacity: 0; transform: scale(0.96) translateY(-6px); }
    to   { opacity: 1; transform: scale(1)    translateY(0); }
}

@keyframes formEntrada {
    from { opacity: 0; transform: translateY(6px); }
    to   { opacity: 1; transform: translateY(0); }
}

/* Hover en cards de cotizaciones e items de cesta */
@media (hover: hover) and (pointer: fine) {
    .cot-card {
        transition: transform 180ms ease-out, box-shadow 180ms ease-out;
    }
    .cot-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 18px rgba(200,149,108,0.2) !important;
    }
    .item-cesta-card {
        transition: transform 160ms ease-out, box-shadow 160ms ease-out;
    }
    .item-cesta-card:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(44,26,14,0.12) !important;
    }
}

/* Press state en botones WhatsApp */
.wa-btn {
    transition: transform 130ms cubic-bezier(0.23, 1, 0.32, 1), filter 130ms ease-out !important;
}
.wa-btn:active {
    transform: scale(0.98) !important;
    filter: brightness(0.91) !important;
}

/* Animación entrada formulario de conversión inline */
.conv-form-entrada {
    animation: formEntrada 200ms cubic-bezier(0.23, 1, 0.32, 1) both;
}

"""