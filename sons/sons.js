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
  Cada áudio toca no máximo 5 segundos.
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
  { arquivo: 'meme-10.mp3', evento: '67' }
];
