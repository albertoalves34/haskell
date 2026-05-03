module Testes where

import Test.HUnit
import Calculate
import Alimento
import Plano
import Login  (verificarSenha, validarRegistro)
import Banco  (rowParaAlimento)


a1, a2, a3 :: Alimento
a1 = Alimento "Frango"  165.0 31.0  0.0 3.6 Almoco Proteina
a2 = Alimento "Arroz"   130.0  2.5 28.0 0.5 Almoco Carboidrato
a3 = Alimento "Feijão"   76.0  4.5 14.0 0.5 Almoco Leguminosa

bancTeste :: [Alimento]
bancTeste =
  [ Alimento "Ovo"     155.0 11.0  1.1 12.0 Cafe   Proteina
  , Alimento "Frango"  159.0 32.0  0.0  3.0 Almoco Proteina
  , Alimento "Maçã"     52.0  0.3 14.0  0.2 Lanche Fruta
  , Alimento "Omelete" 154.0 11.0  1.1 12.0 Jantar Proteina
  ]


testarFatorLevementeAtivo :: Test
testarFatorLevementeAtivo = TestCase $
  assertEqual "fator LevementeAtivo deve ser 1.375" 1.375 (nivelAtividadeParaFator LevementeAtivo)

testarFatorModeramenteAtivo :: Test
testarFatorModeramenteAtivo = TestCase $
  assertEqual "fator ModeramenteAtivo deve ser 1.55" 1.55 (nivelAtividadeParaFator ModeramenteAtivo)

testarFatorMuitoAtivo :: Test
testarFatorMuitoAtivo = TestCase $
  assertEqual "fator MuitoAtivo deve ser 1.725" 1.725 (nivelAtividadeParaFator MuitoAtivo)

testarFatorSedentario :: Test
testarFatorSedentario = TestCase $
  assertEqual "fator Sedentario deve ser 1.2" 1.2 (nivelAtividadeParaFator Sedentario)

testarFatorExtraAtivo :: Test
testarFatorExtraAtivo = TestCase $
  assertEqual "fator ExtraAtivo deve ser 1.9" 1.9 (nivelAtividadeParaFator ExtraAtivo)

testarTMBMasculino :: Test
testarTMBMasculino = TestCase $
  assertEqual "TMB Masculino divergente, esperado 1673.75" 1673.75 (calcularTMB Masculino 70.0 175.0 25)

testarTMBFeminino :: Test
testarTMBFeminino = TestCase $
  assertEqual "TMB Feminino divergente, esperado 1320.25" 1320.25 (calcularTMB Feminino 60.0 165.0 30)

testarTDEE :: Test
testarTDEE = TestCase $
  assertEqual "TDEE deve ser 2008.5" 2008.5 (calcularTDEE 1673.75 Sedentario)

testarMetaPerderGordura :: Test
testarMetaPerderGordura = TestCase $
  assertEqual "meta PerderGordura deve ser 1608.5" 1608.5 (calcularMeta 2008.5 PerderGordura)

testarMetaManterPeso :: Test
testarMetaManterPeso = TestCase $
  assertEqual "meta ManterPeso deve ser 2008.5" 2008.5 (calcularMeta 2008.5 ManterPeso)

testarMetaGanharMassa :: Test
testarMetaGanharMassa = TestCase $
  assertEqual "meta GanharMassa deve ser 2258.5" 2258.5 (calcularMeta 2008.5 GanharMassa)

testarFatoresPerderGordura :: Test
testarFatoresPerderGordura = TestCase $
  assertEqual "fatores PerderGordura" (2.0, 4.0) (fatoresPorObjetivo PerderGordura)

testarFatoresGanharMassa :: Test
testarFatoresGanharMassa = TestCase $
  assertEqual "fatores GanharMassa" (2.0, 5.0) (fatoresPorObjetivo GanharMassa)

testarFatoresManterPeso :: Test
testarFatoresManterPeso = TestCase $
  assertEqual "fatores ManterPeso" (2.0, 4.0) (fatoresPorObjetivo ManterPeso)

testarCalcularMacros :: Test
testarCalcularMacros = TestCase $
  assertEqual "macros PerderGordura" (Macros 140.0 222.75 17.5) (calcularMacros 1608.5 70.0 PerderGordura)

--Alimento 

testarConversaoCafeParaTexto :: Test
testarConversaoCafeParaTexto = TestCase $
  assertEqual "Cafe para texto" "cafe" (tipoParaTexto Cafe)

testarConversaoAlmocoParaTexto :: Test
testarConversaoAlmocoParaTexto = TestCase $
  assertEqual "Almoco para texto" "almoco" (tipoParaTexto Almoco)

testarConversaoTextoParaAlmoco :: Test
testarConversaoTextoParaAlmoco = TestCase $
  assertEqual "texto para Almoco" Almoco (textoParaTipo "almoco")

testarConversaoTextoInvalidoDefaultCafe :: Test
testarConversaoTextoInvalidoDefaultCafe = TestCase $
  assertEqual "texto invalido retorna Cafe" Cafe (textoParaTipo "invalido")

testarRoundtripTipoTexto :: Test
testarRoundtripTipoTexto = TestCase $
  assertEqual "roundtrip Jantar" Jantar (textoParaTipo (tipoParaTexto Jantar))

-- ── Alimento (grupo)

testarGrupoParaTextoProteina :: Test
testarGrupoParaTextoProteina = TestCase $
  assertEqual "Proteina para texto" "proteina" (grupoParaTexto Proteina)

testarGrupoParaTextoCarboidrato :: Test
testarGrupoParaTextoCarboidrato = TestCase $
  assertEqual "Carboidrato para texto" "carboidrato" (grupoParaTexto Carboidrato)

testarTextoParaGrupoProteina :: Test
testarTextoParaGrupoProteina = TestCase $
  assertEqual "texto para Proteina" Proteina (textoParaGrupo "proteina")

testarTextoParaGrupoFruta :: Test
testarTextoParaGrupoFruta = TestCase $
  assertEqual "texto para Fruta" Fruta (textoParaGrupo "fruta")

testarTextoParaGrupoInvalidoDefaultProteina :: Test
testarTextoParaGrupoInvalidoDefaultProteina = TestCase $
  assertEqual "texto invalido retorna Proteina" Proteina (textoParaGrupo "invalido")

testarRoundtripGrupoTexto :: Test
testarRoundtripGrupoTexto = TestCase $
  assertEqual "roundtrip Leguminosa" Leguminosa (textoParaGrupo (grupoParaTexto Leguminosa))

--Plano

testarArredondarParaCima :: Test
testarArredondarParaCima = TestCase $
  assertEqual "arredondar 3.7 == 4.0" 4.0 (arredondar 3.7)

testarArredondarParaBaixo :: Test
testarArredondarParaBaixo = TestCase $
  assertEqual "arredondar 2.2 == 2.0" 2.0 (arredondar 2.2)

testarDistribuicaoPerderGordura :: Test
testarDistribuicaoPerderGordura = TestCase $
  assertEqual "distribuicao PerderGordura" (0.20, 0.35, 0.10, 0.35) (distribuicao PerderGordura)

testarDistribuicaoGanharMassa :: Test
testarDistribuicaoGanharMassa = TestCase $
  assertEqual "distribuicao GanharMassa" (0.25, 0.35, 0.15, 0.25) (distribuicao GanharMassa)

testarSomaDistribuicaoIgualUm :: Test
testarSomaDistribuicaoIgualUm = TestCase $ do
  let (a, b, c, d) = distribuicao ManterPeso
  assertBool "soma distribuicao deve ser 1.0" (abs (a + b + c + d - 1.0) < 1e-10)

testarCriacaoPorcaoGramas :: Test
testarCriacaoPorcaoGramas = TestCase $
  let alimentoTeste = Alimento "Frango" 100.0 30.0 0.0 3.0 Almoco Proteina
  in assertEqual "pGramas deve ser 200.0" 200.0 (pGramas (mkPorcao alimentoTeste 200.0))

testarCriacaoPorcaoCalorias :: Test
testarCriacaoPorcaoCalorias = TestCase $
  let alimentoTeste = Alimento "Arroz" 130.0 2.5 28.0 0.5 Almoco Carboidrato
  in assertEqual "pCalorias deve ser 300.0" 300.0 (pCalorias (mkPorcao alimentoTeste 300.0))

testarEscolherAlimentosListaVazia :: Test
testarEscolherAlimentosListaVazia = TestCase $
  assertEqual "lista vazia retorna []" ([] :: [Alimento]) (escolherAlimentos [] 1)

testarEscolherAlimentosListaUnitaria :: Test
testarEscolherAlimentosListaUnitaria = TestCase $
  assertEqual "lista unitaria retorna [a1]" [a1] (escolherAlimentos [a1] 5)

testarEscolherAlimentosDiaZero :: Test
testarEscolherAlimentosDiaZero = TestCase $
  assertEqual "dia 0 seleciona primeiro" a1 (head (escolherAlimentos [a1, a2, a3] 0))

testarDistribuirCalListaVazia :: Test
testarDistribuirCalListaVazia = TestCase $
  assertEqual "distribuirCal [] retorna []" ([] :: [Porcao]) (distribuirCal [] 500.0)

testarDistribuirCalUmAlimento :: Test
testarDistribuirCalUmAlimento = TestCase $
  assertEqual "distribuirCal [a1] retorna 1 porcao" 1 (length (distribuirCal [a1] 500.0))

testarDistribuirCalDoisAlimentos :: Test
testarDistribuirCalDoisAlimentos = TestCase $ do
  let [p1, p2] = distribuirCal [a1, a2] 1000.0
  assertEqual "p1 calorias == 600.0" 600.0 (pCalorias p1)
  assertEqual "p2 calorias == 400.0" 400.0 (pCalorias p2)

testarEscolherComFallbackEncontra :: Test
testarEscolherComFallbackEncontra = TestCase $
  assertBool "encontra alimento do grupo" (escolherComFallback [a1] [Proteina] 0 /= Nothing)

testarEscolherComFallbackNaoEncontra :: Test
testarEscolherComFallbackNaoEncontra = TestCase $
  assertEqual "lista vazia retorna Nothing" Nothing (escolherComFallback [] [Proteina] 0)

testarEscolherComFallbackFallback :: Test
testarEscolherComFallbackFallback = TestCase $
  let laticinios = Alimento "Iogurte" 61.0 3.5 4.7 3.3 Cafe Laticinios
  in assertBool "usa segundo grupo como fallback" (escolherComFallback [laticinios] [Proteina, Laticinios] 0 /= Nothing)

testarSlotsPorTipoCafe :: Test
testarSlotsPorTipoCafe = TestCase $
  assertEqual "cafe tem 3 slots" 3 (length (slotsPorTipo Cafe))

testarSlotsPorTipoAlmoco :: Test
testarSlotsPorTipoAlmoco = TestCase $
  assertEqual "almoco tem 3 slots" 3 (length (slotsPorTipo Almoco))

testarSlotsPorTipoLanche :: Test
testarSlotsPorTipoLanche = TestCase $
  assertEqual "lanche tem 2 slots" 2 (length (slotsPorTipo Lanche))

testarSlotsPorTipoJantar :: Test
testarSlotsPorTipoJantar = TestCase $
  assertEqual "jantar tem 3 slots" 3 (length (slotsPorTipo Jantar))

testarMontarRefeicaoDiaCalorias :: Test
testarMontarRefeicaoDiaCalorias = TestCase $
  assertEqual "meta calorias correta" 500.0 (rdCalorias (montarRefeicaoDia bancTeste Cafe "Café da Manhã" 500.0 1))

testarMontarRefeicaoDiaTipo :: Test
testarMontarRefeicaoDiaTipo = TestCase $
  assertEqual "tipo texto correto" "Café da Manhã" (rdTipo (montarRefeicaoDia bancTeste Cafe "Café da Manhã" 500.0 1))

testarMontarDiaNumeracao :: Test
testarMontarDiaNumeracao = TestCase $
  assertEqual "dpDia correto" 3 (dpDia (montarDia bancTeste ManterPeso 2000.0 3))

testarPlanoSemanalTamanho :: Test
testarPlanoSemanalTamanho = TestCase $
  assertEqual "plano tem 7 dias" 7 (length (gerarPlanoSemanal bancTeste ManterPeso 2000.0))

testarPlanoSemanalDiasCorretos :: Test
testarPlanoSemanalDiasCorretos = TestCase $
  assertEqual "dias numerados 1..7" [1..7] (map dpDia (gerarPlanoSemanal bancTeste ManterPeso 2000.0))

testarVerificarSenha :: Test
testarVerificarSenha = TestCase $ do
  assertBool "senha correta retorna True"  (verificarSenha "abc123" "abc123")
  assertBool "senha errada retorna False" (not (verificarSenha "errada" "abc123"))

testarValidarRegistro :: Test
testarValidarRegistro = TestCase $ do
  assertEqual "registro valido"  (Right ())                             (validarRegistro "Ana" "ana@email.com" "senha123")
  assertEqual "nome vazio"       (Left "Nome não pode ser vazio")       (validarRegistro ""    "ana@email.com" "senha123")
  assertEqual "email invalido"   (Left "Email inválido")                (validarRegistro "Ana" "emailsemarroba" "senha123")
  assertEqual "senha curta"      (Left "Senha deve ter pelo menos 6 caracteres") (validarRegistro "Ana" "ana@email.com" "abc")

testarRowParaAlimento :: Test
testarRowParaAlimento = TestCase $
  let row      = ("Frango", 165.0, 31.0, 0.0, 3.6, "almoco", "proteina")
      esperado = Alimento "Frango" 165.0 31.0 0.0 3.6 Almoco Proteina
  in assertEqual "rowParaAlimento converte corretamente" esperado (rowParaAlimento row)

--Suite completa 

suiteTestes :: Test
suiteTestes = TestList
  [ testarFatorMuitoAtivo
  , testarFatorModeramenteAtivo
  , testarFatorLevementeAtivo
  , testarFatorSedentario
  , testarFatorExtraAtivo
  , testarTMBMasculino
  , testarTMBFeminino
  , testarTDEE
  , testarMetaPerderGordura
  , testarMetaManterPeso
  , testarMetaGanharMassa
  , testarFatoresPerderGordura
  , testarFatoresGanharMassa
  , testarFatoresManterPeso
  , testarCalcularMacros
  , testarConversaoCafeParaTexto
  , testarConversaoAlmocoParaTexto
  , testarConversaoTextoParaAlmoco
  , testarConversaoTextoInvalidoDefaultCafe
  , testarRoundtripTipoTexto
  , testarGrupoParaTextoProteina
  , testarGrupoParaTextoCarboidrato
  , testarTextoParaGrupoProteina
  , testarTextoParaGrupoFruta
  , testarTextoParaGrupoInvalidoDefaultProteina
  , testarRoundtripGrupoTexto
  , testarArredondarParaCima
  , testarArredondarParaBaixo
  , testarDistribuicaoPerderGordura
  , testarDistribuicaoGanharMassa
  , testarSomaDistribuicaoIgualUm
  , testarCriacaoPorcaoGramas
  , testarCriacaoPorcaoCalorias
  , testarEscolherAlimentosListaVazia
  , testarEscolherAlimentosListaUnitaria
  , testarEscolherAlimentosDiaZero
  , testarDistribuirCalListaVazia
  , testarDistribuirCalUmAlimento
  , testarDistribuirCalDoisAlimentos
  , testarEscolherComFallbackEncontra
  , testarEscolherComFallbackNaoEncontra
  , testarEscolherComFallbackFallback
  , testarSlotsPorTipoCafe
  , testarSlotsPorTipoAlmoco
  , testarSlotsPorTipoLanche
  , testarSlotsPorTipoJantar
  , testarMontarRefeicaoDiaCalorias
  , testarMontarRefeicaoDiaTipo
  , testarMontarDiaNumeracao
  , testarPlanoSemanalTamanho
  , testarPlanoSemanalDiasCorretos
  , testarVerificarSenha
  , testarValidarRegistro
  , testarRowParaAlimento
  ]
