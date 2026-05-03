import Test.HUnit
import Testes

main :: IO ()
main = do
  _ <- runTestTT suiteTestes
  return ()
