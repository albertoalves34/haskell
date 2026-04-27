module Calculate where

data Sexo
  = Masculino
  | Feminino
  deriving (Show, Eq)

data NivelAtividade
  = Sedentario       -- pouco ou nenhum exercício
  | LevementeAtivo   -- exercício 1-3 dias/semana
  | ModeramenteAtivo -- exercício 3-5 dias/semana
  | MuitoAtivo       -- exercício 6-7 dias/semana
  | ExtraAtivo       -- atleta, trabalho físico intenso
  deriving (Show, Eq)

-- Objetivo do plano alimentar
data Objetivo
  = PerderGordura  -- déficit calórico
  | ManterPeso     -- manutenção
  | GanharMassa    -- superávit calórico
  deriving (Show, Eq)

-- Resultado dos macronutrientes sugeridos (em gramas)
data Macros = Macros
  { proteina     :: Double  -- gramas de proteína
  , carboidrato  :: Double  -- gramas de carboidrato
  , gordura      :: Double  -- gramas de gordura
  } deriving (Show, Eq)


nivelAtividadeParaFator :: NivelAtividade -> Double
nivelAtividadeParaFator Sedentario = 1.2
nivelAtividadeParaFator LevementeAtivo = 1.375
nivelAtividadeParaFator ModeramenteAtivo = 1.55
nivelAtividadeParaFator MuitoAtivo = 1.725
nivelAtividadeParaFator ExtraAtivo = 1.9


calcularTMB :: Sexo -> Double -> Double -> Int -> Double
calcularTMB Masculino peso altura idade = 10 * peso + 6.25 * altura - 5 * fromIntegral(idade) + 5
calcularTMB Feminino peso altura idade = 10 * peso + 6.25 * altura - 5 * fromIntegral(idade) - 161


calcularTDEE :: Double -> NivelAtividade -> Double
calcularTDEE tmb nivel = tmb * nivelAtividadeParaFator nivel


calcularMeta :: Double -> Objetivo -> Double
calcularMeta tdee PerderGordura = tdee - 400
calcularMeta tdee ManterPeso = tdee
calcularMeta tdee GanharMassa = tdee + 250

calcularMacros :: Double -> Double -> Objetivo -> Macros
calcularMacros meta peso objetivo = Macros
  { proteina    = prot
  , gordura     = gord
  , carboidrato = carb
  }
  where
    (fatProt, fatGord) = fatoresPorObjetivo objetivo
    prot = peso * fatProt
    gord = peso / fatGord
    carb = (meta - ((prot * 4.0) + (gord * 9.0))) / 4.0

fatoresPorObjetivo :: Objetivo -> (Double, Double)
fatoresPorObjetivo PerderGordura = (2.0, 4.0)
fatoresPorObjetivo ManterPeso    = (2.0, 4.0)  
fatoresPorObjetivo GanharMassa   = (2.0, 5.0)