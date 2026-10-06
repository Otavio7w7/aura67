/*
  Lista de áudios do jogo. Para adicionar um áudio novo:
    1. Coloque o arquivo (.mp3, .ogg ou .m4a) nesta pasta "sons/".
    2. Acrescente uma linha abaixo com o nome do arquivo e o evento em que ele toca.

  Eventos disponíveis (campo "evento"):
    '67'     - a cada 67 de aura farmada (padrão; sorteia entre todos os '67')
    'nivel'  - ao subir de nível
    'chefe'  - quando um chefe hater aparece
    'vitoria'- ao derrotar um chefe
    'roubo'  - quando um hater encosta no 67 e rouba aura
    'sigma'  - ao pegar a aura rara (modo Sigma)
    'ego'    - ao inflar o ego
    'desafio'- ao cumprir um desafio relâmpago
  Se um evento não tiver áudio próprio, o jogo usa um áudio sorteado de '67'.
  Cada áudio toca no máximo 5 segundos. Para um áudio longo tocar inteiro, use o campo "max"
  (segundos), por exemplo { arquivo: 'x.mp3', evento: 'ego', max: 15 }.
  O mesmo arquivo pode aparecer em mais de uma linha (um evento por linha).
*/
window.AURA_SONS = [
  { arquivo: 'meme-01.mp3', evento: '67' },
  { arquivo: 'meme-02.mp3', evento: '67' },
  { arquivo: 'meme-03.mp3', evento: '67' },
  { arquivo: 'meme-04.mp3', evento: '67' },
  { arquivo: 'meme-05.mp3', evento: '67' },
  { arquivo: 'meme-06.mp3', evento: '67' },
  { arquivo: 'meme-07.mp3', evento: '67' },
  { arquivo: 'meme-08.mp3', evento: '67' },
  { arquivo: 'meme-09.mp3', evento: '67' },
  { arquivo: 'meme-10.mp3', evento: '67' },

  // Lote do Otavio (06/10/2026)
  { arquivo: 'ai-que-delicia-mickey.mp3', evento: '67' },
  { arquivo: 'ze-da-manga.mp3', evento: '67' },
  { arquivo: 'cala-boca.mp3', evento: '67' },
  { arquivo: 'tu-e-gay-mano.mp3', evento: '67' },
  { arquivo: 'seu-madruga-nossa.mp3', evento: '67' },
  { arquivo: 'cariani-eu-quero-eu-posso.mp3', evento: '67' },
  { arquivo: 'cariani-eu-quero-eu-posso.mp3', evento: 'nivel' },
  { arquivo: 'cariani-maldito-homem.mp3', evento: 'nivel', max: 16 },
  { arquivo: 'cala-boca.mp3', evento: 'chefe' },
  { arquivo: 'seu-madruga-nossa.mp3', evento: 'roubo' },
  { arquivo: 'lula-tira-que-eu-vou-cagar.mp3', evento: 'roubo', max: 7 },
  { arquivo: 'lula-reflexao.mp3', evento: 'ego', max: 15 },
  { arquivo: 'lula-neymar-bater.mp3', evento: 'vitoria', max: 30 },
  { arquivo: 'ai-que-delicia-mickey.mp3', evento: 'sigma' }
];
