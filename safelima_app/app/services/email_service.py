import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


def send_reset_email(to_email: str, codigo: str):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    mail_from = os.getenv("MAIL_FROM")

    print("SMTP_HOST:", smtp_host)
    print("SMTP_PORT:", smtp_port)
    print("SMTP_USER:", smtp_user)
    print("MAIL_FROM:", mail_from)

    if not smtp_host or not smtp_user or not smtp_password or not mail_from:
        raise ValueError("Faltan variables SMTP en el .env")

    subject = "Recuperación de contraseña - SafeLima"

    body = f"""
Hola,

Recibimos una solicitud para restablecer tu contraseña en SafeLima.

Tu código de recuperación es: {codigo}

Este código vencerá en 15 minutos.

Si no solicitaste este cambio, ignora este mensaje.
"""

    msg = MIMEMultipart()
    msg["From"] = mail_from
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    server = smtplib.SMTP(smtp_host, smtp_port)
    server.connect(smtp_host, smtp_port)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
    server.quit()