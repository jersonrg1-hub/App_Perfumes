BASE = """
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&family=Lato:wght@300;400;600&display=swap');

html, body, .stApp {
    font-family: 'Lato', sans-serif;
    color: #2c1a0e;
    font-size: 16px;
    line-height: 1.7;
}

.stApp {
    background-color: #fdf6f0 !important;
}

.main { background-color: #fdf6f0; }

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

h1 { font-size: 2.2rem !important; margin-bottom: 1rem !important; }
h2 { font-size: 1.8rem !important; margin-bottom: 0.8rem !important; }
h3 { font-size: 1.4rem !important; margin-bottom: 0.6rem !important; }
h4 { font-size: 1.15rem !important; margin-bottom: 0.5rem !important; }

.titulo-app {
    font-family: 'Playfair Display', serif;
    font-size: 3rem;
    font-weight: 700;
    color: #2c1a0e;
    text-align: center;
    letter-spacing: -0.02em;
    margin-bottom: 0.3rem;
    line-height: 1.1;
}

.subtitulo-app {
    text-align: center;
    color: #a07850;
    font-size: 0.8rem;
    letter-spacing: 0.22em;
    text-transform: uppercase;
    margin-bottom: 2.5rem;
    font-weight: 300;
}

.stButton > button {
    border-radius: 10px !important;
    font-family: 'Lato', sans-serif !important;
    font-weight: 600 !important;
    font-size: 0.95rem !important;
    letter-spacing: 0.02em !important;
    padding: 0.55rem 1.2rem !important;
    transition: transform 0.18s ease, box-shadow 0.18s ease !important;
}

.stButton > button[kind="primary"] {
    background: linear-gradient(135deg, #2c1a0e, #5c3a1e) !important;
    color: white !important;
    border: none !important;
}

.stButton > button[kind="primary"]:hover {
    transform: translateY(-2px) !important;
    box-shadow: 0 6px 20px rgba(44, 26, 14, 0.28) !important;
}

.stButton > button[kind="primary"] p,
.stButton > button[kind="primary"] span,
.stButton > button[kind="primary"] div {
    color: white !important;
    font-weight: 600 !important;
}

.stButton > button[kind="secondary"] {
    border-color: #c8956c !important;
    color: #2c1a0e !important;
}

.stButton > button[kind="secondary"]:hover {
    background-color: #f5e6d8 !important;
    transform: translateY(-1px) !important;
}

.stButton > button:active {
    transform: scale(0.97) !important;
}

[data-testid="stVerticalBlockBorderWrapper"] {
    border-color: #e0c9b4 !important;
    border-radius: 14px !important;
    background: #fffaf7 !important;
    padding: 0.8rem !important;
}

div[data-testid="stAlert"] {
    border-radius: 12px !important;
    border: none !important;
    padding: 0.9rem 1.1rem !important;
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

.stWarning p, .stWarning strong {
    color: #744210 !important;
}

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

.element-container {
    margin-bottom: 0.6rem;
}

[data-testid="stStatusWidget"] {
    border-radius: 12px !important;
    border-color: #c8956c !important;
    background: #fffaf7 !important;
}
"""