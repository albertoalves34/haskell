{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Alimento where

import Data.Aeson (ToJSON(..))
import GHC.Generics (Generic)

data TipoRefeicao = Cafe | Almoco | Lanche | Jantar
  deriving (Show, Eq, Generic)

instance ToJSON TipoRefeicao where
  toJSON Cafe   = "cafe"
  toJSON Almoco = "almoco"
  toJSON Lanche = "lanche"
  toJSON Jantar = "jantar"

data GrupoAlimento
  = Proteina | Carboidrato | Vegetal | Leguminosa
  | Fruta | Laticinios | Oleaginosa | Suplemento
  deriving (Show, Eq, Generic)

instance ToJSON GrupoAlimento where
  toJSON Proteina    = "proteina"
  toJSON Carboidrato = "carboidrato"
  toJSON Vegetal     = "vegetal"
  toJSON Leguminosa  = "leguminosa"
  toJSON Fruta       = "fruta"
  toJSON Laticinios  = "laticinios"
  toJSON Oleaginosa  = "oleaginosa"
  toJSON Suplemento  = "suplemento"

data Alimento = Alimento
  { nomeAlimento  :: String
  , calPor100g    :: Double
  , protPor100g   :: Double
  , carbPor100g   :: Double
  , gordPor100g   :: Double
  , tipoRefeicao  :: TipoRefeicao
  , grupoAlimento :: GrupoAlimento
  } deriving (Show, Eq, Generic)

instance ToJSON Alimento

tipoParaTexto :: TipoRefeicao -> String
tipoParaTexto Cafe   = "cafe"
tipoParaTexto Almoco = "almoco"
tipoParaTexto Lanche = "lanche"
tipoParaTexto Jantar = "jantar"

textoParaTipo :: String -> TipoRefeicao
textoParaTipo "almoco" = Almoco
textoParaTipo "lanche" = Lanche
textoParaTipo "jantar" = Jantar
textoParaTipo _        = Cafe

grupoParaTexto :: GrupoAlimento -> String
grupoParaTexto Proteina    = "proteina"
grupoParaTexto Carboidrato = "carboidrato"
grupoParaTexto Vegetal     = "vegetal"
grupoParaTexto Leguminosa  = "leguminosa"
grupoParaTexto Fruta       = "fruta"
grupoParaTexto Laticinios  = "laticinios"
grupoParaTexto Oleaginosa  = "oleaginosa"
grupoParaTexto Suplemento  = "suplemento"

textoParaGrupo :: String -> GrupoAlimento
textoParaGrupo "carboidrato" = Carboidrato
textoParaGrupo "vegetal"     = Vegetal
textoParaGrupo "leguminosa"  = Leguminosa
textoParaGrupo "fruta"       = Fruta
textoParaGrupo "laticinios"  = Laticinios
textoParaGrupo "oleaginosa"  = Oleaginosa
textoParaGrupo "suplemento"  = Suplemento
textoParaGrupo _             = Proteina
