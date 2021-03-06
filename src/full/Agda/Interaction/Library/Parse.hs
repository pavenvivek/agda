-- | Parser for @.agda-lib@ files.
--
--   Example file:
--
--   @
--     name: Main
--     depend:
--       standard-library
--     include: .
--       src more-src
--   @
--
--   Should parse as:
--
--   @
--     AgdaLib
--       { libName     = "Main"
--       , libFile     = path_to_this_file
--       , libIncludes = [ "." , "src" , "more-src" ]
--       , libDepends  = [ "standard-library" ]
--       }
--   @
--
module Agda.Interaction.Library.Parse ( parseLibFile, splitCommas, trimLineComment, LineNumber ) where

import Control.Applicative
import Control.Exception
import Control.Monad
import Data.Char
import qualified Data.List as List
import System.FilePath

import Agda.Interaction.Library.Base

import Agda.Utils.Except ( MonadError(throwError) )
import Agda.Utils.IO ( catchIO )
import Agda.Utils.String ( ltrim )

-- | Parser monad: Can throw @String@ error messages.
--
type P = Either String

-- | The config files we parse have the generic structure of a sequence
--   of @field : content@ entries.
type GenericFile = [GenericEntry]

data GenericEntry = GenericEntry
  { geHeader  :: String   -- ^ E.g. field name.    @trim@med.
  , geContent :: [String] -- ^ E.g. field content. @trim@med.
  }

-- | Library file field format format [sic!].
data Field = forall a. Field
  { fName     :: String                           -- ^ Name of the field.
  , fOptional :: Bool                             -- ^ Is it optional?
  , fParse    :: [String] -> P a                  -- ^ Content parser for this field.
  , fSet      :: a -> AgdaLibFile -> AgdaLibFile  -- ^ Sets parsed content in 'AgdaLibFile' structure.
  }

-- | @.agda-lib@ file format with parsers and setters.
agdaLibFields :: [Field]
agdaLibFields =
  -- Andreas, 2017-08-23, issue #2708, field "name" is optional.
  [ Field "name"    True  parseName                      $ \ name l -> l { libName     = name }
  , Field "include" True  (pure . concatMap words)       $ \ inc  l -> l { libIncludes = inc }
  , Field "depend"  True  (pure . concatMap splitCommas) $ \ ds   l -> l { libDepends  = ds }
  ]
  where
    parseName [s] | [name] <- words s = pure name
    parseName ls = throwError $ "Bad library name: '" ++ unwords ls ++ "'"

-- | Parse @.agda-lib@ file.
--
--   Sets 'libFile' name and turn mentioned include directories into absolute pathes
--   (provided the given 'FilePath' is absolute).
--
parseLibFile :: FilePath -> IO (P AgdaLibFile)
parseLibFile file =
  (fmap setPath . parseLib <$> readFile file) `catchIO` \e ->
    return (Left $ "Failed to read library file " ++ file ++ ".\nReason: " ++ show e)
  where
    setPath lib = unrelativise (takeDirectory file) lib{ libFile = file }
    unrelativise dir lib = lib { libIncludes = map (dir </>) (libIncludes lib) }

-- | Parse file contents.
parseLib :: String -> P AgdaLibFile
parseLib s = fromGeneric =<< parseGeneric s

-- | Parse 'GenericFile' with 'agdaLibFields' descriptors.
fromGeneric :: GenericFile -> P AgdaLibFile
fromGeneric = fromGeneric' agdaLibFields

-- | Given a list of 'Field' descriptors (with their custom parsers),
--   parse a 'GenericFile' into the 'AgdaLibFile' structure.
--
--   Checks mandatory fields are present; no duplicate fields, no unknown fields.
fromGeneric' :: [Field] -> GenericFile -> P AgdaLibFile
fromGeneric' fields fs = do
  checkFields fields (map geHeader fs)
  foldM upd emptyLibFile fs
  where
    upd :: AgdaLibFile -> GenericEntry -> P AgdaLibFile
    upd l (GenericEntry h cs) = do
      Field{..} <- findField h fields
      x         <- fParse cs
      return $ fSet x l

-- | Ensure that there are no duplicate fields and no mandatory fields are missing.
checkFields :: [Field] -> [String] -> P ()
checkFields fields fs = do
  let mandatory = [ fName f | f <- fields, not $ fOptional f ]
      -- Missing fields.
      missing   = mandatory List.\\ fs
      -- Duplicate fields.
      dup       = fs List.\\ List.nub fs
      -- Plural s for error message.
      s xs      = if length xs > 1 then "s" else ""
      list xs   = List.intercalate ", " [ "'" ++ f ++ "'" | f <- xs ]
  when (not $ null missing) $ throwError $ "Missing field" ++ s missing ++ " " ++ list missing
  when (not $ null dup)     $ throwError $ "Duplicate field" ++ s dup ++ " " ++ list dup

-- | Find 'Field' with given 'fName', throw error if unknown.
findField :: String -> [Field] -> P Field
findField s fs = maybe err return $ List.find ((s ==) . fName) fs
  where err = throwError $ "Unknown field '" ++ s ++ "'"

-- Generic file parser ----------------------------------------------------

-- | Example:
--
-- @
--     parseGeneric "name:Main--BLA\ndepend:--BLA\n  standard-library--BLA\ninclude : . --BLA\n  src more-src   \n"
--     == Right [("name",["Main"]),("depend",["standard-library"]),("include",[".","src more-src"])]
-- @
parseGeneric :: String -> P GenericFile
parseGeneric s =
  groupLines =<< concat <$> mapM (uncurry parseLine) (zip [1..] $ map stripComments $ lines s)

type LineNumber = Int

-- | Lines with line numbers.
data GenericLine
  = Header  LineNumber String
      -- ^ Header line, like a field name, e.g. "include :".  Cannot be indented.
      --   @String@ is 'trim'med.
  | Content LineNumber String
      -- ^ Other line.  Must be indented.
      --   @String@ is 'trim'med.
  deriving (Show)

-- | Parse line into 'Header' and 'Content' components.
--
--   Precondition: line comments and trailing whitespace have been stripped away.
--
--   Example file:
--
--   @
--     name: Main
--     depend:
--       standard-library
--     include: .
--       src more-src
--   @
--
--   This should give
--
--   @
--     [ Header  1 "name"
--     , Content 1 "Main"
--     , Header  2 "depend"
--     , Content 3 "standard-library"
--     , Header  4 "include"
--     , Content 4 "."
--     , Content 5 "src more-src"
--     ]
--   @
parseLine :: LineNumber -> String -> P [GenericLine]
parseLine _ "" = pure []
parseLine l s@(c:_)
    -- Indented lines are 'Content'.
  | isSpace c   = pure [Content l $ ltrim s]
    -- Non-indented lines are 'Header'.
  | otherwise   =
    case break (==':') s of
      -- Headers are single words followed by a colon.
      -- Anything after the colon that is not whitespace is 'Content'.
      (h, ':' : r) ->
        case words h of
          [h] -> pure $ [Header l h] ++ [Content l r' | let r' = ltrim r, not (null r')]
          []  -> throwError $ show l ++ ": Missing field name"
          hs  -> throwError $ show l ++ ": Bad field name " ++ show h
      _ -> throwError $ show l ++ ": Missing ':' for field " ++ show (ltrim s)

-- | Collect 'Header' and subsequent 'Content's into 'GenericEntry'.
--
--   Tailing 'Content's?  That's an error.
--
groupLines :: [GenericLine] -> P GenericFile
groupLines [] = pure []
groupLines (Content l c : _) = throwError $ show l ++ ": Missing field"
groupLines (Header _ h : ls) = (GenericEntry h [ c | Content _ c <- cs ] :) <$> groupLines ls1
  where
    (cs, ls1) = span isContent ls
    isContent Content{} = True
    isContent Header{} = False

-- | Remove leading whitespace and line comment.
trimLineComment :: String -> String
trimLineComment = stripComments . ltrim

-- | Break a comma-separated string.  Result strings are @trim@med.
splitCommas :: String -> [String]
splitCommas s = words $ map (\c -> if c == ',' then ' ' else c) s

-- | ...and trailing, but not leading, whitespace.
stripComments :: String -> String
stripComments "" = ""
stripComments ('-':'-':_) = ""
stripComments (c : s)     = cons c (stripComments s)
  where
    cons c "" | isSpace c = ""
    cons c s = c : s
