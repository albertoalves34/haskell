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
  , pCal100g  :: Double  -- info nutricional por 100g para exibição
  , pProt100g :: Double
  , pCarb100g :: Double
  , pGord100g :: Double
  , pTipo     :: String  -- tipo de refeição (para filtrar substitutos)
  } deriving (Show, Generic)

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

--Tirar numeros quebrados do front
arredondar :: Double -> Double
arredondar x = fromIntegral (round x :: Int)

--Limita tamaho da porção a partir de do limite de cal
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
  

escolherAlimentos :: [Alimento] -> Int -> [Alimento]
escolherAlimentos []  _      = []
escolherAlimentos [a] _      = [a]
escolherAlimentos xs  diaIdx =
  let n     = length xs
      idx1  = mod (diaIdx * 2) n 
      idx2' = mod (diaIdx * 2 + 1) n -- 
  in [xs !! idx1]

distribuirCal :: [Alimento] -> Double -> [Porcao]
distribuirCal []       _   = []
distribuirCal [a]      cal = [mkPorcao a cal]
distribuirCal (a1:a2:_) cal = [mkPorcao a1 (cal * 0.6), mkPorcao a2 (cal * 0.4)]

montarRefeicaoDia :: [Alimento] -> TipoRefeicao -> String -> Double -> Int -> RefeicaoDia
montarRefeicaoDia banco tipo tipoStr metaCal diaIdx =
  let disponiveis = filter (\a -> tipoRefeicao a == tipo) banco
      porcoes     = distribuirCal (escolherAlimentos disponiveis diaIdx) metaCal
  in RefeicaoDia tipoStr (arredondar metaCal) porcoes

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
