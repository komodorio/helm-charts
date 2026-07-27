import base64

from helpers.helm_helper import get_yaml_from_helm_template, helm_agent_template

TLS_SECRET_NAME = "komodor-admission-controller-tls"

FAKE_TLS_CERT = base64.b64encode(b"test-tls-cert").decode()
FAKE_TLS_KEY = base64.b64encode(b"test-tls-key").decode()
FAKE_CA_CERT = base64.b64encode(b"test-ca-cert").decode()


def test_static_tls_cert_data_uses_provided_values():
    values_file = f"""
capabilities:
  admissionController:
    enabled: true
    webhookServer:
      staticTlsCertData:
        tlsCert: "{FAKE_TLS_CERT}"
        tlsKey: "{FAKE_TLS_KEY}"
        caCert: "{FAKE_CA_CERT}"
"""
    secret_data = get_yaml_from_helm_template("test=test", "Secret", TLS_SECRET_NAME, ["data"], values_file=values_file)

    assert secret_data["tls.crt"] == FAKE_TLS_CERT, f"Expected tls.crt={FAKE_TLS_CERT}, got: {secret_data['tls.crt']}"
    assert secret_data["tls.key"] == FAKE_TLS_KEY, f"Expected tls.key={FAKE_TLS_KEY}, got: {secret_data['tls.key']}"
    assert secret_data["ca.crt"] == FAKE_CA_CERT, f"Expected ca.crt={FAKE_CA_CERT}, got: {secret_data['ca.crt']}"


def test_static_tls_cert_data_partial_falls_through_to_generation():
    # Only one of three fields set — should fall through to cert generation without crashing
    values_file = f"""
capabilities:
  admissionController:
    enabled: true
    webhookServer:
      staticTlsCertData:
        tlsCert: "{FAKE_TLS_CERT}"
"""
    secret_data = get_yaml_from_helm_template("test=test", "Secret", TLS_SECRET_NAME, ["data"], values_file=values_file)

    assert secret_data["tls.crt"] != FAKE_TLS_CERT, "Expected tls.crt to be generated, not the fake value"
    assert secret_data["tls.key"] != FAKE_TLS_KEY, "Expected tls.key to be generated, not the fake value"
    assert secret_data["ca.crt"] != FAKE_CA_CERT, "Expected ca.crt to be generated, not the fake value"


def test_static_tls_cert_data_null_does_not_crash():
    # staticTlsCertData explicitly null — should fall through to cert generation without crashing
    values_file = """
capabilities:
  admissionController:
    enabled: true
    webhookServer:
      staticTlsCertData:
"""
    secret_data = get_yaml_from_helm_template("test=test", "Secret", TLS_SECRET_NAME, ["data"], values_file=values_file)

    assert secret_data["tls.crt"] != FAKE_TLS_CERT, "Expected tls.crt to be generated, not the fake value"
    assert secret_data["tls.key"] != FAKE_TLS_KEY, "Expected tls.key to be generated, not the fake value"
    assert secret_data["ca.crt"] != FAKE_CA_CERT, "Expected ca.crt to be generated, not the fake value"
