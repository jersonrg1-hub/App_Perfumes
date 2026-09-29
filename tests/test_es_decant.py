"""Tests de config.es_decant() — regla compartida 'es este ml un decant'."""
from backend.core.config import es_decant


def test_es_decant_true_para_tamanos_decant():
    assert es_decant(2) is True
    assert es_decant(5) is True
    assert es_decant(10) is True


def test_es_decant_false_para_tamanos_completo():
    assert es_decant(50) is False
    assert es_decant(100) is False


def test_es_decant_acepta_string_numerico():
    assert es_decant("5") is True
    assert es_decant("5.0") is True


def test_es_decant_no_lanza_con_valor_corrupto():
    assert es_decant("texto_invalido") is False
    assert es_decant(None) is False
    assert es_decant("") is False
