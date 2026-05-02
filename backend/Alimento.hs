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

data Alimento = Alimento
  { nomeAlimento :: String
  , calPor100g   :: Double
  , protPor100g  :: Double
  , carbPor100g  :: Double
  , gordPor100g  :: Double
  , tipoRefeicao :: TipoRefeicao
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
