FORMS = """
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

    /* ── DATE INPUT ── */
    .stDateInput input {
        background-color: #ffffff !important;
        color: #2c1a0e !important;
        border-color: #e0c9b4 !important;
    }

    /* ── LABELS ── */
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
"""