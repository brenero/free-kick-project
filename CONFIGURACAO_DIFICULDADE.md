# Guia de Configuração - Goleiro e Barreira

## Parâmetros do Goleiro

No arquivo [goalkeeper.tscn](scenes/goalkeeper.tscn) ou no inspetor do Godot:

### `reaction_time` (padrão: 0.3)
- Tempo em segundos que o goleiro demora para reagir após o chute
- **Menor valor = Mais difícil** (goleiro reage mais rápido)
- **Maior valor = Mais fácil** (goleiro reage mais devagar)
- Recomendado: 0.2-0.5

### `dive_speed` (padrão: 8.0)
- Velocidade do mergulho do goleiro
- **Maior valor = Mais difícil** (goleiro mais rápido)
- **Menor valor = Mais fácil** (goleiro mais lento)
- Recomendado: 5.0-12.0

### `max_reach` (padrão: 3.0)
- Distância horizontal máxima que o goleiro consegue alcançar (em metros)
- **Maior valor = Mais difícil** (goleiro cobre mais área)
- **Menor valor = Mais fácil** (goleiro cobre menos área)
- Recomendado: 2.0-4.0 (gol tem 7.32m de largura)

### `jump_height` (padrão: 2.0)
- Altura máxima que o goleiro consegue alcançar (em metros)
- **Maior valor = Mais difícil** (goleiro pega bolas mais altas)
- **Menor valor = Mais fácil** (mais espaço em cima)
- Recomendado: 1.5-2.44 (gol tem 2.44m de altura)

### `save_probability` (padrão: 0.7)
- Probabilidade de o goleiro tentar defender (0.0 a 1.0)
- **Maior valor = Mais difícil** (goleiro sempre tenta)
- **Menor valor = Mais fácil** (goleiro às vezes não reage)
- Recomendado: 0.5-0.9

## Parâmetros da Barreira

No arquivo [wall.tscn](scenes/wall.tscn) ou no inspetor do Godot:

### `num_players` (padrão: 5)
- Número de jogadores na barreira
- **Maior valor = Mais difícil** (mais jogadores bloqueando)
- **Menor valor = Mais fácil** (menos jogadores)
- Recomendado: 3-6 jogadores

### `player_spacing` (padrão: 0.7)
- Espaçamento entre jogadores em metros
- **Menor valor = Mais difícil** (barreira mais compacta)
- **Maior valor = Mais fácil** (mais espaços)
- Recomendado: 0.5-1.0

### `player_height` (padrão: 1.8)
- Altura dos jogadores na barreira (em metros)
- **Maior valor = Mais difícil** (jogadores mais altos bloqueiam mais)
- **Menor valor = Mais fácil** (jogadores mais baixos, mais fácil passar por cima)
- Recomendado: 1.6-2.0 (altura média humana)

### `wall_distance` (padrão: 9.15)
- Distância da barreira em relação à bola (em metros)
- Regulamento FIFA: 9.15m
- **Menor valor = Mais difícil** (barreira mais perto)
- **Maior valor = Mais fácil** (barreira mais longe)
- Recomendado: 8.0-10.0

### `jump_chance` (padrão: 0.6)
- Chance dos jogadores pularem (0.0 a 1.0)
- **Maior valor = Mais difícil** (mais jogadores pulam)
- **Menor valor = Mais fácil** (menos jogadores pulam)
- Recomendado: 0.4-0.8

### `jump_delay` (padrão: 0.4)
- Tempo em segundos antes da barreira pular após o chute
- **Menor valor = Mais difícil** (pula mais cedo)
- **Maior valor = Mais fácil** (dá tempo de passar)
- Recomendado: 0.3-0.6

### `jump_height` (padrão: 0.8)
- Altura do pulo dos jogadores em metros
- **Maior valor = Mais difícil** (bloqueiam bolas mais altas)
- **Menor valor = Mais fácil** (deixam espaço em cima)
- Recomendado: 0.5-1.2

## Níveis de Dificuldade Sugeridos

### Fácil
```gdscript
# Goleiro
reaction_time = 0.5
dive_speed = 6.0
max_reach = 2.5
jump_height = 1.8
save_probability = 0.5

# Barreira
num_players = 3
player_height = 1.6
jump_chance = 0.4
jump_delay = 0.5
jump_height = 0.6
```

### Médio (Padrão)
```gdscript
# Goleiro
reaction_time = 0.3
dive_speed = 8.0
max_reach = 3.0
jump_height = 2.0
save_probability = 0.7

# Barreira
num_players = 5
player_height = 1.8
jump_chance = 0.6
jump_delay = 0.4
jump_height = 0.8
```

### Difícil
```gdscript
# Goleiro
reaction_time = 0.2
dive_speed = 10.0
max_reach = 3.5
jump_height = 2.2
save_probability = 0.85

# Barreira
num_players = 6
player_height = 2.0
jump_chance = 0.8
jump_delay = 0.3
jump_height = 1.0
```

## Como Testar

1. Abra o projeto no Godot
2. Clique no nó `Goalkeeper` na cena [game.tscn](scenes/game.tscn)
3. Ajuste os parâmetros no Inspector
4. Clique no nó `Wall` e ajuste seus parâmetros
5. Rode o jogo (F5) para testar
6. Pressione R para reiniciar e testar novamente

## Dicas de Balanceamento

- O goleiro deveria defender aproximadamente 40-60% dos chutes bem executados
- A barreira deve ser desafiadora mas não impossível de passar
- Chutes com timing perfeito devem ter alta chance de gol
- Chutes com overshoot devem sempre passar por cima da barreira e do gol
