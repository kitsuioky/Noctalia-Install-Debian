# Problemas comuns

**A tela de login não abriu / travou**
Ctrl+Alt+F2, faça login e rode `sudo noctalia-recover`, depois `sudo reboot`. Você volta para o login em texto. Para abrir o Hyprland pela TTY: `start-hyprland` (ou `Hyprland`).

**O instalador parou com erro**
Veja o fim do log em `/var/log/noctalia-install-deb/`. Corrija e rode `sudo ./install.sh` de novo — é seguro repetir.

**Erro 404 em `pkg.noctalia.dev/apt` (repositório antigo)**
O Noctalia v4 foi descontinuado e o repositório antigo saiu do ar. Este instalador usa o v5 (`pkg.noctalia.dev/deb`) e remove sozinho o arquivo antigo. Se precisar remover na mão: `sudo rm -f /etc/apt/sources.list.d/noctalia.sources /etc/apt/sources.list.d/noctalia.list`

**`hyprland` ou `noctalia` não encontrado**
Rode `sudo apt update`. Para o Noctalia, tente trocar a build: `sudo ./install.sh --only 02 --only 04 --noctalia-build trixie` (ou `unstable`).

**Barra do Noctalia não aparece**
Teste no terminal: `noctalia` e leia a mensagem de erro.

**Atalhos de volume/brilho/launcher não respondem**
Eles chamam o Noctalia por `noctalia msg ...`. Veja todos os comandos com `noctalia msg --help` (ou em docs.noctalia.dev) e ajuste em `~/.config/hypr/noctalia-deb/keybinds.lua` (ou `.conf`).

**Erro/aviso amarelo no Hyprland sobre a config**
O Hyprland 0.55+ usa Lua. Teste a config com `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` e veja a mensagem. Cada parte fica em um arquivo de `~/.config/hypr/noctalia-deb/`; se um deles tiver erro, apague ou comente a linha dele no bloco do `hyprland.lua`.

**Cursor do mouse invisível (máquina virtual)**
Em `~/.config/hypr/noctalia-deb/env.lua` (ou `env.conf`), descomente a linha/bloco `no_hardware_cursors = true`.

**Sem rede depois de reiniciar**
O instalador comenta a rede antiga em `/etc/network/interfaces` para o NetworkManager assumir. Use `nmtui` na TTY. O original está em `/var/backups/noctalia-install-deb/`.

**Restaurar um arquivo alterado**
Tudo que o instalador troca é copiado antes para `/var/backups/noctalia-install-deb/<data-hora>/` mantendo o caminho original.

**Aviso "hyprland marcado para autoremoção do testing"**
O Debian pode retirar o `hyprland` do testing por algum problema em dependência (veja tracker.debian.org/pkg/hyprland). Se ele sumir, rode o instalador de novo mais tarde, ou instale por outra fonte (sid, backports ou compilando) e depois use `sudo ./install.sh --skip 03`.

**A compilação do shell falhou (ou travou a VM)**
O instalador volta sozinho para o pacote oficial `noctalia`. Para ver o erro, abra o log em `/var/log/noctalia-install-deb/`. Se a VM ficou sem memória, aumente a RAM (4 GB ou mais) e rode `sudo ./install.sh --only 04 --shell kyo` (ou `--shell noctalia`). A pasta do código fica em `~/.local/src/kyo` (ou `noctalia`) e a compilação em `build-release/` dentro dela.

**"Pacotes não encontrados no Debian agora: ..."**
Algum pacote de compilação mudou de nome ou saiu do testing. Rode `sudo apt update` e tente de novo; se continuar, use `--shell-source apt` e me mande a lista.

**Quero voltar para o shell oficial**
`sudo ./install.sh --only 04 --shell noctalia --shell-source apt`. Se o Kyo estava instalado, remova antes: `sudo rm /usr/local/bin/kyo`.

**Plymouth: tela preta ou problema no boot**
No menu do GRUB aperte `e`, apague `quiet splash` da linha que começa com `linux` e aperte F10. Depois remova a opção em `/etc/default/grub` (há backup em `/var/backups/noctalia-install-deb/`) e rode `sudo update-grub`.
