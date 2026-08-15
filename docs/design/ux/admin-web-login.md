# Admin Web — Login / Signup (especificação aprovada)

Documento de referência para implementação. Base: decisões do produto + referência visual "Social Sports Club Management UI Kit" (Figma `uHI8j3ewUsP9cU3ZN5oNxS`), adaptada aos tokens do Flag. Consulte também `docs/design/tokens.md` e `docs/design/ux/referencias.md`.

## Decisões aprovadas

| # | Decisão |
|---|---|
| a | Signup de organizador com **aprovação de super usuário** (ADMIN). Conta fica pendente até aprovação. |
| b | **"Esqueci a senha"** por e-mail (link de redefinição; exige SMTP no backend). |
| c | Somente **e-mail e senha** (sem SSO). |
| d | Sessão: JWT persistente + opção **"Manter conectado"** (padrão desmarcado) + **logout sempre visível**. |
| e | Pós-login: **home** (menu). |
| f | Layout: **split screen** — formulário à esquerda, **arte à direita** (para quem olha). |
| g | Mensagem no painel de arte: **"O melhor lugar para acompanhar um campeonato de flag"**. |
| h | **Tema escuro** nas telas de autenticação (como o kit). App autenticado continua claro (tokens). |
| i | Sign up: **E-mail, Senha e Confirmar senha**. |

## Layout (desktop ≥960px)

```
┌──────────────────────────────┬──────────────────────────────┐
│  FORMULÁRIO (esquerda)       │  ARTE / IMAGEM (direita)     │
│  [logo] Flag Admin Web       │  Imagem esportiva + gradiente │
│  Acesse sua conta            │  "O melhor lugar para         │
│  E-mail                      │   acompanhar um campeonato    │
│  Senha          (olho)       │   de flag"                    │
│  [x] Manter conectado        │  (tema escuro)                │
│  Esqueci a senha             │                               │
│  [ Entrar ]                  │                               │
│  Criar conta                 │                               │
└──────────────────────────────┴──────────────────────────────┘
```

- **Mobile (<960px)**: empilha — marca + formulário centralizado; painel de arte oculto (ou faixa fina no topo).

## Especificação visual (derivada do kit, tema escuro)

### Cores (telas de autenticação)
- Fundo da tela: `#102219`
- Superfície/card: `#1F2924` / `#1A2621`
- Neutros de texto: `#FFFFFF`, `#5B6F68`, `rgba(255,255,255,0.3)` (placeholder)
- **Brand/primário**: `#13EC80` (borda ativa, checkbox/switch ativos, botão primário)
- Fundo de input: `rgba(255,255,255,0.05)`

### Componentes
- **Input**: altura ~58px, padding 12×14, raio ~24px, fundo `rgba(255,255,255,0.05)`; estado ativo com borda `#13EC80`; texto placeholder `rgba(255,255,255,0.3)` (Lexend 18), texto preenchido branco; senha com ícone de olho (mostrar/ocultar)
- **Checkbox** ("Manter conectado"): 20×20, raio 6; off `#1A2621` + borda; on `#13EC80` + check
- **Botão primário**: pill (raio ~28), padding 12×32, fundo `#13EC80`, texto escuro; loading com spinner
- **Link** ("Esqueci a senha" / "Criar conta"): texto branco/neutro com destaque `#13EC80`

### Tipografia
- Título da tela: Lexend/Outfit ExtraBold (~28–36)
- Label de campo: 16 (médio); texto de input: 18; secundário: 14

## Fluxos

### 1. Login
Campos E-mail + Senha (com olho), "Manter conectado", link "Esqueci a senha", botão "Entrar", rodapé "Não tem conta? Criar conta". Erros inline no campo + mensagem de credenciais inválidas.

### 2. Sign Up
E-mail, Senha, **Confirmar senha**. Botão "Criar conta". Após envio: **estado de sucesso** "Conta criada! Acesso liberado após aprovação de um administrador." (sem login automático). Link "Já tenho conta".

### 3. Esqueci a senha (3 passos)
1. E-mail → "Enviar link de redefinição"
2. Confirmação "Enviamos um link para seu e-mail"
3. Nova senha + Confirmar (após clicar no link do e-mail)

### 4. Aprovação (super usuário / ADMIN)
Após login de ADMIN: acesso a uma **tela exclusiva de aprovações** (pendências de signup) — separada da gestão geral de usuários.

## Backend necessário
- Signup com estado **pendente** (`users.status` ou flag `approved`); aprovação altera para ativo
- Endpoints: criar conta (pendente), listar pendências (ADMIN), aprovar/rejeitar (ADMIN)
- Recuperação de senha: e-mail com token/link (requer SMTP/configuração de e-mail)

## Imagens de referência
Salvas em `docs/design/ux/figma-ref/` (`login.png`, `signup.png`, `forgot-password.png`) — para inspeção visual humana.
