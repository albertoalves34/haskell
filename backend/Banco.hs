{-# LANGUAGE OverloadedStrings #-}

module Banco where

import Database.SQLite.Simple
import Alimento (Alimento(..), TipoRefeicao, textoParaTipo)

-- ─── Tabela de usuários ───────────────────────────────────────────────────────

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

-- ─── Tabela de alimentos ──────────────────────────────────────────────────────

initAlimentosDB :: Connection -> IO ()
initAlimentosDB conn = execute_ conn
  "CREATE TABLE IF NOT EXISTS alimentos \
  \(id INTEGER PRIMARY KEY AUTOINCREMENT, \
  \ nome TEXT NOT NULL, \
  \ cal_por_100g REAL NOT NULL, \
  \ prot_por_100g REAL NOT NULL, \
  \ carb_por_100g REAL NOT NULL, \
  \ gord_por_100g REAL NOT NULL, \
  \ tipo_refeicao TEXT NOT NULL, \
  \ user_id INTEGER)"

-- Adiciona alimento criado pelo usuário
addAlimento :: Connection -> String -> Double -> Double -> Double -> Double -> String -> Int -> IO ()
addAlimento conn nome cal prot carb gord tipo userId =
  execute conn
    "INSERT INTO alimentos (nome, cal_por_100g, prot_por_100g, carb_por_100g, gord_por_100g, tipo_refeicao, user_id) \
    \VALUES (?, ?, ?, ?, ?, ?, ?)"
    (nome, cal, prot, carb, gord, tipo, userId)

-- Retorna alimentos base + alimentos do usuário como [Alimento]
getAlimentos :: Connection -> Int -> IO [Alimento]
getAlimentos conn userId = do
  rows <- query conn
    "SELECT nome, cal_por_100g, prot_por_100g, carb_por_100g, gord_por_100g, tipo_refeicao \
    \FROM alimentos WHERE user_id IS NULL OR user_id = ?"
    (Only userId) :: IO [(String, Double, Double, Double, Double, String)]
  return $ map rowParaAlimento rows
  where
    rowParaAlimento (nome, cal, prot, carb, gord, tipo) =
      Alimento nome cal prot carb gord (textoParaTipo tipo)

-- ─── Seed de alimentos base ───────────────────────────────────────────────────

type AlimentoSeed = (String, Double, Double, Double, Double, String)

seedDB :: Connection -> IO ()
seedDB conn = do
  [Only count] <- query_ conn
    "SELECT COUNT(*) FROM alimentos WHERE user_id IS NULL" :: IO [Only Int]
  if count > 0
    then return ()
    else mapM_ insert alimentosBase
  where
    insert row = execute conn
      "INSERT INTO alimentos (nome, cal_por_100g, prot_por_100g, carb_por_100g, gord_por_100g, tipo_refeicao) \
      \VALUES (?, ?, ?, ?, ?, ?)"
      row

alimentosBase :: [AlimentoSeed]
alimentosBase =
  -- café
  [ ("Ovo mexido",              155.0, 11.0,  1.1, 12.0, "cafe")
  , ("Ovo cozido",              155.0, 13.0,  1.1, 11.0, "cafe")
  , ("Pão integral",            247.0,  8.5, 41.3,  3.4, "cafe")
  , ("Pão francês",             300.0,  9.0, 58.0,  3.0, "cafe")
  , ("Aveia",                   389.0, 16.9, 66.3,  6.9, "cafe")
  , ("Granola",                 401.0, 10.0, 66.0, 12.0, "cafe")
  , ("Banana",                   89.0,  1.1, 23.0,  0.3, "cafe")
  , ("Mamão",                    43.0,  0.5, 10.8,  0.1, "cafe")
  , ("Iogurte natural",          61.0,  3.5,  4.7,  3.3, "cafe")
  , ("Tapioca",                 358.0,  0.7, 86.7,  0.2, "cafe")
  , ("Cuscuz de milho",         347.0,  7.9, 73.0,  1.5, "cafe")
  , ("Queijo minas",            264.0, 17.0,  3.0, 21.0, "cafe")
  -- almoço
  , ("Peito de frango grelhado", 159.0, 32.0,  0.0,  3.0, "almoco")
  , ("Coxa de frango assada",    189.0, 26.0,  0.0,  9.0, "almoco")
  , ("Sobrecoxa de frango",      220.0, 23.0,  0.0, 14.0, "almoco")
  , ("Alcatra grelhada",         219.0, 27.0,  0.0, 12.0, "almoco")
  , ("Picanha grelhada",         293.0, 24.0,  0.0, 21.0, "almoco")
  , ("Carne moída grelhada",     219.0, 27.0,  0.0, 12.0, "almoco")
  , ("Músculo cozido",           209.0, 28.0,  0.0, 10.0, "almoco")
  , ("Contra-filé grelhado",     247.0, 25.0,  0.0, 16.0, "almoco")
  , ("Salmão grelhado",          208.0, 20.0,  0.0, 13.0, "almoco")
  , ("Tilápia grelhada",          96.0, 20.0,  0.0,  2.0, "almoco")
  , ("Atum em lata (água)",      109.0, 24.0,  0.0,  1.0, "almoco")
  , ("Sardinha grelhada",        208.0, 19.0,  0.0, 14.0, "almoco")
  , ("Arroz branco cozido",      130.0,  2.7, 28.2,  0.3, "almoco")
  , ("Arroz integral cozido",    124.0,  2.6, 25.8,  1.0, "almoco")
  , ("Macarrão integral cozido", 174.0,  7.5, 35.0,  1.3, "almoco")
  , ("Batata doce cozida",        86.0,  1.6, 20.1,  0.1, "almoco")
  , ("Batata inglesa cozida",     52.0,  1.2, 12.0,  0.1, "almoco")
  , ("Mandioca cozida",          125.0,  0.6, 30.0,  0.3, "almoco")
  , ("Feijão preto cozido",       77.0,  4.5, 14.0,  0.5, "almoco")
  , ("Feijão carioca cozido",     76.0,  4.8, 13.7,  0.5, "almoco")
  , ("Lentilha cozida",          116.0,  9.0, 20.0,  0.4, "almoco")
  , ("Grão-de-bico cozido",      164.0,  9.0, 27.0,  2.6, "almoco")
  , ("Brócolis cozido",           34.0,  2.8,  6.6,  0.4, "almoco")
  , ("Cenoura cozida",            34.0,  1.3,  7.7,  0.2, "almoco")
  , ("Abobrinha refogada",        18.0,  1.1,  3.4,  0.2, "almoco")
  , ("Couve-flor cozida",         31.0,  2.4,  5.0,  0.3, "almoco")
  , ("Espinafre refogado",        23.0,  2.9,  3.6,  0.4, "almoco")
  -- lanche
  , ("Maçã",                     52.0,  0.3, 14.0,  0.2, "lanche")
  , ("Banana",                   89.0,  1.1, 23.0,  0.3, "lanche")
  , ("Laranja",                  47.0,  0.9, 12.0,  0.1, "lanche")
  , ("Manga",                    60.0,  0.8, 15.0,  0.4, "lanche")
  , ("Morango",                  32.0,  0.7,  7.7,  0.3, "lanche")
  , ("Uva",                      69.0,  0.7, 18.0,  0.2, "lanche")
  , ("Abacate",                 160.0,  2.0,  9.0, 15.0, "lanche")
  , ("Melancia",                 30.0,  0.6,  7.6,  0.2, "lanche")
  , ("Goiaba",                   80.0,  2.6, 15.0,  1.0, "lanche")
  , ("Castanha de caju",        553.0, 18.0, 30.0, 44.0, "lanche")
  , ("Amendoim torrado",        567.0, 26.0, 16.0, 49.0, "lanche")
  , ("Amêndoa",                 579.0, 21.0, 22.0, 50.0, "lanche")
  , ("Nozes",                   654.0, 15.0, 14.0, 65.0, "lanche")
  , ("Iogurte grego",           133.0,  9.0,  4.0, 10.0, "lanche")
  , ("Queijo cottage",           98.0, 11.0,  3.4,  4.3, "lanche")
  , ("Whey protein",            400.0, 80.0,  7.0,  5.0, "lanche")
  , ("Pasta de amendoim",       595.0, 25.0, 18.0, 50.0, "lanche")
  -- jantar
  , ("Omelete",                 154.0, 11.0,  1.1, 12.0, "jantar")
  , ("Tilápia grelhada",         96.0, 20.0,  0.0,  2.0, "jantar")
  , ("Peito de frango grelhado", 159.0, 32.0,  0.0,  3.0, "jantar")
  , ("Salmão grelhado",         208.0, 20.0,  0.0, 13.0, "jantar")
  , ("Atum em lata (água)",     109.0, 24.0,  0.0,  1.0, "jantar")
  , ("Bacalhau cozido",         113.0, 26.0,  0.0,  0.5, "jantar")
  , ("Macarrão integral cozido",174.0,  7.5, 35.0,  1.3, "jantar")
  , ("Quinoa cozida",           120.0,  4.4, 21.3,  1.9, "jantar")
  , ("Arroz integral cozido",   124.0,  2.6, 25.8,  1.0, "jantar")
  , ("Grão-de-bico cozido",     164.0,  9.0, 27.0,  2.6, "jantar")
  , ("Lentilha cozida",         116.0,  9.0, 20.0,  0.4, "jantar")
  , ("Sopa de legumes",          35.0,  1.5,  7.0,  0.3, "jantar")
  ]
