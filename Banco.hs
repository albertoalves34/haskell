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
