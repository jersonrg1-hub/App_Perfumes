ANIMATIONS = """
.stApp {
    animation: fadeIn 0.5s ease-in-out;
}

.perfume-card {
    animation: slideUp 0.35s ease-out;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.perfume-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(160, 120, 80, 0.18) !important;
}

.precio-card {
    animation: slideUp 0.4s ease-out;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.precio-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 25px rgba(44, 26, 14, 0.3) !important;
}

.perfume-item {
    animation: fadeIn 0.3s ease-in-out;
    transition: all 0.22s ease;
}

.perfume-item:hover {
    background: #fff3eb;
    border-color: #c8956c;
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(160, 120, 80, 0.16);
}

.stTabs [data-baseweb="tab-panel"] {
    animation: fadeIn 0.25s ease-in-out;
}

[data-testid="column"] {
    transition: all 0.18s ease;
}

.streamlit-expanderHeader {
    transition: background-color 0.18s ease !important;
}

.stButton > button:active {
    transform: scale(0.97) !important;
}

.stSuccess, .stError, .stWarning, .stInfo {
    animation: slideIn 0.25s ease-out;
}

.stProgress > div > div {
    transition: width 0.4s ease !important;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to   { opacity: 1; }
}

@keyframes slideUp {
    from { opacity: 0; transform: translateY(16px); }
    to   { opacity: 1; transform: translateY(0); }
}

@keyframes slideIn {
    from { opacity: 0; transform: translateX(-8px); }
    to   { opacity: 1; transform: translateX(0); }
}

@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
        animation-duration: 0.01ms !important;
        transition-duration: 0.01ms !important;
    }
}
"""