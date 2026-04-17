{-# LANGUAGE OverloadedStrings #-}

import Web.Scotty (get, scotty, text)

main :: IO ()
main =
  scotty 3000 $ do
    get "/healthz" $ text "ok"
    get "/" $ text "demo-scotty-sqlite running"
