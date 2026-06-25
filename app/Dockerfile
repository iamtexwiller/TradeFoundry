FROM python:3.12-slim

WORKDIR /app

# Instala dependências antes de copiar o código — aproveita cache de
# camadas do Docker quando só o código muda, não as dependências.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Executa como usuário não-root, seguindo o mesmo princípio de menor
# privilégio já usado pela imagem nginx-unprivileged no restante do projeto.
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
