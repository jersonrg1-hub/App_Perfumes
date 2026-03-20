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
"""