# Aura 67 com login e ranking (GitHub Pages + Supabase)

O Supabase é o backend gratuito (login + banco). O GitHub Pages só serve o `index.html`.

## 1. Criar o projeto no Supabase
1. Crie conta em supabase.com e um projeto novo (plano Free).
2. **Authentication > Providers > Email**: deixe habilitado e **desligue "Confirm email"**
   (o login por nick usa um e-mail fictício `nick@aura67.app`, que não recebe mensagens).
3. **SQL Editor**: cole todo o conteúdo de `supabase.sql` e execute.
4. **Project Settings > API**: copie a **Project URL** e a chave **anon public**.

## 2. Configurar o jogo
No `index.html`, perto do início, edite:

    window.AURA_CFG = { url: 'https://SEU-PROJETO.supabase.co', key: 'SUA_CHAVE_ANON', domain: 'aura67.app' };

A chave `anon` é pública por design; quem protege os dados são as regras do SQL (RLS).
**Nunca** coloque a chave `service_role` no site.

## 3. Publicar
Suba o `index.html` no repositório e ative o GitHub Pages (Settings > Pages).

## Se o cadastro der "Email address is invalid"
O Supabase pode recusar o domínio fictício. Troque `domain` em `AURA_CFG` por outro (ex.: um domínio seu) e tente de novo.

## Limitações (importante)
- O jogo roda no navegador, então **o ranking não é à prova de trapaça**: quem mexer no console consegue enviar valores falsos.
  O SQL só barra valores absurdos. Para ranking realmente confiável, a pontuação teria de ser calculada no servidor.
- Não há recuperação de senha (não existe e-mail real). Esqueceu a senha = criar outro nick (ou resetar o usuário no painel do Supabase).
- Ao logar em uma conta existente, o progresso da nuvem substitui o do navegador.

## Temporada 2 (reset geral)
1. No Supabase, **SQL Editor**: cole todo o conteúdo de `reset-temporada.sql` e execute.
   **Isso apaga todas as contas e todo o ranking, sem volta.** No fim ele mostra `contas = 0` e `jogadores = 0`.
2. No navegador de cada jogador, o jogo novo apaga sozinho o save antigo (`aura67.v3`) e a sessão antiga ao abrir.
   Quem estava logado vê a tela de entrada e precisa criar o nick de novo.

## Áudios
Os áudios ficam na pasta `sons/` e são listados em `sons/sons.js`. Para incluir um novo:
1. Coloque o arquivo (`.mp3`, `.ogg` ou `.m4a`) em `sons/`.
2. Acrescente uma linha em `sons/sons.js`, por exemplo `{ arquivo: 'meu-audio.mp3', evento: '67' },`.

Eventos: `67` (a cada 67 de aura, sorteado), `nivel`, `chefe`, `vitoria`, `roubo`, `sigma`, `ego`, `desafio`.
Evento sem áudio próprio usa um sorteado de `67`. Cada áudio toca no máximo 5 s.

## Dificuldade (Temporada 2)
- Geradores 3x mais caros (antes 2x), crescimento de preço 1,20 por unidade (antes 1,165), geradores do fim do jogo bem mais caros.
- Multiplicadores 6x mais caros (antes 3x). Pose: 30 x 1,6^nível.
- Ego: primeiro ponto com 1M de aura na rodada (antes 5K), +6% por ponto (antes +40%). Poder supremo x1,25 (antes x1,5).
- Haters a partir do nível 1, mais rápidos, mais resistentes e roubando mais; chefes a partir do nível 4.
  Perder um desafio relâmpago chama 2 haters. Combo exige toques mais rápidos. Aura rara aparece menos e some mais rápido.
- Em simulação de um jogador ativo e esperto, o nível 18 passou de ~20 min para ~18 h de jogo.

## Arena (batalha entre jogadores)
1. No Supabase, **SQL Editor**: cole todo o conteúdo de `arena.sql` e execute (uma vez; pode repetir sem perder nada).
   No fim ele lista as 4 colunas novas (`last_seen`, `coins`, `arena_items`, `arena_wins`).
2. Sem esse passo a aba Arena mostra "A Arena ainda não foi ativada no servidor" e o resto do jogo funciona normal.

Como funciona:
- Aba **Arena** lista quem está online (sinal a cada 5 s). Desafio vale 35 s; o outro aceita ou recusa num pop-up.
- 5 minutos, os dois começam do zero. Ego, Loja do Ego, bônus de nível/conquistas, dia especial, hora premiada, ovo secreto,
  bênção da Bequinha e itens da Arena **não valem** lá dentro. Aura rara, haters e desafios relâmpago continuam.
- Exceção da conta `bequinha` na Arena: escudo (haters roubam metade, atrapalham menos e não quebram o combo) e ataque
  (+12% de chance de crítico e golpe dobrado nos haters). O teto de placar dela no servidor é 5x (`arena_tick`).
- O save normal fica guardado e volta igual no fim (não é salvo nem enviado durante a batalha).
- Vence quem tiver mais aura farmada; o servidor decide pelo relógio dele. 20 s sem sinal (app fechado ou em segundo plano) = W.O.
- A moeda só é dada pelo servidor: máximo 3 por dia e 1 por dia contra o mesmo jogador. Placar acima do teto possível é ignorado.
- **Loja da Arena** (bônus permanentes no jogo normal): Aura do Campeão x10 (1 moeda, compra única), Grito de guerra x2 por nível
  (2, 5, 10, 15, 20), Mãos de gladiador +5 cliques/s por nível (1, 3, 6, 10, 15), Título Gladiador ⚔️ no ranking (1 moeda).
  Os preços ficam em `arena_buy` no `arena.sql` e em `AR_ITEMS` no `index.html` (mudar nos dois).
