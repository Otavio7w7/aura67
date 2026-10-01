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
