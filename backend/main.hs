{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import Web.Scotty
import Data.Aeson
import GHC.Generics
import Network.Wai.Middleware.Cors
import Control.Monad.IO.Class
import Network.HTTP.Types.Status
import Database.SQLite.Simple
import System.Environment (lookupEnv)
import Data.Maybe (fromMaybe)
import Text.Read (readMaybe)
import Banco
import Login
import Calculate
import Alimento
import Plano

-- ─── Tipos de dados para as rotas ────────────────────────────────────────────

data RegistroData = RegistroData
  { nome  :: String
  , email :: String
  , senha :: String
  } deriving (Show, Generic)

instance FromJSON RegistroData
instance ToJSON RegistroData

data CalculoData = CalculoData
  { calcPeso     :: Double
  , calcAltura   :: Double
  , calcIdade    :: Int
  , calcSexo     :: String  -- "masculino" | "feminino"
  , calcNivel    :: String  -- "sedentario" | "levemente_ativo" | ...
  , calcObjetivo :: String  -- "perder_gordura" | "manter_peso" | "ganhar_massa"
  } deriving (Show, Generic)

instance FromJSON CalculoData

data NovoAlimentoData = NovoAlimentoData
  { naUserId :: Int
  , naNome   :: String
  , naCal    :: Double
  , naProt   :: Double
  , naCarb   :: Double
  , naGord   :: Double
  , naTipo   :: String  -- "cafe" | "almoco" | "lanche" | "jantar"
  } deriving (Show, Generic)

instance FromJSON NovoAlimentoData

data PlanoData = PlanoData
  { pdUserId   :: Int
  , pdCalorias :: Double
  , pdObjetivo :: String  -- "perder_gordura" | "manter_peso" | "ganhar_massa"
  } deriving (Show, Generic)

instance FromJSON PlanoData

-- ─── Helpers de parsing ───────────────────────────────────────────────────────

parseSexo :: String -> Maybe Sexo
parseSexo "masculino" = Just Masculino
parseSexo "feminino"  = Just Feminino
parseSexo _           = Nothing

parseNivel :: String -> Maybe NivelAtividade
parseNivel "sedentario"           = Just Sedentario
parseNivel "levemente_ativo"      = Just LevementeAtivo
parseNivel "moderadamente_ativo"  = Just ModeramenteAtivo
parseNivel "muito_ativo"          = Just MuitoAtivo
parseNivel "extra_ativo"          = Just ExtraAtivo
parseNivel _                      = Nothing

parseObjetivo :: String -> Maybe Objetivo
parseObjetivo "perder_gordura" = Just PerderGordura
parseObjetivo "manter_peso"    = Just ManterPeso
parseObjetivo "ganhar_massa"   = Just GanharMassa
parseObjetivo _                = Nothing

tiposValidos :: [String]
tiposValidos = ["cafe", "almoco", "lanche", "jantar"]

-- ─── Main ─────────────────────────────────────────────────────────────────────

main :: IO ()
main = do
  portStr <- lookupEnv "PORT"
  let port = fromMaybe 3000 (portStr >>= readMaybe)
  dbPath      <- fmap (fromMaybe "banco.db")  (lookupEnv "DB_PATH")
  frontendDir <- fmap (fromMaybe "frontend")  (lookupEnv "FRONTEND_DIR")
  conn <- open dbPath
  initDB conn
  initAlimentosDB conn
  seedDB conn
  scotty port $ do
    middleware $ cors $ const $ Just simpleCorsResourcePolicy
      { corsRequestHeaders = ["Content-Type"] }

    get "/healthz" $ do
      json $ object ["status" .= ("ok" :: String)]

    get "/" $ redirect "/login"
    get "/login"     $ file (frontendDir ++ "/login.html")
    get "/registro"  $ file (frontendDir ++ "/registro.html")
    get "/dashboard" $ file (frontendDir ++ "/dashboard.html")

    -- Registro de usuário
    post "/api/registro" $ do
      dados <- jsonData :: ActionM RegistroData
      liftIO $ addUser conn (nome dados) (email dados) (senha dados)
      json $ object
        [ "status"  .= ("ok" :: String)
        , "message" .= ("Usuário registrado com sucesso!" :: String)
        ]

    -- Login
    loginRoute conn

    -- Cálculo de macros
    post "/api/calcular" $ do
      dados <- jsonData :: ActionM CalculoData
      case (parseSexo (calcSexo dados), parseNivel (calcNivel dados), parseObjetivo (calcObjetivo dados)) of
        (Just sexo, Just nivel, Just objetivo) -> do
          let tmb    = calcularTMB sexo (calcPeso dados) (calcAltura dados) (calcIdade dados)
              tdee   = calcularTDEE tmb nivel
              meta   = calcularMeta tdee objetivo
              macros = calcularMacros meta (calcPeso dados) objetivo
          json $ object
            [ "calorias"    .= meta
            , "proteina"    .= proteina macros
            , "carboidrato" .= carboidrato macros
            , "gordura"     .= gordura macros
            ]
        _ -> do
          status status400
          json $ object
            [ "status"  .= ("error" :: String)
            , "message" .= ("Valores inválidos para sexo, nivel de atividade ou objetivo." :: String)
            ]

    -- Adicionar alimento ao banco do usuário
    post "/api/alimento" $ do
      dados <- jsonData :: ActionM NovoAlimentoData
      if naTipo dados `elem` tiposValidos
        then do
          liftIO $ addAlimento conn
            (naNome dados) (naCal dados) (naProt dados)
            (naCarb dados) (naGord dados) (naTipo dados)
            (naUserId dados)
          json $ object
            [ "status"  .= ("ok" :: String)
            , "message" .= ("Alimento adicionado com sucesso!" :: String)
            ]
        else do
          status status400
          json $ object
            [ "status"  .= ("error" :: String)
            , "message" .= ("Tipo de refeição invalido. Use: cafe, almoco, lanche ou jantar." :: String)
            ]

    -- Listar alimentos disponíveis para o usuário
    get "/api/alimentos/:userId" $ do
      uid   <- pathParam "userId" :: ActionM Int
      banco <- liftIO $ getAlimentos conn uid
      let alimentoParaJSON a = object
            [ "nome"  .= nomeAlimento a
            , "cal"   .= calPor100g a
            , "prot"  .= protPor100g a
            , "carb"  .= carbPor100g a
            , "gord"  .= gordPor100g a
            , "tipo"  .= tipoParaTexto (tipoRefeicao a)
            ]
      json $ map alimentoParaJSON banco

    -- Gerar plano semanal
    post "/api/plano" $ do
      dados <- jsonData :: ActionM PlanoData
      case parseObjetivo (pdObjetivo dados) of
        Nothing -> do
          status status400
          json $ object
            [ "status"  .= ("error" :: String)
            , "message" .= ("Objetivo inválido." :: String)
            ]
        Just objetivo -> do
          banco <- liftIO $ getAlimentos conn (pdUserId dados)
          let plano = gerarPlanoSemanal banco objetivo (pdCalorias dados)
          json $ object ["plano" .= plano]
