COMPONENTS = """
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
        padding: 2rem;
        text-align: center;
        margin: 1.5rem 0;
        box-shadow: 0 6px 24px rgba(44, 26, 14, 0.3);
        transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .precio-box:hover {
        transform: translateY(-3px);
        box-shadow: 0 10px 30px rgba(44, 26, 14, 0.4);
    }

    .precio-box .label {
        color: #e8c9a8;
        font-size: 0.85rem;
        letter-spacing: 0.2em;
        text-transform: uppercase;
        margin-bottom: 0.5rem;
        font-weight: 300;
    }

    .precio-box .valor {
        color: #ffffff;
        font-family: 'Playfair Display', serif;
        font-size: 3.5rem;
        font-weight: 700;
        line-height: 1;
        text-shadow: 0 2px 8px rgba(0,0,0,0.2);
    }

    .precio-box .tamanio {
        color: #c8956c;
        font-size: 0.9rem;
        margin-top: 0.6rem;
        letter-spacing: 0.12em;
    }

    /* ── LISTA PERFUMES ── */
    .perfume-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 0.9rem 1.2rem;
        border-radius: 12px;
        margin-bottom: 0.6rem;
        background: white;
        border: 1px solid #f0e0d0;
        transition: all 0.25s ease;
        box-shadow: 0 1px 4px rgba(160, 120, 80, 0.08);
    }

    .perfume-item:hover {
        background: #fff3eb;
        border-color: #c8956c;
        transform: translateY(-2px);
        box-shadow: 0 6px 16px rgba(160, 120, 80, 0.18);
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

    .contador {
        font-size: 0.8rem;
        color: #a07850;
        margin-bottom: 1rem;
        font-style: italic;
    }

    /* ── BOTONES ── */
    .stButton button {
        background-color: #2c1a0e !important;
        color: white !important;
        border: none !important;
        border-radius: 8px !important;
        font-weight: 600 !important;
        transition: all 0.2s ease !important;
    }

    .stButton button:hover {
        background-color: #5c3a1e !important;
        color: white !important;
        transform: translateY(-1px) !important;
        box-shadow: 0 4px 12px rgba(44, 26, 14, 0.3) !important;
    }

    .stButton button:active {
        transform: translateY(0) !important;
        background-color: #1a0f08 !important;
    }

    .stButton button[kind="primary"] {
        background-color: #c8956c !important;
    }

    .stButton button[kind="primary"]:hover {
        background-color: #a07850 !important;
    }

    a[href*="wa.me"]:hover {
        opacity: 0.85 !important;
        transform: translateY(-1px) !important;
    }

    /* ── EXPANDER ── */
    .stExpander {
        border: 1px solid #e8d5c4 !important;
        border-radius: 12px !important;
        background: white !important;
    }

    .stExpander summary {
        background: #2c1a0e !important;
        border-radius: 10px !important;
    }

    .stExpander summary span,
    .stExpander summary p {
        color: white !important;
    }

    .stExpander summary:hover {
        background: #5c3a1e !important;
    }

    .stExpander [data-testid="stExpanderDetails"] {
        background: white !important;
        padding: 1rem !important;
    }

    .stExpander [data-testid="stExpanderDetails"] p,
    .stExpander [data-testid="stExpanderDetails"] strong,
    .stExpander [data-testid="stExpanderDetails"] li,
    .stExpander [data-testid="stExpanderDetails"] ul {
        color: #2c1a0e !important;
    }

    .stExpander .stButton button {
        background-color: #2c1a0e !important;
        color: white !important;
    }

    .stExpander .stButton button p,
    .stExpander .stButton button span {
        color: white !important;
    }

    .stExpander .stButton button:hover {
        background-color: #5c3a1e !important;
        color: white !important;
    }

    /* ── MULTISELECT ── */
    .stMultiSelect > div > div,
    .stMultiSelect [data-baseweb="select"] {
        background-color: #ffffff !important;
        border-color: #e0c9b4 !important;
        min-height: 48px !important;
    }

    .stMultiSelect input {
        color: #2c1a0e !important;
    }

    .stMultiSelect [data-baseweb="select"] > div,
    .stMultiSelect [data-baseweb="select"] > div > div {
        background-color: #ffffff !important;
        color: #2c1a0e !important;
    }

    .stMultiSelect li span,
    .stMultiSelect [role="option"] span {
        color: #2c1a0e !important;
    }

    .stMultiSelect [data-baseweb="tag"],
    .stMultiSelect span[data-baseweb="tag"] {
        background-color: #2c1a0e !important;
        color: white !important;
    }

    .stMultiSelect [data-baseweb="tag"] *,
    .stMultiSelect span[data-baseweb="tag"] span {
        color: white !important;
        background-color: transparent !important;
    }

    /* ── MENSAJES ── */
    div[data-testid="stAlert"] {
        border-radius: 12px !important;
        border: none !important;
        padding: 1rem 1.2rem !important;
        box-shadow: 0 2px 8px rgba(0,0,0,0.06) !important;
    }

    /* Warning */
    div[data-testid="stAlert"][data-baseweb="notification"][kind="warning"],
    .stWarning {
        background: linear-gradient(135deg, #fffbeb, #fef3c7) !important;
        border-left: 4px solid #d69e2e !important;
    }

    .stWarning p,
    .stWarning strong,
    [data-testid="stNotification"] p,
    [data-testid="stNotification"] strong,
    div[data-baseweb="notification"] p,
    div[data-baseweb="notification"] strong {
        color: #744210 !important;
        font-size: 0.95rem !important;
    }

    /* Info */
    .stInfo {
        background: linear-gradient(135deg, #ebf8ff, #bee3f8) !important;
        border-left: 4px solid #3182ce !important;
    }

    .stInfo p {
        color: #2c5282 !important;
        font-size: 0.95rem !important;
    }

    /* Success */
    .stSuccess {
        background: linear-gradient(135deg, #f0fff4, #c6f6d5) !important;
        border-left: 4px solid #38a169 !important;
    }

    .stSuccess p {
        color: #276749 !important;
        font-size: 0.95rem !important;
    }

    /* Error */
    .stError {
        background: linear-gradient(135deg, #fff5f5, #fed7d7) !important;
        border-left: 4px solid #e53e3e !important;
    }

    .stError p {
        color: #742a2a !important;
        font-size: 0.95rem !important;
    }
"""