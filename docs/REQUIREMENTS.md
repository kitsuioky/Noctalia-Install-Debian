# Requisitos

- Debian Testing (ou Debian 13 que será atualizado para testing), **64 bits (amd64)**, instalação mínima (sem ambiente gráfico).
- Usuário normal com **sudo**.
- Internet funcionando durante a instalação (cabo é o mais simples).
- Cerca de 8 GB livres (a compilação do shell e as dependências ocupam bastante; mais se usar `--with-office`).
- **4 GB de RAM ou mais** para compilar (o link final com LTO é pesado). Em VM, dê 4 GB e 2+ núcleos.
- Máquina com GPU/driver que rode Wayland (Intel/AMD funcionam direto; NVIDIA precisa de ajustes extras).

## Como instalar

    sudo apt install -y git
    git clone <endereço-do-repositório> Noctalia-install-deb
    cd Noctalia-install-deb
    sudo ./install.sh
    sudo reboot

Opções úteis: `--shell kyo|noctalia`, `--shell-repo URL`, `--shell-source apt`, `--with-plymouth`, `--kb-layout us`, `--greeter tuigreet`, `--noctalia-build trixie`, `--with-office`, `--no-upgrade`, `--only 07`, `--skip 06`.
