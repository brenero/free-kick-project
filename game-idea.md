Com prazer! A mecânica que definimos é uma fusão sofisticada e tática de estratégia (deckbuilding) e habilidade (execução).

Aqui está um resumo das mecânicas básicas do seu jogo de **Roguelike de Bater Falta (Freekick Deckbuilder)**, dividido em partes para suas anotações:

---

## I. 🔄 Fluxo Central da Jogada (Turno de Batalha)

A "batalha" é resolvida em um ciclo de três fases, onde cada cobrança de falta é um turno:

1.  **Fase Tática:** Jogador joga cartas para modificar o chute.
2.  **Fase de Mira:** Jogador posiciona o ponto de impacto desejado ($P_{desejado}$).
3.  **Fase de Execução:** Jogador executa o mini-game de *timing* para definir o erro final.

---

## II. 🃏 Fase Tática: Cartas e Potencial

As cartas não chutam a bola por você; elas definem o **potencial** máximo da sua execução.

* **Recurso:** **Energia** (ou Foco) é o recurso gasto para jogar cartas.
* **Função dos Cards:** Os cards modificam os **parâmetros de execução** antes do chute:
    * **Cartas de Precisão:** Reduzem o **Raio de Precisão ($R$)** do chute (o Círculo de Erro).
    * **Cartas de Força:** Aumentam o **`MAX_KICK_POWER`** e/ou o **`SHOT_MULTIPLIER`**.
    * **Cartas de Efeito/Status:** Aplicam bônus de curva garantida ou *debuffs* na defesa do goleiro.
* **Visualização Crucial:** O **Círculo de Precisão** na tela se atualiza em **tempo real** conforme as cartas são jogadas, mostrando a área máxima de erro.

---

## III. 🎯 Fase de Mira e Precisão

Esta fase estabelece o risco/recompensa. O tamanho do círculo de precisão é definido pelas cartas.

1.  **Ponto Desejado ($P_{desejado}$):** O jogador usa o controle (mouse/WASD/gamepad) para escolher o ponto exato no gol (ex: ângulo superior).
2.  **Risco da Posição:**
    * **Ângulo Superior:** Alto risco, pois um erro pode levar a bola **para fora** do gol (devido ao Círculo de Erro).
    * **Centro/Meia Altura:** Risco menor de chutar para fora, mas maior chance de o **goleiro defender** (devido ao tempo de reação).
3.  **Fórmula do Ponto Final de Impacto ($P_{real}$):**
    $$
    P_{real} = P_{desejado} + (Vetor\ Aleatório \times R \times E_{%})
    $$
    Onde $R$ (Raio de Precisão) é o resultado das cartas e $E_{%}$ (Erro de Execução) é o resultado do mini-game.

---

## IV. 🎮 Fase de Execução: O Mini-Game de Habilidade

O jogador executa um **mini-game clássico de barra de *timing*** para definir o **Erro de Execução ($E_{%})$**.

### A. O Chute Normal (Controle)

* **Mini-Game:** O jogador pressiona e solta o botão de chute no momento ideal.
* **Resultado:** Onde o cursor para na barra define o **Percentual de Erro ($E_{%})$** (de $0\%$ a $100\%$).
* **Acerto Perfeito ($E_{%} = 0\%$):** O chute vai **exatamente** para $P_{desejado}$.
* **Erro Parcial:** $E_{%}$ alto, resultando no desvio da bola para um ponto dentro do Raio de Precisão ($R$).

### B. O Overshoot (A Punição Máxima)

* **Mecanismo:** Se o jogador **carregar demais** a barra (o cursor entra na zona de *overshoot* e o botão não é solto a tempo).
* **Punição:** O *overshoot* força a jogada a ser um **Chute para Fora**.
    * $E_{%}$ é forçado a **$100\%$**.
    * O Raio de Precisão ($R$) é ignorado e substituído por um **Raio de Overshoot ($R_{overshoot}$)**, maior e direcional, que garante que o ponto final de impacto esteja **fora da área do gol**.
    * A força do chute sofre uma **penalidade** (redução).

---

## V. 💻 Tecnologia e Física

* **Motor:** Godot 4.5.
* **Física:** Uso do **Jolt Physics** (Plugin) para resolver de forma confiável o problema de **túnel de colisão** e colisões de alta velocidade (quando a bola bate na trave).