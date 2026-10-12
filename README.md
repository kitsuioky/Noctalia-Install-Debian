# Noctalia Install Debian

Instalador automatizado para preparar uma instalação mínima do **Debian Testing** com **Hyprland** e o shell **Noctalia v5** ou **Kyo**, o fork mantido no repositório de [kitsuioky](https://github.com/kitsuioky).

O projeto procura entregar uma sessão Wayland pronta para uso sem instalar um ambiente de desktop completo como GNOME ou KDE Plasma. O instalador é modular e pode ser executado novamente: antes de alterar arquivos existentes, cria cópias de segurança.

## Funcionalidades

- **Preparação do sistema:** atualiza os índices APT, instala ferramentas básicas e, por padrão, executa `full-upgrade`.
- **Repositórios:** configura Debian Testing com `contrib`, `non-free` e `non-free-firmware`, adiciona o repositório do Noctalia v5 e tenta configurar o repositório do Brave.
- **Hyprland:** instala o compositor Wayland, portais, suporte a XWayland, clipboard e ferramentas de captura de tela.
- **Escolha do shell:** permite instalar o Kyo compilado do código-fonte, compilar o Noctalia original ou instalar o pacote `noctalia` via APT.
- **Configuração adaptativa:** seleciona automaticamente o formato de configuração do Hyprland conforme a versão instalada — Lua nas versões mais recentes e hyprlang nas anteriores.
- **Atalhos e mouse:** configura atalhos de teclado, movimentação e redimensionamento de janelas com o mouse, regras de janelas, aparência e inicialização automática.
- **Login gráfico:** configura `greetd` com o greeter do Noctalia quando disponível, ou tenta alternativas como `tuigreet` e `gtkgreet`.
- **Rede, Bluetooth e áudio:** instala NetworkManager, BlueZ e PipeWire, além de firmware e microcódigo quando disponíveis.
- **Aplicativos de uso diário:** inclui Nautilus, Alacritty, GNOME Software, Flatpak/Flathub, Brave Origin quando disponível, utilitários de sistema, mídia, fontes e leitor de PDF.
- **Plymouth opcional:** permite configurar uma tela de inicialização com o tema simples incluído ou com um tema obtido de um repositório Git.
- **LibreOffice opcional:** instala Writer, Calc e Impress com `--with-office`.
- **Validação e recuperação:** verifica componentes instalados, registra logs e disponibiliza `noctalia-recover` para desativar o login gráfico caso haja problemas.
- **Backups:** mantém cópias dos arquivos alterados em `/var/backups/noctalia-install-deb/`.

## Requisitos

- Debian Testing de 64 bits (`amd64`), preferencialmente uma instalação mínima sem outro ambiente gráfico.
- Usuário normal com permissões `sudo`.
- Conexão com a internet durante a instalação.
- Aproximadamente **8 GB de espaço livre**; mais se instalar o LibreOffice.
- **4 GB de RAM ou mais** recomendados para compilar o shell.
- GPU e driver compatíveis com Wayland. Intel e AMD costumam funcionar diretamente; NVIDIA pode exigir ajustes adicionais.

Consulte [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md) para detalhes.

## Instalação

Clone o repositório do instalador, entre na pasta e execute:

```bash
sudo apt update
sudo apt install -y git
# Clone aqui o repositório deste instalador
cd Noctalia-Install-Debian
sudo ./install.sh
sudo reboot
```

O instalador solicita a escolha do shell quando executado em um terminal interativo. Sem terminal interativo, o padrão é Kyo.

### Escolher o shell

**Kyo (fork de kitsuioky, compilado do Git):**

```bash
sudo ./install.sh --shell kyo
```

**Noctalia original, compilado do Git:**

```bash
sudo ./install.sh --shell noctalia
```

**Noctalia original, instalado pelo pacote APT:**

```bash
sudo ./install.sh --shell noctalia --shell-source apt
```

Também é possível informar outro repositório, uma branch/tag ou um diretório local:

```bash
sudo ./install.sh --shell kyo --shell-repo https://github.com/kitsuioky/kyo.git --shell-ref main
sudo ./install.sh --shell-dir "$HOME/Projetos/kyo"
```

O instalador instala as dependências de compilação e tenta instalar o shell em `/usr/local`. Se a compilação falhar, pode recorrer ao pacote oficial `noctalia`; nesse caso, o log e o terminal avisam que o shell escolhido não foi instalado.

### Opções úteis

| Opção | Função |
|---|---|
| `--help` | Exibe todas as opções disponíveis. |
| `--only NN` | Executa apenas o módulo indicado; pode ser repetida. |
| `--skip NN` | Pula o módulo indicado; pode ser repetida. |
| `--kb-layout br` | Define o layout do teclado; aceita, por exemplo, `us`. |
| `--greeter NOME` | Seleciona `noctalia`, `tuigreet` ou `gtkgreet`. |
| `--noctalia-build auto` | Escolhe a origem do pacote Noctalia (`auto`, `unstable` ou `trixie`). |
| `--no-upgrade` | Não executa o `full-upgrade` do sistema. |
| `--with-plymouth` | Ativa a configuração do tema Plymouth incluído. |
| `--plymouth-repo URL` | Usa um tema Plymouth de um repositório Git. |
| `--with-office` | Instala o LibreOffice. |

Exemplos:

```bash
sudo ./install.sh --no-upgrade
sudo ./install.sh --kb-layout us --greeter tuigreet
sudo ./install.sh --only 07
sudo ./install.sh --skip 06
sudo ./install.sh --with-plymouth --with-office
```

## Estrutura do projeto

```text
.
├── install.sh       # Entrada principal, opções e execução dos módulos
├── lib/             # Funções comuns, logs, backups, APT e validações
├── modules/         # Etapas numeradas da instalação
├── config/          # Configurações do Hyprland, Alacritty e Plymouth
├── docs/            # Requisitos, mouse/atalhos e solução de problemas
├── LICENSE          # Licença MIT
└── README.md
```

Os módulos numerados cobrem sistema base, repositórios, Hyprland, shell, aplicativos, hardware, configuração/login, Plymouth e validação.

## Mouse e atalhos

Por padrão, `Super` + botão esquerdo permite mover janelas e `Super` + botão direito permite redimensioná-las. O projeto também inclui atalhos para abrir o terminal e o launcher, além de regras para janelas utilitárias.

Consulte [`docs/MOUSE.md`](docs/MOUSE.md) para a lista detalhada de atalhos.

## Logs, backups e recuperação

- **Log da instalação:** `/var/log/noctalia-install-deb/`
- **Backups:** `/var/backups/noctalia-install-deb/`
- **Recuperação se o login gráfico falhar:** entre em uma TTY com `Ctrl` + `Alt` + `F2`, faça login e execute:

```bash
sudo noctalia-recover
sudo reboot
```

O comando desativa o `greetd` e reativa o login em texto pela TTY. Para diagnosticar outros problemas, consulte [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## Avisos

Este instalador altera fontes APT, instala pacotes e configura serviços do sistema. Leia os scripts antes de executá-lo em uma máquina importante. Embora faça backups dos arquivos que altera, recomenda-se manter uma cópia de segurança dos dados pessoais.

## Licença

Distribuído sob a licença MIT. Consulte [`LICENSE`](LICENSE).
