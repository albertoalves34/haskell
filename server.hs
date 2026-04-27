{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import Web.Scotty
import Data.Aeson (FromJSON, ToJSON, object, (.=))
import GHC.Generics (Generic)
import Network.Wai.Middleware.Cors
    ( cors
    , simpleCorsResourcePolicy
    , CorsResourcePolicy(corsRequestHeaders) )
import Control.Monad.IO.Class (liftIO)
import Database.SQLite.Simple
import Banco
import Login (loginRoute)

data RegistroData = RegistroData
  { nome  :: String
  , email :: String
  , senha :: String
  } deriving (Show, Generic)

instance FromJSON RegistroData
instance ToJSON RegistroData

main :: IO ()
main = do
  conn <- open "banco.db"
  initDB conn
  scotty 3000 $ do
    middleware $ cors $ const $ Just simpleCorsResourcePolicy
      { corsRequestHeaders = ["Content-Type"] }

    post "/api/registro" $ do
      dados <- jsonData :: ActionM RegistroData
      liftIO $ addUser conn (nome dados) (email dados) (senha dados)
      json $ object
        [ "status"  .= ("ok" :: String)
        , "message" .= ("Usuário registrado com sucesso!" :: String)
        ]

    loginRoute conn
