
open import Common.Reflection
open import Common.Prelude
open import Common.Equality
open import Common.TC

pattern `el x = el (lit 0) x
pattern `Nat = `el (def (quote Nat) [])
pattern _`→_ a b = `el (pi (vArg a) (abs "_" b))
pattern `Set     = el (lit 1) (sort (lit 0))
pattern `⊥       = `el (def (quote ⊥) [])

pattern `zero  = con (quote zero) []
pattern `suc n = con (quote suc) (vArg n ∷ [])

prDef : FunDef
prDef =
  funDef (`Nat `→ `Nat)
       ( clause [] (extLam ( clause (vArg `zero ∷ []) `zero
                           ∷ clause (vArg (`suc (var "x")) ∷ []) (var 0 [])
                           ∷ []) [])
       ∷ [] )

magicDef : FunDef
magicDef =
  funDef (el (lit 1) (pi (hArg `Set) (abs "A" (`⊥ `→ `el (var 1 [])))))
       ( clause [] (extLam ( absurdClause (vArg absurd ∷ [])
                           ∷ []) [])
       ∷ [] )

unquoteDecl magic = define magic magicDef

checkMagic : {A : Set} → ⊥ → A
checkMagic = magic

unquoteDecl pr = define pr prDef

magic′ : {A : Set} → ⊥ → A
magic′ = unquote (give (extLam (absurdClause (vArg absurd ∷ []) ∷ []) []))

module Pred (A : Set) where
  unquoteDecl pr′ = define pr′ prDef

check : pr 10 ≡ 9
check = refl

check′ : Pred.pr′ ⊥ 10 ≡ 9
check′ = refl
