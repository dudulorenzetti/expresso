# Expresso ☕

App de barra de menus para Mac que mantém a tela acordada (e, se você quiser, impede o Mac de entrar em repouso) pelo tempo que você escolher.

* Clique esquerdo na xícara: abre o painel (modo, duração, Ligar/Desligar, Sair).
* Clique direito na xícara: liga ou desliga na hora.
* Dois modos: só a tela, ou tela e repouso do sistema.
* Duração: 1 h, 2 h, 3 h, sem limite, ou um tempo personalizado.

## Como baixar

1. Abra a página de [Releases](https://github.com/dudulorenzetti/expresso/releases/latest) e baixe o `Expresso.zip`.
2. Dê dois cliques no zip para descompactar.
3. Arraste o `Expresso.app` para a pasta Aplicativos.

## Como abrir na primeira vez

O Expresso não tem o selo (notarização) da Apple, então o macOS bloqueia na primeira abertura. Para liberar:

1. Abra o Expresso uma vez. Vai aparecer um aviso dizendo que não foi possível verificar o app. Clique em OK.
2. Vá em **Ajustes do Sistema > Privacidade e Segurança**, role até o fim e clique em **Abrir Mesmo Assim** ao lado do aviso do Expresso.
3. Confirme com sua senha ou Touch ID.

Em versões mais antigas do macOS também funciona clicar com o botão direito no app e escolher **Abrir**.

Depois disso ele abre normalmente. A xícara aparece na barra de menus, no canto superior direito.

## Ressalvas

* Só funciona em Mac com chip Apple (M1 ou mais novo, arm64). Não roda em Mac com processador Intel.
* Testado no macOS 27. Em versões mais antigas não foi testado.
* Sem selo nem notarização da Apple: por isso o aviso na primeira abertura.
* Projeto pessoal, sem garantia.

## Como compilar

Precisa das Command Line Tools da Apple (não precisa do Xcode completo).

```sh
./build.sh
```

O app sai em `build/Expresso.app`, assinado ad hoc. Para refazer o ícone, rode `icone/gerar-icone.sh`.
