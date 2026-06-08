import os
from flask import Flask, render_template

app = Flask(__name__)

# =============================================================
#  EDITE AQUI: coloque o nome dos integrantes do seu grupo.
#  Eles vao aparecer automaticamente no site (renderizados
#  pelo Flask). Esse e o papel do "backend": o Python monta
#  a pagina antes de enviar pro navegador.
# =============================================================
integrantes = [
    "Fulano de Tal",
    "Ciclana de Souza",
    "Beltrano Silva",
]


@app.route("/")
def home():
    return render_template("index.html", integrantes=integrantes)


if __name__ == "__main__":
    # A porta vem da variavel de ambiente PORT (se existir),
    # senao usa 5000. Assim o mesmo arquivo funciona tanto
    # rodando direto (PORT=80) quanto dentro do conteiner (5000).
    port = int(os.environ.get("PORT", 5000))
    # host="0.0.0.0" -> aceita conexoes de qualquer lugar (nao so do proprio servidor)
    app.run(host="0.0.0.0", port=port, debug=True)
