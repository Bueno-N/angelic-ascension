class_name OnlineConfig
extends RefCounted
## Servidor do ranking mundial (Supabase, plano gratuito). VAZIO = modo OFFLINE (o jogo funciona normalmente; o ranking mostra só o seu melhor).
## Para ligar: crie o projeto, rode docs/weekly_ranking.sql e preencha as duas linhas abaixo (passo a passo em docs/ONLINE.md).
## A chave "anon" é PÚBLICA por design (fica no app); a segurança está nas funções SQL, não no segredo da chave.
const URL := ""        # ex.: "https://abcd1234.supabase.co"
const ANON_KEY := ""   # chave anon/public do projeto

static func enabled() -> bool:
    return URL != "" and ANON_KEY != ""
