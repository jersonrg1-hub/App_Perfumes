ANIMATIONS = """
    /* ── ANIMACIONES ── */
    .stApp {
        animation: fadeIn 0.6s ease-in-out;
    }

    .precio-box {
        animation: slideUp 0.5s ease-out;
    }

    .perfume-card {
        animation: slideUp 0.4s ease-out;
    }

    .perfume-item {
        animation: fadeIn 0.3s ease-in-out;
    }

    @keyframes fadeIn {
        from { opacity: 0; }
        to   { opacity: 1; }
    }

    @keyframes slideUp {
        from { opacity: 0; transform: translateY(20px); }
        to   { opacity: 1; transform: translateY(0);    }
    }

    [data-testid="column"] {
        transition: all 0.2s ease;
    }

    div[style*="linear-gradient(135deg, #2c1a0e"] {
        animation: slideUp 0.4s ease-out;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    div[style*="linear-gradient(135deg, #2c1a0e"]:hover {
        transform: translateY(-3px);
        box-shadow: 0 8px 25px rgba(44, 26, 14, 0.35) !important;
    }
"""