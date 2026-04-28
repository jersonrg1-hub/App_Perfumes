import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from datetime import timedelta
from config import fmt_precio, hoy_peru

COLORES = {
    "primary": "#2c1a0e",
    "accent": "#c8956c",
    "light": "#f5e6d8",
    "medium": "#a07850",
    "bg": "#fdf6f0",
    "grid": "#f0e0d0",
}

def _layout(title):
    return dict(
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor=COLORES["bg"],
        font=dict(family="Lato, sans-serif", color=COLORES["primary"], size=12),
        margin=dict(l=30, r=20, t=40, b=60),
        title=dict(text=title, font=dict(size=15, color=COLORES["primary"]), x=0),
        xaxis=dict(
            gridcolor=COLORES["grid"],
            linecolor=COLORES["grid"],
            tickfont=dict(color=COLORES["primary"], size=12),
            tickformat="%d/%m",
        ),
        yaxis=dict(
            gridcolor=COLORES["grid"],
            linecolor=COLORES["grid"],
            tickfont=dict(color=COLORES["primary"], size=12),
            tickprefix="S/ ",
        ),
        legend=dict(
            orientation="h",
            y=-0.2,
            font=dict(color=COLORES["primary"], size=12),
            bgcolor="rgba(0,0,0,0)",
        ),
        hoverlabel=dict(
            bgcolor=COLORES["primary"],
            font_color="white",
            font_size=13,
            bordercolor=COLORES["primary"],
        ),
    )


@st.cache_data(ttl=120)
def _preparar_ventas(df_ventas):
    df = df_ventas.copy()
    if df["Fecha"].dtype == object:
        df["Fecha"] = pd.to_datetime(df["Fecha"].astype(str).str.strip(), errors="coerce")
    return df.dropna(subset=["Fecha"])


def _grafico_barras_dia(df):
    hoy = hoy_peru()
    inicio = hoy - timedelta(days=29)
    df_periodo = df[df["Fecha"].dt.date >= inicio]

    if df_periodo.empty:
        st.info("Sin ventas en los últimos 30 días")
        return

    diario = (
        df_periodo.groupby(df_periodo["Fecha"].dt.date)
        .agg(Ventas=("Precio_Cobrado", "count"), Total=("Precio_Cobrado", "sum"))
        .reset_index()
        .rename(columns={"Fecha": "Dia"})
    )
    diario["Dia"] = pd.to_datetime(diario["Dia"])
    diario["Media7"] = diario["Total"].rolling(7, min_periods=1).mean()

    fig = go.Figure()

    fig.add_trace(go.Bar(
        x=diario["Dia"],
        y=diario["Total"],
        name="Total vendido (S/)",
        marker=dict(
            color=COLORES["accent"],
            line=dict(color=COLORES["primary"], width=0.5)
        ),
        hovertemplate="<b>%{x|%d/%m/%Y}</b><br>Total: S/ %{y:.2f}<br><extra></extra>",
    ))

    fig.add_trace(go.Scatter(
        x=diario["Dia"],
        y=diario["Media7"],
        name="Media móvil 7 días",
        line=dict(color=COLORES["primary"], width=2, dash="dot"),
        marker=dict(size=5, color=COLORES["primary"]),
        hovertemplate="<b>%{x|%d/%m/%Y}</b><br>Media: S/ %{y:.2f}<extra></extra>",
    ))

    layout = _layout("Ventas por día — últimos 30 días")
    layout["yaxis"]["title"] = dict(text="Total (S/)", font=dict(color=COLORES["medium"]))
    layout["xaxis"]["title"] = dict(text="Fecha", font=dict(color=COLORES["medium"]))
    layout["bargap"] = 0.3

    fig.update_layout(**layout)
    st.plotly_chart(fig, use_container_width=True, config={"responsive": True})

    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Total período", f"S/ {fmt_precio(diario['Total'].sum())}")
    with col2:
        st.metric("Días con ventas", f"{(diario['Total'] > 0).sum()} de {len(diario)}")
    with col3:
        st.metric("Promedio diario", f"S/ {fmt_precio(diario['Total'].mean())}")


def _grafico_linea_mensual(df):
    df_valido = df[df["Fecha"].notna()]
    mensual = (
        df_valido.groupby(df_valido["Fecha"].dt.to_period("M"))
        .agg(Ventas=("Precio_Cobrado", "count"), Total=("Precio_Cobrado", "sum"))
        .reset_index()
    )
    mensual["Mes"] = mensual["Fecha"].dt.to_timestamp()
    mensual["MesLabel"] = mensual["Mes"].dt.strftime("%b %Y")

    if len(mensual) < 2:
        st.info("Se necesitan al menos 2 meses de datos para la tendencia")
        return

    fig = go.Figure()

    fig.add_trace(go.Scatter(
        x=mensual["MesLabel"],
        y=mensual["Total"],
        name="Total mensual (S/)",
        mode="lines+markers+text",
        line=dict(color=COLORES["accent"], width=3),
        marker=dict(size=10, color=COLORES["primary"], line=dict(color=COLORES["accent"], width=2)),
        fill="tozeroy",
        fillcolor="rgba(200,149,108,0.12)",
        text=[f"S/ {fmt_precio(v)}" for v in mensual["Total"]],
        textposition="top center",
        textfont=dict(color=COLORES["primary"], size=11),
        hovertemplate="<b>%{x}</b><br>Total: S/ %{y:.2f}<extra></extra>",
    ))

    fig.add_trace(go.Scatter(
        x=mensual["MesLabel"],
        y=mensual["Ventas"],
        name="N° de ventas",
        mode="lines+markers+text",
        line=dict(color=COLORES["medium"], width=2, dash="dash"),
        marker=dict(size=7, color=COLORES["medium"]),
        yaxis="y2",
        text=[str(v) for v in mensual["Ventas"]],
        textposition="bottom center",
        textfont=dict(color=COLORES["medium"], size=11),
        hovertemplate="<b>%{x}</b><br>Ventas: %{y}<extra></extra>",
    ))

    layout = _layout("Tendencia mensual")
    layout["yaxis"]["title"] = dict(text="Total (S/)", font=dict(color=COLORES["accent"]))
    layout["yaxis2"] = dict(
        overlaying="y", side="right",
        tickfont=dict(color=COLORES["medium"], size=12),
        title=dict(text="N° ventas", font=dict(color=COLORES["medium"])),
        gridcolor="rgba(0,0,0,0)",
        linecolor="rgba(0,0,0,0)",
    )
    layout["xaxis"]["tickangle"] = -30

    fig.update_layout(**layout)
    st.plotly_chart(fig, use_container_width=True, config={"responsive": True})

    mejor = mensual.loc[mensual["Total"].idxmax()]
    col1, col2 = st.columns(2)
    with col1:
        st.metric("Mejor mes", f"{mejor['MesLabel']} — S/ {fmt_precio(mejor['Total'])}")
    with col2:
        variacion = mensual["Total"].pct_change().iloc[-1] * 100 if len(mensual) > 1 else 0
        st.metric("Variación último mes", f"{variacion:+.1f}%")


def mostrar_graficos(df_ventas):
    if df_ventas.empty:
        st.info("📭 No hay ventas para graficar")
        return

    if "Precio_Cobrado" not in df_ventas.columns or "Fecha" not in df_ventas.columns:
        st.warning("⚠️ Faltan columnas Fecha o Precio_Cobrado")
        return

    df = _preparar_ventas(df_ventas)

    if df.empty:
        st.info("📭 No hay ventas con fechas válidas")
        return

    st.markdown("#### 📊 Ventas por día")
    _grafico_barras_dia(df)

    st.markdown("---")
    st.markdown("#### 📈 Tendencia mensual")
    _grafico_linea_mensual(df)