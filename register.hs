{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Register where

import Web.Scotty
import Database.SQLite.Simple
import Data.Aeson (FromJSON, object, (.=))
import GHC.Generics (Generic)
import Control.Monad.IO.Class (liftIO)
import Banco

data RegistroData = RegistroData
  { nome  :: String
  , email :: String
  , senha :: String
  } deriving (Show, Generic)

instance FromJSON RegistroData

registerRoute :: Connection -> ScottyM ()
registerRoute conn =
  post "/api/registro" $ do
    dados <- jsonData :: ActionM RegistroData
    liftIO $ addUser conn (nome dados) (email dados) (senha dados)
    json $ object
      [ "status"  .= ("ok" :: String)
      , "message" .= ("Usuário registrado com sucesso!" :: String)
      ]