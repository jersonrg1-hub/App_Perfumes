FORMS = """
    /* CORRECCIÓN #5: forms.py es la fuente única de verdad para inputs
       se eliminaron los estilos de inputs de base.py para evitar conflictos */

    /* ── CONTENEDOR DE FORMULARIO ── */
    /* MEJORA #6: estilo para st.container(border=True) del form de venta */
    [data-testid="stVerticalBlockBorderWrapper"] {
        border-color: #e0c9b4 !important;
        border-radius: 12px !important;
        background: #fffaf7 !important;
        padding: 0.5rem !important;
    }

    /* ── SELECTBOX ── */
    .stSelectbox div[data-baseweb="select"],
    div[data-baseweb="select"] {
        background-color: #ffffff !important;
        border-color: #e0c9b4 !important;
        border-radius: 8px !important;
    }

    div[data-baseweb="select"]:focus-within {
        border-color: #c8956c !important;
        box-shadow: 0 0 0 2px rgba(200, 149, 108, 0.2) !important;
    }

    div[data-baseweb="select"] *,
    .stSelectbox div[data-baseweb="select"] span,
    .stSelectbox div[data-baseweb="select"] div,
    .stSelectbox [data-baseweb="select"] input {
        color: #2c1a0e !important;
        background-color: #ffffff !important;
    }

    /* ── INPUTS DE TEXTO ── */
    .stTextInput input,
    .stNumberInput input {
        background-color: #ffffff !important;
        color: #2c1a0e !important;
        border-color: #e0c9b4 !important;
        border-radius: 8px !important;
        cursor: text !important;
    }

    .stTextInput input::placeholder {
        color: #a07850 !important;
        opacity: 1 !important;
    }

    /* MEJORA #7: focus visible en inputs */
    .stTextInput input:focus,
    .stNumberInput input:focus {
        border-color: #c8956c !important;
        box-shadow: 0 0 0 2px rgba(200, 149, 108, 0.2) !important;
        outline: none !important;
    }

    /* ── DATE INPUT ── */
    .stDateInput input {
        background-color: #ffffff !important;
        color: #2c1a0e !important;
        border-color: #e0c9b4 !important;
        border-radius: 8px !important;
    }

    .stDateInput input:focus {
        border-color: #c8956c !important;
        box-shadow: 0 0 0 2px rgba(200, 149, 108, 0.2) !important;
        outline: none !important;
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