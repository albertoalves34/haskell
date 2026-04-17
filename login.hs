{-# LANGUAGE OverloadedStrings #-}


import Routes
import Web.Scotty
import Database.SQLite.Simple
import Banco  

loginUser :: Connection -> String -> String -> IO (Either String String)
loginUser conn email passsword = do
    user <- getUserByEmail conn email
        case user of
                Just (userId, storedPass) -> 
                    if storedPass == password
                        then return $ Right "Login sucesso!"
                        else return $ Left "Senha incorreta"
                    Nothing -> 
                        return $ Left "Email não encontrado"