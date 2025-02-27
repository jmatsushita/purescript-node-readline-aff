-- | This module provides an interface in Aff to Node.ReadLine
-- |
-- | Example usage:
-- |
-- | ```
-- | import Node.ReadLine (close) as RL
-- | import Node.ReadLine.Aff (question, setPrompt, prompt, createConsoleInterface, noCompletion)
-- | main :: Effect Unit
-- | main = do
-- |   interface <- createConsoleInterface noCompletion
-- |   runAff_ (either
-- |             (\err -> showError err *> RL.close interface)
-- |             (const $ RL.close interface))
-- |           (loop interface)
-- |   where
-- |     showError err = error (show err)
-- |     loop interface = do
-- |       setPrompt "$ " interface
-- |       dog <- question "What's your dog's name?\n" interface
-- |       liftEff <<< log $ ("Can I pet " <> dog <> "?")
-- |       str <- prompt interface
-- |       case uncons str of
-- |         Just {head: 'y'} -> liftEff $ log "Thanks!"
-- |         _ -> (liftEff $ log "C'mon! Be a sport about it!") *> loop interface
-- | ````
module Node.ReadLine.Aff
  ( close
  , prompt
  , question
  , setPrompt
  , module RLExports
  ) where

import Prelude

import Effect.Aff (makeAff, nonCanceler)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (class MonadEffect, liftEffect)
import Data.Either (Either(..))
import Data.String (length)
import Node.ReadLine (output, completer, terminal, historySize, noCompletion, createInterface, createConsoleInterface, Completer, Interface, InterfaceOptions) as RLExports
import Node.ReadLine as RL

-- | Writes a query to the output and returns the response
question
  :: forall m
   . MonadAff m
  => String
  -> RL.Interface
  -> m String
question q interface = do
  liftAff $ makeAff go
  where
    go handler = RL.question q (handler <<< Right) interface $> nonCanceler

-- | Set the prompt, this is displayed for future `prompt` calls.
setPrompt
  :: forall m
   . MonadEffect m
  => String
  -> RL.Interface
  -> m Unit
setPrompt promptText interface =
  liftEffect $ RL.setPrompt promptText interface

-- | Read a single line from input using the current prompt.
prompt
  :: forall m
   . MonadAff m
  => RL.Interface
  -> m String
prompt interface = do
  liftAff $ makeAff go
  where
    go handler = do
      RL.setLineHandler (handler <<< Right) interface
      RL.prompt interface
      pure nonCanceler

-- | Close the specified Interface. This should upon error, or when you're done reading input.
close
  :: forall m
   . MonadEffect m
  => RL.Interface
  -> m Unit
close interface = liftEffect (RL.close interface)
