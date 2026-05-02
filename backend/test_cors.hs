{-# LANGUAGE OverloadedStrings #-}
import Network.Wai.Middleware.Cors
d = simpleCorsResourcePolicy { corsRequestHeaders = ["Content-Type"] }
main = print "ok"
