# Imagem base: Python ja instalado, versao enxuta ("slim")
FROM python:3.12-slim

# Pasta de trabalho dentro do conteiner
WORKDIR /app

# Instala as dependencias primeiro (aproveita cache do Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o resto do projeto (main.py, templates/, ...)
COPY . .

# Dentro do conteiner o Flask escuta na porta 5000
EXPOSE 5000

# Comando que sobe a aplicacao quando o conteiner inicia
CMD ["python", "main.py"]
