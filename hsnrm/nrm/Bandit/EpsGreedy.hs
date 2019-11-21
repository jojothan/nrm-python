-- |
-- Module      : Bandit.EpsGreedy
-- Copyright   : (c) 2019, UChicago Argonne, LLC.
-- License     : MIT
-- Maintainer  : fre@freux.fr
--
-- This module implements the fixed rate Epsilon-Greedy MAB algorithm.
module Bandit.EpsGreedy
  ( EpsGreedy (..),
    Weight (..),
    EpsGreedyHyper (..),
    ScreeningGreedy (..),
    ExploreExploitGreedy (..),
    pickreturn,
    pickAction,
    updateAvgLoss,
  )
where

import Bandit.Class
import Bandit.Util
import Protolude
import System.Random

-- | The EpsGreedy state
data EpsGreedy a
  = -- | Still screening for initial estimates
    Screening (ScreeningGreedy a)
  | -- | The sampling procedure has started.
    ExploreExploit (ExploreExploitGreedy a)

data ScreeningGreedy a
  = ScreeningGreedy
      { tScreening :: Int,
        epsScreening :: Double,
        screening :: a,
        screened :: [(Double, a)],
        screenQueue :: [a]
      }

data ExploreExploitGreedy a
  = ExploreExploitGreedy
      { t :: Int,
        eps :: Double,
        lastAction :: a,
        k :: Int,
        weights :: NonEmpty (Weight a)
      }

-- | The information maintaining structure for one action.
data Weight a
  = Weight
      { averageLoss :: Double,
        hits :: Int,
        action :: a
      }
  deriving (Generic)

-- | The epsilon-greedy hyperparameter.
data EpsGreedyHyper a
  = EpsGreedyHyper
      { epsilon :: Double,
        arms :: Arms a
      }

-- The fixed rate Epsilon-Greedy MAB algorithm.
-- Offers no interesting guarantees, works well in practice.
instance (Eq a) => Bandit (EpsGreedy a) (EpsGreedyHyper a) a Double where

  init g (EpsGreedyHyper e (Arms (a :| as))) =
    ( Screening $ ScreeningGreedy
        { tScreening = 1,
          epsScreening = e,
          screening = a,
          screened = [],
          screenQueue = as
        },
      a,
      g
    )

  step g l =
    get >>= \case
      Screening sg ->
        case screenQueue sg of
          (a : as) -> do
            put $ Screening $
              sg
                { tScreening = tScreening sg + 1,
                  screening = a,
                  screened = (l, screening sg) : screened sg,
                  screenQueue = as
                }
            return (a, g)
          [] -> do
            let eeg = ExploreExploitGreedy
                  { t = tScreening sg + 1,
                    eps = epsScreening sg,
                    lastAction = screening sg,
                    k = length (screened sg) + 1,
                    weights = toW <$> ((l, screening sg) :| screened sg)
                  }
            pickreturn eeg g
            where
              toW :: forall a. (Double, a) -> Weight a
              toW (loss, action) = Weight loss 1 action
      ExploreExploit s -> do
        let eeg =
              s
                { t = t s + 1,
                  weights = weights s <&> \w ->
                    if action w == lastAction s
                      then updateAvgLoss l w
                      else w
                }
        pickreturn eeg g

-- | Action selection and  return
pickreturn ::
  (RandomGen g, MonadState (EpsGreedy b) m) =>
  ExploreExploitGreedy b ->
  g ->
  m (b, g)
pickreturn eeg g = do
  let (a, g') = pickAction eeg g
  put $ ExploreExploit $ eeg {lastAction = a}
  return (a, g')

-- | Action selection primitive
pickAction :: (RandomGen g) => ExploreExploitGreedy a -> g -> (a, g)
pickAction ExploreExploitGreedy {..} =
  sampleWL (toList $ weights <&> w2tuple)
  where
    w2tuple :: Weight b -> (Double, b)
    w2tuple (Weight avgloss _hits action) = (avgloss, action)

-- | This is a rudimentary online mean accumulator. Its numerical properties
-- are probably bad, but we don't need much more here.
updateAvgLoss :: Double -> Weight a -> Weight a
updateAvgLoss l (Weight avgloss hits action) =
  Weight
    ( (avgloss * fromIntegral hits + l)
        / (fromIntegral hits + 1)
    )
    (hits + 1)
    action
