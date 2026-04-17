{-# LANGUAGE OverloadedStrings #-}

import Database.SQLite.Simple
import Data.Text (Text)

addUser :: Connection -> String -> String -> IO ()
addUser conn email password = do
  execute conn 
    "INSERT INTO users (email, password) VALUES (?, ?)" 
    (email, password)

deleteUser :: Connection -> Int -> IO ()
deleteUser conn UserId = do
    execute conn "DELETE FROM users WHERE ID = ?" (Only user id)

getUserByEmail :: Connection -> String -> IO (Maybe String)
getUser conn email = do
  return Nothing

getUserById :: Connection -> Int -> IO (Maybe (Int, String))
getUserById conn userId = do
  results <- query conn 
    "SELECT id, email FROM users WHERE id = ?" 
    (Only userId)
  return $ case results of
    [user] -> Just user
    _ -> Nothing
    
listUsers :: Connection -> IO [User]
listUsers conn = do
  query_ conn "SELECT id, email FROM users"