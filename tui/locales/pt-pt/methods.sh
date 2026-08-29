#!/usr/bin/env bash
CONTENT="
Existem dois ambientes para a instalação do Open Voice OS:

    - Contentores como o Docker
    - Configuração num ambiente Python virtual

Os contentores proporcionam isolamento e facilidade de implementação, enquanto um ambiente Python virtual proporciona mais flexibilidade e controlo sobre a instalação.

Se o método de contentor for selecionado, o Docker será instalado automaticamente se não estiver presente no sistema.

Seleccione um método de implantação:
"
LOCKED_CONTENT="
Foi detetada uma instalação existente do Open Voice OS, pelo que apenas o método que já utiliza está disponível:

    - Método detetado: $INSTANCE_TYPE

Para instalar com outro método, desinstale primeiro a instância existente e execute novamente o instalador.

Confirme o método de instalação:
"
TITLE="Open Voice OS Instalação - Implementação"

export CONTENT LOCKED_CONTENT TITLE
