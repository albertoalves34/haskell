# Backend Web com Haskell+Scotty


## 1. Identificação

- Nome: Alberto Alves Júnior
- Curso: Sistemas de Informação

---

## 2. Tema/objetivo

O objetivo do trabalho foi criar um serviço web que gera planos alimentares personalizados. A ideia é simples: o usuário informa dados como peso, altura, idade, sexo, nível de atividade e objetivo, e o sistema calcula suas necessidades calóricas e monta um plano alimentar semanal automaticamente.

A lógica principal do serviço é dividida em duas partes. Primeiro, são feitos os cálculos nutricionais (TMB, TDEE, meta e macros). Depois, com esses valores, o sistema monta o plano alimentar escolhendo alimentos de uma base e distribuindo as calorias ao longo das refeições do dia.

Em relação à programação funcional, tentei manter a maior parte da lógica em funções puras, o que facilitou bastante os testes e a organização. Também usei tipos algébricos para representar melhor os dados (como sexo, objetivo, etc.), pattern matching para tratar os casos e funções como `map` e `filter` para manipular listas. Além disso, deixei separado o que é lógica pura do que envolve `IO` (web e banco), o que ajudou a manter o código mais limpo.

---

## 3. Processo de desenvolvimento

No início do desenvolvimento, eu foquei nas partes em que eu já tinha mais clareza de como resolver. Por isso, comecei implementando operações básicas de CRUD, como criar usuário, excluir usuário, listar usuários, login, etc. Foi nessa etapa que eu descobri o `data` do Haskell (pesquisando algo como "equivalente a struct em Haskell" no Google — ajudou bastante). Usei isso para criar diversos tipos que facilitaram muito a organização e a fluidez do projeto, como: `Sexo`, `NivelAtividade`, `Objetivo`, `Macros`, entre outros.

Uma decisão que acabou sendo bem importante no projeto foi a organização da arquitetura. O `main.hs` é o único arquivo que importa o Scotty. Todos os outros módulos (`Calculate`, `Alimento`, `Plano`, `Banco`, `Login`) não sabem que existe um framework web. As rotas no `main.hs` fazem o mínimo possível: recebem o JSON, convertem para os tipos internos, chamam funções e devolvem o resultado. Por exemplo, a rota `/api/calcular` basicamente só chama funções como `calcularTMB`, `calcularTDEE`, `calcularMeta` e `calcularMacros`, que estão todas em `Calculate.hs` sem nenhuma dependência de IO. Isso facilitou muito, porque permitiu testar toda a lógica usando HUnit sem precisar subir o servidor.

As funções mais centrais do projeto são justamente essas funções puras. A parte de cálculo nutricional gira em torno de `calcularTMB`, `calcularTDEE`, `calcularMeta` e `calcularMacros`, enquanto a geração do plano usa funções como `gerarPlanoSemanal`, `montarDia` e `montarRefeicaoDia`. Também criei funções auxiliares como `escolherComFallback` e `distribuirCal` para lidar com seleção de alimentos e distribuição de calorias. Em termos de estrutura de dados, as mais importantes foram `Alimento`, que é usada em praticamente todo o sistema, `Macros`, que carrega o resultado dos cálculos, e a estrutura `DiaPlano → RefeicaoDia → Porcao`, que representa o plano completo e é enviada como JSON para o frontend.

Em termos de programação funcional, o que mais usei foram tipos algébricos e pattern matching. Tipos como `Sexo`, `NivelAtividade`, `Objetivo`, `TipoRefeicao` e `GrupoAlimento` ajudaram a evitar erros e deixaram o código mais claro, substituindo strings "soltas" por valores bem definidos. O pattern matching aparece praticamente em toda a lógica (como nos cálculos e nas conversões de entrada). Também usei bastante funções de alta ordem como `map`, `filter` e `foldr` na construção dos planos. O tipo `Maybe` foi útil para tratar casos inválidos sem quebrar o programa, principalmente nas funções de parse e seleção. No geral, tentei manter uma separação clara: tudo que é lógica ficou puro, e IO ficou restrito ao banco e à camada web.

Depois disso, utilizei o Claude Code para gerar uma parte inicial do frontend, mais para visualizar como essas operações ficariam na prática. Em seguida, comecei a implementar os cálculos da dieta (TMB, TDEE, meta calórica) e também a parte de informações do usuário, como nível de atividade e objetivo.

A próxima etapa foi a parte de alimentos, que acabou sendo uma das mais trabalhosas. O principal problema foi que, para o sistema fazer sentido, eu precisava de um banco de dados bem populado com alimentos e suas informações nutricionais. A solução mais rápida foi usar uma IA (Claude Sonnet 4.6) para gerar esses dados e inserir no banco SQLite (`banco.db`).

Porém, mais adiante, quando descobri que o projeto deveria rodar no Render, tive outro problema: o SQLite não funciona bem lá sem pagar por armazenamento persistente. Minha solução foi simples: sempre que o backend não encontra o banco, ele repopula automaticamente com uma lista de alimentos definida em `Banco.hs`.

Outro problema na parte de alimentos foi que, inicialmente, eu não tinha uma categorização clara entre eles. Isso fazia com que o sistema gerasse refeições estranhas, como um almoço com carne moída, peito de frango e salmão ao mesmo tempo. Para resolver isso, adicionei uma classificação dos alimentos (proteína, carboidrato, vegetal, etc.).

Além disso, antes as refeições tinham apenas dois alimentos, o que gerava distribuições pouco naturais, como 450g de arroz e 300g de carne. Resolvi isso adicionando um terceiro alimento, o que deixou as refeições mais equilibradas (por exemplo: 300g de arroz, 150g de cenoura ralada e 220g de carne).

Mesmo assim, ainda surgiam casos estranhos, principalmente no café da manhã. Como alguns alimentos têm baixa densidade calórica (ex: frutas), em dietas com muitas calorias acabava gerando porções como 900g de melão com 60g de ovos. O ideal seria balancear melhor com alimentos mais calóricos, mas como o tempo era curto, mantive assim. Com a inclusão de três alimentos por refeição, isso já melhorou bastante.

Uma melhoria que eu gostaria de ter implementado, e que percebi ao mostrar o projeto para minha namorada, seria usar medidas mais práticas no dia a dia, como "2 ovos" ou "2 xícaras de arroz", em vez de apenas gramas (ex: 120g de ovo). Isso deixaria o sistema mais intuitivo.

Sobre o deploy no Render, tive alguns problemas também. Um deles foi relacionado ao fato de eu desenvolver no macOS, que não diferencia maiúsculas e minúsculas nos nomes de arquivos. Já no Linux (usado pelo Render), isso faz diferença, então alguns módulos não eram encontrados. Foi algo simples de resolver, mas no início achei que fosse um problema mais sério e perdi um tempo investigando.

Outro detalhe foi em relação às rotas: eu não estava utilizando rotas relativas corretamente. Mas isso foi rápido de ajustar.

---

## 4. Testes

Para validar o sistema, eu usei HUnit, conforme recomendado, para testar as funções puras do projeto. No total, foram 52 testes organizados em uma única suíte (`suiteTestes`) que roda com `runTestTT`. Como a maior parte da lógica foi feita de forma pura (sem IO), foi possível testar tudo isoladamente, sem precisar subir o servidor nem depender de banco de dados, o que facilitou bastante.

Eu acabei cobrindo várias partes do sistema. Na parte de cálculos, testei TMB, TDEE, metas calóricas, macros e os fatores de atividade. No módulo de alimentos, testei as conversões entre enums e strings (tipo e grupo), incluindo casos de ida e volta e também entradas inválidas. Já na parte de plano alimentar, testei coisas como arredondamento, distribuição de calorias, montagem das refeições e a geração do plano semanal completo com 7 dias. No login, validei regras básicas como senha mínima, nome e email. Também fiz alguns testes na parte de banco, principalmente na conversão de uma linha do SQLite para o tipo `Alimento`.

Os testes foram feitos usando `assertEqual` e `assertBool`, comparando diretamente o que a função retorna com o valor esperado. Por exemplo:

```haskell
testarTMBFeminino :: Test
testarTMBFeminino = TestCase $
  assertEqual "TMB Feminino divergente, esperado 1320.25" 1320.25 (calcularTMB Feminino 60.0 165.0 30)
```

---

## 5. Execução

Para rodar o projeto, você precisa ter o GHC (preferencialmente 9.8.4), Cabal (>= 2.4) e SQLite instalados. As dependências Haskell são gerenciadas automaticamente pelo Cabal.

A forma mais simples é rodar localmente. Basta entrar na pasta `backend`, executar `cabal update`, depois `cabal build` e, em seguida, `cabal run dietaapp` para subir o servidor na porta 3000. Se quiser rodar os testes, use `cabal run testes`. O banco SQLite é criado automaticamente como `banco.db` (ou no caminho definido em `DB_PATH`).

Também é possível rodar com Docker, o que facilita a configuração. Na raiz do projeto, use `docker build -t dietaapp .` e depois `docker run -p 3000:3000 -v $(pwd)/data:/data dietaapp`. O volume garante que o banco não seja perdido.

Com o servidor rodando, é só acessar no navegador: `/login.html`, `/registro.html` ou `/dashboard.html` em `http://localhost:3000`.

---

## 6. Deploy

Link do serviço publicado: <https://haskell-b3vs.onrender.com/login>

Após os arquivos estarem publicados no GitHub, eu realizei o registro na plataforma e vinculei ao meu GitHub. Depois forneci o link do meu repositório para o Render e cliquei em "deploy latest commit". Após corrigir alguns problemas que mencionei no tópico 3, o projeto foi inicializado perfeitamente na plataforma.

---

## 7. Resultado final



https://github.com/user-attachments/assets/cb95bfc8-6e2a-49a4-a922-3d1c4674ac7e

**Funcionamento**



---

## 8. Uso de IA

### 8.1 Ferramentas de IA utilizadas

Utilizei duas ferramentas para me auxiliar no projeto: o Claude Code (Claude Sonnet 4.6, assinatura premium) e o GPT (seleção de modelo automática, plano gratuito).

---

### 8.2 Interações relevantes com IA

#### Interação 1

- **Objetivo da consulta:** Popular o banco de dados
- **Trecho do prompt ou resumo fiel:** "Como posso popular um banco de dados em Haskell, utilizando o SQLite, sem inserir elementos à mão?"
- **O que foi aproveitado:** A ideia de percorrer uma lista hardcoded em Haskell inserindo os alimentos no banco (usando `mapM_`)
- **O que foi modificado ou descartado:** Nessa interação foi tudo aproveitado — foi uma boa solução no momento. Apenas depois fiz alterações na forma como os alimentos eram organizados e refiz essa parte, mas usando a mesma lógica

#### Interação 2

- **Objetivo da consulta:** Entender por que o build funcionava localmente mas falhava no Render
- **Trecho do prompt ou resumo fiel:** "Meu projeto Haskell compila no macOS mas o Render retorna erro de módulo não encontrado. Os arquivos existem. O que pode estar causando isso?"
- **O que foi aproveitado:** A explicação de que macOS é case-insensitive e Linux não é — o problema era que os nomes dos módulos importados não batiam exatamente com os nomes dos arquivos em maiúsculas/minúsculas
- **O que foi modificado ou descartado:** Corrigi os nomes dos arquivos e imports para usar a capitalização correta

#### Interação 3

- **Objetivo da consulta:** Pedir exemplos de funções de teste HUnit
- **Trecho do prompt ou resumo fiel:** "Como funcionam funções de teste HUnit em Haskell?"
- **O que foi aproveitado:** Após ver exemplos simples, principalmente comparando o resultado esperado de uma função com um valor fixo, consegui entender como os testes funcionam e aplicar no projeto
- **O que foi modificado ou descartado:** Todas as funções foram modificadas para se enquadrar no funcionamento do projeto

---

### 8.3 Exemplo de erro, limitação ou sugestão inadequada da IA

Nos primeiros problemas que tive com o Render em relação ao banco de dados, a solução sugerida foi migrar para o PostgreSQL, o que eu considerei muito mais trabalhoso e desnecessário. A solução que adotei foi bem mais simples: repopular o banco automaticamente sempre que necessário.

---

### 8.4 Comentário pessoal sobre o processo envolvendo IA

Acredito que o uso da IA como ferramenta seja muito positivo. Com ela, consigo lidar melhor com problemas específicos e, através de perguntas, preencher lacunas de entendimento mais rapidamente, mesmo quando inicialmente surgem mais dúvidas. Esse processo acaba acelerando bastante o aprendizado.

Outro ponto importante é a ajuda em partes mais burocráticas e de configuração, como no caso do Render. Isso é muito útil, porque o Render é um meio para atingir o objetivo, e não o fim em si. Conseguir resolver essas partes mais rápido deixa o desenvolvimento mais fluido e menos frustrante, evitando perder horas em problemas simples que, muitas vezes, só precisariam de uma segunda opinião.

Lembro de um trabalho que tive com o professor Benhur, em que passei praticamente um sábado inteiro tentando encontrar um vazamento de memória apontado pelo Valgrind. Na época, eu não utilizava nenhum agente integrado ao código, como Copilot ou Claude Code. O máximo que podia fazer era colar trechos no ChatGPT, mas não consegui resolver o problema. Depois, já utilizando o Copilot para depurar, ele identificou que o erro nem estava no meu código, mas sim no arquivo de teste fornecido, que utilizava um dado sem dar `free`. Isso foi bem frustrante, porque era algo fora do meu controle.

No geral, é por isso que vejo a IA como uma ferramenta muito útil: não substitui o entendimento, mas ajuda bastante a destravar problemas e tornar o processo mais eficiente.

---

## 9. Referências e créditos

- **Vídeo: GitHub Comandos Simples**  
  URL: https://www.youtube.com/watch?v=-l4Aa8wef8s&t

- **Vídeo: Funcionamento do Render**  
  URL: https://www.youtube.com/watch?v=0v74FFEPcrU

- **Material interativo: Demo Scotty Codespace (ELC117)**  
  URL: https://liascript.github.io/course/?https://raw.githubusercontent.com/elc117/demo-scotty-codespace-2026a/main/README.md#1  
  Descrição: Demonstração prática de um web service em Haskell usando Scotty, com exemplos de rotas e integração backend.

- **Material da disciplina: ELC117 - Paradigmas de Programação (UFSM)**  
  URL: https://liascript.github.io/course/?https://raw.githubusercontent.com/AndreaInfUFSM/elc117-2026a/main/classes/12/README.md#12  
  Descrição: Conteúdo da disciplina abordando programação funcional em Haskell, incluindo funções puras, IO, testes e desenvolvimento web com Scotty.

- **Artigo: Haskell – Tipos de Dados Algébricos (Blog do Kunigami)**  
  URL: https://kuniga.wordpress.com/2011/09/25/haskell-tipos-de-dados-algebricos/  
  Descrição: Explica como definir tipos com `data` em Haskell, incluindo equivalentes a struct, enum e estruturas recursivas.

- **Site oficial: Linguagem Haskell**  
  URL: https://www.haskell.org/  
  Descrição: Documentação oficial da linguagem, destacando conceitos como funções puras, imutabilidade e avaliação preguiçosa.

- **Artigo: Haskell (Wikipedia)**  
  URL: https://en.wikipedia.org/wiki/Haskell  
  Descrição: Visão geral da linguagem, incluindo tipagem estática, avaliação lazy e conceitos como pattern matching e type classes.
