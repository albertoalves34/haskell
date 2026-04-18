{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

import Web.Scotty
import Network.HTTP.Types (status400)
import Data.Aeson (object, (.=))
import Banco
import qualified Control.Exception as E
import Control.Applicative ((<|>))

-- Função auxiliar para login
loginUser :: String -> String -> IO (Either String String)
loginUser email password = do
  result <- E.catch
    (do
      user <- getUserByEmail () email
      case user of
        Just (userId, storedPass) ->
          if storedPass == password
            then return $ Right "Login realizado com sucesso!"
            else return $ Left "Senha incorreta"
        Nothing ->
          return $ Left "Email não encontrado"
    )
    (\(e :: E.SomeException) -> return $ Left $ show e)
  return result

main :: IO ()
main = do
  scotty 3000 $ do
    -- Rota de registro
    post "/api/register" $ do
      email <- (param "email") <|> return ""
      password <- (param "password") <|> return ""
      
      if null email || null password
        then do
          status status400
          json $ object ["status" .= ("error" :: String), 
                        "message" .= ("Email e senha obrigatórios" :: String)]
        else do
          _ <- liftIO $ addUser () email password
          json $ object ["status" .= ("ok" :: String), 
                        "message" .= ("Usuário registrado com sucesso!" :: String)]
    
    -- Rota de login
    post "/api/login" $ do
      email <- (param "email") <|> return ""
      password <- (param "password") <|> return ""
      
      if null email || null password
        then do
          status status400
          json $ object ["status" .= ("error" :: String),
                        "message" .= ("Email e senha obrigatórios" :: String)]
        else do
          result <- liftIO $ loginUser email password
          case result of
            Right msg -> json $ object ["status" .= ("ok" :: String),
                                       "message" .= msg]
            Left err -> do
              status status400
              json $ object ["status" .= ("error" :: String),
                            "message" .= err]
    
    -- Rota para listar usuários
    get "/api/users" $ do
      users <- liftIO $ listUsers ()
      json users
    
    -- Rota raiz
    get "/" $ do
      text "DietaApp API - Use /api/login ou /api/register"
