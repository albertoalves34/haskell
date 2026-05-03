{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Plano where

import Alimento
import Calculate
import Data.Aeson
import GHC.Generics

data Porcao = Porcao
  { pNome     :: String
  , pGramas   :: Double
  , pCalorias :: Double
  , pCal100g  :: Double
  , pProt100g :: Double
  , pCarb100g :: Double
  , pGord100g :: Double
  , pTipo     :: String
  } deriving (Show, Eq, Generic)

instance ToJSON Porcao

data RefeicaoDia = RefeicaoDia
  { rdTipo     :: String
  , rdCalorias :: Double
  , rdPorcoes  :: [Porcao]
  } deriving (Show, Generic)

instance ToJSON RefeicaoDia

data DiaPlano = DiaPlano
  { dpDia    :: Int
  , dpCafe   :: RefeicaoDia
  , dpAlmoco :: RefeicaoDia
  , dpLanche :: RefeicaoDia
  , dpJantar :: RefeicaoDia
  } deriving (Show, Generic)

instance ToJSON DiaPlano

distribuicao :: Objetivo -> (Double, Double, Double, Double)
distribuicao PerderGordura = (0.20, 0.35, 0.10, 0.35)
distribuicao ManterPeso    = (0.25, 0.35, 0.10, 0.30)
distribuicao GanharMassa   = (0.25, 0.35, 0.15, 0.25)

arredondar :: Double -> Double
arredondar x = fromIntegral (round x :: Int)

mkPorcao :: Alimento -> Double -> Porcao
mkPorcao a cal = Porcao
  { pNome     = nomeAlimento a
  , pGramas   = arredondar (cal / calPor100g a * 100)
  , pCalorias = arredondar cal
  , pCal100g  = calPor100g  a
  , pProt100g = protPor100g a
  , pCarb100g = carbPor100g a
  , pGord100g = gordPor100g a
  , pTipo     = tipoParaTexto (tipoRefeicao a)
  }

-- Fallback: distribui calorias igualmente entre alimentos sem considerar grupo
escolherAlimentos :: [Alimento] -> Int -> [Alimento]
escolherAlimentos []  _   = []
escolherAlimentos [a] _   = [a]
escolherAlimentos xs dia  =
  let n  = length xs
      i1 = mod (dia * 3)     n
      i2 = mod (dia * 3 + 1) n
      i3 = mod (dia * 3 + 2) n
  in if n >= 3
       then [xs !! i1, xs !! i2, xs !! i3]
       else [xs !! i1, xs !! i2]

distribuirCal :: [Alimento] -> Double -> [Porcao]
distribuirCal []           _   = []
distribuirCal [a]          cal = [mkPorcao a cal]
distribuirCal [a1,a2]      cal = [mkPorcao a1 (cal * 0.6), mkPorcao a2 (cal * 0.4)]
distribuirCal (a1:a2:a3:_) cal = [mkPorcao a1 (cal * 0.5), mkPorcao a2 (cal * 0.3), mkPorcao a3 (cal * 0.2)]

-- Composição por grupo alimentar

-- Tenta encontrar um alimento de um dos grupos (em ordem de prioridade)
escolherComFallback :: [Alimento] -> [GrupoAlimento] -> Int -> Maybe Alimento
escolherComFallback alimentos grupos seed =
  let candidatos g = filter (\a -> grupoAlimento a == g) alimentos
      primeira     = foldr (\g acc -> let xs = candidatos g
                                      in if null xs then acc else Just xs)
                           Nothing grupos
  in case primeira of
       Nothing -> Nothing
       Just xs -> Just (xs !! mod seed (length xs))

-- Slot: (grupos em ordem de prioridade, fração das calorias da refeição)
type Slot = ([GrupoAlimento], Double)

slotsCafe, slotsAlmoco, slotsLanche, slotsJantar :: [Slot]
slotsCafe   = [ ([Proteina, Laticinios], 0.40)
              , ([Carboidrato],          0.40)
              , ([Fruta],                0.20) ]
slotsAlmoco = [ ([Proteina],            0.50)
              , ([Carboidrato],          0.30)
              , ([Leguminosa, Vegetal],  0.20) ]
slotsLanche = [ ([Fruta, Carboidrato],  0.50)
              , ([Oleaginosa, Laticinios, Suplemento], 0.50) ]
slotsJantar = [ ([Proteina],               0.50)
              , ([Carboidrato, Leguminosa], 0.30)
              , ([Vegetal, Leguminosa],     0.20) ]

slotsPorTipo :: TipoRefeicao -> [Slot]
slotsPorTipo Cafe   = slotsCafe
slotsPorTipo Almoco = slotsAlmoco
slotsPorTipo Lanche = slotsLanche
slotsPorTipo Jantar = slotsJantar

montarRefeicaoDia :: [Alimento] -> TipoRefeicao -> String -> Double -> Int -> RefeicaoDia
montarRefeicaoDia banco tipo tipoStr metaCal diaIdx =
  let disponiveis = filter (\a -> tipoRefeicao a == tipo) banco
      slots       = slotsPorTipo tipo
      nSlots      = length slots
      porcoes     = [ mkPorcao al (metaCal * frac)
                    | ((grupos, frac), offset) <- zip slots [0..]
                    , Just al <- [escolherComFallback disponiveis grupos (diaIdx * nSlots + offset)]
                    ]
      -- fallback para distribuição simples se não houver alimentos classificados
      porcoesFinal = if null porcoes
                       then distribuirCal (escolherAlimentos disponiveis diaIdx) metaCal
                       else porcoes
  in RefeicaoDia tipoStr (arredondar metaCal) porcoesFinal

montarDia :: [Alimento] -> Objetivo -> Double -> Int -> DiaPlano
montarDia banco objetivo totalCal dia =
  let (pC, pA, pL, pJ) = distribuicao objetivo
  in DiaPlano dia
      (montarRefeicaoDia banco Cafe   "Café da Manhã" (totalCal * pC) dia)
      (montarRefeicaoDia banco Almoco "Almoço"        (totalCal * pA) dia)
      (montarRefeicaoDia banco Lanche "Lanche"        (totalCal * pL) dia)
      (montarRefeicaoDia banco Jantar "Jantar"        (totalCal * pJ) dia)

gerarPlanoSemanal :: [Alimento] -> Objetivo -> Double -> [DiaPlano]
gerarPlanoSemanal banco objetivo totalCal =
  map (montarDia banco objetivo totalCal) [1..7]
