COMPONENTS = """
.perfume-card {
    background: #ffffff;
    border: 1px solid #ede0d4;
    border-radius: 14px;
    padding: 1.4rem 1.8rem 1.6rem;
    margin: 1rem 0;
    box-shadow: 0 1px 4px rgba(160, 120, 80, 0.06);
    transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
}

.perfume-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 24px rgba(160, 120, 80, 0.12);
    border-color: #c8956c;
}

.perfume-card .marca {
    font-size: 0.68rem;
    letter-spacing: 0.22em;
    text-transform: uppercase;
    color: #c8956c;
    font-weight: 600;
    margin-bottom: 0.35rem;
    font-family: 'Lato', sans-serif;
}

.perfume-card .nombre {
    font-family: 'Playfair Display', serif;
    font-size: 1.55rem;
    color: #2c1a0e;
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.15;
}

.precio-card {
    background: #ffffff;
    border: 1px solid #ede0d4;
    border-radius: 12px;
    text-align: center;
    margin-bottom: 0.6rem;
    transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
}

.precio-card:hover {
    transform: translateY(-3px);
    border-color: #c8956c;
    box-shadow: 0 6px 18px rgba(160, 120, 80, 0.12) !important;
}

.precio-box {
    background: #fdf6f0;
    border: 1px solid #ede0d4;
    border-radius: 14px;
    padding: 1.6rem;
    text-align: center;
    margin: 1.2rem 0;
    transition: transform 0.2s ease, border-color 0.2s ease;
}

.precio-box:hover {
    transform: translateY(-2px);
    border-color: #c8956c;
}

.precio-box .label {
    color: #a07850;
    font-size: 0.72rem;
    letter-spacing: 0.2em;
    text-transform: uppercase;
    margin-bottom: 0.4rem;
    font-weight: 600;
}

.precio-box .valor {
    color: #2c1a0e;
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

.perfume-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 1.4rem;
    border-radius: 12px;
    margin-bottom: 0.5rem;
    background: white;
    border: 1px solid #ede0d4;
    transition: all 0.2s ease;
}

.perfume-item:hover {
    border-color: #c8956c;
    transform: translateY(-2px);
    box-shadow: 0 4px 14px rgba(160, 120, 80, 0.1);
}

.perfume-item .pf-nombre {
    color: #2c1a0e;
    font-weight: 600;
    font-size: 1rem;
}

.perfume-item .pf-precio {
    color: #c8956c;
    font-weight: 700;
    font-size: 1.1rem;
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

.stButton button {
    border-radius: 10px !important;
    font-family: 'Lato', sans-serif !important;
    font-weight: 600 !important;
    transition: all 0.18s ease !important;
    background-color: #2c1a0e !important;
    color: white !important;
    border: none !important;
}

.stButton button p,
.stButton button span {
    color: white !important;
    font-weight: 600 !important;
}

.stButton button:hover {
    background-color: #3d2512 !important;
    transform: translateY(-1px) !important;
    box-shadow: 0 4px 14px rgba(44, 26, 14, 0.28) !important;
}

.stButton button:active {
    transform: scale(0.97) !important;
    background-color: #1a0f08 !important;
}

.stButton button[kind="primary"] {
    background: linear-gradient(135deg, #2c1a0e 0%, #5c3a1e 100%) !important;
}

.stButton button[kind="primary"]:hover {
    transform: translateY(-2px) !important;
    box-shadow: 0 6px 20px rgba(44, 26, 14, 0.32) !important;
}

[data-testid="stExpanderHeader"] {
    background: #f5e6d8 !important;
    border-radius: 10px !important;
    color: #2c1a0e !important;
    font-family: 'Lato', sans-serif !important;
    font-weight: 600 !important;
    transition: background 0.18s ease !important;
}

[data-testid="stExpanderHeader"]:hover {
    background: #ead5c0 !important;
}

[data-testid="stExpanderHeader"] p,
[data-testid="stExpanderHeader"] span,
[data-testid="stExpanderHeader"] div {
    color: #2c1a0e !important;
}

[data-testid="stExpanderDetails"] {
    background: white !important;
    padding: 1rem !important;
    border: 1px solid #e8d5c4 !important;
    border-top: none !important;
    border-radius: 0 0 12px 12px !important;
}

[data-testid="stExpanderDetails"] p,
[data-testid="stExpanderDetails"] strong,
[data-testid="stExpanderDetails"] li {
    color: #2c1a0e !important;
}

.stMultiSelect > div > div,
.stMultiSelect [data-baseweb="select"] {
    background-color: #ffffff !important;
    border-color: #e0c9b4 !important;
    min-height: 48px !important;
    border-radius: 8px !important;
}

.stMultiSelect [data-baseweb="tag"],
.stMultiSelect span[data-baseweb="tag"] {
    background-color: #2c1a0e !important;
    color: white !important;
    border-radius: 6px !important;
}

.stMultiSelect [data-baseweb="tag"] *,
.stMultiSelect span[data-baseweb="tag"] span {
    color: white !important;
    background-color: transparent !important;
}

div[data-testid="stAlert"] {
    border-radius: 12px !important;
    border: none !important;
    padding: 1rem 1.2rem !important;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important;
}

.stWarning {
    background: linear-gradient(135deg, #fffbeb, #fef3c7) !important;
    border-left: 4px solid #d69e2e !important;
}
.stWarning p, .stWarning strong { color: #744210 !important; font-size: 0.95rem !important; }

.stInfo {
    background: linear-gradient(135deg, #ebf8ff, #bee3f8) !important;
    border-left: 4px solid #3182ce !important;
}
.stInfo p { color: #2c5282 !important; font-size: 0.95rem !important; }

.stSuccess {
    background: linear-gradient(135deg, #d4edda, #a8d5b5) !important;
    border-left: 4px solid #276749 !important;
}
.stSuccess p, .stSuccess strong, .stSuccess span {
    color: #0f3d22 !important;
    font-size: 0.95rem !important;
    font-weight: 700 !important;
}

.stError {
    background: linear-gradient(135deg, #fff5f5, #fed7d7) !important;
    border-left: 4px solid #e53e3e !important;
}
.stError p { color: #742a2a !important; font-size: 0.95rem !important; }

[data-testid="stStatusWidget"] {
    border-radius: 12px !important;
    border-color: #c8956c !important;
    background: #fffaf7 !important;
    font-family: 'Lato', sans-serif !important;
}

@media (max-width: 640px) {
    .titulo-app { font-size: 2rem; }
    .precio-box .valor { font-size: 2.2rem; }
    .perfume-card .nombre { font-size: 1.2rem; }
    .perfume-item { padding: 0.7rem 0.9rem; }
}
"""