
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Banco where

import Data.Text (Text)
import Data.Aeson (ToJSON, FromJSON)
import GHC.Generics (Generic)

-- Tipo User (simulado em memória)
data User = User Int String  -- id, email
  deriving (Show, Generic)

instance ToJSON User
instance FromJSON User

type Connection = ()

-- Adicionar usuário (simulado)
addUser :: Connection -> String -> String -> IO ()
addUser _ email password = do
  putStrLn $ "Usuário " ++ email ++ " criado com sucesso!"

-- Buscar usuário por email (simulado)
getUserByEmail :: Connection -> String -> IO (Maybe (Int, String))
getUserByEmail _ email = do
  if email == "test@email.com"
    then return $ Just (1, "password123")
    else return Nothing

-- Buscar usuário por ID (simulado)
getUserById :: Connection -> Int -> IO (Maybe User)
getUserById _ userId = do
  if userId == 1
    then return $ Just (User 1 "test@email.com")
    else return Nothing

-- Listar todos os usuários (simulado)
listUsers :: Connection -> IO [User]
listUsers _ = do
  return [User 1 "test@email.com", User 2 "user@email.com"]

-- Deletar usuário (simulado)
deleteUser :: Connection -> Int -> IO ()
deleteUser _ userId = do
  putStrLn "Usuário deletado!"

-- Atualizar senha (simulado)
updateUserPassword :: Connection -> Int -> String -> IO ()
updateUserPassword _ userId newPassword = do
  putStrLn "Senha atualizada!"