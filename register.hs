{-# LANGUAGE OverloadedStrings #-}


import Routes
import Web.Scotty
import Database.SQLite.Simple
import Banco  

registerRoute :: Connection -> ScottyM ()
registerRoute conn = do
  post register $ do
    email <- param "email"      
    password <- param "password"
    
  
    liftIO $ addUser conn email password
    
    json $ object ["status" .= ("sucesso" :: String)]