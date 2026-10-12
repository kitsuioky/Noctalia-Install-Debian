# Mouse e atalhos

O Hyprland não desenha barra de título nem botões nas janelas. O jeito de usar o mouse nelas é este:

| Ação | Como fazer |
|---|---|
| Mover uma janela | Segure **Super** e arraste com o botão **esquerdo** |
| Redimensionar | Segure **Super** e arraste com o botão **direito**, ou arraste a **borda** da janela |
| Dar foco | Passe o mouse ou clique na janela |
| Trocar de área de trabalho | **Super + roda do mouse** (ou clique no Noctalia) |
| Janela flutuante / lado a lado | **Super + V** |

Janelas de utilitários (volume, rede, Bluetooth, calculadora, caixas de abrir/salvar arquivo) já abrem flutuando e centralizadas.

## Atalhos principais

| Atalho | O que faz |
|---|---|
| Super + Enter | Terminal (Alacritty) |
| Super + Espaço (ou D) | Launcher do Noctalia |
| Super + E | Arquivos (Nautilus) |
| Super + B | Brave Origin |
| Super + S | Central de controle do Noctalia |
| Super + , (vírgula) | Configurações do Noctalia |
| Super + X | Menu de sessão (sair, reiniciar, desligar) |
| Super + L | Travar a tela |
| Super + Q | Fechar janela |
| Super + F | Tela cheia |
| Super + setas | Mudar o foco |
| Super + Shift + setas | Mover a janela |
| Super + 1…9 | Área de trabalho |
| Super + Shift + 1…9 | Mandar janela para a área |
| Print / Shift+Print | Print da área / da tela (vai para a área de transferência) |
| Super + Shift + S | Print da área e abrir no Swappy |
| Super + Shift + E | Sair do Hyprland |

## Onde mudar

Arquivos em `~/.config/hypr/noctalia-deb/`:

No Hyprland 0.55 ou mais novo os arquivos são `.lua`; nos mais antigos são `.conf`:

- `mouse` — mouse e touchpad
- `keybinds` — atalhos de teclado
- `windowrules` — regras de janela
- `look` — teclado e visual

Esses arquivos são regravados quando você roda o instalador de novo (com backup antes). Para ajustes seus, coloque no final do `~/.config/hypr/hyprland.lua` (ou `hyprland.conf`), que o instalador nunca sobrescreve.
