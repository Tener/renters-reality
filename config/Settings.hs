{-# LANGUAGE CPP               #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE OverloadedStrings #-}
module Settings
    ( hamletFile
    , cassiusFile
    , juliusFile
    , luciusFile
    , widgetFile
    , approot
    , staticLink
    , setTitle
    , withConnectionPool
    ) where

import Data.Monoid (mempty)
import System.Directory (doesFileExist)
import Language.Haskell.TH.Syntax
import Database.Persist.Postgresql

import qualified Text.Hamlet  as H
import qualified Text.Cassius as H
import qualified Text.Julius  as H
import qualified Text.Lucius  as H

import Data.Text (Text)
import qualified Data.Text as T

import Yesod (MonadControlIO, hamlet, addWidget, addCassius, addJulius, addLucius)
import qualified Yesod as Y

setTitle :: Y.Yesod m => String -> Y.GWidget s m ()
setTitle = Y.setTitle . Y.toHtml . (++) "Renters' reality | "

approot :: Text
approot =
#ifdef PRODUCTION
    "http://rentersreality.com"
#else
    "http://localhost:3000"
#endif

staticLink :: FilePath -> String
staticLink x =
#ifdef PRODUCTION
    "/static/" ++ x
#else
    "http://rentersreality.com/static/" ++ x
#endif

globFile :: String -> String -> FilePath
globFile kind x = kind ++ "/" ++ x ++ "." ++ kind

hamletFile :: FilePath -> Q Exp
hamletFile = H.hamletFile . globFile "hamlet"

cassiusFile :: FilePath -> Q Exp
cassiusFile = 
#ifdef PRODUCTION
  H.cassiusFile . globFile "cassius"
#else
  H.cassiusFileDebug . globFile "cassius"
#endif

luciusFile :: FilePath -> Q Exp
luciusFile = 
#ifdef PRODUCTION
  H.luciusFile . globFile "lucius"
#else
  H.luciusFileDebug . globFile "lucius"
#endif

juliusFile :: FilePath -> Q Exp
juliusFile =
#ifdef PRODUCTION
  H.juliusFile . globFile "julius"
#else
  H.juliusFileDebug . globFile "julius"
#endif

widgetFile :: FilePath -> Q Exp
widgetFile x = do
    let h = unlessExists (globFile "hamlet")  hamletFile
    let c = unlessExists (globFile "cassius") cassiusFile
    let j = unlessExists (globFile "julius")  juliusFile
    let l = unlessExists (globFile "lucius")  luciusFile
    [|addWidget $h >> addCassius $c >> addJulius $j >> addLucius $l|]
  where
    unlessExists tofn f = do
        e <- qRunIO $ doesFileExist $ tofn x
        if e then f x else [|mempty|]

connStr :: Text
connStr = "user=renters password=reality host=localhost port=5432 dbname=renters"

connCount :: Int
connCount = 100

withConnectionPool :: MonadControlIO m => (ConnectionPool -> m a) -> m a
withConnectionPool = withPostgresqlPool connStr connCount
