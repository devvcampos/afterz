# Aftermath 0.2.0 — painel e sensoryESP

Base visual independente em Luau para o novo projeto Aftermath. Reaproveita a
biblioteca NeverLose vendorizada do Newz 0.6.1, com o mesmo tema escuro e destaque
ciano. A pasta original do Newz permanece separada e não é uma dependência.

## O que está pronto

- Janela com menu lateral, busca, perfil e marca d'água.
- Abas **Início**, **Jogo** e **Configurações**.
- Atalho **Alt esquerdo** para abrir/ocultar, com tecla configurável.
- Tamanhos Small, Default e Large, marca d'água opcional e botão de encerramento.
- Gerenciador de preferências da NeverLose em `aftermath/Configs`.
- Biblioteca completa de componentes: botões, toggles, sliders, listas, atalhos e cores.
- sensoryESP remoto na aba **Jogo**, inicialmente desligado.
- Caixas, nomes, distância em studs, barra/valor da vida, esqueleto, chams e setas.
- Estilo e cor das caixas, contornos, cor/tamanho dos nomes e limite de FPS do ESP.

A integração usa `Players = true` e `LocalPlayer = false`. O próprio sensoryESP
enumera `game:GetService("Players"):GetPlayers()` e acompanha o `Character` de cada
jogador vivo. Os personagens normalmente ficam no Workspace; `Players` contém
os objetos Player e a referência ao personagem. A biblioteca reconfere a lista a
cada segundo, incluindo entradas, respawns e remoções. NPCs e diretórios
específicos do Newz não são configurados como alvos.

## Ativar o ESP

1. Execute `dist/aftermath.lua` no seu ambiente de teste.
2. Abra **Jogo** e ligue **Ativar ESP**.
3. Aguarde o status **ESP: ativo** e ajuste os controles de aparência.
4. Desligue **Ativar ESP** para remover os desenhos. **Encerrar painel** também
   encerra o ESP; ocultar a janela mantém o recurso ligado.

O primeiro acionamento baixa a biblioteca. Desligar e religar reutiliza o código
já carregado na sessão. Os controles alteram a configuração ativa sem reiniciar
o renderizador. Em caso de erro, a chave volta para desligado; os detalhes ficam
no console F9 e em `getgenv().AFTERMATH_PANEL.ESP.GetState().Error`.
As preferências podem ser salvas no gerenciador do topo, incluindo a chave do ESP.

## Executar

O arquivo pronto é `dist/aftermath.lua`. Ele roda no cliente Roblox em um ambiente
compatível com a biblioteca NeverLose usada pelo Newz. Não é uma página web nem
um aplicativo independente do Roblox. Esta extração ainda não foi validada em
uma sessão real do jogo.

A biblioteca herdada usa APIs de arquivos para as preferências e, quando há
`getcustomasset`, pode baixar duas imagens da NeverLose para `AftermathAssets`.
O painel e o adaptador estão incluídos no bundle. O sensoryESP é baixado ao
ativar a integração, por `game:HttpGet` e `loadstring`, de uma revisão fixa:

[`0e161be44ea40bbe215c82051a18258982ac47b9`](https://github.com/rthusrtghdfhtyjkehrfh/sensoryESP/blob/0e161be44ea40bbe215c82051a18258982ac47b9/ESP.lua).

A biblioteca remota também pode baixar fontes e gravar os arquivos de fonte no
diretório do executor. Sua API usa `getgenv()` e mantém uma única instância global
do sensoryESP: ativá-la encerra outra instância dessa biblioteca na mesma sessão,
inclusive uma iniciada pelo Newz. Isso não modifica os arquivos do projeto Newz.
A compatibilidade com um LocalScript padrão do Roblox Studio não foi validada.

Executar o bundle novamente encerra apenas a instância anterior do Aftermath.
O controlador retornado também fica disponível em `getgenv().AFTERMATH_PANEL`
(ou `_G.AFTERMATH_PANEL`), com `Window`, `Tabs`, `Config`, `ESP` e `Destroy()`.

## Editar e gerar

```powershell
python scripts/build.py
python scripts/build.py --check
python scripts/check.py
```

`check.py` requer o runtime e compilador oficiais do Luau no PATH ou em
`.tools/luau` (também aceita `--luau-dir`). Compila os fontes e o bundle e executa
15 testes do adaptador com runtime simulado, incluindo erros de HTTP/API,
atualizações, encerramento e cancelamento durante download. Esses testes não
validam renderização nem compatibilidade visual com o jogo.

| Arquivo | Responsabilidade |
| --- | --- |
| `src/Config.lua` | Nome, versão, cor, tamanho e preferências iniciais |
| `src/Ui.lua` | Abas, seções e controles do painel |
| `src/Main.lua` | Inicialização e encerramento da instância |
| `src/Integrations/SensoryESP.lua` | Download, configuração e ciclo de vida do sensoryESP |
| `vendor/NeverLose.lua` | Biblioteca visual herdada |
| `scripts/build.py` | Geração local do bundle legível |
| `dist/aftermath.lua` | Arquivo único para executar |

Para acrescentar controles do novo projeto, comece pela aba `Tabs.Game` em
`src/Ui.lua`. O adaptador mapeia os controles para `Load`, `GetConfig` e `Unload`,
os métodos existentes na revisão conferida. A estrutura de `Outlines` e
`Chams.Highlight` segue essa API; não há tentativa de adivinhar métodos de update.
Não edite o bundle diretamente: gere-o novamente após alterar os fontes.

Na sessão real, confira: um segundo jogador vivo; entrada e saída de jogadores;
morte/respawn; atualização dos controles; desligamento; encerramento e reexecução
do bundle. Personagens sem `Player.Character` ou sem um filho `Humanoid` vivo
não são alvos da integração atual. Esqueleto depende dos nomes de partes R6/R15.

## Origem

A cópia da NeverLose preserva o cabeçalho do autor. A única alteração local na
biblioteca é o diretório de cache de imagens, de `NLAssets` para `AftermathAssets`.
`src/Main.lua` e `src/Ui.lua` foram reescritos para retirar as dependências de jogo;
O adaptador sensoryESP foi implementado separadamente para o Aftermath. Os módulos
locais de ESP, mira e movimento do Newz não foram copiados.
Veja `LICENSE` e `THIRD_PARTY_NOTICES.md`.
