{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Banco where

import Control.Exception (catch, SomeException)
import Database.SQLite.Simple
import Alimento (Alimento(..), TipoRefeicao, GrupoAlimento, textoParaTipo, textoParaGrupo)

--Tabela de usuários 

initDB :: Connection -> IO ()
initDB conn = execute_ conn
  "CREATE TABLE IF NOT EXISTS users \
  \(id INTEGER PRIMARY KEY AUTOINCREMENT, \
  \ nome TEXT NOT NULL, \
  \ email TEXT NOT NULL UNIQUE, \
  \ senha TEXT NOT NULL)"

addUser :: Connection -> String -> String -> String -> IO ()
addUser conn nome email senha =
  execute conn
    "INSERT INTO users (nome, email, senha) VALUES (?, ?, ?)"
    (nome, email, senha)

getUserByEmail :: Connection -> String -> IO (Maybe (Int, String))
getUserByEmail conn email = do
  results <- query conn
    "SELECT id, senha FROM users WHERE email = ?"
    (Only email)
  return $ case results of
    [row] -> Just row
    _     -> Nothing

getUserById :: Connection -> Int -> IO (Maybe (Int, String, String))
getUserById conn userId = do
  results <- query conn
    "SELECT id, nome, email FROM users WHERE id = ?"
    (Only userId)
  return $ case results of
    [row] -> Just row
    _     -> Nothing

deleteUser :: Connection -> Int -> IO ()
deleteUser conn userId =
  execute conn "DELETE FROM users WHERE id = ?" (Only userId)

-- ─── Tabela de alimentos 

initAlimentosDB :: Connection -> IO ()
initAlimentosDB conn = do
  execute_ conn
    "CREATE TABLE IF NOT EXISTS alimentos \
    \(id INTEGER PRIMARY KEY AUTOINCREMENT, \
    \ nome TEXT NOT NULL, \
    \ cal_por_100g REAL NOT NULL, \
    \ prot_por_100g REAL NOT NULL, \
    \ carb_por_100g REAL NOT NULL, \
    \ gord_por_100g REAL NOT NULL, \
    \ tipo_refeicao TEXT NOT NULL, \
    \ grupo TEXT NOT NULL DEFAULT 'proteina', \
    \ user_id INTEGER)"
  -- adiciona coluna grupo em bancos antigos (ignora se já existe)
  (execute_ conn "ALTER TABLE alimentos ADD COLUMN grupo TEXT NOT NULL DEFAULT 'proteina'")
    `catch` \(_ :: SomeException) -> return ()

addAlimento :: Connection -> String -> Double -> Double -> Double -> Double -> String -> String -> Int -> IO ()
addAlimento conn nome cal prot carb gord tipo grupo userId =
  execute conn
    "INSERT INTO alimentos (nome, cal_por_100g, prot_por_100g, carb_por_100g, gord_por_100g, tipo_refeicao, grupo, user_id) \
    \VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
    (nome, cal, prot, carb, gord, tipo, grupo, userId)

rowParaAlimento :: (String, Double, Double, Double, Double, String, String) -> Alimento
rowParaAlimento (nome, cal, prot, carb, gord, tipo, grupo) =
  Alimento nome cal prot carb gord (textoParaTipo tipo) (textoParaGrupo grupo)

getAlimentos :: Connection -> Int -> IO [Alimento]
getAlimentos conn userId = do
  rows <- query conn
    "SELECT nome, cal_por_100g, prot_por_100g, carb_por_100g, gord_por_100g, tipo_refeicao, grupo \
    \FROM alimentos WHERE user_id IS NULL OR user_id = ?"
    (Only userId) :: IO [(String, Double, Double, Double, Double, String, String)]
  return $ map rowParaAlimento rows

-- Seed de alimentos base 

-- (nome, cal, prot, carb, gord, tipo, grupo)
type AlimentoSeed = (String, Double, Double, Double, Double, String, String)

seedDB :: Connection -> IO ()
seedDB conn = do
  -- verifica se o seed está atualizado checando um alimento conhecido com grupo correto
  rows <- query_ conn
    "SELECT grupo FROM alimentos WHERE user_id IS NULL AND nome = 'Arroz branco cozido'"
    :: IO [Only String]
  case rows of
    [Only "carboidrato"] -> return ()
    _ -> do
      execute_ conn "DELETE FROM alimentos WHERE user_id IS NULL"
      mapM_ insert alimentosBase
  where
    insert row = execute conn
      "INSERT INTO alimentos (nome, cal_por_100g, prot_por_100g, carb_por_100g, gord_por_100g, tipo_refeicao, grupo) \
      \VALUES (?, ?, ?, ?, ?, ?, ?)"
      row

alimentosBase :: [AlimentoSeed]
alimentosBase =
--Café da Manhã 
  [ ("Ovo mexido",               155.0, 11.0,  1.1, 12.0, "cafe", "proteina")
  , ("Ovo cozido",               155.0, 13.0,  1.1, 11.0, "cafe", "proteina")
  , ("Iogurte natural",           61.0,  3.5,  4.7,  3.3, "cafe", "laticinios")
  , ("Queijo minas",             264.0, 17.0,  3.0, 21.0, "cafe", "laticinios")
  , ("Pão integral",             247.0,  8.5, 41.3,  3.4, "cafe", "carboidrato")
  , ("Pão francês",              300.0,  9.0, 58.0,  3.0, "cafe", "carboidrato")
  , ("Aveia",                    389.0, 16.9, 66.3,  6.9, "cafe", "carboidrato")
  , ("Granola",                  401.0, 10.0, 66.0, 12.0, "cafe", "carboidrato")
  , ("Tapioca",                  358.0,  0.7, 86.7,  0.2, "cafe", "carboidrato")
  , ("Cuscuz de milho",          347.0,  7.9, 73.0,  1.5, "cafe", "carboidrato")
  , ("Banana",                    89.0,  1.1, 23.0,  0.3, "cafe", "fruta")
  , ("Mamão",                     43.0,  0.5, 10.8,  0.1, "cafe", "fruta")
--almoço
  , ("Peito de frango grelhado", 159.0, 32.0,  0.0,  3.0, "almoco", "proteina")
  , ("Coxa de frango assada",    189.0, 26.0,  0.0,  9.0, "almoco", "proteina")
  , ("Sobrecoxa de frango",      220.0, 23.0,  0.0, 14.0, "almoco", "proteina")
  , ("Alcatra grelhada",         219.0, 27.0,  0.0, 12.0, "almoco", "proteina")
  , ("Picanha grelhada",         293.0, 24.0,  0.0, 21.0, "almoco", "proteina")
  , ("Carne moída grelhada",     219.0, 27.0,  0.0, 12.0, "almoco", "proteina")
  , ("Músculo cozido",           209.0, 28.0,  0.0, 10.0, "almoco", "proteina")
  , ("Contra-filé grelhado",     247.0, 25.0,  0.0, 16.0, "almoco", "proteina")
  , ("Salmão grelhado",          208.0, 20.0,  0.0, 13.0, "almoco", "proteina")
  , ("Tilápia grelhada",          96.0, 20.0,  0.0,  2.0, "almoco", "proteina")
  , ("Atum em lata (água)",      109.0, 24.0,  0.0,  1.0, "almoco", "proteina")
  , ("Sardinha grelhada",        208.0, 19.0,  0.0, 14.0, "almoco", "proteina")
  , ("Arroz branco cozido",      130.0,  2.7, 28.2,  0.3, "almoco", "carboidrato")
  , ("Arroz integral cozido",    124.0,  2.6, 25.8,  1.0, "almoco", "carboidrato")
  , ("Macarrão integral cozido", 174.0,  7.5, 35.0,  1.3, "almoco", "carboidrato")
  , ("Batata doce cozida",        86.0,  1.6, 20.1,  0.1, "almoco", "carboidrato")
  , ("Batata inglesa cozida",     52.0,  1.2, 12.0,  0.1, "almoco", "carboidrato")
  , ("Mandioca cozida",          125.0,  0.6, 30.0,  0.3, "almoco", "carboidrato")
  , ("Feijão preto cozido",       77.0,  4.5, 14.0,  0.5, "almoco", "leguminosa")
  , ("Feijão carioca cozido",     76.0,  4.8, 13.7,  0.5, "almoco", "leguminosa")
  , ("Lentilha cozida",          116.0,  9.0, 20.0,  0.4, "almoco", "leguminosa")
  , ("Grão-de-bico cozido",      164.0,  9.0, 27.0,  2.6, "almoco", "leguminosa")
  , ("Brócolis cozido",           34.0,  2.8,  6.6,  0.4, "almoco", "vegetal")
  , ("Cenoura cozida",            34.0,  1.3,  7.7,  0.2, "almoco", "vegetal")
  , ("Abobrinha refogada",        18.0,  1.1,  3.4,  0.2, "almoco", "vegetal")
  , ("Couve-flor cozida",         31.0,  2.4,  5.0,  0.3, "almoco", "vegetal")
  , ("Espinafre refogado",        23.0,  2.9,  3.6,  0.4, "almoco", "vegetal")
-- lanche
  , ("Maçã",                      52.0,  0.3, 14.0,  0.2, "lanche", "fruta")
  , ("Banana",                    89.0,  1.1, 23.0,  0.3, "lanche", "fruta")
  , ("Laranja",                   47.0,  0.9, 12.0,  0.1, "lanche", "fruta")
  , ("Manga",                     60.0,  0.8, 15.0,  0.4, "lanche", "fruta")
  , ("Morango",                   32.0,  0.7,  7.7,  0.3, "lanche", "fruta")
  , ("Uva",                       69.0,  0.7, 18.0,  0.2, "lanche", "fruta")
  , ("Abacate",                  160.0,  2.0,  9.0, 15.0, "lanche", "fruta")
  , ("Melancia",                  30.0,  0.6,  7.6,  0.2, "lanche", "fruta")
  , ("Goiaba",                    80.0,  2.6, 15.0,  1.0, "lanche", "fruta")
  , ("Castanha de caju",         553.0, 18.0, 30.0, 44.0, "lanche", "oleaginosa")
  , ("Amendoim torrado",         567.0, 26.0, 16.0, 49.0, "lanche", "oleaginosa")
  , ("Amêndoa",                  579.0, 21.0, 22.0, 50.0, "lanche", "oleaginosa")
  , ("Nozes",                    654.0, 15.0, 14.0, 65.0, "lanche", "oleaginosa")
  , ("Pasta de amendoim",        595.0, 25.0, 18.0, 50.0, "lanche", "oleaginosa")
  , ("Iogurte grego",            133.0,  9.0,  4.0, 10.0, "lanche", "laticinios")
  , ("Queijo cottage",            98.0, 11.0,  3.4,  4.3, "lanche", "laticinios")
  , ("Whey protein",             400.0, 80.0,  7.0,  5.0, "lanche", "suplemento")
-- jantar
  , ("Omelete",                  154.0, 11.0,  1.1, 12.0, "jantar", "proteina")
  , ("Tilápia grelhada",          96.0, 20.0,  0.0,  2.0, "jantar", "proteina")
  , ("Peito de frango grelhado", 159.0, 32.0,  0.0,  3.0, "jantar", "proteina")
  , ("Salmão grelhado",          208.0, 20.0,  0.0, 13.0, "jantar", "proteina")
  , ("Atum em lata (água)",      109.0, 24.0,  0.0,  1.0, "jantar", "proteina")
  , ("Bacalhau cozido",          113.0, 26.0,  0.0,  0.5, "jantar", "proteina")
  , ("Macarrão integral cozido", 174.0,  7.5, 35.0,  1.3, "jantar", "carboidrato")
  , ("Quinoa cozida",            120.0,  4.4, 21.3,  1.9, "jantar", "carboidrato")
  , ("Arroz integral cozido",    124.0,  2.6, 25.8,  1.0, "jantar", "carboidrato")
  , ("Grão-de-bico cozido",      164.0,  9.0, 27.0,  2.6, "jantar", "leguminosa")
  , ("Lentilha cozida",          116.0,  9.0, 20.0,  0.4, "jantar", "leguminosa")
  , ("Sopa de legumes",           35.0,  1.5,  7.0,  0.3, "jantar", "vegetal")
  ]
