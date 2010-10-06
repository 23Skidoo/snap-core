{-# LANGUAGE TemplateHaskell #-}
module Main where

------------------------------------------------------------------------------
import           Char
import           Data.List
import qualified Data.Text as T
import           System
import           System.Directory
import           System.Console.GetOpt
import           System.FilePath
------------------------------------------------------------------------------

import Snap.StarterTH


------------------------------------------------------------------------------
-- Creates a value tDir :: ([String], [(String, String)])
$(buildData "tDirDefault"   "default")
$(buildData "tDirBareBones" "barebones")


------------------------------------------------------------------------------
usage :: String
usage = unlines
    ["Usage:"
    ,""
    ,"  snap <action>"
    ,""
    ,"    <action> can be one of:"
    ,"      init - create a new project directory structure in the current directory"
    ]


------------------------------------------------------------------------------
data InitFlag = InitBareBones
              | InitHelp
  deriving (Show, Eq)


setup :: String -> ([FilePath], [(String, String)]) -> IO ()
setup projName tDir = do
    mapM createDirectory (fst tDir)
    mapM_ write (snd tDir)
  where
    write (f,c) =
        if isSuffixOf "foo.cabal" f
          then writeFile (projName++".cabal") (insertProjName $ T.pack c)
          else writeFile f c
    isNameChar c = isAlphaNum c || c == '-'
    insertProjName c = T.unpack $ T.replace
                           (T.pack "projname")
                           (T.pack $ filter isNameChar projName) c

------------------------------------------------------------------------------
initProject :: [String] -> IO ()
initProject args = do
    case getOpt Permute options args of
      (flags, _, [])
        | InitHelp `elem` flags -> do putStrLn initUsage
                                      exitFailure
        | otherwise             -> init' (InitBareBones `elem` flags)

      (_, _, errs) -> do putStrLn $ concat errs
                         putStrLn initUsage
                         exitFailure
  where
    initUsage = unlines
        ["Usage:"
        ,""
        ,"  snap init"
        ,""
        ,"    -b  --barebones   Depend only on -core and -server"
        ,"    -h  --help        Print this message"
        ]

    options =
        [ Option ['b'] ["barebones"] (NoArg InitBareBones)
                 "Depend only on -core and -server"
        , Option ['h'] ["help"]      (NoArg InitHelp)
                 "Print this message"
        ]

    init' isBareBones = do
        cur <- getCurrentDirectory
        let dirs = splitDirectories cur
            projName = last dirs
        setup projName (if isBareBones then tDirBareBones else tDirDefault)


------------------------------------------------------------------------------
main :: IO ()
main = do
    args <- getArgs
    case args of
        ("init":args') -> initProject args'
        _              -> do putStrLn usage
                             exitFailure

