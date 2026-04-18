{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import Web.Scotty
import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)
import Network.Wai.Middleware.Cors
    ( cors,
      simpleCorsResourcePolicy,
      CorsResourcePolicy(corsRequestHeaders) )
import Control.Monad.IO.Class (liftIO)

-- 1. Definimos o formato dos dados que vamos receber do HTML
-- O (Generic) e as instâncias FromJSON/ToJSON fazem o Haskell
-- saber como converter isso automaticamente de/para JSON.
data Usuario = Usuario
  { nome  :: String
  , email :: String
  , senha :: String
  } deriving (Show, Generic)

instance FromJSON Usuario
instance ToJSON Usuario

main :: IO ()
main = scotty 3000 $ do
  -- 2. Ativamos o CORS com suporte a JSON.
  middleware $ cors $ const $ Just simpleCorsResourcePolicy
    { corsRequestHeaders = ["Content-Type"] }

  -- 3. Criamos a rota para receber o formulário
  post "/api/registro" $ do
    -- jsonData lê o corpo da requisição e tenta transformar no tipo Usuario
    novoUsuario <- jsonData :: ActionM Usuario
    
    -- Aqui você faria a lógica de salvar no banco de dados!
    -- Vamos apenas imprimir no terminal do Haskell por enquanto:
    liftIO $ putStrLn $ "Novo usuário recebido: " ++ show novoUsuario

    -- 4. Devolvemos uma resposta de sucesso pro JavaScript em formato JSON
    json novoUsuario