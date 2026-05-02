{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Login where

import Web.Scotty
import Database.SQLite.Simple
import Data.Aeson (FromJSON, object, (.=))
import GHC.Generics (Generic)
import Control.Monad.IO.Class (liftIO)
import Network.HTTP.Types.Status (status401)
import Banco

data LoginData = LoginData
  { loginEmail    :: String
  , loginPassword :: String
  } deriving (Show, Generic)

instance FromJSON LoginData

loginUser :: Connection -> String -> String -> IO (Either String Int)
loginUser conn email password = do
  result <- getUserByEmail conn email
  case result of
    Just (userId, storedPass) ->
      if storedPass == password
        then return $ Right userId
        else return $ Left "Senha incorreta"
    Nothing ->
      return $ Left "Email não encontrado"

loginRoute :: Connection -> ScottyM ()
loginRoute conn =
  post "/api/login" $ do
    dados  <- jsonData :: ActionM LoginData
    result <- liftIO $ loginUser conn (loginEmail dados) (loginPassword dados)
    case result of
      Right userId ->
        json $ object
          [ "status"  .= ("ok" :: String)
          , "message" .= ("Login realizado com sucesso!" :: String)
          , "userId"  .= userId
          ]
      Left err -> do
        status status401
        json $ object
          [ "status"  .= ("error" :: String)
          , "message" .= err
          ]
