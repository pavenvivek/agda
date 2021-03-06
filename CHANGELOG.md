Release notes for Agda version 2.5.4
====================================

Syntax and LaTeX backend
------------------------

* The `code` environment can now take arguments [Issues
  [#2744](https://github.com/agda/agda/issues/2744) and
  [#2453](https://github.com/agda/agda/issues/2453)].

  Everything from \begin{code} to the end of the line is preserved in
  the generated LaTeX code, and not treated as Agda code.

  The default implementation of the `code` environment recognises one
  optional argument, `hide`, which can be used for code that should be
  type-checked, but not typeset:
  ```latex
  \begin{code}[hide]
    open import Module
  \end{code}
  ```

  The `AgdaHide` macro has not been removed, but has been deprecated
  in favour of `[hide]`.

* The `AgdaSuppressSpace` and `AgdaMultiCode` environments no longer
  take an argument.

  Instead some documents need to be compiled multiple times.

* The `--count-clusters` flag can now be given in `OPTIONS` pragmas.

Language
--------

### Syntax

* Infix let declarations. [Issue [#917](https://github.com/agda/agda/issues/917)]

  Let declarations can now be defined in infix (or mixfix) style. For instance:
  ```agda
    f : Nat → Nat
    f n = let _!_ : Nat → Nat → Nat
              x ! y = 2 * x + y
          in n ! n
  ```


Release notes for Agda version 2.5.3
====================================

Installation and infrastructure
-------------------------------

* Added support for GHC 8.0.2 and 8.2.1.

* Removed support for GHC 7.6.3.

* Markdown support for literate Agda
  \[PR [#2357](https://github.com/agda/agda/pull/2357)].

  Files ending in `.lagda.md` will be parsed as literate Markdown files.

  + Code blocks start with  ```` ``` ```` or ```` ```agda ```` in its own line, and end with
    ```` ``` ````, also in its own line.
  + Code blocks which should be type-checked by Agda but should not be visible
    when the Markdown is rendered may be enclosed in HTML comment delimiters
    (`<!--`  and `-->`).
  + Code blocks which should be ignored by Agda, but rendered in the final
    document may be indented by four spaces.
  + Note that inline code fragments are not supported due to the difficulty of
    interpreting their indentation level with respect to the rest of the file.

Language
--------

### Pattern matching

* Dot patterns.

  The dot in front of an inaccessible pattern can now be skipped if the
  pattern consists entirely of constructors or literals. For example:
  ```agda
    open import Agda.Builtin.Bool

    data D : Bool → Set where
      c : D true

    f : (x : Bool) → D x → Bool
    f true c = true

  ```
  Before this change, you had to write `f .true c = true`.

* With-clause patterns can be replaced by _
  [Issue [#2363](https://github.com/agda/agda/issues/2363)].
  Example:
  ```agda
    test : Nat → Set
    test zero    with zero
    test _       | _ = Nat
    test (suc x) with zero
    test _       | _ = Nat
  ```
  We do not have to spell out the pattern of the parent clause
  (`zero` / `suc x`) in the with-clause if we do not need the
  pattern variables.  Note that `x` is not in scope in the
  with-clause!

  A more elaborate example, which cannot be reduced to
  an ellipsis `...`:
  ```agda
    record R : Set where
      coinductive -- disallow matching
      field f : Bool
            n : Nat

    data P (r : R) : Nat → Set where
      fTrue  : R.f r ≡ true → P r zero
      nSuc   : P r (suc (R.n r))

    data Q : (b : Bool) (n : Nat) →  Set where
      true! : Q true zero
      suc!  : ∀{b n} → Q b (suc n)

    test : (r : R) {n : Nat} (p : P r n) → Q (R.f r) n
    test r nSuc       = suc!
    test r (fTrue p)  with R.f r
    test _ (fTrue ()) | false
    test _ _          | true = true!  -- underscore instead of (isTrue _)
  ```

* Pattern matching lambdas (also known as extended lambdas) can now be
  nullary, mirroring the behaviour for ordinary function definitions.
  [Issue [#2671](https://github.com/agda/agda/issues/2671)]

  This is useful for case splitting on the result inside an
  expression: given
  ```agda
  record _×_ (A B : Set) : Set where
    field
      π₁ : A
      π₂ : B
  open _×_
  ```
  one may case split on the result (C-c C-c RET) in a hole
  ```agda
    λ { → {!!}}
  ```
  of type A × B to produce
  ```agda
    λ { .π₁ → {!!} ; .π₂ → {!!}}
  ```

* Records with a field of an empty type are now recognized as empty by Agda.
  In particular, they can be matched against with an absurd pattern ().
  For example:
  ```agda
    data ⊥ : Set where

    record Empty : Set where
      field absurdity : ⊥

    magic : Empty → ⊥
    magic ()
  ```

* Injective pragmas.

  Injective pragmas can be used to mark a definition as injective for the
  pattern matching unifier. This can be used as a version of
  `--injective-type-constructors` that only applies to specific datatypes.
  For example:
  ```agda
    open import Agda.Builtin.Equality
    data Fin : Nat → Set where
      zero : {n : Nat} → Fin (suc n)
      suc  : {n : Nat} → Fin n → Fin (suc n)

    {-# INJECTIVE Fin #-}

    Fin-injective : {m n : Nat} → Fin m ≡ Fin n → m ≡ n
    Fin-injective refl = refl
  ```
  Aside from datatypes, this pragma can also be used to mark other definitions
  as being injective (for example postulates).

* Metavariables can no longer be instantiated during case splitting. This means
  Agda will refuse to split instead of taking the first constructor it finds.
  For example:
  ```agda
    open import Agda.Builtin.Nat

    data Vec (A : Set) : Nat → Set where
      nil : Vec A 0
      cons : {n : Nat} → A → Vec A n → Vec A (suc n)

    foo : Vec Nat _ → Nat
    foo x = {!x!}
  ```
  In Agda 2.5.2, case splitting on `x` produced the single clause
  `foo nil = {!!}`, but now Agda refuses to split.

### Reflection

* New TC primitive: `debugPrint`.

  ```agda
    debugPrint : String → Nat → List ErrorPart → TC ⊤
  ```

  This maps to the internal function `reportSDoc`. Debug output is enabled with
  the `-v` flag at the command line, or in an `OPTIONS` pragma. For instance,
  giving `-v a.b.c:10` enables printing from `debugPrint "a.b.c.d" 10 msg`. In the
  Emacs mode, debug output ends up in the `*Agda debug*` buffer.

### Built-ins

* BUILTIN REFL is now superfluous, subsumed by BUILTIN EQUALITY
  [Issue [#2389](https://github.com/agda/agda/issues/2389)].

* BUILTIN EQUALITY is now more liberal
  [Issue [#2386](https://github.com/agda/agda/issues/2386)].
  It accepts, among others, the following new definitions of equality:
  ```agda
    -- Non-universe polymorphic:
    data _≡_ {A : Set} (x : A) : A → Set where
      refl : x ≡ x

    -- ... with explicit argument to refl;
    data _≡_ {A : Set} : (x y : A) → Set where
      refl : {x : A} → x ≡ x

    -- ... even visible
    data _≡_ {A : Set} : (x y : A) → Set where
      refl : (x : A) → x ≡ x

    -- Equality in a different universe than domain:
    -- (also with explicit argument to refl)
    data _≡_ {a} {A : Set a} (x : A) : A → Set where
      refl : x ≡ x

  ```
  The standard definition is still:
  ```agda
    -- Equality in same universe as domain:
    data _≡_ {a} {A : Set a} (x : A) : A → Set a where
      refl : x ≡ x
  ```

### Miscellaneous

* Rule change for omitted top-level module headers.
  [Issue [#1077](https://github.com/agda/agda/issues/1077)]

  If your file is named `Bla.agda`, then the following content
  is rejected.
  ```agda
    foo = Set
    module Bla where
      bar = Set
  ```
  Before the fix of this issue, Agda would add the missing module
  header `module Bla where` at the top of the file.
  However, in this particular case it is more likely the user
  put the declaration `foo = Set` before the module start in error.
  Now you get the error
  ```
    Illegal declaration(s) before top-level module
  ```
  if the following conditions are met:

    1. There is at least one non-import declaration or non-toplevel pragma
       before the start of the first module.

    2. The module has the same name as the file.

    3. The module is the only module at this level
       (may have submodules, of course).

  If you should see this error, insert a top-level module
  before the illegal declarations, or move them inside the
  existing module.

Emacs mode
----------

* New warnings:

  - Unreachable clauses give rise to a simple warning. They are
    highlighted in gray.

  - Incomplete patterns are non-fatal warnings: it is possible
    to keep interacting with the file (the reduction will simply
    be stuck on arguments not matching any pattern).
    The definition with incomplete patterns are highlighted in
    wheat.

* Clauses which do not hold definitionally are now highlighted in white smoke.

* Fewer commands have the side effect that the buffer is saved.

* Aborting commands.

  Now one can (try to) abort an Agda command by using `C-c C-x C-a` or
  a menu entry. The effect is similar to that of restarting Agda (`C-c
  C-x C-r`), but some state is preserved, which could mean that it
  takes less time to reload the module.

  Warning: If a command is aborted while it is writing data to disk
  (for instance .agdai files or Haskell files generated by the GHC
  backend), then the resulting files may be corrupted. Note also that
  external commands (like GHC) are not aborted, and their output may
  continue to be sent to the Emacs mode.

* New bindings for the Agda input method:

  - All the bold digits are now available. The naming scheme is `\Bx` for digit `x`.

  - Typing `\:` you can now get a whole slew of colons.

    (The Agda input method originally only bound the standard unicode colon,
    which looks deceptively like the normal colon.)

* Case splitting now preserves underscores.
  [Issue [#819](https://github.com/agda/agda/issues/819)]
  ```agda
    data ⊥ : Set where

    test : {A B : Set} → A → ⊥ → B
    test _ x = {! x !}
  ```
  Splitting on `x` yields
  ```agda
    test _ ()
  ```

* Interactively expanding ellipsis.
  [Issue [#2589](https://github.com/agda/agda/issues/2589)]
  An ellipsis in a with-clause can be expanded by splitting on "variable" "." (dot).
  ```agda
    test0 : Nat → Nat
    test0 x with zero
    ... | q = {! . !}  -- C-c C-c
  ```
  Splitting on dot here yields:
  ```agda
    test0 x | q = ?
  ```

* New command to check an expression against the type of the hole
  it is in and see what it elaborates to.
  [Issue [#2700](https://github.com/agda/agda/issues/2700)]
  This is useful to determine e.g. what solution typeclass resolution yields.
  The command is bound to `C-c C-;` and respects the `C-u` modifier.

  ```agda
    record Pointed (A : Set) : Set where
      field point : A

    it : ∀ {A : Set} {{x : A}} → A
    it {{x}} = x

    instance _ = record { point = 3 - 4 }

    _ : Pointed Nat
    _ = {! it !} -- C-u C-u C-c C-;
  ```
  yields
  ```agda
    Goal: Pointed Nat
    Elaborates to: record { point = 0 }
  ```

* If `agda2-give` is called with a prefix, then giving is forced,
  i.e., the safety checks are skipped,
  including positivity, termination, and double type-checking.
  [Issue [#2730](https://github.com/agda/agda/issues/2730)]

  Invoke forced giving with key sequence `C-u C-c C-SPC`.


Library management
------------------

* The `name` field in an `.agda-lib` file is now optional.
  [Issue [#2708](https://github.com/agda/agda/issues/2708)]

  This feature is convenient if you just want to specify the dependencies
  and include pathes for your local project in an `.agda-lib` file.

  Naturally, libraries without names cannot be depended on.


Compiler backends
-----------------

* Unified compiler pragmas

  The compiler pragmas (`COMPILED`, `COMPILED_DATA`, etc.) have been unified across
  backends into two new pragmas:

  ```
    {-# COMPILE <Backend> <Name> <Text> #-}
    {-# FOREIGN <Backend> <Text> #-}
  ```

  The old pragmas still work, but will emit a warning if used. They will be
  removed completely in Agda 2.6.

  The translation of old pragmas into new ones is as follows:

  Old | New
  --- | ---
  `{-# COMPILED f e #-}` | `{-# COMPILE GHC f = e #-}`
  `{-# COMPILED_TYPE A T #-}` | `{-# COMPILE GHC A = type T #-}`
  `{-# COMPILED_DATA A D C1 .. CN #-}` | `{-# COMPILE GHC A = data D (C1 \| .. \| CN) #-}`
  `{-# COMPILED_DECLARE_DATA #-}` | obsolete, removed
  `{-# COMPILED_EXPORT f g #-}` | `{-# COMPILE GHC f as g #-}`
  `{-# IMPORT M #-}` | `{-# FOREIGN GHC import qualified M #-}`
  `{-# HASKELL code #-}` | `{-# FOREIGN GHC code #-}`
  `{-# COMPILED_UHC f e #-}` | `{-# COMPILE UHC f = e #-}`
  `{-# COMPILED_DATA_UHC A D C1 .. CN #-}` | `{-# COMPILE UHC A = data D (C1 \| .. \| CN) #-}`
  `{-# IMPORT_UHC M #-}` | `{-# FOREIGN UHC __IMPORT__ M #-}`
  `{-# COMPILED_JS f e #-}` | `{-# COMPILE JS f = e #-}`

* GHC Haskell backend

  The COMPILED pragma (and the corresponding COMPILE GHC pragma) is now also
  allowed for functions. This makes it possible to have both an Agda
  implementation and a native Haskell runtime implementation.

  The GHC file header pragmas `LANGUAGE`, `OPTIONS_GHC`, and `INCLUDE`
  inside a `FOREIGN GHC` pragma are recognized and printed correctly
  at the top of the generated Haskell file.
  [Issue [#2712](https://github.com/agda/agda/issues/2712)]


* UHC compiler backend

  The UHC backend has been moved to its own repository
  [https://github.com/agda/agda-uhc] and is no longer part of the Agda
  distribution.

* Haskell imports are no longer transitively inherited from imported modules.

  The (now deprecated) IMPORT and IMPORT_UHC pragmas no longer cause import
  statements in modules importing the module containing the pragma.

  The same is true for the corresponding FOREIGN pragmas.

* Support for stand-alone backends.

  There is a new API in `Agda.Compiler.Backend` for creating stand-alone
  backends using Agda as a library. This allows prospective backend writers to
  experiment with new backends without having to change the Agda code base.

HTML backend
------------

* Anchors for identifiers (excluding bound variables) are now the
  identifiers themselves rather than just the file position
  [Issue [#2604](https://github.com/agda/agda/issues/2604)].

  Symbolic anchors look like
  ```html
  <a id="test1">
  <a id="M.bla">
  ```
  while other anchors just give the character position in the file:
  ```html
  <a id="42">
  ```

  Top-level module names do not get a symbolic anchor, since the position of
  a top-level module is defined to be the beginning of the file.

  Example:

  ```agda
  module Issue2604 where   -- Character position anchor

  test1 : Set₁             -- Issue2604.html#test1
  test1 = bla
    where
    bla = Set              -- Character position anchor

  test2 : Set₁             -- Issue2604.html#test2
  test2 = bla
    where
    bla = Set              -- Character position anchor

  test3 : Set₁             -- Issue2604.html#test3
  test3 = bla
    module M where         -- Issue2604.html#M
    bla = Set              -- Issue2604.html#M.bla

  module NamedModule where -- Issue2604.html#NamedModule
    test4 : Set₁           -- Issue2604.html#NamedModule.test4
    test4 = M.bla

  module _ where           -- Character position anchor
    test5 : Set₁           -- Character position anchor
    test5 = M.bla
  ```

* Some generated HTML files now have different file names [Issue
  [#2725](https://github.com/agda/agda/issues/2725)].

  Agda now uses an encoding that amounts to first converting the
  module names to UTF-8, and then percent-encoding the resulting
  bytes. For instance, HTML for the module `Σ` is placed in
  `%CE%A3.html`.

LaTeX backend
-------------

* The LaTeX backend now handles indentation in a different way [Issue
  [#1832](https://github.com/agda/agda/issues/1832)].

  A constraint on the indentation of the first token *t* on a line is
  determined as follows:
  * Let *T* be the set containing every previous token (in any code
    block) that is either the initial token on its line or preceded by
    at least one whitespace character.
  * Let *S* be the set containing all tokens in *T* that are not
    *shadowed* by other tokens in *T*. A token *t₁* is shadowed by
    *t₂* if *t₂* is further down than *t₁* and does not start to the
    right of *t₁*.
  * Let *L* be the set containing all tokens in *S* that start to the
    left of *t*, and *E* be the set containing all tokens in *S* that
    start in the same column as *t*.
  * The constraint is that *t* must be indented further than every
    token in *L*, and aligned with every token in *E*.

  Note that if any token in *L* or *E* belongs to a previous code
  block, then the constraint may not be satisfied unless (say) the
  `AgdaAlign` environment is used in an appropriate way.

  If custom settings are used, for instance if `\AgdaIndent` is
  redefined, then the constraint discussed above may not be satisfied.
  (Note that the meaning of the `\AgdaIndent` command's argument has
  changed, and that the command is now used in a different way in the
  generated LaTeX files.)

  Examples:
  * Here `C` is indented further than `B`:

    ```agda
    postulate
      A  B
          C : Set
    ```

  * Here `C` is not (necessarily) indented further than `B`, because
    `X` shadows `B`:

    ```agda
    postulate
      A  B  : Set
      X
          C : Set
    ```

  The new rule is inspired by, but not identical to, the one used by
  lhs2TeX's poly mode (see Section 8.4 of the [manual for lhs2TeX
  version 1.17](https://www.andres-loeh.de/lhs2tex/Guide2-1.17.pdf)).

* Some spacing issues
  [[#2353](https://github.com/agda/agda/issues/2353),
  [#2441](https://github.com/agda/agda/issues/2441),
  [#2733](https://github.com/agda/agda/issues/2733),
  [#2740](https://github.com/agda/agda/issues/2740)] have been fixed.

* The user can now control the typesetting of (certain) individual tokens
  by redefining the `\AgdaFormat` command. Example:
  ```latex
  \usepackage{ifthen}

  % Insert extra space before some tokens.
  \DeclareRobustCommand{\AgdaFormat}[2]{%
    \ifthenelse{
      \equal{#1}{≡⟨} \OR
      \equal{#1}{≡⟨⟩} \OR
      \equal{#1}{∎}
    }{\ }{}#2}
  ```
  Note the use of `\DeclareRobustCommand`. The first argument to
  `\AgdaFormat` is the token, and the second argument the thing to
  be typeset.

* One can now instruct the agda package not to select any fonts.

  If the `nofontsetup` option is used, then some font packages are
  loaded, but specific fonts are not selected:
  ```latex
  \usepackage[nofontsetup]{agda}
  ```

* The height of empty lines is now configurable
  [[#2734](https://github.com/agda/agda/issues/2734)].

  The height is controlled by the length `\AgdaEmptySkip`, which by
  default is `\baselineskip`.

* The alignment feature regards the string `+̲`, containing `+` and a
  combining character, as having length two. However, it seems more
  reasonable to treat it as having length one, as it occupies a single
  column, if displayed "properly" using a monospace font. The new flag
  `--count-clusters` is an attempt at fixing this. When this flag is
  enabled the backend counts ["extended grapheme
  clusters"](http://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries)
  rather than code points.

  Note that this fix is not perfect: a single extended grapheme
  cluster might be displayed in different ways by different programs,
  and might, in some cases, occupy more than one column. Here are some
  examples of extended grapheme clusters, all of which are treated as
  a single character by the alignment algorithm:
  ```
  │ │
  │+̲│
  │Ö̂│
  │நி│
  │ᄀힰᇹ│
  │ᄀᄀᄀᄀᄀᄀힰᇹᇹᇹᇹᇹᇹ│
  │ │
  ```

  Note also that the layout machinery does not count extended grapheme
  clusters, but code points. The following code is syntactically
  correct, but if `--count-clusters` is used, then the LaTeX backend
  does not align the two `field` keywords:
  ```agda
    record +̲ : Set₁ where  field A : Set
                            field B : Set
  ```

  The `--count-clusters` flag is not enabled in all builds of Agda,
  because the implementation depends on the
  [ICU](http://site.icu-project.org) library, the installation of
  which could cause extra trouble for some users. The presence of this
  flag is controlled by the Cabal flag `enable-cluster-counting`.

* A faster variant of the LaTeX backend: QuickLaTeX.

  When this variant of the backend is used the top-level module is not
  type-checked, only scope-checked. This implies that some
  highlighting information is not available. For instance, overloaded
  constructors are not resolved.

  QuickLaTeX can be invoked from the Emacs mode, or using `agda
  --latex --only-scope-checking`. If the module has already been
  type-checked successfully, then this information is reused; in this
  case QuickLaTeX behaves like the regular LaTeX backend.

  The `--only-scope-checking` flag can also be used independently, but
  it is perhaps unclear what purpose that would serve. (The flag can
  currently not be combined with `--html`, `--dependency-graph` or
  `--vim`.) The flag is not allowed in safe mode.

Pragmas and options
-------------------

* The `--safe` option is now a valid pragma.

  This makes it possible to declare a module as being part of the safe
  subset of the language by stating `{-# OPTIONS --safe #-}` at the top
  of the corresponding file. Incompatibilities between the `--safe` option
  and other options or language constructs are non-fatal errors.

* The `--no-main` option is now a valid pragma.

  One can now suppress the compiler warning about a missing main function by
  putting
  ```agda
    {-# OPTIONS --no-main #-}
  ```
  on top of the file.

* New command-line option and pragma `--warning=MODE` (or `-W MODE`) for
  setting the warning mode. Current options are
  - `warn` for displaying warnings (default)
  - `error` for turning warnings into errors
  - `ignore` for not displaying warnings

List of fixed issues
--------------------

For 2.5.3, the following issues have been fixed
(see [bug tracker](https://github.com/agda/agda/issues)):

  - [#142](https://github.com/agda/agda/issues/142): Inherited dot patterns in with functions are not checked
  - [#623](https://github.com/agda/agda/issues/623): Error message points to importing module rather than imported module
  - [#657](https://github.com/agda/agda/issues/657): Yet another display form problem
  - [#668](https://github.com/agda/agda/issues/668): Ability to stop, or restart, typechecking somehow
  - [#705](https://github.com/agda/agda/issues/705): confusing error message for ambiguous datatype module name
  - [#719](https://github.com/agda/agda/issues/719): Error message for duplicate module definition points to external module instead of internal module
  - [#776](https://github.com/agda/agda/issues/776): Unsolvable constraints should give error
  - [#819](https://github.com/agda/agda/issues/819): Case-splitting doesn't preserve underscores
  - [#883](https://github.com/agda/agda/issues/883): Rewrite loses type information
  - [#899](https://github.com/agda/agda/issues/899): Instance search fails if there are several definitionally equal values in scope
  - [#1077](https://github.com/agda/agda/issues/1077): problem with module syntax, with parametric module import
  - [#1126](https://github.com/agda/agda/issues/1126): Port optimizations from the Epic backend
  - [#1175](https://github.com/agda/agda/issues/1175): Internal Error in Auto
  - [#1544](https://github.com/agda/agda/issues/1544): Positivity polymorphism needed for compositional positivity analysis
  - [#1611](https://github.com/agda/agda/issues/1611): Interactive splitting instantiates meta
  - [#1664](https://github.com/agda/agda/issues/1664): Add Reflection primitives to expose precedence and fixity
  - [#1817](https://github.com/agda/agda/issues/1817): Solvable size constraints reported as unsolvable
  - [#1832](https://github.com/agda/agda/issues/1832): Insufficient indentation in LaTeX-rendered Agda code
  - [#1834](https://github.com/agda/agda/issues/1834): Copattern matching: order of clauses should not matter here
  - [#1886](https://github.com/agda/agda/issues/1886): Second copies of telescopes not checked?
  - [#1899](https://github.com/agda/agda/issues/1899): Positivity checker does not treat datatypes and record types in the same way
  - [#1975](https://github.com/agda/agda/issues/1975): Type-incorrect instantiated overloaded constructor accepted in pattern
  - [#1976](https://github.com/agda/agda/issues/1976): Type-incorrect instantiated projection accepted in pattern
  - [#2035](https://github.com/agda/agda/issues/2035): Matching on string causes solver to fail with internal error
  - [#2146](https://github.com/agda/agda/issues/2146): Unicode syntax for instance arguments
  - [#2217](https://github.com/agda/agda/issues/2217): Abort Agda without losing state
  - [#2229](https://github.com/agda/agda/issues/2229): Absence or presence of top-level module header affects scope
  - [#2253](https://github.com/agda/agda/issues/2253): Wrong scope error for abstract constructors
  - [#2261](https://github.com/agda/agda/issues/2261): Internal error in Auto/CaseSplit.hs:284
  - [#2270](https://github.com/agda/agda/issues/2270): Printer does not use sections.
  - [#2329](https://github.com/agda/agda/issues/2329): Size solver does not use type `Size< i` to gain the necessary information
  - [#2354](https://github.com/agda/agda/issues/2354): Interaction between instance search, size solver, and ordinary constraint solver.
  - [#2355](https://github.com/agda/agda/issues/2355): Literate Agda parser does not recognize TeX comments
  - [#2360](https://github.com/agda/agda/issues/2360): With clause stripping chokes on ambiguous projection
  - [#2362](https://github.com/agda/agda/issues/2362): Printing of parent patterns when with-clause does not match
  - [#2363](https://github.com/agda/agda/issues/2363): Allow underscore in with-clause patterns
  - [#2366](https://github.com/agda/agda/issues/2366): With-clause patterns renamed in error message
  - [#2368](https://github.com/agda/agda/issues/2368): Internal error after refining a tactic @ MetaVars.hs:267
  - [#2371](https://github.com/agda/agda/issues/2371): Shadowed module parameter crashes interaction
  - [#2372](https://github.com/agda/agda/issues/2372): problems when instances are declared with inferred types
  - [#2374](https://github.com/agda/agda/issues/2374): Ambiguous projection pattern could be disambiguated by visibility
  - [#2376](https://github.com/agda/agda/issues/2376): Termination checking interacts badly with eta-contraction
  - [#2377](https://github.com/agda/agda/issues/2377): open public is useless before module header
  - [#2381](https://github.com/agda/agda/issues/2381): Search (`C-c C-z`) panics on pattern synonyms
  - [#2386](https://github.com/agda/agda/issues/2386): Relax requirements of BUILTIN EQUALITY
  - [#2389](https://github.com/agda/agda/issues/2389): BUILTIN REFL not needed
  - [#2400](https://github.com/agda/agda/issues/2400): LaTeX backend error on LaTeX comments
  - [#2402](https://github.com/agda/agda/issues/2402): Parameters not dropped when reporting incomplete patterns
  - [#2403](https://github.com/agda/agda/issues/2403): Termination checker should reduce arguments in structural order check
  - [#2405](https://github.com/agda/agda/issues/2405): instance search failing in parameterized module
  - [#2408](https://github.com/agda/agda/issues/2408): DLub sorts are not serialized
  - [#2412](https://github.com/agda/agda/issues/2412): Problem with checking  with sized types
  - [#2413](https://github.com/agda/agda/issues/2413): Agda crashes on x@y pattern
  - [#2415](https://github.com/agda/agda/issues/2415): Size solver reports "inconsistent upper bound" even though there is a solution
  - [#2416](https://github.com/agda/agda/issues/2416): Cannot give size as computed by solver
  - [#2422](https://github.com/agda/agda/issues/2422): Overloaded inherited projections don't resolve
  - [#2423](https://github.com/agda/agda/issues/2423): Inherited projection on lhs
  - [#2426](https://github.com/agda/agda/issues/2426): On just warning about missing cases
  - [#2429](https://github.com/agda/agda/issues/2429): Irrelevant lambda should be accepted when relevant lambda is expected
  - [#2430](https://github.com/agda/agda/issues/2430): Another regression related to parameter refinement?
  - [#2433](https://github.com/agda/agda/issues/2433): rebindLocalRewriteRules re-adds global rewrite rules
  - [#2434](https://github.com/agda/agda/issues/2434): Exact split analysis is too strict when matching on eta record constructor
  - [#2441](https://github.com/agda/agda/issues/2441): Incorrect alignement in latex using the new ACM format
  - [#2444](https://github.com/agda/agda/issues/2444): Generalising compiler pragmas
  - [#2445](https://github.com/agda/agda/issues/2445): The LaTeX backend is slow
  - [#2447](https://github.com/agda/agda/issues/2447): Cache loaded interfaces even if a type error is encountered
  - [#2449](https://github.com/agda/agda/issues/2449): Agda depends on additional C library icu
  - [#2451](https://github.com/agda/agda/issues/2451): Agda panics when attempting to rewrite a typeclass Eq
  - [#2456](https://github.com/agda/agda/issues/2456): Internal error when postulating instance
  - [#2458](https://github.com/agda/agda/issues/2458): Regression: Agda-2.5.3 loops where Agda-2.5.2 passes
  - [#2462](https://github.com/agda/agda/issues/2462): Overloaded postfix projection does not resolve
  - [#2464](https://github.com/agda/agda/issues/2464): Eta contraction for irrelevant functions breaks subject reduction
  - [#2466](https://github.com/agda/agda/issues/2466): Case split to make hidden variable visible does not work
  - [#2467](https://github.com/agda/agda/issues/2467): REWRITE without BUILTIN REWRITE crashes
  - [#2469](https://github.com/agda/agda/issues/2469): "Partial" pattern match causes segfault at runtime
  - [#2472](https://github.com/agda/agda/issues/2472): Regression related to the auto command
  - [#2477](https://github.com/agda/agda/issues/2477): Sized data type analysis brittle, does not reduce size
  - [#2478](https://github.com/agda/agda/issues/2478): Multiply defined labels on the user manual (pdf)
  - [#2479](https://github.com/agda/agda/issues/2479): "Occurs check" error in generated Haskell code
  - [#2480](https://github.com/agda/agda/issues/2480): Agda accepts incorrect (?) code, subject reduction broken
  - [#2482](https://github.com/agda/agda/issues/2482): Wrong counting of data parameters with new-style mutual blocks
  - [#2483](https://github.com/agda/agda/issues/2483): Files are sometimes truncated to a size of 201 bytes
  - [#2486](https://github.com/agda/agda/issues/2486): Imports via FOREIGN are not transitively inherited anymore
  - [#2488](https://github.com/agda/agda/issues/2488): Instance search inhibits holes for instance fields
  - [#2493](https://github.com/agda/agda/issues/2493): Regression: Agda seems to loop when expression is given
  - [#2494](https://github.com/agda/agda/issues/2494): Instance fields sometimes have incorrect goal types
  - [#2495](https://github.com/agda/agda/issues/2495): Regression: termination checker of Agda-2.5.3 seemingly loops where Agda-2.5.2 passes
  - [#2500](https://github.com/agda/agda/issues/2500): Adding fields to a record can cause Agda to reject previous definitions
  - [#2510](https://github.com/agda/agda/issues/2510): Wrong error with --no-pattern-matching
  - [#2517](https://github.com/agda/agda/issues/2517): "Not a variable error"
  - [#2518](https://github.com/agda/agda/issues/2518): CopatternReductions in TreeLess
  - [#2523](https://github.com/agda/agda/issues/2523): The documentation of `--without-K` is outdated
  - [#2529](https://github.com/agda/agda/issues/2529): Unable to install Agda on Windows.
  - [#2537](https://github.com/agda/agda/issues/2537): case splitting with 'with' creates {_} instead of replicating the arguments it found.
  - [#2538](https://github.com/agda/agda/issues/2538): Internal error when parsing as-pattern
  - [#2543](https://github.com/agda/agda/issues/2543): Case splitting with ellipsis produces spurious parentheses
  - [#2545](https://github.com/agda/agda/issues/2545): Race condition in api tests
  - [#2549](https://github.com/agda/agda/issues/2549): Rewrite rule for higher path constructor does not fire
  - [#2550](https://github.com/agda/agda/issues/2550): Internal error in Agda.TypeChecking.Substitute
  - [#2552](https://github.com/agda/agda/issues/2552): Let bindings in module telescopes crash Agda.Interaction.BasicOps
  - [#2553](https://github.com/agda/agda/issues/2553): Internal error in Agda.TypeChecking.CheckInternal
  - [#2554](https://github.com/agda/agda/issues/2554): More flexible size-assignment in successor style
  - [#2555](https://github.com/agda/agda/issues/2555): Why does the positivity checker care about non-recursive occurrences?
  - [#2558](https://github.com/agda/agda/issues/2558): Internal error in Warshall Solver
  - [#2560](https://github.com/agda/agda/issues/2560): Internal Error in Reduce.Fast
  - [#2564](https://github.com/agda/agda/issues/2564): Non-exact-split highlighting makes other highlighting disappear
  - [#2568](https://github.com/agda/agda/issues/2568): agda2-infer-type-maybe-toplevel (in hole) does not respect "single-solution" requirement of instance resolution
  - [#2571](https://github.com/agda/agda/issues/2571): Record pattern translation does not eta contract
  - [#2573](https://github.com/agda/agda/issues/2573): Rewrite rules fail depending on unrelated changes
  - [#2574](https://github.com/agda/agda/issues/2574): No link attached to module without toplevel name
  - [#2575](https://github.com/agda/agda/issues/2575): Internal error, related to caching
  - [#2577](https://github.com/agda/agda/issues/2577): deBruijn fail for higher order instance problem
  - [#2578](https://github.com/agda/agda/issues/2578): Catch-all clause face used incorrectly for parent with pattern
  - [#2579](https://github.com/agda/agda/issues/2579): Import statements with module instantiation should not trigger an error message
  - [#2580](https://github.com/agda/agda/issues/2580): Implicit absurd match is NonVariant, explicit not
  - [#2583](https://github.com/agda/agda/issues/2583): Wrong de Bruijn index introduced by absurd pattern
  - [#2584](https://github.com/agda/agda/issues/2584): Duplicate warning printing
  - [#2585](https://github.com/agda/agda/issues/2585): Definition by copatterns not modulo eta
  - [#2586](https://github.com/agda/agda/issues/2586): "λ where" with single absurd clause not parsed
  - [#2588](https://github.com/agda/agda/issues/2588): `agda --latex` produces invalid LaTeX when there are block comments
  - [#2592](https://github.com/agda/agda/issues/2592): Internal Error in Agda/TypeChecking/Serialise/Instances/Common.hs
  - [#2597](https://github.com/agda/agda/issues/2597): Inline record definitions confuse the reflection API
  - [#2602](https://github.com/agda/agda/issues/2602): Debug output messes up AgdaInfo buffer
  - [#2603](https://github.com/agda/agda/issues/2603): Internal error in MetaVars.hs
  - [#2604](https://github.com/agda/agda/issues/2604): Use QNames as anchors in generated HTML
  - [#2605](https://github.com/agda/agda/issues/2605): HTML backend generates anchors for whitespace
  - [#2606](https://github.com/agda/agda/issues/2606): Check that LHS of a rewrite rule doesn't reduce is too strict
  - [#2612](https://github.com/agda/agda/issues/2612): `exact-split` documentation is outdated and incomplete
  - [#2613](https://github.com/agda/agda/issues/2613): Parametrised modules, with-abstraction and termination
  - [#2620](https://github.com/agda/agda/issues/2620): Internal error in auto.
  - [#2621](https://github.com/agda/agda/issues/2621): Case splitting instantiates meta
  - [#2626](https://github.com/agda/agda/issues/2626): triggered internal error with sized types in MetaVars module
  - [#2629](https://github.com/agda/agda/issues/2629): Exact splitting should not complain about absurd clauses
  - [#2631](https://github.com/agda/agda/issues/2631): docs for auto aren't clear on how to use flags/options
  - [#2632](https://github.com/agda/agda/issues/2632): some flags to auto dont seem to work in current agda 2.5.2
  - [#2637](https://github.com/agda/agda/issues/2637): Internal error in Agda.TypeChecking.Pretty, possibly related to sized types
  - [#2639](https://github.com/agda/agda/issues/2639): Performance regression, possibly related to the size solver
  - [#2641](https://github.com/agda/agda/issues/2641): Required instance of FromNat when compiling imported files
  - [#2642](https://github.com/agda/agda/issues/2642): Records with duplicate fields
  - [#2644](https://github.com/agda/agda/issues/2644): Wrong substitution in expandRecordVar
  - [#2645](https://github.com/agda/agda/issues/2645): Agda accepts postulated fields in a record
  - [#2646](https://github.com/agda/agda/issues/2646): Only warn if fixities for undefined symbols are given
  - [#2649](https://github.com/agda/agda/issues/2649): Empty list of "previous definition" in duplicate definition error
  - [#2652](https://github.com/agda/agda/issues/2652): Added a new variant of the colon to the Agda input method
  - [#2653](https://github.com/agda/agda/issues/2653): agda-mode: "cannot refine" inside instance argument even though term to be refined typechecks there
  - [#2654](https://github.com/agda/agda/issues/2654): Internal error on result splitting without --postfix-projections
  - [#2664](https://github.com/agda/agda/issues/2664): Segmentation fault with compiled programs using mutual record
  - [#2665](https://github.com/agda/agda/issues/2665): Documentation: Record update syntax in wrong location
  - [#2666](https://github.com/agda/agda/issues/2666): Internal error at Agda/Syntax/Abstract/Name.hs:113
  - [#2667](https://github.com/agda/agda/issues/2667): Panic error on unbound variable.
  - [#2669](https://github.com/agda/agda/issues/2669): Interaction: incorrect field variable name generation
  - [#2671](https://github.com/agda/agda/issues/2671): Feature request: nullary pattern matching lambdas
  - [#2679](https://github.com/agda/agda/issues/2679): Internal error at "Typechecking/Abstract.hs:133" and "TypeChecking/Telescope.hs:68"
  - [#2682](https://github.com/agda/agda/issues/2682): What are the rules for projections of abstract records?
  - [#2684](https://github.com/agda/agda/issues/2684): Bad error message for abstract constructor
  - [#2686](https://github.com/agda/agda/issues/2686): Abstract constructors should be ignored when resolving overloading
  - [#2690](https://github.com/agda/agda/issues/2690): [regression?] Agda engages in deep search instead of immediately failing
  - [#2700](https://github.com/agda/agda/issues/2700): Add a command to check against goal type (and normalise)
  - [#2703](https://github.com/agda/agda/issues/2703): Regression: Internal error for underapplied indexed constructor
  - [#2705](https://github.com/agda/agda/issues/2705): The GHC backend might diverge in infinite file creation
  - [#2708](https://github.com/agda/agda/issues/2708): Why is the `name` field in .agda-lib files mandatory?
  - [#2710](https://github.com/agda/agda/issues/2710): Type checker hangs
  - [#2712](https://github.com/agda/agda/issues/2712): Compiler Pragma for headers
  - [#2714](https://github.com/agda/agda/issues/2714): Option --no-main should be allowed as file-local option
  - [#2717](https://github.com/agda/agda/issues/2717): internal error at DisplayForm.hs:197
  - [#2718](https://github.com/agda/agda/issues/2718): Interactive 'give' doesn't insert enough parenthesis
  - [#2721](https://github.com/agda/agda/issues/2721): Without-K doesn't prevent heterogeneous conflict between literals
  - [#2723](https://github.com/agda/agda/issues/2723): Unreachable clauses in definition by copattern matching trip clause compiler
  - [#2725](https://github.com/agda/agda/issues/2725): File names for generated HTML files
  - [#2726](https://github.com/agda/agda/issues/2726): Old regression related to with
  - [#2727](https://github.com/agda/agda/issues/2727): Internal errors related to rewrite
  - [#2729](https://github.com/agda/agda/issues/2729): Regression: case splitting uses variable name variants instead of the unused original names
  - [#2730](https://github.com/agda/agda/issues/2730): Command to give in spite of termination errors
  - [#2731](https://github.com/agda/agda/issues/2731): Agda fails to build with happy 1.19.6
  - [#2733](https://github.com/agda/agda/issues/2733): Avoid some uses of \AgdaIndent?
  - [#2734](https://github.com/agda/agda/issues/2734): Make height of empty lines configurable
  - [#2736](https://github.com/agda/agda/issues/2736): Segfault using Alex 3.2.2 and cpphs
  - [#2740](https://github.com/agda/agda/issues/2740): Indenting every line of code should be a no-op


Release notes for Agda version 2.5.2
====================================

Installation and infrastructure
-------------------------------

* Modular support for literate programming

  Literate programming support has been moved out of the lexer and into the
  `Agda.Syntax.Parser.Literate` module.

  Files ending in `.lagda` are still interpreted as literate TeX.
  The extension `.lagda.tex` may now also be used for literate TeX files.

  Support for more literate code formats and extensions can be added
  modularly.

  By default, `.lagda.*` files are opened in the Emacs mode
  corresponding to their last extension.  One may switch to and from
  Agda mode manually.

* reStructuredText

  Literate Agda code can now be written in reStructuredText format, using
  the `.lagda.rst` extension.

  As a general rule, Agda will parse code following a line ending in `::`,
  as long as that line does not start with `..`. The module name must
  match the path of the file in the documentation, and must be given
  explicitly.  Several files have been converted already, for instance:

  - `language/mixfix-operators.lagda.rst`
  - `tools/compilers.lagda.rst`

  Note that:

  - Code blocks inside an rST comment block will be type-checked by Agda,
    but not rendered in the documentation.
  - Code blocks delimited by `.. code-block:: agda` will be rendered in
    the final documenation, but not type-checked by Agda.
  - All lines inside a codeblock must be further indented than the first line
    of the code block.
  - Indentation must be consistent between code blocks. In other
    words, the file as a whole must be a valid Agda file if all the
    literate text is replaced by white space.

* Documentation testing

  All documentation files in the `doc/user-manual` directory that end
  in `.lagda.rst` can be typechecked by running `make
  user-manual-test`, and also as part of the general test suite.

* Support installation through Stack

  The Agda sources now also include a configuration for the stack install tool
  (tested through continuous integration).

  It should hence be possible to repeatably build any future Agda version
  (including unreleased commits) from source by checking out that version and
  running `stack install` from the checkout directory.
  By using repeatable builds, this should keep selecting the same dependencies
  in the face of new releases on Hackage.

  For further motivation, see
  Issue [#2005](https://github.com/agda/agda/issues/2005).

* Removed the `--test` command-line option

  This option ran the internal test-suite. This test-suite was
  implemented using Cabal supports for
  test-suites. [Issue [#2083](https://github.com/agda/agda/issues/2083)].

* The `--no-default-libraries` flag has been split into two flags
  [Issue [#1937](https://github.com/agda/agda/issues/1937)]

  - `--no-default-libraries`: Ignore the defaults file but still look for local
    `.agda-lib` files
  - `--no-libraries`: Don't use any `.agda-lib` files (the previous behaviour
    of `--no-default-libraries`).

* If `agda` was built inside `git` repository, then the `--version` flag
  will display the hash of the commit used, and whether the tree was
  `-dirty` (i.e. there were uncommited changes in the working directory).
  Otherwise, only the version number is shown.

Language
--------

* Dot patterns are now optional

  Consider the following program

  ```agda
  data Vec (A : Set) : Nat → Set where
    []   : Vec A zero
    cons : ∀ n → A → Vec A n → Vec A (suc n)

  vmap : ∀ {A B} n → (A → B) → Vec A n → Vec B n
  vmap .zero    f []            = []
  vmap .(suc m) f (cons m x xs) = cons m (f x) (vmap m f xs)
  ```

  If we don't care about the dot patterns they can (and could previously) be
  replaced by wildcards:

  ```agda
  vmap : ∀ {A B} n → (A → B) → Vec A n → Vec B n
  vmap _ f []            = []
  vmap _ f (cons m x xs) = cons m (f x) (vmap m f xs)
  ```

  Now it is also allowed to give a variable pattern in place of the dot
  pattern. In this case the variable will be bound to the value of the dot
  pattern. For our example:

  ```agda
  vmap : ∀ {A B} n → (A → B) → Vec A n → Vec B n
  vmap n f []            = []
  vmap n f (cons m x xs) = cons m (f x) (vmap m f xs)
  ```

  In the first clause `n` reduces to `zero` and in the second clause
  `n` reduces to `suc m`.

* Module parameters can now be refined by pattern matching

  Previously, pattern matches that would refine a variable outside the
  current left-hand side was disallowed. For instance, the following
  would give an error, since matching on the vector would
  instantiate `n`.

  ```agda
  module _ {A : Set} {n : Nat} where
    f : Vec A n → Vec A n
    f []       = []
    f (x ∷ xs) = x ∷ xs
  ```

  Now this is no longer disallowed. Instead `n` is bound to the
  appropriate value in each clause.

* With-abstraction now abstracts also in module parameters

  The change that allows pattern matching to refine module parameters also
  allows with-abstraction to abstract in them. For instance,

  ```agda
  module _ (n : Nat) (xs : Vec Nat (n + n)) where
    f : Nat
    f with n + n
    f    | nn = ? -- xs : Vec Nat nn
  ```

  Note: Any function argument or lambda-bound variable bound outside a given
  function counts as a module parameter.

  To prevent abstraction in a parameter you can hide it inside a definition. In
  the above example,

  ```agda
  module _ (n : Nat) (xs : Vec Nat (n + n)) where

    ys : Vec Nat (n + n)
    ys = xs

    f : Nat
    f with n + n
    f    | nn = ? -- xs : Vec Nat nn, ys : Vec Nat (n + n)
  ```

* As-patterns [Issue [#78](https://github.com/agda/agda/issues/78)].

  As-patterns (`@`-patterns) are finally working and can be used to name a
  pattern. The name has the same scope as normal pattern variables (i.e. the
  right-hand side, where clause, and dot patterns). The name reduces to the
  value of the named pattern. For example::

  ```agda
  module _ {A : Set} (_<_ : A → A → Bool) where
    merge : List A → List A → List A
    merge xs [] = xs
    merge [] ys = ys
    merge xs@(x ∷ xs₁) ys@(y ∷ ys₁) =
      if x < y then x ∷ merge xs₁ ys
               else y ∷ merge xs ys₁
  ```

* Idiom brackets.

  There is new syntactic sugar for idiom brackets:

    `(| e a1 .. an |)` expands to

    `pure e <*> a1 <*> .. <*> an`

  The desugaring takes place before scope checking and only requires names
  `pure` and `_<*>_` in scope. Idiom brackets work well with operators, for
  instance

    `(| if a then b else c |)` desugars to

    `pure if_then_else_ <*> a <*> b <*> c`

  Limitations:

    - The top-level application inside idiom brackets cannot include
      implicit applications, so `(| foo {x = e} a b |)` is illegal. In
      the case `e` is pure you can write `(| (foo {x = e}) a b |)`
      which desugars to

        `pure (foo {x = e}) <*> a <*> b`

    - Binding syntax and operator sections cannot appear immediately inside
      idiom brackets.

* Layout for pattern matching lambdas.

  You can now write pattern matching lambdas using the syntax

  ```agda
  λ where false → true
          true  → false
  ```

  avoiding the need for explicit curly braces and semicolons.

* Overloaded projections
  [Issue [#1944](https://github.com/agda/agda/issues/1944)].

  Ambiguous projections are no longer a scope error.  Instead they get
  resolved based on the type of the record value they are
  eliminating.  This corresponds to constructors, which can be
  overloaded and get disambiguated based on the type they are
  introducing.  Example:

  ```agda
  module _ (A : Set) (a : A) where

  record R B : Set where
    field f : B
  open R public

  record S B : Set where
    field f : B
  open S public
  ```

  Exporting `f` twice from both `R` and `S` is now allowed.  Then,

  ```agda
  r : R A
  f r = a

  s : S A
  f s = f r
  ```

  disambiguates to:

  ```agda
  r : R A
  R.f r = a

  s : S A
  S.f s = R.f r
  ```

  If the type of the projection is known, it can also be disambiguated
  unapplied.

  ```agda
  unapplied : R A -> A
  unapplied = f
  ```

* Postfix projections
  [Issue [#1963](https://github.com/agda/agda/issues/1963)].

  Agda now supports a postfix syntax for projection application.
  This style is more in harmony with copatterns.  For example:

  ```agda
  record Stream (A : Set) : Set where
    coinductive
    field head : A
          tail : Stream A

  open Stream

  repeat : ∀{A} (a : A) → Stream A
  repeat a .head = a
  repeat a .tail = repeat a

  zipWith : ∀{A B C} (f : A → B → C) (s : Stream A) (t : Stream B) → Stream C
  zipWith f s t .head = f (s .head) (t .head)
  zipWith f s t .tail = zipWith f (s .tail) (t .tail)

  module Fib (Nat : Set) (zero one : Nat) (plus : Nat → Nat → Nat) where

    {-# TERMINATING #-}
    fib : Stream Nat
    fib .head = zero
    fib .tail .head = one
    fib .tail .tail = zipWith plus fib (fib .tail)
  ```

  The thing we eliminate with projection now is visibly the head,
  i.e., the left-most expression of the sequence (e.g. `repeat` in
  `repeat a .tail`).

  The syntax overlaps with dot patterns, but for type correct left
  hand sides there is no confusion: Dot patterns eliminate function
  types, while (postfix) projection patterns eliminate record types.

  By default, Agda prints system-generated projections (such as by
  eta-expansion or case splitting) prefix.  This can be changed with
  the new option:

  ```agda
  {-# OPTIONS --postfix-projections #-}
  ```

  Result splitting in extended lambdas (aka pattern lambdas) always
  produces postfix projections, as prefix projection pattern do not
  work here: a prefix projection needs to go left of the head, but the
  head is omitted in extended lambdas.

  ```agda
  dup : ∀{A : Set}(a : A) → A × A
  dup = λ{ a → ? }
  ```

  Result splitting (`C-c C-c RET`) here will yield:

  ```agda
  dup = λ{ a .proj₁ → ? ; a .proj₂ → ? }
  ```

* Projection parameters
  [Issue [#1954](https://github.com/agda/agda/issues/1954)].

  When copying a module, projection parameters will now stay hidden
  arguments, even if the module parameters are visible.
  This matches the situation we had for constructors since long.
  Example:

  ```agda
  module P (A : Set) where
    record R : Set where
      field f : A

  open module Q A = P A
  ```

  Parameter `A` is now hidden in `R.f`:

  ```agda
  test : ∀{A} → R A → A
  test r = R.f r
  ```

  Note that a module parameter that corresponds to the record value
  argument of a projection will not be hidden.

  ```agda
  module M (A : Set) (r : R A) where
    open R A r public

  test' : ∀{A} → R A → A
  test' r = M.f r
  ```

* Eager insertion of implicit arguments
  [Issue [#2001](https://github.com/agda/agda/issues/2001)]

  Implicit arguments are now (again) eagerly inserted in left-hand sides. The
  previous behaviour of inserting implicits for where blocks, but not
  right-hand sides was not type safe.

* Module applications can now be eta expanded/contracted without
  changing their behaviour
  [Issue #[1985](https://github.com/agda/agda/issues/1985)]

  Previously definitions exported using `open public` got the
  incorrect type for underapplied module applications.

  Example:

  ```agda
  module A where
    postulate A : Set

  module B (X : Set) where
    open A public

  module C₁ = B
  module C₂ (X : Set) = B X
  ```

  Here both `C₁.A` and `C₂.A` have type `(X : Set) → Set`.

* Polarity pragmas.

  Polarity pragmas can be attached to postulates. The polarities express
  how the postulate's arguments are used. The following polarities
  are available:

  `_`:  Unused.

  `++`: Strictly positive.

  `+`:  Positive.

  `-`:  Negative.

  `*`:  Unknown/mixed.

  Polarity pragmas have the form

  ```
  {-# POLARITY name <zero or more polarities> #-}
  ```

  and can be given wherever fixity declarations can be given. The
  listed polarities apply to the given postulate's arguments
  (explicit/implicit/instance), from left to right. Polarities
  currently cannot be given for module parameters. If the postulate
  takes n arguments (excluding module parameters), then the number of
  polarities given must be between 0 and n (inclusive).

  Polarity pragmas make it possible to use postulated type formers in
  recursive types in the following way:

  ```agda
  postulate
    ∥_∥ : Set → Set

  {-# POLARITY ∥_∥ ++ #-}

  data D : Set where
    c : ∥ D ∥ → D
  ```

  Note that one can use postulates that may seem benign, together with
  polarity pragmas, to prove that the empty type is inhabited:

  ```agda
  postulate
    _⇒_    : Set → Set → Set
    lambda : {A B : Set} → (A → B) → A ⇒ B
    apply  : {A B : Set} → A ⇒ B → A → B

  {-# POLARITY _⇒_ ++ #-}

  data ⊥ : Set where

  data D : Set where
    c : D ⇒ ⊥ → D

  not-inhabited : D → ⊥
  not-inhabited (c f) = apply f (c f)

  inhabited : D
  inhabited = c (lambda not-inhabited)

  bad : ⊥
  bad = not-inhabited inhabited
  ```

  Polarity pragmas are not allowed in safe mode.

* Declarations in a `where`-block are now
  private. [Issue [#2101](https://github.com/agda/agda/issues/2101)]
  This means that

  ```agda
  f ps = body where
    decls
  ```

  is now equivalent to

  ```agda
  f ps = body where
    private
      decls
  ```

  This changes little, since the `decls` were anyway not in scope
  outside `body`.  However, it makes a difference for abstract
  definitions, because private type signatures can see through
  abstract definitions.  Consider:

  ```agda
  record Wrap (A : Set) : Set where
    field unwrap : A

  postulate
    P : ∀{A : Set} → A → Set

  abstract

    unnamedWhere : (A : Set) → Set
    unnamedWhere A = A
      where  -- the following definitions are private!
      B : Set
      B = Wrap A

      postulate
        b : B
        test : P (Wrap.unwrap b)  -- succeeds
  ```

  The `abstract` is inherited in `where`-blocks from the parent (here:
  function `unnamedWhere`).  Thus, the definition of `B` is opaque and
  the type equation `B = Wrap A` cannot be used to check type
  signatures, not even of abstract definitions.  Thus, checking the
  type  `P (Wrap.unwrap b)` would fail.  However, if `test` is
  private, abstract definitions are translucent in its type, and
  checking succeeds.  With the implemented change, all
  `where`-definitions are private, in this case `B`, `b`, and `test`,
  and the example succeeds.

  Nothing changes for the named forms of `where`,

  ```agda
  module M where
  module _ where
  ```

  For instance, this still fails:

  ```agda
  abstract

    unnamedWhere : (A : Set) → Set
    unnamedWhere A = A
      module M where
      B : Set
      B = Wrap A

      postulate
        b : B
        test : P (Wrap.unwrap b)  -- fails
  ```

* Private anonymous modules now work as expected
  [Issue [#2199](https://github.com/agda/agda/issues/2199)]

  Previously the `private` was ignored for anonymous modules causing
  its definitions to be visible outside the module containing the
  anonymous module.  This is no longer the case. For instance,

  ```agda
  module M where
    private
      module _ (A : Set) where
        Id : Set
        Id = A

    foo : Set → Set
    foo = Id

  open M

  bar : Set → Set
  bar = Id -- Id is no longer in scope here
  ```

* Pattern synonyms are now expanded on left hand sides of DISPLAY
  pragmas [Issue [#2132](https://github.com/agda/agda/issues/2132)].
  Example:

  ```agda
  data D : Set where
    C c : D
    g : D → D

  pattern C′ = C

  {-# DISPLAY C′ = C′ #-}
  {-# DISPLAY g C′ = c #-}
  ```

  This now behaves as:

  ```agda
  {-# DISPLAY C = C′ #-}
  {-# DISPLAY g C = c #-}
  ```

  Expected error for

  ```agda
  test : C ≡ g C
  test = refl
  ```

  is thus:

  ```
  C′ != c of type D
  ```

* The built-in floats have new semantics to fix inconsistencies
  and to improve cross-platform portability.

  - Float equality has been split into two primitives.
    ``primFloatEquality`` is designed to establish
    decidable propositional equality while
    ``primFloatNumericalEquality`` is intended for numerical
    computations. They behave as follows:

    ```
    primFloatEquality NaN NaN = True
    primFloatEquality 0.0 -0.0 = False

    primFloatNumericalEquality NaN NaN = False
    primFloatNumericalEquality 0.0 -0.0 = True
    ```

    This change fixes an inconsistency, see [Issue [#2169](https://github.com/agda/agda/issues/2169)].
    For further detail see the [user manual](http://agda.readthedocs.io/en/latest/language/built-ins.html#floats).

  - Floats now have only one `NaN` value. This is necessary
    for proper Float support in the JavaScript backend,
    as JavaScript (and some other platforms) only support
    one `NaN` value.

  - The primitive function `primFloatLess` was renamed
    `primFloatNumericalLess`.

* Added new primitives to built-in floats:

  - `primFloatNegate : Float → Float`
    [Issue [#2194](https://github.com/agda/agda/issues/2194)]

  - Trigonometric primitives
    [Issue [#2200](https://github.com/agda/agda/issues/2200)]:

    ```agda
    primCos   : Float → Float
    primTan   : Float → Float
    primASin  : Float → Float
    primACos  : Float → Float
    primATan  : Float → Float
    primATan2 : Float → Float → Float
    ```

* Anonymous declarations
  [Issue [#1465](https://github.com/agda/agda/issues/1465)].

  A module can contain an arbitrary number of declarations
  named `_` which will scoped-checked and type-checked but
  won't be made available in the scope (nor exported). They
  cannot introduce arguments on the LHS (but one can use
  lambda-abstractions on the RHS) and they cannot be defined
  by recursion.

  ```agda
  _ : Set → Set
  _ = λ x → x
  ```

### Rewriting

* The REWRITE pragma can now handle several names.  E.g.:
  ```agda
  {-# REWRITE eq1 eq2 #-}
  ```

### Reflection

* You can now use macros in reflected terms
  [Issue [#2130](https://github.com/agda/agda/issues/2130)].

  For instance, given a macro

  ```agda
  macro
    some-tactic : Term → TC ⊤
    some-tactic = ...
  ```

  the term `def (quote some-tactic) []` represents a call to the
  macro. This makes it a lot easier to compose tactics.

* The reflection machinery now uses normalisation less often:

  * Macros no longer normalise the (automatically quoted) term
    arguments.

  * The TC primitives `inferType`, `checkType` and `quoteTC` no longer
    normalise their arguments.

  * The following deprecated constructions may also have been changed:
    `quoteGoal`, `quoteTerm`, `quoteContext` and `tactic`.

* New TC primitive: `withNormalisation`.

  To recover the old normalising behaviour of `inferType`, `checkType`,
  `quoteTC` and `getContext`, you can wrap them inside a call to
  `withNormalisation true`:

  ```agda
    withNormalisation : ∀ {a} {A : Set a} → Bool → TC A → TC A
  ```

* New TC primitive: `reduce`.

  ```agda
  reduce : Term → TC Term
  ```

  Reduces its argument to weak head normal form.

* Added new TC primitive: `isMacro`
  [Issue [#2182](https://github.com/agda/agda/issues/2182)]

  ```agda
  isMacro : Name → TC Bool
  ```

  Returns `true` if the name refers to a macro, otherwise `false`.

* The `record-type` constructor now has an extra argument containing
  information about the record type's fields:
  ```agda
    data Definition : Set where
      …
      record-type : (c : Name) (fs : List (Arg Name)) → Definition
      …
  ```

Type checking
-------------

* Files with open metas can be imported now
  [Issue [#964](https://github.com/agda/agda/issues/964)].  This
  should make simultaneous interactive development on several modules
  more pleasant.

  Requires option: `--allow-unsolved-metas`

  Internally, before serialization, open metas are turned into postulates named

  ```
    unsolved#meta.<nnn>
  ```

  where `<nnn>` is the internal meta variable number.

* The performance of the compile-time evaluator has been greatly improved.

  - Fixed a memory leak in evaluator
    (Issue [#2147](https://github.com/agda/agda/issues/2147)).

  - Reduction speed improved by an order of magnitude and is now
    comparable to the performance of GHCi. Still call-by-name though.

* The detection of types that satisfy K added in Agda 2.5.1 has been
  rolled back (see
  Issue [#2003](https://github.com/agda/agda/issues/2003)).

* Eta-equality for record types is now only on after the positivity
  checker has confirmed it is safe to have it.  Eta-equality for
  unguarded inductive records previously lead to looping of the type
  checker.
  [See Issue [#2197](https://github.com/agda/agda/issues/2197)]

  ```agda
  record R : Set where
    inductive
    field r : R

    loops : R
    loops = ?
  ```

  As a consequence of this change, the following example does not
  type-check any more:

  ```agda
  mutual
    record ⊤ : Set where

    test : ∀ {x y : ⊤} → x ≡ y
    test = refl
  ```

  It fails because the positivity checker is only run after the mutual
  block, thus, eta-equality for `⊤` is not available when checking
  test.

  One can declare eta-equality explicitly, though, to make this
  example work.

  ```agda
  mutual
    record ⊤ : Set where
      eta-equality

    test : ∀ {x y : ⊤} → x ≡ y
    test = refl
  ```

* Records with instance fields are now eta expanded before instance search.

  For instance, assuming `Eq` and `Ord` with boolean functions `_==_` and `_<_`
  respectively,

  ```agda
    record EqAndOrd (A : Set) : Set where
      field {{eq}}  : Eq A
            {{ord}} : Ord A


    leq : {A : Set} {{_ : EqAndOrd A}} → A → A → Bool
    leq x y = x == y || x < y
  ```

  Here the `EqAndOrd` record is automatically unpacked before instance search,
  revealing the component `Eq` and `Ord` instances.

  This can be used to simulate superclass dependencies.

* Overlappable record instance fields.

  Instance fields in records can be marked as overlappable using the new
  `overlap` keyword:

  ```agda
    record Ord (A : Set) : Set where
      field
        _<_ : A → A → Bool
        overlap {{eqA}} : Eq A
  ```

  When instance search finds multiple candidates for a given instance goal and
  they are **all** overlappable it will pick the left-most candidate instead of
  refusing to solve the instance goal.

  This can be use to solve the problem arising from shared "superclass"
  dependencies. For instance, if you have, in addition to `Ord` above, a `Num`
  record that also has an `Eq` field and want to write a function requiring
  both `Ord` and `Num`, any `Eq` constraint will be solved by the `Eq` instance
  from whichever argument that comes first.

  ```agda
    record Num (A : Set) : Set where
      field
        fromNat : Nat → A
        overlap {{eqA}} : Eq A

    lessOrEqualFive : {A : Set} {{NumA : Num A}} {{OrdA : Ord A}} → A → Bool
    lessOrEqualFive x = x == fromNat 5 || x < fromNat 5
  ```

  In this example the call to `_==_` will use the `eqA` field from `NumA`
  rather than the one from `OrdA`. Note that these may well be different.

* Instance fields can be left out of copattern matches
  [Issue [#2288](https://github.com/agda/agda/issues/2288)]

  Missing cases for instance fields (marked `{{` `}}`) in copattern matches
  will be solved using instance search. This makes defining instances with
  superclass fields much nicer. For instance, we can define `Nat` instances of
  `Eq`, `Ord` and `Num` from above as follows:

  ```agda
    instance
      EqNat : Eq Nat
      _==_ {{EqNat}} n m = eqNat n m

      OrdNat : Ord Nat
      _<_ {{OrdNat}} n m = lessNat n m

      NumNat : Num Nat
      fromNat {{NumNat}} n = n
  ```

  The `eqA` fields of `Ord` and `Num` are filled in using instance search (with
  `EqNat` in this case).

* Limited instance search depth
  [Issue [#2269](https://github.com/agda/agda/issues/2269)]

  To prevent instance search from looping on bad instances
  (see [Issue #1743](https://github.com/agda/agda/issues/1743)) the search
  depth of instance search is now limited. The maximum depth can be set with
  the `--instance-search-depth` flag and the default value is `500`.

Emacs mode
----------

* New command `C-u C-u C-c C-n`: Use `show` to display the result of
  normalisation.

  Calling `C-u C-u C-c C-n` on an expression `e` (in a hole or at top level)
  normalises `show e` and prints the resulting string, or an error message if
  the expression does not normalise to a literal string.

  This is useful when working with complex data structures for which you have
  defined a nice `Show` instance.

  Note that the name `show` is hardwired into the command.

* Changed feature: Interactively split result.

  Make-case (`C-c C-c`) with no variables will now *either* introduce
  function arguments *or* do a copattern split (or fail).

  This is as before:

  ```agda
  test : {A B : Set} (a : A) (b : B) → A × B
  test a b = ?

  -- expected:
  -- proj₁ (test a b) = {!!}
  -- proj₂ (test a b) = {!!}

  testFun : {A B : Set} (a : A) (b : B) → A × B
  testFun = ?

  -- expected:
  -- testFun a b = {!!}
  ```

  This is has changed:

  ```agda
  record FunRec A : Set where
    field funField : A → A
  open FunRec

  testFunRec : ∀{A} → FunRec A
  testFunRec = ?

  -- expected (since 2016-05-03):
  -- funField testFunRec = {!!}

  -- used to be:
  -- funField testFunRec x = {!!}
  ```

* Changed feature: Split on hidden variables.

  Make-case (`C-c C-c`) will no longer split on the given hidden
  variables, but only make them visible. (Splitting can then be
  performed in a second go.)

  ```agda
  test : ∀{N M : Nat} → Nat → Nat → Nat
  test N M = {!.N N .M!}
  ```

  Invoking splitting will result in:

  ```agda
  test {N} {M} zero M₁ = ?
  test {N} {M} (suc N₁) M₁ = ?
  ```

  The hidden `.N` and `.M` have been brought into scope, the
  visible `N` has been split upon.

* Non-fatal errors/warnings.

  Non-fatal errors and warnings are now displayed in the info buffer
  and do not interrupt the typechecking of the file.

  Currently termination errors, unsolved metavariables, unsolved
  constraints, positivity errors, deprecated BUILTINs, and empty
  REWRITING pragmas are non-fatal errors.

* Highlighting for positivity check failures

  Negative occurences of a datatype in its definition are now
  highlighted in a way similar to termination errors.

* The abbrev for codata was replaced by an abbrev for code
  environments.

  If you type `c C-x '` (on a suitably standard setup), then Emacs
  will insert the following text:

  ```agda
  \begin{code}<newline>  <cursor><newline>\end{code}<newline>.
  ```

* The LaTeX backend can now be invoked from the Emacs mode.

  Using the compilation command (`C-c C-x C-c`).

  The flag `--latex-dir` can be used to set the output directory (by
  default: `latex`). Note that if this directory is a relative path,
  then it is interpreted relative to the "project root". (When the
  LaTeX backend is invoked from the command line the path is
  interpreted relative to the current working directory.) Example: If
  the module `A.B.C` is located in the file `/foo/A/B/C.agda`, then
  the project root is `/foo/`, and the default output directory is
  `/foo/latex/`.

* The compilation command (`C-c C-x C-c`) now by default asks for a
  backend.

  To avoid this question, set the customisation variable
  `agda2-backend` to an appropriate value.

* The command `agda2-measure-load-time` no longer "touches" the file,
  and the optional argument `DONT-TOUCH` has been removed.

* New command `C-u (C-u) C-c C-s`: Simplify or normalise the solution `C-c C-s` produces

  When writing examples, it is nice to have the hole filled in with
  a normalised version of the solution. Calling `C-c C-s` on

  ```agda
  _ : reverse (0 ∷ 1 ∷ []) ≡ ?
  _ = refl
  ```

  used to yield the non informative `reverse (0 ∷ 1 ∷ [])` when we would
  have hopped to get `1 ∷ 0 ∷ []` instead. We can now control finely the
  degree to which the solution is simplified.

* Changed feature: Solving the hole at point

  Calling `C-c C-s` inside a specific goal does not solve *all* the goals
  already instantiated internally anymore: it only solves the one at hand
  (if possible).

* New bindings: All the blackboard bold letters are now available
  [Pull Request [#2305](https://github.com/agda/agda/pull/2305)]

  The Agda input method only bound a handful of the blackboard bold letters
  but programmers were actually using more than these. They are now all
  available: lowercase and uppercase. Some previous bindings had to be
  modified for consistency. The naming scheme is as follows:

  * `\bx` for lowercase blackboard bold
  * `\bX` for uppercase blackboard bold
  * `\bGx` for lowercase greek blackboard bold (similar to `\Gx` for
    greeks)
  * `\bGX` for uppercase greek blackboard bold (similar to `\GX` for
    uppercase greeks)

* Replaced binding for go back

  Use `M-,` (instead of `M-*`) for go back in Emacs ≥ 25.1 (and
  continue using `M-*` with previous versions of Emacs).

Compiler backends
-----------------

* JS compiler backend

  The JavaScript backend has been (partially) rewritten. The
  JavaScript backend now supports most Agda features, notably
  copatterns can now be compiled to JavaScript. Furthermore, the
  existing optimizations from the other backends now apply to the
  JavaScript backend as well.

* GHC, JS and UHC compiler backends

  Added new primitives to built-in floats
  [Issues [#2194](https://github.com/agda/agda/issues/2194) and
  [#2200](https://github.com/agda/agda/issues/2200)]:

  ```agda
  primFloatNegate : Float → Float
  primCos         : Float → Float
  primTan         : Float → Float
  primASin        : Float → Float
  primACos        : Float → Float
  primATan        : Float → Float
  primATan2       : Float → Float → Float
  ```

LaTeX backend
-------------

* Code blocks are now (by default) surrounded by vertical space.
  [Issue [#2198](https://github.com/agda/agda/issues/2198)]

  Use `\AgdaNoSpaceAroundCode{}` to avoid this vertical space, and
  `\AgdaSpaceAroundCode{}` to reenable it.

  Note that, if `\AgdaNoSpaceAroundCode{}` is used, then empty lines
  before or after a code block will not necessarily lead to empty
  lines in the generated document. However, empty lines *inside* the
  code block do (by default) lead to empty lines in the output.

  If you prefer the previous behaviour, then you can use the `agda.sty`
  file that came with the previous version of Agda.

* `\AgdaHide{...}` now eats trailing spaces (using `\ignorespaces`).

* New environments: `AgdaAlign`, `AgdaSuppressSpace` and
  `AgdaMultiCode`.

  Sometimes one might want to break up a code block into multiple
  pieces, but keep code in different blocks aligned with respect to
  each other. Then one can use the `AgdaAlign` environment. Example
  usage:
  ```latex
    \begin{AgdaAlign}
    \begin{code}
      code
        code  (more code)
    \end{code}
    Explanation...
    \begin{code}
      aligned with "code"
        code  (aligned with (more code))
    \end{code}
    \end{AgdaAlign}
  ```
  Note that `AgdaAlign` environments should not be nested.

  Sometimes one might also want to hide code in the middle of a code
  block. This can be accomplished in the following way:
  ```latex
    \begin{AgdaAlign}
    \begin{code}
      visible
    \end{code}
    \AgdaHide{
    \begin{code}
      hidden
    \end{code}}
    \begin{code}
      visible
    \end{code}
    \end{AgdaAlign}
  ```
  However, the result may be ugly: extra space is perhaps inserted
  around the code blocks.

  The `AgdaSuppressSpace` environment ensures that extra space is only
  inserted before the first code block, and after the last one (but
  not if `\AgdaNoSpaceAroundCode{}` is used).

  The environment takes one argument, the number of wrapped code
  blocks (excluding hidden ones). Example usage:
  ```latex
    \begin{AgdaAlign}
    \begin{code}
      code
        more code
    \end{code}
    Explanation...
    \begin{AgdaSuppressSpace}{2}
    \begin{code}
      aligned with "code"
        aligned with "more code"
    \end{code}
    \AgdaHide{
    \begin{code}
      hidden code
    \end{code}}
    \begin{code}
        also aligned with "more code"
    \end{code}
    \end{AgdaSuppressSpace}
    \end{AgdaAlign}
  ```

  Note that `AgdaSuppressSpace` environments should not be nested.

  There is also a combined environment, `AgdaMultiCode`, that combines
  the effects of `AgdaAlign` and `AgdaSuppressSpace`.

Tools
-----

### agda-ghc-names

The `agda-ghc-names` now has its own repository at

  https://github.com/agda/agda-ghc-names

and is no longer distributed with Agda.

Release notes for Agda version 2.5.1.2
======================================

* Fixed broken type signatures that were incorrectly accepted due to
  [GHC #12784](https://ghc.haskell.org/trac/ghc/ticket/12784).

Release notes for Agda version 2.5.1.1
======================================

Installation and infrastructure
-------------------------------

* Added support for GHC 8.0.1.

* Documentation is now built with Python >=3.3, as done by
  [readthedocs.org](https://readthedocs.org/).

Bug fixes
---------

* Fixed a serious performance problem with instance search

  Issues [#1952](https://github.com/agda/agda/issues/1952) and
  [#1998](https://github.com/agda/agda/issues/1998). Also related:
  [#1955](https://github.com/agda/agda/issues/1955) and
  [#2025](https://github.com/agda/agda/issues/2025)

* Interactively splitting variable with `C-c C-c` no longer introduces
  new trailing patterns.  This fixes
  Issue [#1950](https://github.com/agda/agda/issues/1950).

  ```agda
  data Ty : Set where
    _⇒_ : Ty → Ty → Ty

  ⟦_⟧ : Ty → Set
  ⟦ A ⇒ B ⟧ = ⟦ A ⟧ → ⟦ B ⟧

  data Term : Ty → Set where
    K : (A B : Ty) → Term (A ⇒ (B ⇒ A))

  test : (A : Ty) (a : Term A) → ⟦ A ⟧
  test A a = {!a!}
  ```

  Before change, case splitting on `a` would give

  ```agda
  test .(A ⇒ (B ⇒ A)) (K A B) x x₁ = ?
  ```

  Now, it yields

  ```agda
  test .(A ⇒ (B ⇒ A)) (K A B) = ?
  ```

* In literate TeX files, `\begin{code}` and `\end{code}` can be
  preceded (resp. followed) by TeX code on the same line. This fixes
  Issue [#2077](https://github.com/agda/agda/issues/2077).

* Other issues fixed (see
  [bug tracker](https://github.com/agda/agda/issues)):

  [#1951](https://github.com/agda/agda/issues/1951) (mixfix binders
  not working in 'syntax')

  [#1967](https://github.com/agda/agda/issues/1967) (too eager
  insteance search error)

  [#1974](https://github.com/agda/agda/issues/1974) (lost constraint
  dependencies)

  [#1982](https://github.com/agda/agda/issues/1982) (internal error in
  unifier)

  [#2034](https://github.com/agda/agda/issues/2034) (function type
  instance goals)

Compiler backends
-----------------

* UHC compiler backend

  Added support for UHC 1.1.9.4.

Release notes for Agda version 2.5.1
====================================

Documentation
-------------

* There is now an official Agda User Manual:
  http://agda.readthedocs.org/en/stable/

Installation and infrastructure
-------------------------------

* Builtins and primitives are now defined in a new set of modules available to
  all users, independent of any particular library. The modules are

  ```agda
  Agda.Builtin.Bool
  Agda.Builtin.Char
  Agda.Builtin.Coinduction
  Agda.Builtin.Equality
  Agda.Builtin.Float
  Agda.Builtin.FromNat
  Agda.Builtin.FromNeg
  Agda.Builtin.FromString
  Agda.Builtin.IO
  Agda.Builtin.Int
  Agda.Builtin.List
  Agda.Builtin.Nat
  Agda.Builtin.Reflection
  Agda.Builtin.Size
  Agda.Builtin.Strict
  Agda.Builtin.String
  Agda.Builtin.TrustMe
  Agda.Builtin.Unit
  ```

  The standard library reexports the primitives from the new modules.

  The `Agda.Builtin` modules are installed in the same way as
  `Agda.Primitive`, but unlike `Agda.Primitive` they are not loaded
  automatically.

Pragmas and options
-------------------

* Library management

  There is a new 'library' concept for managing include paths. A library
  consists of
    - a name,
    - a set of libraries it depends on, and
    - a set of include paths.

  A library is defined in a `.agda-lib` file using the following
  format:

  ```
  name: LIBRARY-NAME  -- Comment
  depend: LIB1 LIB2
    LIB3
    LIB4
  include: PATH1
    PATH2
    PATH3
  ```

  Dependencies are library names, not paths to `.agda-lib` files, and
  include paths are relative to the location of the library-file.

  To be useable, a library file has to be listed (with its full path)
  in `AGDA_DIR/libraries` (or `AGDA_DIR/libraries-VERSION`, for a
  given Agda version). `AGDA_DIR` defaults to `~/.agda` on Unix-like
  systems and `C:/Users/USERNAME/AppData/Roaming/agda` or similar on
  Windows, and can be overridden by setting the `AGDA_DIR` environment
  variable.

  Environment variables in the paths (of the form `$VAR` or `${VAR}`)
  are expanded. The location of the libraries file used can be
  overridden using the `--library-file=FILE` flag, although this is
  not expected to be very useful.

  You can find out the precise location of the 'libraries' file by
  calling `agda -l fjdsk Dummy.agda` and looking at the error message
  (assuming you don't have a library called fjdsk installed).

  There are three ways a library gets used:

    - You supply the `--library=LIB` (or `-l LIB`) option to
      Agda. This is equivalent to adding a `-iPATH` for each of the
      include paths of `LIB` and its (transitive) dependencies.

    - No explicit `--library` flag is given, and the current project
      root (of the Agda file that is being loaded) or one of its
      parent directories contains a `.agda-lib` file defining a
      library `LIB`. This library is used as if a `--librarary=LIB`
      option had been given, except that it is not necessary for the
      library to be listed in the `AGDA_DIR/libraries` file.

    - No explicit `--library` flag, and no `.agda-lib` file in the
      project root. In this case the file `AGDA_DIR/defaults` is read
      and all libraries listed are added to the path. The defaults
      file should contain a list of library names, each on a separate
      line. In this case the current directory is also added to the
      path.

      To disable default libraries, you can give the flag
      `--no-default-libraries`.

  Library names can end with a version number (for instance,
  `mylib-1.2.3`). When resolving a library name (given in a `--library`
  flag, or listed as a default library or library dependency) the
  following rules are followed:

    - If you don't give a version number, any version will do.

    - If you give a version number an exact match is required.

    - When there are multiple matches an exact match is preferred, and
      otherwise the latest matching version is chosen.

  For example, suppose you have the following libraries installed:
  `mylib`, `mylib-1.0`, `otherlib-2.1`, and `otherlib-2.3`. In this
  case, aside from the exact matches you can also say
  `--library=otherlib` to get `otherlib-2.3`.

* New Pragma `COMPILED_DECLARE_DATA` for binding recursively defined
  Haskell data types to recursively defined Agda data types.

  If you have a Haskell type like

  ```haskell
  {-# LANGUAGE GADTs #-}

  module Issue223 where

  data A where
    BA :: B -> A

  data B where
    AB :: A -> B
    BB :: B
  ```

  You can now bind it to corresponding mutual Agda inductive data
  types as follows:

  ```agda
  {-# IMPORT Issue223 #-}

  data A : Set
  {-# COMPILED_DECLARE_DATA A Issue223.A #-}
  data B : Set
  {-# COMPILED_DECLARE_DATA B Issue223.B #-}

  data A where
    BA : B → A

  {-# COMPILED_DATA A Issue223.A Issue223.BA #-}
  data B where
    AB : A → B
    BB : B

  {-# COMPILED_DATA B Issue223.B Issue223.AB Issue223.BB #-}
  ```

  This fixes Issue [#223](https://github.com/agda/agda/issues/223).

* New pragma `HASKELL` for adding inline Haskell code (GHC backend only)

  Arbitrary Haskell code can be added to a module using the `HASKELL`
  pragma. For instance,

  ```agda
  {-# HASKELL
    echo :: IO ()
    echo = getLine >>= putStrLn
  #-}

  postulate echo : IO ⊤
  {-# COMPILED echo echo #-}
  ```

* New option `--exact-split`.

  The `--exact-split` flag causes Agda to raise an error whenever a
  clause in a definition by pattern matching cannot be made to hold
  definitionally (i.e. as a reduction rule). Specific clauses can be
  excluded from this check by means of the `{-# CATCHALL #-}` pragma.

  For instance, the following definition will be rejected as the second clause
  cannot be made to hold definitionally:

  ```agda
  min : Nat → Nat → Nat
  min zero    y       = zero
  min x       zero    = zero
  min (suc x) (suc y) = suc (min x y
  ```

  Catchall clauses have to be marked as such, for instance:

  ```agda
  eq : Nat → Nat → Bool
  eq zero    zero    = true
  eq (suc m) (suc n) = eq m n
  {-# CATCHALL #-}
  eq _       _       = false
  ```

* New option: `--no-exact-split`.

  This option can be used to override a global `--exact-split` in a
  file, by adding a pragma `{-# OPTIONS --no-exact-split #-}`.

* New options: `--sharing` and `--no-sharing`.

  These options are used to enable/disable sharing and call-by-need
  evaluation.  The default is `--no-sharing`.

  Note that they cannot appear in an OPTIONS pragma, but have to be
  given as command line arguments or added to the Agda Program Args
  from Emacs with `M-x customize-group agda2`.

* New pragma `DISPLAY`.

  ```agda
  {-# DISPLAY f e1 .. en = e #-}
  ```

  This causes `f e1 .. en` to be printed in the same way as `e`, where
  `ei` can bind variables used in `e`. The expressions `ei` and `e`
  are scope checked, but not type checked.

  For example this can be used to print overloaded (instance) functions with
  the overloaded name:

  ```agda
  instance
    NumNat : Num Nat
    NumNat = record { ..; _+_ = natPlus }

  {-# DISPLAY natPlus a b = a + b #-}
  ```

  Limitations

  - Left-hand sides are restricted to variables, constructors, defined
    functions or types, and literals. In particular, lambdas are not
    allowed in left-hand sides.

  - Since `DISPLAY` pragmas are not type checked implicit argument
    insertion may not work properly if the type of `f` computes to an
    implicit function space after pattern matching.

* Removed pragma `{-# ETA R #-}`

  The pragma `{-# ETA R #-}` is replaced by the `eta-equality` directive
  inside record declarations.

* New option `--no-eta-equality`.

  The `--no-eta-equality` flag disables eta rules for declared record
  types.  It has the same effect as `no-eta-equality` inside each
  declaration of a record type `R`.

  If used with the OPTIONS pragma it will not affect records defined
  in other modules.

* The semantics of `{-# REWRITE r #-}` pragmas in parametrized modules
  has changed (see
  Issue [#1652](https://github.com/agda/agda/issues/1652)).

  Rewrite rules are no longer lifted to the top context. Instead, they
  now only apply to terms in (extensions of) the module context. If
  you want the old behaviour, you should put the `{-# REWRITE r #-}`
  pragma outside of the module (i.e. unindent it).

* New pragma `{-# INLINE f #-}` causes `f` to be inlined during
  compilation.

* The `STATIC` pragma is now taken into account during compilation.

  Calls to a function marked `STATIC` are normalised before
  compilation. The typical use case for this is to mark the
  interpreter of an embedded language as `STATIC`.

* Option `--type-in-type` no longer implies
  `--no-universe-polymorphism`, thus, it can be used with explicit
  universe
  levels. [Issue [#1764](https://github.com/agda/agda/issues/1764)] It
  simply turns off error reporting for any level mismatch now.
  Examples:

  ```agda
  {-# OPTIONS --type-in-type #-}

  Type : Set
  Type = Set

  data D {α} (A : Set α) : Set where
    d : A → D A

  data E α β : Set β where
    e : Set α → E α β
  ```

* New `NO_POSITIVITY_CHECK` pragma to switch off the positivity checker
  for data/record definitions and mutual blocks.

  The pragma must precede a data/record definition or a mutual block.

  The pragma cannot be used in `--safe` mode.

  Examples (see `Issue1614*.agda` and `Issue1760*.agda` in
  `test/Succeed/`):

  1. Skipping a single data definition.

     ```agda
     {-# NO_POSITIVITY_CHECK #-}
     data D : Set where
       lam : (D → D) → D
     ```

  2. Skipping a single record definition.

     ```agda
     {-# NO_POSITIVITY_CHECK #-}
     record U : Set where
       field ap : U → U
     ```

  3. Skipping an old-style mutual block: Somewhere within a `mutual`
     block before a data/record definition.

     ```agda
     mutual
       data D : Set where
         lam : (D → D) → D

       {-# NO_POSITIVITY_CHECK #-}
       record U : Set where
         field ap : U → U
     ```

  4. Skipping an old-style mutual block: Before the `mutual` keyword.

     ```agda
     {-# NO_POSITIVITY_CHECK #-}
     mutual
       data D : Set where
         lam : (D → D) → D

       record U : Set where
         field ap : U → U
     ```

  5. Skipping a new-style mutual block: Anywhere before the
     declaration or the definition of data/record in the block.

     ```agda
     record U : Set
     data D   : Set

     record U where
       field ap : U → U

     {-# NO_POSITIVITY_CHECK #-}
     data D where
       lam : (D → D) → D
     ```

* Removed `--no-coverage-check`
  option. [Issue [#1918](https://github.com/agda/agda/issues/1918)]

Language
--------

### Operator syntax

* The default fixity for syntax declarations has changed from -666 to 20.

* Sections.

  Operators can be sectioned by replacing arguments with underscores.
  There must not be any whitespace between these underscores and the
  adjacent nameparts. Examples:

  ```agda
  pred : ℕ → ℕ
  pred = _∸ 1

  T : Bool → Set
  T = if_then ⊤ else ⊥

  if : {A : Set} (b : Bool) → A → A → A
  if b = if b then_else_
  ```

  Sections are translated into lambda expressions. Examples:

  ```agda
  _∸ 1              ↦  λ section → section ∸ 1

  if_then ⊤ else ⊥  ↦  λ section → if section then ⊤ else ⊥

  if b then_else_   ↦  λ section section₁ →
                           if b then section else section₁
  ```

  Operator sections have the same fixity as the underlying operator
  (except in cases like `if b then_else_`, in which the section is
  "closed", but the operator is not).

  Operator sections are not supported in patterns (with the exception
  of dot patterns), and notations coming from syntax declarations
  cannot be sectioned.

* A long-standing operator fixity bug has been fixed. As a consequence
  some programs that used to parse no longer do.

  Previously each precedence level was (incorrectly) split up into
  five separate ones, ordered as follows, with the earlier ones
  binding less tightly than the later ones:

    - Non-associative operators.

    - Left associative operators.

    - Right associative operators.

    - Prefix operators.

    - Postfix operators.

  Now this problem has been addressed. It is no longer possible to mix
  operators of a given precedence level but different associativity.
  However, prefix and right associative operators are seen as having
  the same associativity, and similarly for postfix and left
  associative operators.

  Examples
  --------

  The following code is no longer accepted:

  ```agda
  infixl 6 _+_
  infix  6 _∸_

  rejected : ℕ
  rejected = 1 + 0 ∸ 1
  ```

  However, the following previously rejected code is accepted:

  ```agda
  infixr 4 _,_
  infix  4 ,_

  ,_ : {A : Set} {B : A → Set} {x : A} → B x → Σ A B
  , y = _ , y

  accepted : Σ ℕ λ i → Σ ℕ λ j → Σ (i ≡ j) λ _ → Σ ℕ λ k → j ≡ k
  accepted = 5 , , refl , , refl
  ```

* The classification of notations with binders into the categories
  infix, prefix, postfix or closed has
  changed. [Issue [#1450](https://github.com/agda/agda/issues/1450)]

  The difference is that, when classifying the notation, only
  *regular* holes are taken into account, not *binding* ones.

  Example: The notation

  ```agda
  syntax m >>= (λ x → f) = x <- m , f
  ```

  was previously treated as infix, but is now treated as prefix.

* Notation can now include wildcard binders.

  Example: `syntax Σ A (λ _ → B) = A × B`

* If an overloaded operator is in scope with several distinct
  precedence levels, then several instances of this operator will be
  included in the operator grammar, possibly leading to ambiguity.
  Previously the operator was given the default fixity
  [Issue [#1436](https://github.com/agda/agda/issues/1436)].

  There is an exception to this rule: If there are multiple precedences,
  but at most one is explicitly declared, then only one instance will be
  included in the grammar. If there are no explicitly declared
  precedences, then this instance will get the default precedence, and
  otherwise it will get the declared precedence.

  If multiple occurrences of an operator are "merged" in the grammar,
  and they have distinct associativities, then they are treated as
  being non-associative.

  The three paragraphs above also apply to identical notations (coming
  from syntax declarations) for a given overloaded name.

  Examples:

  ```agda
  module A where

    infixr 5 _∷_
    infixr 5 _∙_
    infixl 3 _+_
    infix  1 bind

    syntax bind c (λ x → d) = x ← c , d

  module B where

    infix  5 _∷_
    infixr 4 _∙_
    -- No fixity declaration for _+_.
    infixl 2 bind

    syntax bind c d = c ∙ d

  module C where

    infixr 2 bind

    syntax bind c d = c ∙ d

  open A
  open B
  open C

  -- _∷_ is infix 5.
  -- _∙_ has two fixities: infixr 4 and infixr 5.
  -- _+_ is infixl 3.
  -- A.bind's notation is infix 1.
  -- B.bind and C.bind's notations are infix 2.

  -- There is one instance of "_ ∷ _" in the grammar, and one
  -- instance of "_ + _".

  -- There are three instances of "_ ∙ _" in the grammar, one
  -- corresponding to A._∙_, one corresponding to B._∙_, and one
  -- corresponding to both B.bind and C.bind.
  ```

### Reflection

* The reflection framework has received a massive overhaul.

  A new type of reflected type checking computations supplants most of
  the old reflection primitives. The `quoteGoal`, `quoteContext` and
  tactic primitives are deprecated and will be removed in the future,
  and the `unquoteDecl` and `unquote` primitives have changed
  behaviour. Furthermore the following primitive functions have been
  replaced by builtin type checking computations:

  ```agda
  - primQNameType              --> AGDATCMGETTYPE
  - primQNameDefinition        --> AGDATCMGETDEFINITION
  - primDataConstructors       --> subsumed by AGDATCMGETDEFINITION
  - primDataNumberOfParameters --> subsumed by AGDATCMGETDEFINITION
  ```

  See below for details.

* Types are no longer packaged with a sort.

  The `AGDATYPE` and `AGDATYPEEL` built-ins have been
  removed. Reflected types are now simply terms.

* Reflected definitions have more information.

  The type for reflected definitions has changed to

  ```agda
  data Definition : Set where
    fun-def     : List Clause  → Definition
    data-type   : Nat → List Name → Definition -- parameters and constructors
    record-type : Name → Definition            -- name of the data/record type
    data-con    : Name → Definition            -- name of the constructor
    axiom       : Definition
    prim-fun    : Definition
  ```

  Correspondingly the built-ins for function, data and record
  definitions (`AGDAFUNDEF`, `AGDAFUNDEFCON`, `AGDADATADEF`,
  `AGDARECORDDEF`) have been removed.

* Reflected type checking computations.

  There is a primitive `TC` monad representing type checking
  computations. The `unquote`, `unquoteDecl`, and the new `unquoteDef`
  all expect computations in this monad (see below). The interface to
  the monad is the following

  ```agda
  -- Error messages can contain embedded names and terms.
  data ErrorPart : Set where
    strErr  : String → ErrorPart
    termErr : Term → ErrorPart
    nameErr : Name → ErrorPart

  {-# BUILTIN AGDAERRORPART       ErrorPart #-}
  {-# BUILTIN AGDAERRORPARTSTRING strErr    #-}
  {-# BUILTIN AGDAERRORPARTTERM   termErr   #-}
  {-# BUILTIN AGDAERRORPARTNAME   nameErr   #-}

  postulate
    TC         : ∀ {a} → Set a → Set a
    returnTC   : ∀ {a} {A : Set a} → A → TC A
    bindTC     : ∀ {a b} {A : Set a} {B : Set b} → TC A → (A → TC B) → TC B

    -- Unify two terms, potentially solving metavariables in the process.
    unify      : Term → Term → TC ⊤

    -- Throw a type error. Can be caught by catchTC.
    typeError  : ∀ {a} {A : Set a} → List ErrorPart → TC A

    -- Block a type checking computation on a metavariable. This will abort
    -- the computation and restart it (from the beginning) when the
    -- metavariable is solved.
    blockOnMeta : ∀ {a} {A : Set a} → Meta → TC A

    -- Backtrack and try the second argument if the first argument throws a
    -- type error.
    catchTC    : ∀ {a} {A : Set a} → TC A → TC A → TC A

    -- Infer the type of a given term
    inferType  : Term → TC Type

    -- Check a term against a given type. This may resolve implicit arguments
    -- in the term, so a new refined term is returned. Can be used to create
    -- new metavariables: newMeta t = checkType unknown t
    checkType  : Term → Type → TC Term

    -- Compute the normal form of a term.
    normalise  : Term → TC Term

    -- Get the current context.
    getContext : TC (List (Arg Type))

    -- Extend the current context with a variable of the given type.
    extendContext : ∀ {a} {A : Set a} → Arg Type → TC A → TC A

    -- Set the current context.
    inContext     : ∀ {a} {A : Set a} → List (Arg Type) → TC A → TC A

    -- Quote a value, returning the corresponding Term.
    quoteTC : ∀ {a} {A : Set a} → A → TC Term

    -- Unquote a Term, returning the corresponding value.
    unquoteTC : ∀ {a} {A : Set a} → Term → TC A

    -- Create a fresh name.
    freshName  : String → TC QName

    -- Declare a new function of the given type. The function must be defined
    -- later using 'defineFun'. Takes an Arg Name to allow declaring instances
    -- and irrelevant functions. The Visibility of the Arg must not be hidden.
    declareDef : Arg QName → Type → TC ⊤

    -- Define a declared function. The function may have been declared using
    -- 'declareDef' or with an explicit type signature in the program.
    defineFun  : QName → List Clause → TC ⊤

    -- Get the type of a defined name. Replaces 'primQNameType'.
    getType    : QName → TC Type

    -- Get the definition of a defined name. Replaces 'primQNameDefinition'.
    getDefinition : QName → TC Definition

  {-# BUILTIN AGDATCM                   TC                 #-}
  {-# BUILTIN AGDATCMRETURN             returnTC           #-}
  {-# BUILTIN AGDATCMBIND               bindTC             #-}
  {-# BUILTIN AGDATCMUNIFY              unify              #-}
  {-# BUILTIN AGDATCMNEWMETA            newMeta            #-}
  {-# BUILTIN AGDATCMTYPEERROR          typeError          #-}
  {-# BUILTIN AGDATCMBLOCKONMETA        blockOnMeta        #-}
  {-# BUILTIN AGDATCMCATCHERROR         catchTC            #-}
  {-# BUILTIN AGDATCMINFERTYPE          inferType          #-}
  {-# BUILTIN AGDATCMCHECKTYPE          checkType          #-}
  {-# BUILTIN AGDATCMNORMALISE          normalise          #-}
  {-# BUILTIN AGDATCMGETCONTEXT         getContext         #-}
  {-# BUILTIN AGDATCMEXTENDCONTEXT      extendContext      #-}
  {-# BUILTIN AGDATCMINCONTEXT          inContext          #-}
  {-# BUILTIN AGDATCMQUOTETERM          quoteTC            #-}
  {-# BUILTIN AGDATCMUNQUOTETERM        unquoteTC          #-}
  {-# BUILTIN AGDATCMFRESHNAME          freshName          #-}
  {-# BUILTIN AGDATCMDECLAREDEF         declareDef         #-}
  {-# BUILTIN AGDATCMDEFINEFUN          defineFun          #-}
  {-# BUILTIN AGDATCMGETTYPE            getType            #-}
  {-# BUILTIN AGDATCMGETDEFINITION      getDefinition      #-}
  ```

* Builtin type for metavariables

  There is a new builtin type for metavariables used by the new reflection
  framework. It is declared as follows and comes with primitive equality,
  ordering and show.

  ```agda
  postulate Meta : Set
  {-# BUILTIN AGDAMETA Meta #-}
  primitive primMetaEquality : Meta → Meta → Bool
  primitive primMetaLess : Meta → Meta → Bool
  primitive primShowMeta : Meta → String
  ```

  There are corresponding new constructors in the `Term` and `Literal`
  data types:

  ```agda
  data Term : Set where
    ...
    meta : Meta → List (Arg Term) → Term

  {-# BUILTIN AGDATERMMETA meta #-}

  data Literal : Set where
    ...
    meta : Meta → Literal

  {-# BUILTIN AGDALITMETA meta #-}
  ```

* Builtin unit type

  The type checker needs to know about the unit type, which you can
  allow by

  ```agda
  record ⊤ : Set where
  {-# BUILTIN UNIT ⊤ #-}
  ```

* Changed behaviour of `unquote`

  The `unquote` primitive now expects a type checking computation
  instead of a pure term. In particular `unquote e` requires

  ```agda
  e : Term → TC ⊤
  ```

  where the argument is the representation of the hole in which the
  result should go. The old `unquote` behaviour (where `unquote`
  expected a `Term` argument) can be recovered by

  ```agda
  OLD: unquote v
  NEW: unquote λ hole → unify hole v
  ```

* Changed behaviour of `unquoteDecl`

  The `unquoteDecl` primitive now expects a type checking computation
  instead of a pure function definition. It is possible to define
  multiple (mutually recursive) functions at the same time. More
  specifically

  ```agda
  unquoteDecl x₁ .. xₙ = m
  ```

  requires `m : TC ⊤` and that `x₁ .. xₙ` are defined (using
  `declareDef` and `defineFun`) after executing `m`. As before `x₁
  .. xₙ : QName` in `m`, but have their declared types outside the
  `unquoteDecl`.

* New primitive `unquoteDef`

  There is a new declaration

  ```agda
  unquoteDef x₁ .. xₙ = m
  ```

  This works exactly as `unquoteDecl` (see above) with the exception
  that `x₁ ..  xₙ` are required to already be declared.

  The main advantage of `unquoteDef` over `unquoteDecl` is that
  `unquoteDef` is allowed in mutual blocks, allowing mutually
  recursion between generated definitions and hand-written
  definitions.

* The reflection interface now exposes the name hint (as a string)
  for variables. As before, the actual binding structure is with
  de Bruijn indices. The String value is just a hint used as a prefix
  to help display the variable. The type `Abs` is a new builtin type used
  for the constructors `Term.lam`, `Term.pi`, `Pattern.var`
  (bultins `AGDATERMLAM`, `AGDATERMPI` and `AGDAPATVAR`).

  ```agda
  data Abs (A : Set) : Set where
    abs : (s : String) (x : A) → Abs A
  {-# BUILTIN ABS    Abs #-}
  {-# BUILTIN ABSABS abs #-}
  ```

  Updated constructor types:

  ```agda
  Term.lam    : Hiding   → Abs Term → Term
  Term.pi     : Arg Type → Abs Type → Term
  Pattern.var : String   → Pattern
  ```

* Reflection-based macros

  Macros are functions of type `t1 → t2 → .. → Term → TC ⊤` that are
  defined in a `macro` block. Macro application is guided by the type
  of the macro, where `Term` arguments desugar into the `quoteTerm`
  syntax and `Name` arguments into the `quote` syntax. Arguments of
  any other type are preserved as-is. The last `Term` argument is the
  hole term given to `unquote` computation (see above).

  For example, the macro application `f u v w` where the macro `f` has
  the type `Term → Name → Bool → Term → TC ⊤` desugars into `unquote
  (f (quoteTerm u) (quote v) w)`

  Limitations:

    - Macros cannot be recursive. This can be worked around by defining the
      recursive function outside the macro block and have the macro call the
      recursive function.

  Silly example:

  ```agda
  macro
    plus-to-times : Term → Term → TC ⊤
    plus-to-times (def (quote _+_) (a ∷ b ∷ [])) hole = unify hole (def (quote _*_) (a ∷ b ∷ []))
    plus-to-times v hole = unify hole v

  thm : (a b : Nat) → plus-to-times (a + b) ≡ a * b
  thm a b = refl
  ```

  Macros are most useful when writing tactics, since they let you hide the
  reflection machinery. For instance, suppose you have a solver

  ```agda
  magic : Type → Term
  ```

  that takes a reflected goal and outputs a proof (when successful). You can
  then define the following macro

  ```agda
  macro
    by-magic : Term → TC ⊤
    by-magic hole =
      bindTC (inferType hole) λ goal →
      unify hole (magic goal)
  ```

  This lets you apply the magic tactic without any syntactic noise at all:

  ```agda
  thm : ¬ P ≡ NP
  thm = by-magic
  ```

### Literals and built-ins

* Overloaded number literals.

  You can now overload natural number literals using the new builtin
  `FROMNAT`:

  ```agda
  {-# BUILTIN FROMNAT fromNat #-}
  ```

  The target of the builtin should be a defined name. Typically you would do
  something like

  ```agda
  record Number (A : Set) : Set where
    field fromNat : Nat → A

  open Number {{...}} public

  {-# BUILTIN FROMNAT fromNat #-}
  ```

  This will cause number literals `n` to be desugared to `fromNat n`
  before type checking.

* Negative number literals.

  Number literals can now be negative. For floating point literals it
  works as expected. For integer literals there is a new builtin
  `FROMNEG` that enables negative integer literals:

  ```agda
  {-# BUILTIN FROMNEG fromNeg #-}
  ```

  This causes negative literals `-n` to be desugared to `fromNeg n`.

* Overloaded string literals.

  String literals can be overladed using the `FROMSTRING` builtin:

  ```agda
  {-# BUILTIN FROMSTRING fromString #-}
  ```

  The will cause string literals `s` to be desugared to `fromString s`
  before type checking.

* Change to builtin integers.

  The `INTEGER` builtin now needs to be bound to a datatype with two
  constructors that should be bound to the new builtins `INTEGERPOS`
  and `INTEGERNEGSUC` as follows:

  ```agda
  data Int : Set where
    pos    : Nat -> Int
    negsuc : Nat -> Int
  {-# BUILTIN INTEGER       Int    #-}
  {-# BUILTIN INTEGERPOS    pos    #-}
  {-# BUILTIN INTEGERNEGSUC negsuc #-}
  ```

  where `negsuc n` represents the integer `-n - 1`. For instance, `-5`
  is represented as `negsuc 4`. All primitive functions on integers
  except `primShowInteger` have been removed, since these can be
  defined without too much trouble on the above representation using
  the corresponding functions on natural numbers.

  The primitives that have been removed are

  ```agda
  primIntegerPlus
  primIntegerMinus
  primIntegerTimes
  primIntegerDiv
  primIntegerMod
  primIntegerEquality
  primIntegerLess
  primIntegerAbs
  primNatToInteger
  ```

* New primitives for strict evaluation

  ```agda
  primitive
    primForce      : ∀ {a b} {A : Set a} {B : A → Set b} (x : A) → (∀ x → B x) → B x
    primForceLemma : ∀ {a b} {A : Set a} {B : A → Set b} (x : A) (f : ∀ x → B x) → primForce x f ≡ f x
  ```

  `primForce x f` evaluates to `f x` if x is in weak head normal form,
  and `primForceLemma x f` evaluates to `refl` in the same
  situation. The following values are considered to be in weak head
  normal form:

    - constructor applications
    - literals
    - lambda abstractions
    - type constructor (data/record types) applications
    - function types
    - Set a

### Modules

* Modules in import directives

  When you use `using`/`hiding`/`renaming` on a name it now
  automatically applies to any module of the same name, unless you
  explicitly mention the module. For instance,

  ```agda
  open M using (D)
  ```

  is equivalent to

  ```agda
  open M using (D; module D)
  ```

  if `M` defines a module `D`. This is most useful for record and data
  types where you always get a module of the same name as the type.

  With this feature there is no longer useful to be able to qualify a
  constructor (or field) by the name of the data type even when it
  differs from the name of the corresponding module. The follow
  (weird) code used to work, but doesn't work anymore:

  ```agda
  module M where
    data D where
      c : D
  open M using (D) renaming (module D to MD)
  foo : D
  foo = D.c
  ```

  If you want to import only the type name and not the module you have to hide
  it explicitly:

  ```agda
  open M using (D) hiding (module D)
  ```

  See discussion on
  Issue [#836](https://github.com/agda/agda/issues/836).

* Private definitions of a module are no longer in scope at the Emacs
  mode top-level.

  The reason for this change is that `.agdai-files` are stripped of
  unused private definitions (which can yield significant performance
  improvements for module-heavy code).

  To test private definitions you can create a hole at the bottom of
  the module, in which private definitions will be visible.

### Records

* New record directives `eta-equality`/`no-eta-equality`

  The keywords `eta-equality`/`no-eta-equality` enable/disable eta
  rules for the (inductive) record type being declared.

  ```agda
  record Σ (A : Set) (B : A -> Set) : Set where
    no-eta-equality
    constructor _,_
    field
      fst : A
      snd : B fst
  open Σ

  -- fail : ∀ {A : Set}{B : A -> Set} → (x : Σ A B) → x ≡ (fst x , snd x)
  -- fail x = refl
  --
  -- x != fst x , snd x of type Σ .A .B
  -- when checking that the expression refl has type x ≡ (fst x , snd x)
  ```

* Building records from modules.

  The `record { <fields> }` syntax is now extended to accept module
  names as well. Fields are thus defined using the corresponding
  definitions from the given module.

  For instance assuming this record type `R` and module `M`:

  ```agda
  record R : Set where
    field
      x : X
      y : Y
      z : Z

  module M where
    x = {! ... !}
    y = {! ... !}

  r : R
  r = record { M; z = {! ... !} }
  ```

  Previously one had to write `record { x = M.x; y = M.y; z = {! ... !} }`.

  More precisely this construction now supports any combination of explicit
  field definitions and applied modules.

  If a field is both given explicitly and available in one of the modules,
  then the explicit one takes precedence.

  If a field is available in more than one module then this is ambiguous
  and therefore rejected. As a consequence the order of assignments does
  not matter.

  The modules can be both applied to arguments and have import directives
  such as `hiding`, `using`, and `renaming`. In particular this construct
  subsumes the record update construction.

  Here is an example of record update:

  ```agda
  -- Record update. Same as: record r { y = {! ... !} }
  r2 : R
  r2 = record { R r; y = {! ... !} }
  ```

  A contrived example showing the use of `hiding`/`renaming`:

  ```agda
  module M2 (a : A) where
    w = {! ... !}
    z = {! ... !}

  r3 : A → R
  r3 a = record { M hiding (y); M2 a renaming (w to y) }
  ```

* Record patterns are now accepted.

  Examples:

  ```agda
  swap : {A B : Set} (p : A × B) → B × A
  swap record{ proj₁ = a; proj₂ = b } = record{ proj₁ = b; proj₂ = a }

  thd3 : ...
  thd3 record{ proj₂ = record { proj₂ = c }} = c
  ```

* Record modules now properly hide all their parameters
  [Issue [#1759](https://github.com/agda/agda/issues/1759)]

  Previously parameters to parent modules were not hidden in the record
  module, resulting in different behaviour between

  ```agda
  module M (A : Set) where
    record R (B : Set) : Set where
  ```

  and

  ```agda
  module M where
    record R (A B : Set) : Set where
  ```

  where in the former case, `A` would be an explicit argument to the module
  `M.R`, but implicit in the latter case. Now `A` is implicit in both cases.

### Instance search

* Performance has been improved, recursive instance search which was
  previously exponential in the depth is now only quadratic.

* Constructors of records and datatypes are not anymore automatically
  considered as instances, you have to do so explicitely, for
  instance:

  ```agda
  -- only [b] is an instance of D
  data D : Set where
    a : D
    instance
      b : D
    c : D

  -- the constructor is now an instance
  record tt : Set where
    instance constructor tt
  ```

* Lambda-bound variables are no longer automatically considered
  instances.

  Lambda-bound variables need to be bound as instance arguments to be
  considered for instance search. For example,

  ```agda
  _==_ : {A : Set} {{_ : Eq A}} → A → A → Bool

  fails : {A : Set} → Eq A → A → Bool
  fails eqA x = x == x

  works : {A : Set} {{_ : Eq A}} → A → Bool
  works x = x == x
  ```

* Let-bound variables are no longer automatically considered
  instances.

  To make a let-bound variable available as an instance it needs to be
  declared with the `instance` keyword, just like top-level
  instances. For example,

  ```agda
  mkEq : {A : Set} → (A → A → Bool) → Eq A

  fails : {A : Set} → (A → A → Bool) → A → Bool
  fails eq x = let eqA = mkEq eq in x == x

  works : {A : Set} → (A → A → Bool) → A → Bool
  works eq x = let instance eqA = mkEq eq in x == x
  ```

* Record fields can be declared instances.

  For example,

  ```agda
  record EqSet : Set₁ where
    field
      set : Set
      instance eq : Eq set
  ```

  This causes the projection function `eq : (E : EqSet) → Eq (set E)`
  to be considered for instance search.

* Instance search can now find arguments in variable types (but such
  candidates can only be lambda-bound variables, they can’t be
  declared as instances)

  ```agda
  module _ {A : Set} (P : A → Set) where

    postulate
      bla : {x : A} {{_ : P x}} → Set → Set

    -- Works, the instance argument is found in the context
    test :  {x : A} {{_ : P x}} → Set → Set
    test B = bla B

    -- Still forbidden, because [P] could be instantiated later to anything
    instance
     postulate
      forbidden : {x : A} → P x
  ```

* Instance search now refuses to solve constraints with unconstrained
  metavariables, since this can lead to non-termination.

  See [Issue [#1532](https://github.com/agda/agda/issues/1523)] for an
  example.

* Top-level instances are now only considered if they are in
  scope. [Issue [#1913](https://github.com/agda/agda/issues/1913)]

  Note that lambda-bound instances need not be in scope.

### Other changes

* Unicode ellipsis character is allowed for the ellipsis token `...`
  in `with` expressions.

* `Prop` is no longer a reserved word.

Type checking
-------------

* Large indices.

  Force constructor arguments no longer count towards the size of a datatype.
  For instance, the definition of equality below is accepted.

  ```agda
  data _≡_ {a} {A : Set a} : A → A → Set where
    refl : ∀ x → x ≡ x
  ```

  This gets rid of the asymmetry that the version of equality which indexes
  only on the second argument could be small, but not the version above which
  indexes on both arguments.

* Detection of datatypes that satisfy K (i.e. sets)

  Agda will now try to detect datatypes that satisfy K when
  `--without-K` is enabled. A datatype satisfies K when it follows
  these three rules:

  - The types of all non-recursive constructor arguments should satisfy K.

  - All recursive constructor arguments should be first-order.

  - The types of all indices should satisfy K.

  For example, the types `Nat`, `List Nat`, and `x ≡ x` (where `x :
  Nat`) are all recognized by Agda as satisfying K.

* New unifier for case splitting

  The unifier used by Agda for case splitting has been completely
  rewritten. The new unifier takes a much more type-directed approach
  in order to avoid the problems in issues
  [#1406](https://github.com/agda/agda/issues/1406),
  [#1408](https://github.com/agda/agda/issues/1408),
  [#1427](https://github.com/agda/agda/issues/1427), and
  [#1435](https://github.com/agda/agda/issues/1435).

  The new unifier also has eta-equality for record types
  built-in. This should avoid unnecessary case splitting on record
  constructors and improve the performance of Agda on code that
  contains deeply nested record patterns (see issues
  [#473](https://github.com/agda/agda/issues/473),
  [#635](https://github.com/agda/agda/issues/635),
  [#1575](https://github.com/agda/agda/issues/1575),
  [#1603](https://github.com/agda/agda/issues/1603),
  [#1613](https://github.com/agda/agda/issues/1613), and
  [#1645](https://github.com/agda/agda/issues/1645)).

  In some cases, the locations of the dot patterns computed by the
  unifier did not correspond to the locations given by the user (see
  Issue [#1608](https://github.com/agda/agda/issues/1608)). This has
  now been fixed by adding an extra step after case splitting that
  checks whether the user-written patterns are compatible with the
  computed ones.

  In some rare cases, the new unifier is still too restrictive when
  `--without-K` is enabled because it cannot generalize over the
  datatype indices (yet). For example, the following code is rejected:

  ```agda
  data Bar : Set₁ where
    bar : Bar
    baz : (A : Set) → Bar

  data Foo : Bar → Set where
    foo : Foo bar

  test : foo ≡ foo → Set₁
  test refl = Set
  ```

* The aggressive behaviour of `with` introduced in 2.4.2.5 has been
  rolled back
  [Issue [#1692](https://github.com/agda/agda/issues/1692)]. With no
  longer abstracts in the types of variables appearing in the
  with-expressions. [Issue [#745](https://github.com/agda/agda/issues/745)]

  This means that the following example no longer works:

  ```agda
  fails : (f : (x : A) → a ≡ x) (b : A) → b ≡ a
  fails f b with a | f b
  fails f b | .b | refl = f b
  ```

  The `with` no longer abstracts the type of `f` over `a`, since `f`
  appears in the second with-expression `f b`. You can use a nested
  `with` to make this example work.

  This example does work again:

  ```agda
  test : ∀{A : Set}{a : A}{f : A → A} (p : f a ≡ a) → f (f a) ≡ a
  test p rewrite p = p
  ```

  After `rewrite p` the goal has changed to `f a ≡ a`, but the type
  of `p` has not been rewritten, thus, the final `p` solves the goal.

  The following, which worked in 2.4.2.5, no longer works:

  ```agda
  fails : (f : (x : A) → a ≡ x) (b : A) → b ≡ a
  fails f b rewrite f b = f b
  ```

  The rewrite with `f b : a ≡ b` is not applied to `f` as
  the latter is part of the rewrite expression `f b`.  Thus,
  the type of `f` remains untouched, and the changed goal
  `b ≡ b` is not solved by `f b`.

* When using `rewrite` on a term `eq` of type `lhs ≡ rhs`, the `lhs`
  is no longer abstracted in `rhs`
  [Issue [#520](https://github.com/agda/agda/issues/520)].  This means
  that

  ```agda
  f pats rewrite eq = body
  ```

  is more than syntactic sugar for

  ```agda
  f pats with lhs | eq
  f pats | _ | refl = body
  ```

  In particular, the following application of `rewrite` is now
  possible

  ```agda
  id : Bool → Bool
  id true  = true
  id false = false

  is-id : ∀ x → x ≡ id x
  is-id true  = refl
  is-id false = refl

  postulate
    P : Bool → Set
    b : Bool
    p : P (id b)

  proof : P b
  proof rewrite is-id b = p
  ```

  Previously, this was desugared to

  ```agda
  proof with b | is-id b
  proof | _ | refl = p
  ```

  which did not type check as `refl` does not have type `b ≡ id b`.
  Now, Agda gets the task of checking `refl : _ ≡ id b` leading to
  instantiation of `_` to `id b`.

Compiler backends
-----------------

* Major Bug Fixes:

  - Function clauses with different arities are now always compiled
    correctly by the GHC/UHC
    backends. (Issue [#727](https://github.com/agda/agda/issues/727))

* Co-patterns

  - The GHC/UHC backends now support co-patterns. (Issues
    [#1567](https://github.com/agda/agda/issues/1567),
    [#1632](https://github.com/agda/agda/issues/1632))

* Optimizations

  - Builtin naturals are now represented as arbitrary-precision
    Integers. See the user manual, section
    "Agda Compilers -> Optimizations" for details.

* GHC Haskell backend (MAlonzo)

  - Pragmas

    Since builtin naturals are compiled to `Integer` you can no longer
    give a `{-# COMPILED_DATA #-}` pragma for `Nat`. The same goes for
    builtin booleans, integers, floats, characters and strings which
    are now hard-wired to appropriate Haskell types.

* UHC compiler backend

  A new backend targeting the Utrecht Haskell Compiler (UHC) is
  available.  It targets the UHC Core language, and it's design is
  inspired by the Epic backend. See the user manual, section "Agda
  Compilers -> UHC Backend" for installation instructions.

  - FFI

    The UHC backend has a FFI to Haskell similar to MAlonzo's. The
    target Haskell code also needs to be compilable using UHC, which
    does not support the Haskell base library version 4.*.

    FFI pragmas for the UHC backend are not checked in any way. If the
    pragmas are wrong, bad things will happen.

  - Imports

    Additional Haskell modules can be brought into scope with the
    `IMPORT_UHC` pragma:

    ```agda
    {-# IMPORT_UHC Data.Char #-}
    ```

    The Haskell modules `UHC.Base` and `UHC.Agda.Builtins` are always in
    scope and don't need to be imported explicitly.

  - Datatypes

    Agda datatypes can be bound to Haskell datatypes as follows:

    Haskell:
    ```haskell
    data HsData a = HsCon1 | HsCon2 (HsData a)
    ```

    Agda:
    ```agda
    data AgdaData (A : Set) : Set where
      AgdaCon1 : AgdaData A
      AgdaCon2 : AgdaData A -> AgdaData A
    {-# COMPILED_DATA_UHC AgdaData HsData HsCon1 HsCon2 #-}
    ```

    The mapping has to cover all constructors of the used Haskell
    datatype, else runtime behavior is undefined!

    There are special reserved names to bind Agda datatypes to certain
    Haskell datatypes. For example, this binds an Agda datatype to
    Haskell's list datatype:

    Agda:
    ```agda
    data AgdaList (A : Set) : Set where
      Nil : AgdaList A
      Cons : A -> AgdaList A -> AgdaList A
    {-# COMPILED_DATA_UHC AgdaList __LIST__ __NIL__ __CONS__ #-}
    ```

    The following "magic" datatypes are available:

    ```
    HS Datatype | Datatype Pragma | HS Constructor | Constructor Pragma
    ()            __UNIT__          ()               __UNIT__
    List          __LIST__          (:)              __CONS__
                                    []               __NIL__
    Bool          __BOOL__          True             __TRUE__
                                    False            __FALSE__
    ```

  - Functions

    Agda postulates can be bound to Haskell functions. Similar as in
    MAlonzo, all arguments of type `Set` need to be dropped before
    calling Haskell functions. An example calling the return function:

    Agda:
    ```agda
    postulate hs-return : {A : Set} -> A -> IO A
    {-# COMPILED_UHC hs-return (\_ -> UHC.Agda.Builtins.primReturn) #-}
    ```

Emacs mode and interaction
--------------------------

* Module contents (`C-c C-o`) now also works for
  records. [See Issue [#1926](https://github.com/agda/agda/issues/1926) ]
  If you have an inferable expression of record type in an interaction
  point, you can invoke `C-c C-o` to see its fields and types.
  Example

  ```agda
  record R : Set where
    field f : A

  test : R → R
  test r = {!r!}  -- C-c C-o here
  ```

* Less aggressive error notification.

  Previously Emacs could jump to the position of an error even if the
  type-checking process was not initiated in the current buffer. Now
  this no longer happens: If the type-checking process was initiated
  in another buffer, then the cursor is moved to the position of the
  error in the buffer visiting the file (if any) and in every window
  displaying the file, but focus should not change from one file to
  another.

  In the cases where focus does change from one file to another, one
  can now use the go-back functionality to return to the previous
  position.

* Removed the `agda-include-dirs` customization parameter.

  Use `agda-program-args` with `-iDIR` or `-lLIB` instead, or add
  libraries to `~/.agda/defaults`
  (`C:/Users/USERNAME/AppData/Roaming/agda/defaults` or similar on
  Windows). See Library management, above, for more information.

Tools
-----

### LaTeX-backend

* The default font has been changed to XITS (which is part of TeX Live):

    http://www.ctan.org/tex-archive/fonts/xits/

  This font is more complete with respect to Unicode.

### agda-ghc-names

* New tool: The command

  ```
  agda-ghc-names fixprof <compile-dir> <ProgName>.prof
  ```

  converts `*.prof` files obtained from profiling runs of
  MAlonzo-compiled code to `*.agdaIdents.prof`, with the original Agda
  identifiers replacing the MAlonzo-generated Haskell identifiers.

  For usage and more details, see `src/agda-ghc-names/README.txt`.

Highlighting and textual backends
---------------------------------

* Names in import directives are now highlighted and are clickable.
  [Issue [#1714](https://github.com/agda/agda/issues/1714)] This leads
  also to nicer printing in the LaTeX and html backends.

Fixed issues
------------

See
[bug tracker (milestone 2.5.1)](https://github.com/agda/agda/issues?q=milestone%3A2.5.1+is%3Aclosed)

Release notes for Agda version 2.4.2.5
======================================

Installation and infrastructure
-------------------------------

* Added support for GHC 7.10.3.

* Added `cpphs` Cabal flag

  Turn on/off this flag to choose cpphs/cpp as the C preprocessor.

  This flag is turn on by default.

  (This flag was added in Agda 2.4.2.1 but it was not documented)

Pragmas and options
-------------------

* Termination pragmas are no longer allowed inside `where` clauses
  [Issue [#1137](https://github.com/agda/agda/issues/1137)].

Type checking
-------------

* `with`-abstraction is more aggressive, abstracts also in types of
  variables that are used in the `with`-expressions, unless they are
  also used in the types of the
  `with`-expressions. [Issue [#1692](https://github.com/agda/agda/issues/1692)]

  Example:

  ```agda
  test : (f : (x : A) → a ≡ x) (b : A) → b ≡ a
  test f b with a | f b
  test f b | .b | refl = f b
  ```

  Previously, `with` would not abstract in types of variables that
  appear in the `with`-expressions, in this case, both `f` and `b`,
  leaving their types unchanged.  Now, it tries to abstract in `f`, as
  only `b` appears in the types of the `with`-expressions which are
  `A` (of `a`) and `a ≡ b` (of `f b`).  As a result, the type of `f`
  changes to `(x : A) → b ≡ x` and the type of the goal to `b ≡ b` (as
  previously).

  This also affects `rewrite`, which is implemented in terms of
  `with`.

  ```agda
  test : (f : (x : A) → a ≡ x) (b : A) → b ≡ a
  test f b rewrite f b = f b
  ```

  As the new `with` is not fully backwards-compatible, some parts of
  your Agda developments using `with` or `rewrite` might need
  maintenance.

Fixed issues
------------

See [bug tracker](https://github.com/agda/agda/issues)

[#1407](https://github.com/agda/agda/issues/1497)

[#1518](https://github.com/agda/agda/issues/1518)

[#1670](https://github.com/agda/agda/issues/1670)

[#1677](https://github.com/agda/agda/issues/1677)

[#1698](https://github.com/agda/agda/issues/1698)

[#1701](https://github.com/agda/agda/issues/1701)

[#1710](https://github.com/agda/agda/issues/1710)

[#1718](https://github.com/agda/agda/issues/1718)

Release notes for Agda version 2.4.2.4
======================================

Installation and infrastructure
-------------------------------

* Removed support for GHC 7.4.2.

Pragmas and options
-------------------

* Option `--copatterns` is now on by default.  To switch off
  parsing of copatterns, use:

  ```agda
  {-# OPTIONS --no-copatterns #-}
  ```

* Option `--rewriting` is now needed to use `REWRITE` pragmas and
  rewriting during reduction.  Rewriting is not `--safe`.

  To use rewriting, first specify a relation symbol `R` that will
  later be used to add rewrite rules.  A canonical candidate would be
  propositional equality

  ```agda
  {-# BUILTIN REWRITE _≡_ #-}
  ```

  but any symbol `R` of type `Δ → A → A → Set i` for some `A` and `i`
  is accepted.  Then symbols `q` can be added to rewriting provided
  their type is of the form `Γ → R ds l r`.  This will add a rewrite
  rule

  ```
  Γ ⊢ l ↦ r : A[ds/Δ]
  ```

  to the signature, which fires whenever a term is an instance of `l`.
  For example, if

  ```agda
  plus0 : ∀ x → x + 0 ≡ x
  ```

  (ideally, there is a proof for `plus0`, but it could be a
  postulate), then

  ```agda
  {-# REWRITE plus0 #-}
  ```

  will prompt Agda to rewrite any well-typed term of the form `t + 0`
  to `t`.

  Some caveats: Agda accepts and applies rewrite rules naively, it is
  very easy to break consistency and termination of type checking.
  Some examples of rewrite rules that should *not* be added:

  ```agda
  refl     : ∀ x → x ≡ x             -- Agda loops
  plus-sym : ∀ x y → x + y ≡ y + x   -- Agda loops
  absurd   : true ≡ false            -- Breaks consistency
  ```

  Adding only proven equations should at least preserve consistency,
  but this is only a conjecture, so know what you are doing!  Using
  rewriting, you are entering into the wilderness, where you are on
  your own!

Language
--------

* `forall` / `∀` now parses like `λ`, i.e., the following parses now
  [Issue [#1583](https://github.com/agda/agda/issues/1538)]:

  ```agda
  ⊤ × ∀ (B : Set) → B → B
  ```

* The underscore pattern `_` can now also stand for an inaccessible
  pattern (dot pattern). This alleviates the need for writing `._`.
  [Issue #[1605](https://github.com/agda/agda/issues/1605)] Instead of

  ```agda
  transVOld : ∀{A : Set} (a b c : A) → a ≡ b → b ≡ c → a ≡ c
  transVOld _ ._ ._ refl refl = refl
  ```

  one can now write

  ```agda
    transVNew : ∀{A : Set} (a b c : A) → a ≡ b → b ≡ c → a ≡ c
    transVNew _ _ _ refl refl = refl
  ```

  and let Agda decide where to put the dots.  This was always possible
  by using hidden arguments

  ```agda
  transH : ∀{A : Set}{a b c : A} → a ≡ b → b ≡ c → a ≡ c
  transH refl refl = refl
  ```

  which is now equivalent to

  ```agda
  transHNew : ∀{A : Set}{a b c : A} → a ≡ b → b ≡ c → a ≡ c
  transHNew {a = _}{b = _}{c = _} refl refl = refl
  ```

  Before, underscore `_` stood for an unnamed variable that could not
  be instantiated by an inaccessible pattern.  If one no wants to
  prevent Agda from instantiating, one needs to use a variable name
  other than underscore (however, in practice this situation seems
  unlikely).

Type checking
-------------

* Polarity of phantom arguments to data and record types has
  changed. [Issue [#1596](https://github.com/agda/agda/issues/1596)]
  Polarity of size arguments is Nonvariant (both monotone and
  antitone).  Polarity of other arguments is Covariant (monotone).
  Both were Invariant before (neither monotone nor antitone).

  The following example type-checks now:

  ```agda
  open import Common.Size

  -- List should be monotone in both arguments
  -- (even when `cons' is missing).

  data List (i : Size) (A : Set) : Set where
    [] : List i A

  castLL : ∀{i A} → List i (List i A) → List ∞ (List ∞ A)
  castLL x = x

  -- Stream should be antitone in the first and monotone in the second argument
  -- (even with field `tail' missing).

  record Stream (i : Size) (A : Set) : Set where
    coinductive
    field
      head : A

  castSS : ∀{i A} → Stream ∞ (Stream ∞ A) → Stream i (Stream i A)
  castSS x = x
  ```

* `SIZELT` lambdas must be consistent
  [Issue [#1523](https://github.com/agda/agda/issues/1523), see Abel
  and Pientka, ICFP 2013].  When lambda-abstracting over type (`Size<
  size`) then `size` must be non-zero, for any valid instantiation of
  size variables.

  - The good:

    ```agda
    data Nat (i : Size) : Set where
      zero : ∀ (j : Size< i) → Nat i
      suc  : ∀ (j : Size< i) → Nat j → Nat i

    {-# TERMINATING #-}
    -- This definition is fine, the termination checker is too strict at the moment.
    fix : ∀ {C : Size → Set}
       → (∀ i → (∀ (j : Size< i) → Nat j -> C j) → Nat i → C i)
       → ∀ i → Nat i → C i
    fix t i (zero j)  = t i (λ (k : Size< i) → fix t k) (zero j)
    fix t i (suc j n) = t i (λ (k : Size< i) → fix t k) (suc j n)
    ```

    The `λ (k : Size< i)` is fine in both cases, as context

    ```agda
    i : Size, j : Size< i
    ```

    guarantees that `i` is non-zero.

  - The bad:

    ```agda
    record Stream {i : Size} (A : Set) : Set where
      coinductive
      constructor _∷ˢ_
      field
        head  : A
        tail  : ∀ {j : Size< i} → Stream {j} A
    open Stream public

    _++ˢ_ : ∀ {i A} → List A → Stream {i} A → Stream {i} A
    []        ++ˢ s = s
    (a ∷ as)  ++ˢ s = a ∷ˢ (as ++ˢ s)
    ```

    This fails, maybe unjustified, at

    ```agda
    i : Size, s : Stream {i} A
      ⊢
        a ∷ˢ (λ {j : Size< i} → as ++ˢ s)
    ```

    Fixed by defining the constructor by copattern matching:

    ```agda
    record Stream {i : Size} (A : Set) : Set where
      coinductive
      field
        head  : A
        tail  : ∀ {j : Size< i} → Stream {j} A
    open Stream public

    _∷ˢ_ : ∀ {i A} → A → Stream {i} A → Stream {↑ i} A
    head  (a ∷ˢ as) = a
    tail  (a ∷ˢ as) = as

    _++ˢ_ : ∀ {i A} → List A → Stream {i} A → Stream {i} A
    []        ++ˢ s = s
    (a ∷ as)  ++ˢ s = a ∷ˢ (as ++ˢ s)
    ```

  - The ugly:

    ```agda
    fix : ∀ {C : Size → Set}
       → (∀ i → (∀ (j : Size< i) → C j) → C i)
       → ∀ i → C i
    fix t i = t i λ (j : Size< i) → fix t j
    ```

    For `i=0`, there is no such `j` at runtime, leading to looping
    behavior.

Interaction
-----------

* Issue [#635](https://github.com/agda/agda/issues/635) has been
  fixed.  Case splitting does not spit out implicit record patterns
  any more.

  ```agda
  record Cont : Set₁ where
    constructor _◃_
    field
      Sh  : Set
      Pos : Sh → Set

  open Cont

  data W (C : Cont) : Set where
    sup : (s : Sh C) (k : Pos C s → W C) → W C

  bogus : {C : Cont} → W C → Set
  bogus w = {!w!}
  ```

  Case splitting on `w` yielded, since the fix of
  Issue [#473](https://github.com/agda/agda/issues/473),

  ```agda
  bogus {Sh ◃ Pos} (sup s k) = ?
  ```

  Now it gives, as expected,

  ```agda
  bogus (sup s k) = ?
  ```

Performance
-----------

* As one result of the 21st Agda Implementor's Meeting (AIM XXI),
  serialization of the standard library is 50% faster (time reduced by
  a third), without using additional disk space for the interface
  files.


Bug fixes
---------

Issues fixed (see [bug tracker](https://github.com/agda/agda/issues)):

[#1546](https://github.com/agda/agda/issues/1546) (copattern matching
and with-clauses)

[#1560](https://github.com/agda/agda/issues/1560) (positivity checker
inefficiency)

[#1584](https://github.com/agda/agda/issues/1548) (let pattern with
trailing implicit)

Release notes for Agda version 2.4.2.3
======================================

Installation and infrastructure
-------------------------------

* Added support for GHC 7.10.1.

* Removed support for GHC 7.0.4.

Language
--------

* `_ `is no longer a valid name for a definition.  The following fails
  now: [Issue [#1465](https://github.com/agda/agda/issues/1465)]

  ```agda
  postulate _ : Set
  ```

* Typed bindings can now contain hiding information
  [Issue [#1391](https://github.com/agda/agda/issues/1391)].  This
  means you can now write

  ```agda
  assoc : (xs {ys zs} : List A) → ((xs ++ ys) ++ zs) ≡ (xs ++ (ys ++ zs))
  ```

  instead of the longer

  ```agda
  assoc : (xs : List A) {ys zs : List A} → ...
  ```

  It also works with irrelevance

  ```agda
  .(xs {ys zs} : List A) → ...
  ```

  but of course does not make sense if there is hiding information already.
  Thus, this is (still) a parse error:

  ```agda
  {xs {ys zs} : List A} → ...
  ```

* The builtins for sized types no longer need accompanying postulates.
  The BUILTIN pragmas for size stuff now also declare the identifiers
  they bind to.

  ```agda
  {-# BUILTIN SIZEUNIV SizeUniv #-}  --  SizeUniv : SizeUniv
  {-# BUILTIN SIZE     Size     #-}  --  Size     : SizeUniv
  {-# BUILTIN SIZELT   Size<_   #-}  --  Size<_   : ..Size → SizeUniv
  {-# BUILTIN SIZESUC  ↑_       #-}  --  ↑_       : Size → Size
  {-# BUILTIN SIZEINF  ∞        #-}  --  ∞       : Size
  ```

  `Size` and `Size<` now live in the new universe `SizeUniv`.  It is
  forbidden to build function spaces in this universe, in order to
  prevent the malicious assumption of a size predecessor

  ```agda
  pred : (i : Size) → Size< i
  ```

  [Issue [#1428](https://github.com/agda/agda/issues/1428)].

* Unambiguous notations (coming from syntax declarations) that resolve
  to ambiguous names are now parsed unambiguously
  [Issue [#1194](https://github.com/agda/agda/issues/1194)].

* If only some instances of an overloaded name have a given associated
  notation (coming from syntax declarations), then this name can only
  be resolved to the given instances of the name, not to other
  instances [Issue [#1194](https://github.com/agda/agda/issues/1194)].

  Previously, if different instances of an overloaded name had
  *different* associated notations, then none of the notations could
  be used. Now all of them can be used.

  Note that notation identity does not only involve the right-hand
  side of the syntax declaration. For instance, the following
  notations are not seen as identical, because the implicit argument
  names are different:

  ```agda
  module A where

    data D : Set where
      c : {x y : D} → D

    syntax c {x = a} {y = b} = a ∙ b

  module B where

    data D : Set where
      c : {y x : D} → D

    syntax c {y = a} {x = b} = a ∙ b
  ```

* If an overloaded operator is in scope with at least two distinct
  fixities, then it gets the default fixity
  [Issue [#1436](https://github.com/agda/agda/issues/1436)].

  Similarly, if two or more identical notations for a given overloaded
  name are in scope, and these notations do not all have the
  same fixity, then they get the default fixity.

Type checking
-------------

* Functions of varying arity can now have with-clauses and use rewrite.

  Example:

  ```agda
  NPred : Nat → Set
  NPred 0       = Bool
  NPred (suc n) = Nat → NPred n

  const : Bool → ∀{n} → NPred n
  const b {0}       = b
  const b {suc n} m = const b {n}

  allOdd : ∀ n → NPred n
  allOdd 0 = true
  allOdd (suc n) m with even m
  ... | true  = const false
  ... | false = allOdd n
  ```

* Function defined by copattern matching can now have `with`-clauses
  and use `rewrite`.

  Example:

  ```agda
  {-# OPTIONS --copatterns #-}

  record Stream (A : Set) : Set where
    coinductive
    constructor delay
    field
      force : A × Stream A
  open Stream

  map : ∀{A B} → (A → B) → Stream A → Stream B
  force (map f s) with force s
  ... | a , as = f a , map f as

  record Bisim {A B} (R : A → B → Set) (s : Stream A) (t : Stream B) : Set where
    coinductive
    constructor ~delay
    field
      ~force : let a , as = force s
                   b , bs = force t
               in  R a b × Bisim R as bs
  open Bisim

  SEq : ∀{A} (s t : Stream A) → Set
  SEq = Bisim (_≡_)

  -- Slightly weird definition of symmetry to demonstrate rewrite.

  ~sym' : ∀{A} {s t : Stream A} → SEq s t → SEq t s
  ~force (~sym' {s = s} {t} p) with force s | force t | ~force p
  ... | a , as | b , bs | r , q rewrite r = refl , ~sym' q
  ```

* Instances can now be defined by copattern
  matching. [Issue [#1413](https://github.com/agda/agda/issues/1413)]
  The following example extends the one in
  [Abel, Pientka, Thibodeau, Setzer, POPL 2013, Section 2.2]:

  ```agda
  {-# OPTIONS --copatterns #-}

  -- The Monad type class

  record Monad (M : Set → Set) : Set1 where
    field
      return : {A : Set}   → A → M A
      _>>=_  : {A B : Set} → M A → (A → M B) → M B
  open Monad {{...}}

  -- The State newtype

  record State (S A : Set) : Set where
    field
      runState : S → A × S
  open State

  -- State is an instance of Monad

  instance
    stateMonad : {S : Set} → Monad (State S)
    runState (return {{stateMonad}} a  ) s  = a , s    -- NEW
    runState (_>>=_  {{stateMonad}} m k) s₀ =          -- NEW
      let a , s₁ = runState m s₀
      in  runState (k a) s₁

  -- stateMonad fulfills the monad laws

  leftId : {A B S : Set}(a : A)(k : A → State S B) →
    (return a >>= k) ≡ k a
  leftId a k = refl

  rightId : {A B S : Set}(m : State S A) →
    (m >>= return) ≡ m
  rightId m = refl

  assoc : {A B C S : Set}(m : State S A)(k : A → State S B)(l : B → State S C) →
     ((m >>= k) >>= l) ≡ (m >>= λ a → k a >>= l)
  assoc m k l = refl
  ```

Emacs mode
----------

* The new menu option `Switch to another version of Agda` tries to do
  what it says.

* Changed feature: Interactively split result.

  [ This is as before: ]
  Make-case (`C-c C-c`) with no variables given tries to split on the
  result to introduce projection patterns.  The hole needs to be of
  record type, of course.

  ```agda
  test : {A B : Set} (a : A) (b : B) → A × B
  test a b = ?
  ```

  Result-splitting `?` will produce the new clauses:

  ```agda
  proj₁ (test a b) = ?
  proj₂ (test a b) = ?
  ```

  [ This has changed: ]
  If hole is of function type, `make-case` will introduce only pattern
  variables (as much as it can).

  ```agda
  testFun : {A B : Set} (a : A) (b : B) → A × B
  testFun = ?
  ```

  Result-splitting `?` will produce the new clause:

  ```agda
  testFun a b = ?
  ```

  A second invocation of `make-case` will then introduce projection
  patterns.

Error messages
--------------

* Agda now suggests corrections of misspelled options, e.g.

  ```agda
  {-# OPTIONS
    --dont-termination-check
    --without-k
    --senf-gurke
    #-}
  ```

  Unrecognized options:

  ```
  --dont-termination-check (did you mean --no-termination-check ?)
  --without-k (did you mean --without-K ?)
  --senf-gurke
  ```

  Nothing close to `--senf-gurke`, I am afraid.

Compiler backends
-----------------

* The Epic backend has been removed
  [Issue [#1481](https://github.com/agda/agda/issues/1481)].

Bug fixes
---------

* Fixed bug with `unquoteDecl` not working in instance blocks
  [Issue [#1491](https://github.com/agda/agda/issues/1491)].

* Other issues fixed (see
  [bug tracker](https://github.com/agda/agda/issues)

  [#1497](https://github.com/agda/agda/issues/1497)

  [#1500](https://github.com/agda/agda/issues/1500)

Release notes for Agda version 2.4.2.2
======================================

Bug fixes
---------

* Compilation on Windows fixed.

* Other issues fixed (see
  [bug tracker](https://github.com/agda/agda/issues))

  [#1332](https://github.com/agda/agda/issues/1322)

  [#1353](https://github.com/agda/agda/issues/1353)

  [#1360](https://github.com/agda/agda/issues/1360)

  [#1366](https://github.com/agda/agda/issues/1366)

  [#1369](https://github.com/agda/agda/issues/1369)

Release notes for Agda version 2.4.2.1
======================================

Pragmas and options
-------------------

* New pragma `{-# TERMINATING #-}` replacing
  `{-# NO_TERMINATION_CHECK #-}`

  Complements the existing pragma `{-# NON_TERMINATING #-}`.  Skips
  termination check for the associated definitions and marks them as
  terminating.  Thus, it is a replacement for `{-#
  NO_TERMINATION_CHECK #-}` with the same semantics.

  You can no longer use pragma `{-# NO_TERMINATION_CHECK #-}` to skip
  the termination check, but must label your definitions as either
  `{-# TERMINATING #-}` or `{-# NON_TERMINATING #-}` instead.

  Note: `{-# OPTION --no-termination-check #-}` labels all your
  definitions as `{-# TERMINATING #-}`, putting you in the danger zone
  of a loop in the type checker.

Language
--------

* Referring to a local variable shadowed by module opening is now an
  error.  Previous behavior was preferring the local over the imported
  definitions. [Issue [#1266](https://github.com/agda/agda/issues/1266)]

  Note that module parameters are locals as well as variables bound by
  λ, dependent function type, patterns, and let.

  Example:

  ```agda
  module M where
    A = Set1

  test : (A : Set) → let open M in A
  ```

  The last `A` produces an error, since it could refer to the local
  variable `A` or to the definition imported from module `M`.

* `with` on a variable bound by a module telescope or a pattern of a
  parent function is now forbidden.
  [Issue [#1342](https://github.com/agda/agda/issues/1342)]

  ```agda
  data Unit : Set where
    unit : Unit

  id : (A : Set) → A → A
  id A a = a

  module M (x : Unit) where

    dx : Unit → Unit
    dx unit = x

    g : ∀ u → x ≡ dx u
    g with x
    g | unit  = id (∀ u → unit ≡ dx u) ?
  ```

  Even though this code looks right, Agda complains about the type
  expression `∀ u → unit ≡ dx u`.  If you ask Agda what should go
  there instead, it happily tells you that it wants `∀ u → unit ≡ dx
  u`. In fact what you do not see and Agda will never show you is that
  the two expressions actually differ in the invisible first argument
  to `dx`, which is visible only outside module `M`.  What Agda wants
  is an invisible `unit` after `dx`, but all you can write is an
  invisible `x` (which is inserted behind the scenes).

  To avoid those kinds of paradoxes, `with` is now outlawed on module
  parameters.  This should ensure that the invisible arguments are
  always exactly the module parameters.

  Since a `where` block is desugared as module with pattern variables
  of the parent clause as module parameters, the same strikes you for
  uses of `with` on pattern variables of the parent function.

  ```agda
  f : Unit → Unit
  f x = unit
    where
      dx : Unit → Unit
      dx unit = x

      g : ∀ u → x ≡ dx u
      g with x
      g | unit  = id ((u : Unit) → unit ≡ dx u) ?
  ```

  The `with` on pattern variable `x` of the parent clause `f x = unit`
  is outlawed now.

Type checking
-------------

* Termination check failure is now a proper error.

  We no longer continue type checking after termination check
  failures.  Use pragmas `{-# NON_TERMINATING #-}` and `{-#
  NO_TERMINATION_CHECK #-}` near the offending definitions if you want
  to do so.  Or switch off the termination checker altogether with
  `{-# OPTIONS --no-termination-check #-}` (at your own risk!).

* (Since Agda 2.4.2): Termination checking `--without-K` restricts
  structural descent to arguments ending in data types or `Size`.
  Likewise, guardedness is only tracked when result type is data or
  record type.

  ```agda
  mutual
    data WOne : Set where wrap : FOne → WOne
    FOne = ⊥ → WOne

  noo : (X : Set) → (WOne ≡ X) → X → ⊥
  noo .WOne refl (wrap f) = noo FOne iso f
  ```

  `noo` is rejected since at type `X` the structural descent
  `f < wrap f` is discounted `--without-K`.

  ```agda
  data Pandora : Set where
    C : ∞ ⊥ → Pandora

  loop : (A : Set) → A ≡ Pandora → A
  loop .Pandora refl = C (♯ (loop ⊥ foo))
  ```

  `loop` is rejected since guardedness is not tracked at type `A`
  `--without-K`.

  See issues [#1023](https://github.com/agda/agda/issues/1023),
  [#1264](https://github.com/agda/agda/issues/1264),
  [#1292](https://github.com/agda/agda/issues/1292).

Termination checking
--------------------

* The termination checker can now recognize simple subterms in dot
  patterns.

  ```agda
  data Subst : (d : Nat) → Set where
    c₁ : ∀ {d} → Subst d → Subst d
    c₂ : ∀ {d₁ d₂} → Subst d₁ → Subst d₂ → Subst (suc d₁ + d₂)

  postulate
    comp : ∀ {d₁ d₂} → Subst d₁ → Subst d₂ → Subst (d₁ + d₂)

  lookup : ∀ d → Nat → Subst d → Set₁
  lookup d             zero    (c₁ ρ)             = Set
  lookup d             (suc v) (c₁ ρ)             = lookup d v ρ
  lookup .(suc d₁ + d₂) v      (c₂ {d₁} {d₂} ρ σ) = lookup (d₁ + d₂) v (comp ρ σ)
  ```

  The dot pattern here is actually normalized, so it is

  ```agda
  suc (d₁ + d₂)
  ```

  and the corresponding recursive call argument is `(d₁ + d₂)`.  In
  such simple cases, Agda can now recognize that the pattern is
  constructor applied to call argument, which is valid descent.

  Note however, that Agda only looks for syntactic equality when
  identifying subterms, since it is not allowed to normalize terms on
  the rhs during termination checking.

  Actually writing the dot pattern has no effect, this works as well,
  and looks pretty magical... ;-)

  ```agda
  hidden : ∀{d} → Nat → Subst d → Set₁
  hidden zero    (c₁ ρ)   = Set
  hidden (suc v) (c₁ ρ)   = hidden v ρ
  hidden v       (c₂ ρ σ) = hidden v (comp ρ σ)
  ```

Tools
-----

### LaTeX-backend

* Fixed the issue of identifiers containing operators being typeset with
  excessive math spacing.

Bug fixes
---------

* Issue [#1194](https://github.com/agda/agda/issues/1194)

* Issue [#836](https://github.com/agda/agda/issues/836): Fields and
  constructors can be qualified by the record/data *type* as well as
  by their record/data module.  This now works also for record/data
  type imported from parametrized modules:

  ```agda
  module M (_ : Set₁) where

    record R : Set₁ where
      field
        X : Set

  open M Set using (R)  -- rather than using (module R)

  X : R → Set
  X = R.X
  ```

Release notes for Agda version 2.4.2
====================================

Pragmas and options
-------------------

* New option: `--with-K`

  This can be used to override a global `--without-K` in a file, by
  adding a pragma `{-# OPTIONS --with-K #-}`.

* New pragma `{-# NON_TERMINATING #-}`

  This is a safer version of `NO_TERMINATION_CHECK` which doesn't
  treat the affected functions as terminating. This means that
  `NON_TERMINATING` functions do not reduce during type checking. They
  do reduce at run-time and when invoking `C-c C-n` at top-level (but
  not in a hole).

Language
--------

* Instance search is now more efficient and recursive (see
  Issue [#938](https://github.com/agda/agda/issues/938)) (but without
  termination check yet).

  A new keyword `instance` has been introduced (in the style of
  `abstract` and `private`) which must now be used for every
  definition/postulate that has to be taken into account during
  instance resolution. For example:

  ```agda
  record RawMonoid (A : Set) : Set where
    field
      nil  : A
      _++_ : A -> A -> A

  open RawMonoid {{...}}

  instance
    rawMonoidList : {A : Set} -> RawMonoid (List A)
    rawMonoidList = record { nil = []; _++_ = List._++_ }

    rawMonoidMaybe : {A : Set} {{m : RawMonoid A}} -> RawMonoid (Maybe A)
    rawMonoidMaybe {A} = record { nil = nothing ; _++_ = catMaybe }
      where
        catMaybe : Maybe A -> Maybe A -> Maybe A
        catMaybe nothing mb = mb
        catMaybe ma nothing = ma
        catMaybe (just a) (just b) = just (a ++ b)
  ```

  Moreover, each type of an instance must end in (something that reduces
  to) a named type (e.g. a record, a datatype or a postulate). This
  allows us to build a simple index structure

  ```
  data/record name  -->  possible instances
  ```

  that speeds up instance search.

  Instance search takes into account all local bindings and all global
  `instance` bindings and the search is recursive. For instance,
  searching for

  ```agda
  ? : RawMonoid (Maybe (List A))
  ```

  will consider the candidates {`rawMonoidList`, `rawMonoidMaybe`}, fail to
  unify the first one, succeeding with the second one

  ```agda
  ? = rawMonoidMaybe {A = List A} {{m = ?m}} : RawMonoid (Maybe (List A))
  ```

  and continue with goal

  ```agda
  ?m : RawMonoid (List A)
  ```

  This will then find

  ```agda
  ?m = rawMonoidList {A = A}
  ```

  and putting together we have the solution.

  Be careful that there is no termination check for now, you can
  easily make Agda loop by declaring the identity function as an
  instance. But it shouldn’t be possible to make Agda loop by only
  declaring structurally recursive instances (whatever that means).

  Additionally:

  - Uniqueness of instances is up to definitional equality (see
    Issue [#899](https://github.com/agda/agda/issues/899)).

  - Instances of the following form are allowed:

    ```agda
    EqSigma : {A : Set} {B : A → Set} {{EqA : Eq A}}
              {{EqB : {a : A} → Eq (B a)}}
              → Eq (Σ A B)
    ```

    When searching recursively for an instance of type `{a : A} → Eq
    (B a)`, a lambda will automatically be introduced and instance
    search will search for something of type `Eq (B a)` in the context
    extended by `a : A`. When searching for an instance, the `a`
    argument does not have to be implicit, but in the definition of
    `EqSigma`, instance search will only be able to use `EqB` if `a`
    is implicit.

  - There is no longer any attempt to solve irrelevant metas by instance
    search.

  - Constructors of records and datatypes are automatically added to the
    instance table.

* You can now use `quote` in patterns.

  For instance, here is a function that unquotes a (closed) natural
  number term.

  ```agda
  unquoteNat : Term → Maybe Nat
  unquoteNat (con (quote Nat.zero) [])            = just zero
  unquoteNat (con (quote Nat.suc) (arg _ n ∷ [])) = fmap suc (unquoteNat n)
  unquoteNat _                                    = nothing
  ```

* The builtin constructors `AGDATERMUNSUPPORTED` and
  `AGDASORTUNSUPPORTED` are now translated to meta variables when
  unquoting.

* New syntactic sugar `tactic e` and `tactic e | e1 | .. | en`.

  It desugars as follows and makes it less unwieldy to call
  reflection-based tactics.

  ```agda
  tactic e                --> quoteGoal g in unquote (e g)
  tactic e | e1 | .. | en --> quoteGoal g in unquote (e g) e1 .. en
  ```

  Note that in the second form the tactic function should generate a
  function from a number of new subgoals to the original goal. The
  type of `e` should be `Term -> Term` in both cases.

* New reflection builtins for literals.

  The term data type `AGDATERM` now needs an additional constructor
   `AGDATERMLIT` taking a reflected literal defined as follows (with
   appropriate builtin bindings for the types `Nat`, `Float`, etc).

  ```agda
  data Literal : Set where
    nat    : Nat    → Literal
    float  : Float  → Literal
    char   : Char   → Literal
    string : String → Literal
    qname  : QName  → Literal

  {-# BUILTIN AGDALITERAL   Literal #-}
  {-# BUILTIN AGDALITNAT    nat     #-}
  {-# BUILTIN AGDALITFLOAT  float   #-}
  {-# BUILTIN AGDALITCHAR   char    #-}
  {-# BUILTIN AGDALITSTRING string  #-}
  {-# BUILTIN AGDALITQNAME  qname   #-}
  ```

  When quoting (`quoteGoal` or `quoteTerm`) literals will be mapped to
  the `AGDATERMLIT` constructor. Previously natural number literals
  were quoted to `suc`/`zero` application and other literals were
  quoted to `AGDATERMUNSUPPORTED`.

* New reflection builtins for function definitions.

  `AGDAFUNDEF` should now map to a data type defined as follows

  (with
  ```agda
  {-# BUILTIN QNAME       QName   #-}
  {-# BUILTIN ARG         Arg     #-}
  {-# BUILTIN AGDATERM    Term    #-}
  {-# BUILTIN AGDATYPE    Type    #-}
  {-# BUILTIN AGDALITERAL Literal #-}
  ```
  ).

  ```agda
  data Pattern : Set where
    con    : QName → List (Arg Pattern) → Pattern
    dot    : Pattern
    var    : Pattern
    lit    : Literal → Pattern
    proj   : QName → Pattern
    absurd : Pattern

  {-# BUILTIN AGDAPATTERN   Pattern #-}
  {-# BUILTIN AGDAPATCON    con     #-}
  {-# BUILTIN AGDAPATDOT    dot     #-}
  {-# BUILTIN AGDAPATVAR    var     #-}
  {-# BUILTIN AGDAPATLIT    lit     #-}
  {-# BUILTIN AGDAPATPROJ   proj    #-}
  {-# BUILTIN AGDAPATABSURD absurd  #-}

  data Clause : Set where
    clause        : List (Arg Pattern) → Term → Clause
    absurd-clause : List (Arg Pattern) → Clause

  {-# BUILTIN AGDACLAUSE       Clause        #-}
  {-# BUILTIN AGDACLAUSECLAUSE clause        #-}
  {-# BUILTIN AGDACLAUSEABSURD absurd-clause #-}

  data FunDef : Set where
    fun-def : Type → List Clause → FunDef

  {-# BUILTIN AGDAFUNDEF    FunDef  #-}
  {-# BUILTIN AGDAFUNDEFCON fun-def #-}
  ```

* New reflection builtins for extended (pattern-matching) lambda.

  The `AGDATERM` data type has been augmented with a constructor

  ```agda
  AGDATERMEXTLAM : List AGDACLAUSE → List (ARG AGDATERM) → AGDATERM
  ```

  Absurd lambdas (`λ ()`) are quoted to extended lambdas with an
  absurd clause.

* Unquoting declarations.

  You can now define (recursive) functions by reflection using the new
  `unquoteDecl` declaration

  ```agda
  unquoteDecl x = e
  ```

  Here e should have type `AGDAFUNDEF` and evaluate to a closed
  value. This value is then spliced in as the definition of `x`. In
  the body `e`, `x` has type `QNAME` which lets you splice in
  recursive definitions.

  Standard modifiers, such as fixity declarations, can be applied to `x` as
  expected.

* Quoted levels

  Universe levels are now quoted properly instead of being quoted to
  `AGDASORTUNSUPPORTED`. `Setω` still gets an unsupported sort,
  however.

* Module applicants can now be operator applications.

  Example:

  ```agda
  postulate
    [_] : A -> B

  module M (b : B) where

  module N (a : A) = M [ a ]
  ```

  [See Issue [#1245](https://github.com/agda/agda/issues/1245)]

* Minor change in module application
  semantics. [Issue [#892](https://github.com/agda/agda/issues/892)]

  Previously re-exported functions were not redefined when
  instantiating a module. For instance

  ```agda
  module A where f = ...
  module B (X : Set) where
    open A public
  module C = B Nat
  ```

  In this example `C.f` would be an alias for `A.f`, so if both `A`
  and `C` were opened `f` would not be ambiguous. However, this
  behaviour is not correct when `A` and `B` share some module
  parameters
  (Issue [#892](https://github.com/agda/agda/issues/892)). To fix this
  `C` now defines its own copy of `f` (which evaluates to `A.f`),
  which means that opening `A` and `C` results in an ambiguous `f`.

Type checking
-------------

* Recursive records need to be declared as either `inductive` or
  `coinductive`.  `inductive` is no longer default for recursive
  records. Examples:

  ```agda
  record _×_ (A B : Set) : Set where
    constructor _,_
    field
      fst : A
      snd : B

  record Tree (A : Set) : Set where
    inductive
    constructor tree
    field
      elem     : A
      subtrees : List (Tree A)

  record Stream (A : Set) : Set where
    coinductive
    constructor _::_
    field
      head : A
      tail : Stream A
  ```

  If you are using old-style (musical) coinduction, a record may have
  to be declared as inductive, paradoxically.

  ```agda
  record Stream (A : Set) : Set where
    inductive -- YES, THIS IS INTENDED !
    constructor _∷_
    field
      head : A
      tail : ∞ (Stream A)
  ```

  This is because the "coinduction" happens in the use of `∞` and not
  in the use of `record`.

Tools
-----

### Emacs mode

* A new menu option `Display` can be used to display the version of
  the running Agda process.

### LaTeX-backend

* New experimental option `references` has been added. When specified,
  i.e.:

  ```latex
  \usepackage[references]{agda}
  ```

  a new command called `\AgdaRef` is provided, which lets you
  reference previously typeset commands, e.g.:

  Let us postulate `\AgdaRef{apa}`.

  ```agda
  \begin{code}
  postulate
    apa : Set
  \end{code}
  ```

  Above `apa` will be typeset (highlighted) the same in the text as in
  the code, provided that the LaTeX output is post-processed using
  `src/data/postprocess-latex.pl`, e.g.:

  ```
  cp $(dirname $(dirname $(agda-mode locate)))/postprocess-latex.pl .
  agda -i. --latex Example.lagda
  cd latex/
  perl ../postprocess-latex.pl Example.tex > Example.processed
  mv Example.processed Example.tex
  xelatex Example.tex
  ```

  Mix-fix and Unicode should work as expected (Unicode requires
  XeLaTeX/LuaLaTeX), but there are limitations:

  - Overloading identifiers should be avoided, if multiples exist
    `\AgdaRef` will typeset according to the first it finds.

  - Only the current module is used, should you need to reference
    identifiers in other modules then you need to specify which other
    module manually, i.e. `\AgdaRef[module]{identifier}`.

Release notes for Agda 2 version 2.4.0.2
========================================

* The Agda input mode now supports alphabetical super and subscripts,
  in addition to the numerical ones that were already present.
  [Issue [#1240](https://github.com/agda/agda/issues/1240)]

* New feature: Interactively split result.

  Make case (`C-c C-c`) with no variables given tries to split on the
  result to introduce projection patterns.  The hole needs to be of
  record type, of course.

  ```agda
  test : {A B : Set} (a : A) (b : B) → A × B
  test a b = ?
  ```

  Result-splitting `?` will produce the new clauses:

  ```agda
  proj₁ (test a b) = ?
  proj₂ (test a b) = ?
  ```

  If hole is of function type ending in a record type, the necessary
  pattern variables will be introduced before the split.  Thus, the
  same result can be obtained by starting from:

  ```agda
  test : {A B : Set} (a : A) (b : B) → A × B
  test = ?
  ```

* The so far undocumented `ETA` pragma now throws an error if applied to
  definitions that are not records.

  `ETA` can be used to force eta-equality at recursive record types,
  for which eta is not enabled automatically by Agda.  Here is such an
  example:

  ```agda
  mutual
    data Colist (A : Set) : Set where
      [] : Colist A
      _∷_ : A → ∞Colist A → Colist A

    record ∞Colist (A : Set) : Set where
      coinductive
      constructor delay
      field       force : Colist A

  open ∞Colist

  {-# ETA ∞Colist #-}

  test : {A : Set} (x : ∞Colist A) → x ≡ delay (force x)
  test x = refl
  ```

  Note: Unsafe use of `ETA` can make Agda loop, e.g. by triggering
  infinite eta expansion!

* Bugs fixed (see [bug tracker](https://github.com/agda/agda/issues)):

  [#1203](https://github.com/agda/agda/issues/1203)

  [#1205](https://github.com/agda/agda/issues/1205)

  [#1209](https://github.com/agda/agda/issues/1209)

  [#1213](https://github.com/agda/agda/issues/1213)

  [#1214](https://github.com/agda/agda/issues/1214)

  [#1216](https://github.com/agda/agda/issues/1216)

  [#1225](https://github.com/agda/agda/issues/1225)

  [#1226](https://github.com/agda/agda/issues/1226)

  [#1231](https://github.com/agda/agda/issues/1231)

  [#1233](https://github.com/agda/agda/issues/1233)

  [#1239](https://github.com/agda/agda/issues/1239)

  [#1241](https://github.com/agda/agda/issues/1241)

  [#1243](https://github.com/agda/agda/issues/1243)

Release notes for Agda 2 version 2.4.0.1
========================================

* The option `--compile-no-main` has been renamed to `--no-main`.

* `COMPILED_DATA` pragmas can now be given for records.

* Various bug fixes.

Release notes for Agda 2 version 2.4.0
======================================

Installation and infrastructure
-------------------------------

* A new module called `Agda.Primitive` has been introduced. This
  module is available to all users, even if the standard library is
  not used.  Currently the module contains level primitives and their
  representation in Haskell when compiling with MAlonzo:

  ```agda
  infixl 6 _⊔_

  postulate
    Level : Set
    lzero : Level
    lsuc  : (ℓ : Level) → Level
    _⊔_   : (ℓ₁ ℓ₂ : Level) → Level

  {-# COMPILED_TYPE Level ()      #-}
  {-# COMPILED lzero ()           #-}
  {-# COMPILED lsuc  (\_ -> ())   #-}
  {-# COMPILED _⊔_   (\_ _ -> ()) #-}

  {-# BUILTIN LEVEL     Level  #-}
  {-# BUILTIN LEVELZERO lzero  #-}
  {-# BUILTIN LEVELSUC  lsuc   #-}
  {-# BUILTIN LEVELMAX  _⊔_    #-}
  ```

  To bring these declarations into scope you can use a declaration
  like the following one:

  ```agda
  open import Agda.Primitive using (Level; lzero; lsuc; _⊔_)
  ```

  The standard library reexports these primitives (using the names
  `zero` and `suc` instead of `lzero` and `lsuc`) from the `Level`
  module.

  Existing developments using universe polymorphism might now trigger
  the following error message:

  ```
  Duplicate binding for built-in thing LEVEL, previous binding to
    .Agda.Primitive.Level
  ```

  To fix this problem, please remove the duplicate bindings.

  Technical details (perhaps relevant to those who build Agda
  packages):

  The include path now always contains a directory
  `<DATADIR>/lib/prim`, and this directory is supposed to contain a
  subdirectory Agda containing a file `Primitive.agda`.

  The standard location of `<DATADIR>` is system- and
  installation-specific.  E.g., in a Cabal `--user` installation of
  Agda-2.3.4 on a standard single-ghc Linux system it would be
  `$HOME/.cabal/share/Agda-2.3.4` or something similar.

  The location of the `<DATADIR>` directory can be configured at
  compile-time using Cabal flags (`--datadir` and `--datasubdir`).
  The location can also be set at run-time, using the `Agda_datadir`
  environment variable.

Pragmas and options
-------------------

* Pragma `NO_TERMINATION_CHECK` placed within a mutual block is now
  applied to the whole mutual block (rather than being discarded
  silently).  Adding to the uses 1.-4. outlined in the release notes
  for 2.3.2 we allow:

  3a. Skipping an old-style mutual block: Somewhere within `mutual`
      block before a type signature or first function clause.

   ```agda
   mutual
     {-# NO_TERMINATION_CHECK #-}
     c : A
     c = d

     d : A
     d = c
   ```

* New option `--no-pattern-matching`

  Disables all forms of pattern matching (for the current file).
  You can still import files that use pattern matching.

* New option `-v profile:7`

  Prints some stats on which phases Agda spends how much time.
  (Number might not be very reliable, due to garbage collection
  interruptions, and maybe due to laziness of Haskell.)

* New option `--no-sized-types`

  Option `--sized-types` is now default.  `--no-sized-types` will turn
  off an extra (inexpensive) analysis on data types used for subtyping
  of sized types.

Language
--------

* Experimental feature: `quoteContext`

  There is a new keyword `quoteContext` that gives users access to the
  list of names in the current local context. For instance:

  ```agda
  open import Data.Nat
  open import Data.List
  open import Reflection

  foo : ℕ → ℕ → ℕ
  foo 0 m = 0
  foo (suc n) m = quoteContext xs in ?
  ```

  In the remaining goal, the list `xs` will consist of two names, `n`
  and `m`, corresponding to the two local variables. At the moment it
  is not possible to access let bound variables (this feature may be
  added in the future).

* Experimental feature: Varying arity.
  Function clauses may now have different arity, e.g.,

  ```agda
  Sum : ℕ → Set
  Sum 0       = ℕ
  Sum (suc n) = ℕ → Sum n

  sum : (n : ℕ) → ℕ → Sum n
  sum 0       acc   = acc
  sum (suc n) acc m = sum n (m + acc)
  ```

  or,

  ```agda
  T : Bool → Set
  T true  = Bool
  T false = Bool → Bool

  f : (b : Bool) → T b
  f false true  = false
  f false false = true
  f true = true
  ```

  This feature is experimental.  Yet unsupported:
  - Varying arity and `with`.

  - Compilation of functions with varying arity to Haskell, JS, or Epic.

* Experimental feature: copatterns.  (Activated with option `--copatterns`)

  We can now define a record by explaining what happens if you project
  the record.  For instance:

  ```agda
  {-# OPTIONS --copatterns #-}

  record _×_ (A B : Set) : Set where
    constructor _,_
    field
      fst : A
      snd : B
  open _×_

  pair : {A B : Set} → A → B → A × B
  fst (pair a b) = a
  snd (pair a b) = b

  swap : {A B : Set} → A × B → B × A
  fst (swap p) = snd p
  snd (swap p) = fst p

  swap3 : {A B C : Set} → A × (B × C) → C × (B × A)
  fst (swap3 t)       = snd (snd t)
  fst (snd (swap3 t)) = fst (snd t)
  snd (snd (swap3 t)) = fst t
  ```

  Taking a projection on the left hand side (lhs) is called a
  projection pattern, applying to a pattern is called an application
  pattern.  (Alternative terms: projection/application copattern.)

  In the first example, the symbol `pair`, if applied to variable
  patterns `a` and `b` and then projected via `fst`, reduces to
  `a`. `pair` by itself does not reduce.

  A typical application are coinductive records such as streams:

  ```agda
  record Stream (A : Set) : Set where
    coinductive
    field
      head : A
      tail : Stream A
  open Stream

  repeat : {A : Set} (a : A) -> Stream A
  head (repeat a) = a
  tail (repeat a) = repeat a
  ```

  Again, `repeat a` by itself will not reduce, but you can take a
  projection (head or tail) and then it will reduce to the respective
  rhs.  This way, we get the lazy reduction behavior necessary to
  avoid looping corecursive programs.

  Application patterns do not need to be trivial (i.e., variable
  patterns), if we mix with projection patterns.  E.g., we can have

  ```agda
  nats : Nat -> Stream Nat
  head (nats zero) = zero
  tail (nats zero) = nats zero
  head (nats (suc x)) = x
  tail (nats (suc x)) = nats x
  ```

  Here is an example (not involving coinduction) which demostrates
  records with fields of function type:

  ```agda
  -- The State monad

  record State (S A : Set) : Set where
    constructor state
    field
      runState : S → A × S
  open State

  -- The Monad type class

  record Monad (M : Set → Set) : Set1 where
    constructor monad
    field
      return : {A : Set}   → A → M A
      _>>=_  : {A B : Set} → M A → (A → M B) → M B


  -- State is an instance of Monad
  -- Demonstrates the interleaving of projection and application patterns

  stateMonad : {S : Set} → Monad (State S)
  runState (Monad.return stateMonad a  ) s  = a , s
  runState (Monad._>>=_  stateMonad m k) s₀ =
    let a , s₁ = runState m s₀
    in  runState (k a) s₁

  module MonadLawsForState {S : Set} where

    open Monad (stateMonad {S})

    leftId : {A B : Set}(a : A)(k : A → State S B) →
      (return a >>= k) ≡ k a
    leftId a k = refl

    rightId : {A B : Set}(m : State S A) →
      (m >>= return) ≡ m
    rightId m = refl

    assoc : {A B C : Set}(m : State S A)(k : A → State S B)(l : B → State S C) →
      ((m >>= k) >>= l) ≡ (m >>= λ a → (k a >>= l))
    assoc m k l = refl
  ```

  Copatterns are yet experimental and the following does not work:

  - Copatterns and `with` clauses.

  - Compilation of copatterns to Haskell, JS, or Epic.

  - Projections generated by

    ```agda
    open R {{...}}
    ```

    are not handled properly on lhss yet.

  - Conversion checking is slower in the presence of copatterns, since
    stuck definitions of record type do no longer count as neutral,
    since they can become unstuck by applying a projection. Thus,
    comparing two neutrals currently requires comparing all they
    projections, which repeats a lot of work.

* Top-level module no longer required.

  The top-level module can be omitted from an Agda file. The module
  name is then inferred from the file name by dropping the path and
  the `.agda` extension. So, a module defined in `/A/B/C.agda` would get
  the name `C`.

  You can also suppress only the module name of the top-level module
  by writing

  ```agda
  module _ where
  ```

  This works also for parameterised modules.

* Module parameters are now always hidden arguments in projections.
  For instance:

  ```agda
  module M (A : Set) where

    record Prod (B : Set) : Set where
      constructor _,_
      field
        fst : A
        snd : B
    open Prod public

  open M
  ```

  Now, the types of `fst` and `snd` are

  ```agda
  fst : {A : Set}{B : Set} → Prod A B → A
  snd : {A : Set}{B : Set} → Prod A B → B
  ```

  Until 2.3.2, they were

  ```agda
  fst : (A : Set){B : Set} → Prod A B → A
  snd : (A : Set){B : Set} → Prod A B → B
  ```

  This change is a step towards symmetry of constructors and projections.
  (Constructors always took the module parameters as hidden arguments).

* Telescoping lets: Local bindings are now accepted in telescopes
  of modules, function types, and lambda-abstractions.

  The syntax of telescopes as been extended to support `let`:

  ```agda
  id : (let ★ = Set) (A : ★) → A → A
  id A x = x
  ```

  In particular one can now `open` modules inside telescopes:

  ```agda
  module Star where
    ★ : Set₁
    ★ = Set


  module MEndo (let open Star) (A : ★) where
    Endo : ★
    Endo = A → A
  ```

  Finally a shortcut is provided for opening modules:

  ```agda
  module N (open Star) (A : ★) (open MEndo A) (f : Endo) where
    ...
  ```

  The semantics of the latter is

  ```agda
  module _ where
    open Star
    module _ (A : ★) where
      open MEndo A
      module N (f : Endo) where
        ...
  ```

  The semantics of telescoping lets in function types and lambda
  abstractions is just expanding them into ordinary lets.

* More liberal left-hand sides in lets
  [Issue [#1028](https://github.com/agda/agda/issues/1028)]:

  You can now write left-hand sides with arguments also for let
  bindings without a type signature. For instance,

  ```agda
  let f x = suc x in f zero
  ```

  Let bound functions still can't do pattern matching though.

* Ambiguous names in patterns are now optimistically resolved in favor
  of constructors. [Issue [#822](https://github.com/agda/agda/issues/822)]
  In particular, the following succeeds now:

  ```agda
  module M where

    data D : Set₁ where
      [_] : Set → D

  postulate [_] : Set → Set

  open M

  Foo : _ → Set
  Foo [ A ] = A
  ```

* Anonymous `where`-modules are opened
  public. [Issue [#848](https://github.com/agda/agda/issues/848)]

  ```
  <clauses>
  f args = rhs
    module _ telescope where
      body
  <more clauses>
  ```

  means the following (not proper Agda code, since you cannot put a
  module in-between clauses)

  ```
  <clauses>
  module _ {arg-telescope} telescope where
    body

  f args = rhs
  <more clauses>
  ```

  Example:

  ```agda
  A : Set1
  A = B module _ where
    B : Set1
    B = Set

  C : Set1
  C = B
  ```

* Builtin `ZERO` and `SUC` have been merged with `NATURAL`.

  When binding the `NATURAL` builtin, `ZERO` and `SUC` are bound to
  the appropriate constructors automatically. This means that instead
  of writing

  ```agda
  {-# BUILTIN NATURAL Nat #-}
  {-# BUILTIN ZERO zero #-}
  {-# BUILTIN SUC suc #-}
  ```

  you just write

  ```agda
  {-# BUILTIN NATURAL Nat #-}
  ```

* Pattern synonym can now have implicit
  arguments. [Issue [#860](https://github.com/agda/agda/issues/860)]

  For example,

  ```agda
  pattern tail=_ {x} xs = x ∷ xs

  len : ∀ {A} → List A → Nat
  len []         = 0
  len (tail= xs) = 1 + len xs
  ```

* Syntax declarations can now have implicit
  arguments. [Issue [#400](https://github.com/agda/agda/issues/400)]

  For example

  ```agda
  id : ∀ {a}{A : Set a} -> A -> A
  id x = x

  syntax id {A} x = x ∈ A
  ```

* Minor syntax changes

  - `-}` is now parsed as end-comment even if no comment was begun. As
    a consequence, the following definition gives a parse error

    ```agda
    f : {A- : Set} -> Set
    f {A-} = A-
    ```

    because Agda now sees `ID(f) LBRACE ID(A) END-COMMENT`, and no
    longer `ID(f) LBRACE ID(A-) RBRACE`.

    The rational is that the previous lexing was to context-sensitive,
    attempting to comment-out `f` using `{-` and `-}` lead to a parse
    error.

  - Fixities (binding strengths) can now be negative numbers as
    well. [Issue [#1109](https://github.com/agda/agda/issues/1109)]

    ```agda
    infix -1 _myop_
    ```

  - Postulates are now allowed in mutual
    blocks. [Issue [#977](https://github.com/agda/agda/issues/977)]

  - Empty where blocks are now
    allowed. [Issue [#947](https://github.com/agda/agda/issues/947)]

  - Pattern synonyms are now allowed in parameterised
    modules. [Issue [#941](https://github.com/agda/agda/issues/941)]

  - Empty hiding and renaming lists in module directives are now allowed.

  - Module directives `using`, `hiding`, `renaming` and `public` can
    now appear in arbitrary order. Multiple
    `using`/`hiding`/`renaming` directives are allowed, but you still
    cannot have both using and `hiding` (because that doesn't make
    sense). [Issue [#493](https://github.com/agda/agda/issues/493)]

Goal and error display
----------------------

* The error message `Refuse to construct infinite term` has been
  removed, instead one gets unsolved meta variables.  Reason: the
  error was thrown over-eagerly.
  [Issue [#795](https://github.com/agda/agda/issues/795)]

* If an interactive case split fails with message

  ```
    Since goal is solved, further case distinction is not supported;
    try `Solve constraints' instead
  ```

  then the associated interaction meta is assigned to a solution.
  Press `C-c C-=` (Show constraints) to view the solution and `C-c
  C-s` (Solve constraints) to apply it.
  [Issue [#289](https://github.com/agda/agda/issues/289)]

Type checking
-------------

* [ Issue [#376](https://github.com/agda/agda/issues/376) ]
  Implemented expansion of bound record variables during meta
  assignment.  Now Agda can solve for metas X that are applied to
  projected variables, e.g.:

  ```agda
  X (fst z) (snd z) = z

  X (fst z)         = fst z
  ```

  Technically, this is realized by substituting `(x , y)` for `z` with fresh
  bound variables `x` and `y`.  Here the full code for the examples:

  ```agda
  record Sigma (A : Set)(B : A -> Set) : Set where
    constructor _,_
    field
      fst : A
      snd : B fst
  open Sigma

  test : (A : Set) (B : A -> Set) ->
    let X : (x : A) (y : B x) -> Sigma A B
        X = _
    in  (z : Sigma A B) -> X (fst z) (snd z) ≡ z
  test A B z = refl

  test' : (A : Set) (B : A -> Set) ->
    let X : A -> A
        X = _
    in  (z : Sigma A B) -> X (fst z) ≡ fst z
  test' A B z = refl
  ```

  The fresh bound variables are named `fst(z)` and `snd(z)` and can appear
  in error messages, e.g.:

  ```agda
  fail : (A : Set) (B : A -> Set) ->
    let X : A -> Sigma A B
        X = _
    in  (z : Sigma A B) -> X (fst z) ≡ z
  fail A B z = refl
  ```

  results in error:

  ```
  Cannot instantiate the metavariable _7 to solution fst(z) , snd(z)
  since it contains the variable snd(z) which is not in scope of the
  metavariable or irrelevant in the metavariable but relevant in the
  solution
  when checking that the expression refl has type _7 A B (fst z) ≡ z
  ```

* Dependent record types and definitions by copatterns require
  reduction with previous function clauses while checking the current
  clause. [Issue [#907](https://github.com/agda/agda/issues/907)]

  For a simple example, consider

  ```agda
  test : ∀ {A} → Σ Nat λ n → Vec A n
  proj₁ test = zero
  proj₂ test = []
  ```

  For the second clause, the lhs and rhs are typed as

  ```agda
  proj₂ test : Vec A (proj₁ test)
  []         : Vec A zero
  ```

  In order for these types to match, we have to reduce the lhs type
  with the first function clause.

  Note that termination checking comes after type checking, so be
  careful to avoid non-termination!  Otherwise, the type checker
  might get into an infinite loop.

* The implementation of the primitive `primTrustMe` has changed.  It
  now only reduces to `REFL` if the two arguments `x` and `y` have the
  same computational normal form.  Before, it reduced when `x` and `y`
  were definitionally equal, which included type-directed equality
  laws such as eta-equality.  Yet because reduction is untyped,
  calling conversion from reduction lead to Agda crashes
  [Issue [#882](https://github.com/agda/agda/issues/882)].

  The amended description of `primTrustMe` is (cf. release notes
  for 2.2.6):

  ```agda
  primTrustMe : {A : Set} {x y : A} → x ≡ y
  ```

  Here `_≡_` is the builtin equality (see BUILTIN hooks for equality,
  above).

  If `x` and `y` have the same computational normal form, then
  `primTrustMe {x = x} {y = y}` reduces to `refl`.

  A note on `primTrustMe`'s runtime behavior: The MAlonzo compiler
  replaces all uses of `primTrustMe` with the `REFL` builtin, without
  any check for definitional equality. Incorrect uses of `primTrustMe`
  can potentially lead to segfaults or similar problems of the
  compiled code.

* Implicit patterns of record type are now only eta-expanded if there
  is a record constructor.
  [Issues [#473](https://github.com/agda/agda/issues/473),
  [#635](https://github.com/agda/agda/issues/635)]

  ```agda
  data D : Set where
    d : D

  data P : D → Set where
    p : P d

  record Rc : Set where
    constructor c
    field f : D

  works : {r : Rc} → P (Rc.f r) → Set
  works p = D
  ```

  This works since the implicit pattern `r` is eta-expanded to `c x`
  which allows the type of `p` to reduce to `P x` and `x` to be
  unified with `d`. The corresponding explicit version is:

  ```agda
  works' : (r : Rc) → P (Rc.f r) → Set
  works' (c .d) p = D
  ```

  However, if the record constructor is removed, the same example will
  fail:

  ```agda
  record R : Set where
    field f : D

  fails : {r : R} → P (R.f r) → Set
  fails p = D

  -- d != R.f r of type D
  -- when checking that the pattern p has type P (R.f r)
  ```

  The error is justified since there is no pattern we could write down
  for `r`.  It would have to look like

  ```agda
  record { f = .d }
  ```

  but anonymous record patterns are not part of the language.

* Absurd lambdas at different source locations are no longer
  different. [Issue [#857](https://github.com/agda/agda/issues/857)]
  In particular, the following code type-checks now:

  ```agda
  absurd-equality : _≡_ {A = ⊥ → ⊥} (λ()) λ()
  absurd-equality = refl
  ```

  Which is a good thing!

* Printing of named implicit function types.

  When printing terms in a context with bound variables Agda renames
  new bindings to avoid clashes with the previously bound names. For
  instance, if `A` is in scope, the type `(A : Set) → A` is printed as
  `(A₁ : Set) → A₁`. However, for implicit function types the name of
  the binding matters, since it can be used when giving implicit
  arguments.

  For this situation, the following new syntax has been introduced:
  `{x = y : A} → B` is an implicit function type whose bound variable
  (in scope in `B`) is `y`, but where the name of the argument is `x`
  for the purposes of giving it explicitly. For instance, with `A` in
  scope, the type `{A : Set} → A` is now printed as `{A = A₁ : Set} →
  A₁`.

  This syntax is only used when printing and is currently not being parsed.

* Changed the semantics of `--without-K`.
  [Issue [#712](https://github.com/agda/agda/issues/712),
  Issue [#865](https://github.com/agda/agda/issues/865),
  Issue [#1025](https://github.com/agda/agda/issues/1025)]

  New specification of `--without-K`:

  When `--without-K` is enabled, the unification of indices for
  pattern matching is restricted in two ways:

  1. Reflexive equations of the form `x == x` are no longer solved,
     instead Agda gives an error when such an equation is encountered.

  2. When unifying two same-headed constructor forms `c us` and `c vs`
     of type `D pars ixs`, the datatype indices `ixs` (but not the
     parameters) have to be *self-unifiable*, i.e. unification of
     `ixs` with itself should succeed positively. This is a nontrivial
     requirement because of point 1.

  Examples:

  - The J rule is accepted.

    ```agda
    J : {A : Set} (P : {x y : A} → x ≡ y → Set) →
        (∀ x → P (refl x)) →
        ∀ {x y} (x≡y : x ≡ y) → P x≡y
    J P p (refl x) = p x
    ```agda

    This definition is accepted since unification of `x` with `y`
    doesn't require deletion or injectivity.

  - The K rule is rejected.

    ```agda
    K : {A : Set} (P : {x : A} → x ≡ x → Set) →
        (∀ x → P (refl {x = x})) →
       ∀ {x} (x≡x : x ≡ x) → P x≡x
    K P p refl = p _
    ```

    Definition is rejected with the following error:

    ```
    Cannot eliminate reflexive equation x = x of type A because K has
    been disabled.
    when checking that the pattern refl has type x ≡ x
    ```

  - Symmetry of the new criterion.

    ```agda
    test₁ : {k l m : ℕ} → k + l ≡ m → ℕ
    test₁ refl = zero

    test₂ : {k l m : ℕ} → k ≡ l + m → ℕ
    test₂ refl = zero
    ```

    Both versions are now accepted (previously only the first one was).

  - Handling of parameters.

    ```agda
    cons-injective : {A : Set} (x y : A) → (x ∷ []) ≡ (y ∷ []) → x ≡ y
    cons-injective x .x refl = refl
    ```

    Parameters are not unified, so they are ignored by the new criterion.

  - A larger example: antisymmetry of ≤.

    ```agda
    data _≤_ : ℕ → ℕ → Set where
      lz : (n : ℕ) → zero ≤ n
      ls : (m n : ℕ) → m ≤ n → suc m ≤ suc n

    ≤-antisym : (m n : ℕ) → m ≤ n → n ≤ m → m ≡ n
    ≤-antisym .zero    .zero    (lz .zero) (lz .zero)   = refl
    ≤-antisym .(suc m) .(suc n) (ls m n p) (ls .n .m q) =
                 cong suc (≤-antisym m n p q)
    ```

  - [ Issue [#1025](https://github.com/agda/agda/issues/1025) ]

    ```agda
    postulate mySpace : Set
    postulate myPoint : mySpace

    data Foo : myPoint ≡ myPoint → Set where
      foo : Foo refl

    test : (i : foo ≡ foo) → i ≡ refl
    test refl = {!!}
    ```

    When applying injectivity to the equation `foo ≡ foo` of type `Foo
    refl`, it is checked that the index `refl` of type `myPoint ≡
    myPoint` is self-unifiable. The equation `refl ≡ refl` again
    requires injectivity, so now the index `myPoint` is checked for
    self-unifiability, hence the error:

    ```
    Cannot eliminate reflexive equation myPoint = myPoint of type
    mySpace because K has been disabled.
    when checking that the pattern refl has type foo ≡ foo
    ```

Termination checking
--------------------

* A buggy facility coined "matrix-shaped orders" that supported
  uncurried functions (which take tuples of arguments instead of one
  argument after another) has been removed from the termination
  checker. [Issue [#787](https://github.com/agda/agda/issues/787)]

* Definitions which fail the termination checker are not unfolded any
  longer to avoid loops or stack overflows in Agda.  However, the
  termination checker for a mutual block is only invoked after
  type-checking, so there can still be loops if you define a
  non-terminating function.  But termination checking now happens
  before the other supplementary checks: positivity, polarity,
  injectivity and projection-likeness.  Note that with the pragma `{-#
  NO_TERMINATION_CHECK #-}` you can make Agda treat any function as
  terminating.

* Termination checking of functions defined by `with` has been improved.

  Cases which previously required `--termination-depth` to pass the
  termination checker (due to use of `with`) no longer need the
  flag. For example

  ```agda
  merge : List A → List A → List A
  merge [] ys = ys
  merge xs [] = xs
  merge (x ∷ xs) (y ∷ ys) with x ≤ y
  merge (x ∷ xs) (y ∷ ys)    | false = y ∷ merge (x ∷ xs) ys
  merge (x ∷ xs) (y ∷ ys)    | true  = x ∷ merge xs (y ∷ ys)
  ```

  This failed to termination check previously, since the `with`
  expands to an auxiliary function `merge-aux`:

  ```agda
  merge-aux x y xs ys false = y ∷ merge (x ∷ xs) ys
  merge-aux x y xs ys true  = x ∷ merge xs (y ∷ ys)
  ```

  This function makes a call to `merge` in which the size of one of
  the arguments is increasing. To make this pass the termination
  checker now inlines the definition of `merge-aux` before checking,
  thus effectively termination checking the original source program.

  As a result of this transformation doing `with` on a variable no longer
  preserves termination. For instance, this does not termination check:

  ```agda
  bad : Nat → Nat
  bad n with n
  ... | zero  = zero
  ... | suc m = bad m
  ```

* The performance of the termination checker has been improved.  For
  higher `--termination-depth` the improvement is significant.  While
  the default `--termination-depth` is still 1, checking with higher
  `--termination-depth` should now be feasible.

Compiler backends
-----------------

* The MAlonzo compiler backend now has support for compiling modules
  that are not full programs (i.e. don't have a main function). The
  goal is that you can write part of a program in Agda and the rest in
  Haskell, and invoke the Agda functions from the Haskell code. The
  following features were added for this reason:

  - A new command-line option `--compile-no-main`: the command

    ```
    agda --compile-no-main Test.agda
    ```

    will compile `Test.agda` and all its dependencies to Haskell and
    compile the resulting Haskell files with `--make`, but (unlike
    `--compile`) not tell GHC to treat `Test.hs` as the main
    module. This type of compilation can be invoked from Emacs by
    customizing the `agda2-backend` variable to value `MAlonzoNoMain` and
    then calling `C-c C-x C-c` as before.

  - A new pragma `COMPILED_EXPORT` was added as part of the MAlonzo
    FFI. If we have an Agda file containing the following:

    ```agda
     module A.B where

     test : SomeType
     test = someImplementation

     {-# COMPILED_EXPORT test someHaskellId #-}
    ```

    then test will be compiled to a Haskell function called
    `someHaskellId` in module `MAlonzo.Code.A.B` that can be invoked
    from other Haskell code. Its type will be translated according to
    the normal MAlonzo rules.

Tools
-----

### Emacs mode

* A new goal command `Helper Function Type` (`C-c C-h`) has been added.

  If you write an application of an undefined function in a goal, the
  `Helper Function Type` command will print the type that the function
  needs to have in order for it to fit the goal. The type is also
  added to the Emacs kill-ring and can be pasted into the buffer using
  `C-y`.

  The application must be of the form `f args` where `f` is the name of the
  helper function you want to create. The arguments can use all the normal
  features like named implicits or instance arguments.

  Example:

  Here's a start on a naive reverse on vectors:

  ```agda
  reverse : ∀ {A n} → Vec A n → Vec A n
  reverse [] = []
  reverse (x ∷ xs) = {!snoc (reverse xs) x!}
  ```

  Calling `C-c C-h` in the goal prints

  ```agda
  snoc : ∀ {A} {n} → Vec A n → A → Vec A (suc n)
  ```

* A new command `Explain why a particular name is in scope` (`C-c
  C-w`) has been added.
  [Issue [#207](https://github.com/agda/agda/issues/207)]

  This command can be called from a goal or from the top-level and will as the
  name suggests explain why a particular name is in scope.

  For each definition or module that the given name can refer to a trace is
  printed of all open statements and module applications leading back to the
  original definition of the name.

  For example, given

  ```agda
  module A (X : Set₁) where
    data Foo : Set where
      mkFoo : Foo
  module B (Y : Set₁) where
    open A Y public
  module C = B Set
  open C
  ```

  Calling `C-c C-w` on `mkFoo` at the top-level prints

  ```
  mkFoo is in scope as
  * a constructor Issue207.C._.Foo.mkFoo brought into scope by
    - the opening of C at Issue207.agda:13,6-7
    - the application of B at Issue207.agda:11,12-13
    - the application of A at Issue207.agda:9,8-9
    - its definition at Issue207.agda:6,5-10
  ```

  This command is useful if Agda complains about an ambiguous name and
  you need to figure out how to hide the undesired interpretations.

* Improvements to the `make case` command (`C-c C-c`)

  - One can now also split on hidden variables, using the name
    (starting with `.`) with which they are printed.  Use `C-c C-`, to
    see all variables in context.

  - Concerning the printing of generated clauses:

    * Uses named implicit arguments to improve readability.

    * Picks explicit occurrences over implicit ones when there is a
      choice of binding site for a variable.

    * Avoids binding variables in implicit positions by replacing dot
      patterns that uses them by wildcards (`._`).

* Key bindings for lots of "mathematical" characters (examples: 𝐴𝑨𝒜𝓐𝔄)
  have been added to the Agda input method.  Example: type
  `\MiA\MIA\McA\MCA\MfA` to get 𝐴𝑨𝒜𝓐𝔄.

  Note: `\McB` does not exist in Unicode (as well as others in that style),
  but the `\MC` (bold) alphabet is complete.

* Key bindings for "blackboard bold" B (𝔹) and 0-9 (𝟘-𝟡) have been
  added to the Agda input method (`\bb` and `\b[0-9]`).

* Key bindings for controlling simplification/normalisation:

  Commands like `Goal type and context` (`C-c C-,`) could previously
  be invoked in two ways. By default the output was normalised, but if
  a prefix argument was used (for instance via `C-u C-c C-,`), then no
  explicit normalisation was performed. Now there are three options:

  - By default (`C-c C-,`) the output is simplified.

  - If `C-u` is used exactly once (`C-u C-c C-,`), then the result is
    neither (explicitly) normalised nor simplified.

  - If `C-u` is used twice (`C-u C-u C-c C-,`), then the result is
    normalised.

### LaTeX-backend

* Two new color scheme options were added to `agda.sty`:

  `\usepackage[bw]{agda}`, which highlights in black and white;
  `\usepackage[conor]{agda}`, which highlights using Conor's colors.

  The default (no options passed) is to use the standard colors.

* If `agda.sty` cannot be found by the LateX environment, it is now
  copied into the LateX output directory (`latex` by default) instead
  of the working directory. This means that the commands needed to
  produce a PDF now is

  ```
  agda --latex -i . <file>.lagda
  cd latex
  pdflatex <file>.tex
  ```

* The LaTeX-backend has been made more tool agnostic, in particular
  XeLaTeX and LuaLaTeX should now work. Here is a small example
  (`test/LaTeXAndHTML/succeed/UnicodeInput.lagda`):

  ```latex
  \documentclass{article}
  \usepackage{agda}
  \begin{document}

  \begin{code}
  data αβγδεζθικλμνξρστυφχψω : Set₁ where

  postulate
    →⇒⇛⇉⇄↦⇨↠⇀⇁ : Set
  \end{code}

  \[
  ∀X [ ∅ ∉ X ⇒ ∃f:X ⟶  ⋃ X\ ∀A ∈ X (f(A) ∈ A) ]
  \]
  \end{document}
  ```

  Compiled as follows, it should produce a nice looking PDF (tested with
  TeX Live 2012):

  ```
  agda --latex <file>.lagda
  cd latex
  xelatex <file>.tex (or lualatex <file>.tex)
  ```

  If symbols are missing or XeLaTeX/LuaLaTeX complains about the font
  missing, try setting a different font using:

  ```latex
  \setmathfont{<math-font>}
  ```

  Use the `fc-list` tool to list available fonts.

* Add experimental support for hyperlinks to identifiers

  If the `hyperref` LateX package is loaded before the Agda package
  and the links option is passed to the Agda package, then the Agda
  package provides a function called `\AgdaTarget`. Identifiers which
  have been declared targets, by the user, will become clickable
  hyperlinks in the rest of the document. Here is a small example
  (`test/LaTeXAndHTML/succeed/Links.lagda`):

  ```latex
  \documentclass{article}
  \usepackage{hyperref}
  \usepackage[links]{agda}
  \begin{document}

  \AgdaTarget{ℕ}
  \AgdaTarget{zero}
  \begin{code}
  data ℕ : Set where
    zero  : ℕ
    suc   : ℕ → ℕ
  \end{code}

  See next page for how to define \AgdaFunction{two} (doesn't turn into a
  link because the target hasn't been defined yet). We could do it
  manually though; \hyperlink{two}{\AgdaDatatype{two}}.

  \newpage

  \AgdaTarget{two}
  \hypertarget{two}{}
  \begin{code}
  two : ℕ
  two = suc (suc zero)
  \end{code}

  \AgdaInductiveConstructor{zero} is of type
  \AgdaDatatype{ℕ}. \AgdaInductiveConstructor{suc} has not been defined to
  be a target so it doesn't turn into a link.

  \newpage

  Now that the target for \AgdaFunction{two} has been defined the link
  works automatically.

  \begin{code}
  data Bool : Set where
    true false : Bool
  \end{code}

  The AgdaTarget command takes a list as input, enabling several
  targets to be specified as follows:

  \AgdaTarget{if, then, else, if\_then\_else\_}
  \begin{code}
  if_then_else_ : {A : Set} → Bool → A → A → A
  if true  then t else f = t
  if false then t else f = f
  \end{code}

  \newpage

  Mixfix identifier need their underscores escaped:
  \AgdaFunction{if\_then\_else\_}.

  \end{document}
  ```

  The boarders around the links can be suppressed using hyperref's
  hidelinks option:

  ```latex
    \usepackage[hidelinks]{hyperref}
  ```

  Note that the current approach to links does not keep track of scoping
  or types, and hence overloaded names might create links which point to
  the wrong place. Therefore it is recommended to not overload names
  when using the links option at the moment, this might get fixed in the
  future.

Release notes for Agda 2 version 2.3.2.2
========================================

* Fixed a bug that sometimes made it tricky to use the Emacs mode on
  Windows [Issue [#757](https://github.com/agda/agda/issues/757)].

* Made Agda build with newer versions of some libraries.

* Fixed a bug that caused ambiguous parse error messages
  [Issue [#147](https://github.com/agda/agda/issues/147)].

Release notes for Agda 2 version 2.3.2.1
========================================

Installation
------------

* Made it possible to compile Agda with more recent versions of
  hashable, QuickCheck and Win32.

* Excluded mtl-2.1.

Type checking
-------------

* Fixed bug in the termination checker
  (Issue [#754](https://github.com/agda/agda/issues/754)).

Release notes for Agda 2 version 2.3.2
======================================

Installation
------------

* The Agda-executable package has been removed.

  The executable is now provided as part of the Agda package.

* The Emacs mode no longer depends on haskell-mode or GHCi.

* Compilation of Emacs mode Lisp files.

  You can now compile the Emacs mode Lisp files by running `agda-mode
  compile`. This command is run by `make install`.

  Compilation can, in some cases, give a noticeable speedup.

  WARNING: If you reinstall the Agda mode without recompiling the
  Emacs Lisp files, then Emacs may continue using the old, compiled
  files.

Pragmas and options
-------------------

* The `--without-K` check now reconstructs constructor parameters.

  New specification of `--without-K`:

  If the flag is activated, then Agda only accepts certain
  case-splits. If the type of the variable to be split is
  `D pars ixs`, where `D` is a data (or record) type, `pars` stands
  for the parameters, and `ixs` the indices, then the following
  requirements must be satisfied:

  - The indices `ixs` must be applications of constructors (or
    literals) to distinct variables. Constructors are usually not
    applied to parameters, but for the purposes of this check
    constructor parameters are treated as other arguments.

  - These distinct variables must not be free in pars.

* Irrelevant arguments are printed as `_` by default now.  To turn on
  printing of irrelevant arguments, use option

  ```
  --show-irrelevant
  ```

* New: Pragma `NO_TERMINATION_CHECK` to switch off termination checker
  for individual function definitions and mutual blocks.

  The pragma must precede a function definition or a mutual block.
  Examples (see `test/Succeed/NoTerminationCheck.agda`):

  1. Skipping a single definition: before type signature.

     ```agda
     {-# NO_TERMINATION_CHECK #-}
     a : A
     a = a
     ```

  2. Skipping a single definition: before first clause.

     ```agda
     b : A
     {-# NO_TERMINATION_CHECK #-}
     b = b
     ```

  3. Skipping an old-style mutual block: Before `mutual` keyword.

     ```agda
     {-# NO_TERMINATION_CHECK #-}
     mutual
       c : A
       c = d

       d : A
       d = c
     ```

  4. Skipping a new-style mutual block: Anywhere before a type
     signature or first function clause in the block

     ```agda
     i : A
     j : A

     i = j
     {-# NO_TERMINATION_CHECK #-}
     j = i
     ```

  The pragma cannot be used in `--safe` mode.

Language
--------

* Let binding record patterns

  ```agda
  record _×_ (A B : Set) : Set where
    constructor _,_
    field
      fst : A
      snd : B
  open _×_

  let (x , (y , z)) = t
  in  u
  ```

  will now be interpreted as

  ```agda
  let x = fst t
      y = fst (snd t)
      z = snd (snd t)
  in  u
  ```

  Note that the type of `t` needs to be inferable. If you need to
  provide a type signature, you can write the following:

  ```agda
  let a : ...
      a = t
      (x , (y , z)) = a
  in  u
  ```

* Pattern synonyms

  A pattern synonym is a declaration that can be used on the left hand
  side (when pattern matching) as well as the right hand side (in
  expressions). For example:

  ```agda
  pattern z    = zero
  pattern ss x = suc (suc x)

  f : ℕ -> ℕ
  f z       = z
  f (suc z) = ss z
  f (ss n)  = n
  ```

  Pattern synonyms are implemented by substitution on the abstract
  syntax, so definitions are scope-checked but not type-checked. They
  are particularly useful for universe constructions.

* Qualified mixfix operators

  It is now possible to use a qualified mixfix operator by qualifying
  the first part of the name. For instance

  ```agda
  import Data.Nat as Nat
  import Data.Bool as Bool

  two = Bool.if true then 1 Nat.+ 1 else 0
  ```

* Sections [Issue [#735](https://github.com/agda/agda/issues/735)].
  Agda now parses anonymous modules as sections:

  ```agda
  module _ {a} (A : Set a) where

    data List : Set a where
      []  : List
      _∷_ : (x : A) (xs : List) → List

  module _ {a} {A : Set a} where

    _++_ : List A → List A → List A
    []       ++ ys = ys
    (x ∷ xs) ++ ys = x ∷ (xs ++ ys)

  test : List Nat
  test = (5 ∷ []) ++ (3 ∷ [])
  ```

  In general, now the syntax

  ```agda
  module _ parameters where
    declarations
  ```

  is accepted and has the same effect as

  ```agda
  private
    module M parameters where
      declarations
  open M public
  ```

  for a fresh name `M`.

* Instantiating a module in an open import statement
  [Issue [#481](https://github.com/agda/agda/issues/481)]. Now
  accepted:

  ```agda
  open import Path.Module args [using/hiding/renaming (...)]
  ```

  This only brings the imported identifiers from `Path.Module` into scope,
  not the module itself!  Consequently, the following is pointless, and raises
  an error:

  ```agda
    import Path.Module args [using/hiding/renaming (...)]
  ```

  You can give a private name `M` to the instantiated module via

  ```agda
  import Path.Module args as M [using/hiding/renaming (...)]
  open import Path.Module args as M [using/hiding/renaming (...)]
  ```

  Try to avoid `as` as part of the arguments.  `as` is not a keyword;
  the following can be legal, although slightly obfuscated Agda code:

  ```agda
  open import as as as as as as
  ```

* Implicit module parameters can be given by name. E.g.

  ```agda
  open M {namedArg = bla}
  ```

  This feature has been introduced in Agda 2.3.0 already.

* Multiple type signatures sharing a same type can now be written as a single
  type signature.

  ```agda
  one two : ℕ
  one = suc zero
  two = suc one
  ```

Goal and error display
----------------------

* Meta-variables that were introduced by hidden argument `arg` are now
  printed as `_arg_number` instead of just `_number`.
  [Issue [#526](https://github.com/agda/agda/issues/526)]

* Agda expands identifiers in anonymous modules when printing.  Should
  make some goals nicer to read.
  [Issue [#721](https://github.com/agda/agda/issues/721)]

* When a module identifier is ambiguous, Agda tells you if one of them
  is a data type module.
  [Issues [#318](https://github.com/agda/agda/issues/318),
  [#705](https://github.com/agda/agda/issues/705)]

Type checking
-------------

* Improved coverage checker. The coverage checker splits on arguments
  that have constructor or literal pattern, committing to the
  left-most split that makes progress.  Consider the lookup function
  for vectors:

  ```agda
  data Fin : Nat → Set where
    zero : {n : Nat} → Fin (suc n)
    suc  : {n : Nat} → Fin n → Fin (suc n)

  data Vec (A : Set) : Nat → Set where
    []  : Vec A zero
    _∷_ : {n : Nat} → A → Vec A n → Vec A (suc n)

  _!!_ : {A : Set}{n : Nat} → Vec A n → Fin n → A
  (x ∷ xs) !! zero  = x
  (x ∷ xs) !! suc i = xs !! i
  ```

  In Agda up to 2.3.0, this definition is rejected unless we add
  an absurd clause

  ```agda
  [] !! ()
  ```

  This is because the coverage checker committed on splitting on the
  vector argument, even though this inevitably lead to failed
  coverage, because a case for the empty vector `[]` is missing.

  The improvement to the coverage checker consists on committing only
  on splits that have a chance of covering, since all possible
  constructor patterns are present.  Thus, Agda will now split first
  on the `Fin` argument, since cases for both `zero` and `suc` are
  present.  Then, it can split on the `Vec` argument, since the empty
  vector is already ruled out by instantiating `n` to a `suc _`.

* Instance arguments resolution will now consider candidates which
  still expect hidden arguments. For example:

  ```agda
  record Eq (A : Set) : Set where
    field eq : A → A → Bool

  open Eq {{...}}

  eqFin : {n : ℕ} → Eq (Fin n)
  eqFin = record { eq = primEqFin }

  testFin : Bool
  testFin = eq fin1 fin2
  ```

  The type-checker will now resolve the instance argument of the `eq`
  function to `eqFin {_}`. This is only done for hidden arguments, not
  instance arguments, so that the instance search stays non-recursive.

* Constraint solving: Upgraded Miller patterns to record patterns.
  [Issue [#456](https://github.com/agda/agda/issues/456)]

  Agda now solves meta-variables that are applied to record patterns.
  A typical (but here, artificial) case is:

  ```agda
  record Sigma (A : Set)(B : A -> Set) : Set where
    constructor _,_
    field
      fst : A
      snd : B fst

  test : (A : Set)(B : A -> Set) ->
    let X : Sigma A B -> Sigma A B
        X = _
    in  (x : A)(y : B x) -> X (x , y) ≡ (x , y)
  test A B x y = refl
  ```

  This yields a constraint of the form

  ```
  _X A B (x , y) := t[x,y]
  ```

  (with `t[x,y] = (x, y)`) which is not a Miller pattern.
  However, Agda now solves this as

  ```
  _X A B z := t[fst z,snd z].
  ```

* Changed: solving recursive constraints.
  [Issue [#585](https://github.com/agda/agda/issues/585)]

  Until 2.3.0, Agda sometimes inferred values that did not pass the
  termination checker later, or would even make Agda loop. To prevent
  this, the occurs check now also looks into the definitions of the
  current mutual block, to avoid constructing recursive solutions. As
  a consequence, also terminating recursive solutions are no longer
  found automatically.

  This effects a programming pattern where the recursively computed
  type of a recursive function is left to Agda to solve.

  ```agda
  mutual

    T : D -> Set
    T pattern1 = _
    T pattern2 = _

    f : (d : D) -> T d
    f pattern1 = rhs1
    f pattern2 = rhs2
  ```

  This might no longer work from now on. See examples
  `test/Fail/Issue585*.agda`.

* Less eager introduction of implicit parameters.
  [Issue [#679](https://github.com/agda/agda/issues/679)]

  Until Agda 2.3.0, trailing hidden parameters were introduced eagerly
  on the left hand side of a definition.  For instance, one could not
  write

  ```agda
  test : {A : Set} -> Set
  test = \ {A} -> A
  ```

  because internally, the hidden argument `{A : Set}` was added to the
  left-hand side, yielding

  ```agda
  test {_} = \ {A} -> A
  ```

  which raised a type error.  Now, Agda only introduces the trailing
  implicit parameters it has to, in order to maintain uniform function
  arity.  For instance, in

  ```agda
  test : Bool -> {A B C : Set} -> Set
  test true {A}      = A
  test false {B = B} = B
  ```

  Agda will introduce parameters `A` and `B` in all clauses, but not
  `C`, resulting in

  ```agda
  test : Bool -> {A B C : Set} -> Set
  test true  {A} {_}     = A
  test false {_} {B = B} = B
  ```

  Note that for checking `where`-clauses, still all hidden trailing
  parameters are in scope.  For instance:

  ```agda
  id : {i : Level}{A : Set i} -> A -> A
  id = myId
    where myId : forall {A} -> A -> A
          myId x = x
  ```

  To be able to fill in the meta variable `_1` in

  ```agda
  myId : {A : Set _1} -> A -> A
  ```

  the hidden parameter `{i : Level}` needs to be in scope.

  As a result of this more lazy introduction of implicit parameters,
  the following code now passes.

  ```agda
  data Unit : Set where
    unit : Unit

  T : Unit → Set
  T unit = {u : Unit} → Unit

  test : (u : Unit) → T u
  test unit with unit
  ... | _ = λ {v} → v
  ```

  Before, Agda would eagerly introduce the hidden parameter `{v}` as
  unnamed left-hand side parameter, leaving no way to refer to it.

  The related Issue [#655](https://github.com/agda/agda/issues/655)
  has also been addressed.  It is now possible to make `synonym'
  definitions

  ```
  name = expression
  ```

  even when the type of expression begins with a hidden quantifier.
  Simple example:

  ```
  id2 = id
  ```

  That resulted in unsolved metas until 2.3.0.

* Agda detects unused arguments and ignores them during equality
  checking. [Issue [#691](https://github.com/agda/agda/issues/691),
  solves also Issue [#44](https://github.com/agda/agda/issues/44)]

  Agda's polarity checker now assigns 'Nonvariant' to arguments that
  are not actually used (except for absurd matches).  If `f`'s first
  argument is Nonvariant, then `f x` is definitionally equal to `f y`
  regardless of `x` and `y`.  It is similar to irrelevance, but does
  not require user annotation.

  For instance, unused module parameters do no longer get in the way:

  ```agda
  module M (x : Bool) where

    not : Bool → Bool
    not true  = false
    not false = true

  open M true
  open M false renaming (not to not′)

  test : (y : Bool) → not y ≡ not′ y
  test y = refl
  ```

  Matching against record or absurd patterns does not count as `use',
  so we get some form of proof irrelevance:

  ```agda
  data ⊥ : Set where
  record ⊤ : Set where
    constructor trivial

  data Bool : Set where
    true false : Bool

  True : Bool → Set
  True true  = ⊤
  True false = ⊥

  fun : (b : Bool) → True b → Bool
  fun true  trivial = true
  fun false ()

  test : (b : Bool) → (x y : True b) → fun b x ≡ fun b y
  test b x y = refl
  ```

  More examples in `test/Succeed/NonvariantPolarity.agda`.

  Phantom arguments:  Parameters of record and data types are considered
  `used' even if they are not actually used.  Consider:

  ```agda
  False : Nat → Set
  False zero    = ⊥
  False (suc n) = False n

  module Invariant where
    record Bla (n : Nat)(p : False n) : Set where

  module Nonvariant where
    Bla : (n : Nat) → False n → Set
    Bla n p = ⊤
  ```

  Even though record `Bla` does not use its parameters `n` and `p`,
  they are considered as used, allowing "phantom type" techniques.

  In contrast, the arguments of function `Bla` are recognized as
  unused.  The following code type-checks if we open `Invariant` but
  leaves unsolved metas if we open `Nonvariant`.

  ```agda
  drop-suc : {n : Nat}{p : False n} → Bla (suc n) p → Bla n p
  drop-suc _ = _

  bla : (n : Nat) → {p : False n} → Bla n p → ⊥
  bla zero {()} b
  bla (suc n) b = bla n (drop-suc b)
  ```

  If `Bla` is considered invariant, the hidden argument in the
  recursive call can be inferred to be `p`.  If it is considered
  non-variant, then `Bla n X = Bla n p` does not entail `X = p` and
  the hidden argument remains unsolved.  Since `bla` does not actually
  use its hidden argument, its value is not important and it could be
  searched for.  Unfortunately, polarity analysis of `bla` happens
  only after type checking, thus, the information that `bla` is
  non-variant in `p` is not available yet when meta-variables are
  solved.  (See
  `test/Fail/BrokenInferenceDueToNonvariantPolarity.agda`)

* Agda now expands simple definitions (one clause, terminating) to
  check whether a function is constructor
  headed. [Issue [#747](https://github.com/agda/agda/issues/747)] For
  instance, the following now also works:

  ```agda
  MyPair : Set -> Set -> Set
  MyPair A B = Pair A B

  Vec : Set -> Nat -> Set
  Vec A zero    = Unit
  Vec A (suc n) = MyPair A (Vec A n)
  ```

  Here, `Unit` and `Pair` are data or record types.

Compiler backends
-----------------

* `-Werror` is now overridable.

  To enable compilation of Haskell modules containing warnings, the
  `-Werror` flag for the MAlonzo backend has been made
  overridable. If, for example, `--ghc-flag=-Wwarn` is passed when
  compiling, one can get away with things like:

  ```agda
  data PartialBool : Set where
    true : PartialBool

  {-# COMPILED_DATA PartialBool Bool True #-}
  ```

  The default behavior remains as it used to be and rejects the above
  program.

Tools
-----

### Emacs mode

* Asynchronous Emacs mode.

  One can now use Emacs while a buffer is type-checked. If the buffer
  is edited while the type-checker runs, then syntax highlighting will
  not be updated when type-checking is complete.

* Interactive syntax highlighting.

  The syntax highlighting is updated while a buffer is type-checked:

  - At first the buffer is highlighted in a somewhat crude way
    (without go-to-definition information for overloaded
    constructors).

  - If the highlighting level is "interactive", then the piece of code
    that is currently being type-checked is highlighted as such. (The
    default is "non-interactive".)

  - When a mutual block has been type-checked it is highlighted
    properly (this highlighting includes warnings for potential
    non-termination).

  The highlighting level can be controlled via the new configuration
  variable `agda2-highlight-level`.

* Multiple case-splits can now be performed in one go.

  Consider the following example:

  ```agda
  _==_ : Bool → Bool → Bool
  b₁ == b₂ = {!!}
  ```

  If you split on `b₁ b₂`, then you get the following code:

  ```agda
  _==_ : Bool → Bool → Bool
  true == true = {!!}
  true == false = {!!}
  false == true = {!!}
  false == false = {!!}
  ```

  The order of the variables matters. Consider the following code:

  ```agda
  lookup : ∀ {a n} {A : Set a} → Vec A n → Fin n → A
  lookup xs i = {!!}
  ```

  If you split on `xs i`, then you get the following code:

  ```agda
  lookup : ∀ {a n} {A : Set a} → Vec A n → Fin n → A
  lookup [] ()
  lookup (x ∷ xs) zero = {!!}
  lookup (x ∷ xs) (suc i) = {!!}
  ```

  However, if you split on `i xs`, then you get the following code
  instead:

  ```agda
  lookup : ∀ {a n} {A : Set a} → Vec A n → Fin n → A
  lookup (x ∷ xs) zero = ?
  lookup (x ∷ xs) (suc i) = ?
  ```

  This code is rejected by Agda 2.3.0, but accepted by 2.3.2 thanks
  to improved coverage checking (see above).

* The Emacs mode now presents information about which module is
  currently being type-checked.

* New global menu entry: `Information about the character at point`.

  If this entry is selected, then information about the character at
  point is displayed, including (in many cases) information about how
  to type the character.

* Commenting/uncommenting the rest of the buffer.

  One can now comment or uncomment the rest of the buffer by typing
  `C-c C-x M-;` or by selecting the menu entry `Comment/uncomment` the
  rest of the buffer".

* The Emacs mode now uses the Agda executable instead of GHCi.

  The `*ghci*` buffer has been renamed to `*agda2*`.

  A new configuration variable has been introduced:
  `agda2-program-name`, the name of the Agda executable (by default
  `agda`).

  The variable `agda2-ghci-options` has been replaced by
  `agda2-program-args`: extra arguments given to the Agda executable
  (by default `none`).

  If you want to limit Agda's memory consumption you can add some
  arguments to `agda2-program-args`, for instance `+RTS -M1.5G -RTS`.

* The Emacs mode no longer depends on haskell-mode.

  Users who have customised certain haskell-mode variables (such as
  `haskell-ghci-program-args`) may want to update their configuration.

### LaTeX-backend

An experimental LaTeX-backend which does precise highlighting a la the
HTML-backend and code alignment a la lhs2TeX has been added.

Here is a sample input literate Agda file:

  ```latex
  \documentclass{article}

  \usepackage{agda}

  \begin{document}

  The following module declaration will be hidden in the output.

  \AgdaHide{
  \begin{code}
  module M where
  \end{code}
  }

  Two or more spaces can be used to make the backend align stuff.

  \begin{code}
  data ℕ : Set where
    zero  : ℕ
    suc   : ℕ → ℕ

  _+_ : ℕ → ℕ → ℕ
  zero   + n = n
  suc m  + n = suc (m + n)
  \end{code}

  \end{document}
  ```

To produce an output PDF issue the following commands:

  ```
  agda --latex -i . <file>.lagda
  pdflatex latex/<file>.tex
  ```

Only the top-most module is processed, like with lhs2tex and unlike
with the HTML-backend. If you want to process imported modules you
have to call `agda --latex` manually on each of those modules.

There are still issues related to formatting, see the bug tracker for
more information:

  https://code.google.com/p/agda/issues/detail?id=697

The default `agda.sty` might therefore change in backwards-incompatible
ways, as work proceeds in trying to resolve those problems.

Implemented features:

* Two or more spaces can be used to force alignment of things, like
  with lhs2tex. See example above.

* The highlighting information produced by the type checker is used to
  generate the output. For example, the data declaration in the
  example above, produces:

  ```agda
  \AgdaKeyword{data} \AgdaDatatype{ℕ} \AgdaSymbol{:}
      \AgdaPrimitiveType{Set} \AgdaKeyword{where}
  ```

  These LaTeX commands are defined in `agda.sty` (which is imported by
  `\usepackage{agda}`) and cause the highlighting.

* The LaTeX-backend checks if `agda.sty` is found by the LaTeX
  environment, if it isn't a default `agda.sty` is copied from Agda's
  `data-dir` into the working directory (and thus made available to
  the LaTeX environment).

  If the default `agda.sty` isn't satisfactory (colors, fonts,
  spacing, etc) then the user can modify it and make put it somewhere
  where the LaTeX environment can find it. Hopefully most aspects
  should be modifiable via `agda.sty` rather than having to tweak the
  implementation.

* `--latex-dir` can be used to change the default output directory.

Release notes for Agda 2 version 2.3.0
======================================

Language
--------

* New more liberal syntax for mutually recursive definitions.

  It is no longer necessary to use the `mutual` keyword to define
  mutually recursive functions or datatypes. Instead, it is enough to
  declare things before they are used. Instead of

  ```agda
  mutual
    f : A
    f = a[f, g]

    g : B[f]
    g = b[f, g]
  ```

  you can now write

  ```agda
  f : A
  g : B[f]
  f = a[f, g]
  g = b[f, g].
  ```

  With the new style you have more freedom in choosing the order in
  which things are type checked (previously type signatures were
  always checked before definitions). Furthermore you can mix
  arbitrary declarations, such as modules and postulates, with
  mutually recursive definitions.

  For data types and records the following new syntax is used to
  separate the declaration from the definition:

  ```agda
  -- Declaration.
  data Vec (A : Set) : Nat → Set  -- Note the absence of 'where'.

  -- Definition.
  data Vec A where
    []   : Vec A zero
    _::_ : {n : Nat} → A → Vec A n → Vec A (suc n)

  -- Declaration.
  record Sigma (A : Set) (B : A → Set) : Set

  -- Definition.
  record Sigma A B where
    constructor _,_
    field fst : A
          snd : B fst
  ```

  When making separated declarations/definitions private or abstract
  you should attach the `private` keyword to the declaration and the
  `abstract` keyword to the definition. For instance, a private,
  abstract function can be defined as

  ```agda
  private
    f : A
  abstract
    f = e
  ```

  Finally it may be worth noting that the old style of mutually
  recursive definitions is still supported (it basically desugars into
  the new style).

* Pattern matching lambdas.

  Anonymous pattern matching functions can be defined using the syntax

  ```
  \ { p11 .. p1n -> e1 ; ... ; pm1 .. pmn -> em }
  ```

  (where, as usual, `\` and `->` can be replaced by `λ` and
  `→`). Internally this is translated into a function definition of
  the following form:

  ```
  .extlam p11 .. p1n = e1
  ...
  .extlam pm1 .. pmn = em
  ```

  This means that anonymous pattern matching functions are generative.
  For instance, `refl` will not be accepted as an inhabitant of the type

  ```agda
  (λ { true → true ; false → false }) ≡
  (λ { true → true ; false → false }),
  ```

  because this is equivalent to `extlam1 ≡ extlam2` for some distinct
  fresh names `extlam1` and `extlam2`.

  Currently the `where` and `with` constructions are not allowed in
  (the top-level clauses of) anonymous pattern matching functions.

  Examples:

  ```agda
  and : Bool → Bool → Bool
  and = λ { true x → x ; false _ → false }

  xor : Bool → Bool → Bool
  xor = λ { true  true  → false
          ; false false → false
          ; _     _     → true
          }

  fst : {A : Set} {B : A → Set} → Σ A B → A
  fst = λ { (a , b) → a }

  snd : {A : Set} {B : A → Set} (p : Σ A B) → B (fst p)
  snd = λ { (a , b) → b }
  ```

* Record update syntax.

  Assume that we have a record type and a corresponding value:

  ```agda
  record MyRecord : Set where
    field
      a b c : ℕ

  old : MyRecord
  old = record { a = 1; b = 2; c = 3 }
  ```

  Then we can update (some of) the record value's fields in the
  following way:

  ```agda
  new : MyRecord
  new = record old { a = 0; c = 5 }
  ```

  Here new normalises to `record { a = 0; b = 2; c = 5 }`. Any
  expression yielding a value of type `MyRecord` can be used instead of
  old.

  Record updating is not allowed to change types: the resulting value
  must have the same type as the original one, including the record
  parameters. Thus, the type of a record update can be inferred if the
  type of the original record can be inferred.

  The record update syntax is expanded before type checking. When the
  expression

  ```agda
  record old { upd-fields }
  ```

  is checked against a record type `R`, it is expanded to

  ```agda
  let r = old in record { new-fields },
  ```

  where old is required to have type `R` and new-fields is defined as
  follows: for each field `x` in `R`,

    - if `x = e` is contained in `upd-fields` then `x = e` is included in
      `new-fields`, and otherwise

    - if `x` is an explicit field then `x = R.x r` is included in
      `new-fields`, and

    - if `x` is an implicit or instance field, then it is omitted from
      `new-fields`.

  (Instance arguments are explained below.) The reason for treating
  implicit and instance fields specially is to allow code like the
  following:

  ```agda
  record R : Set where
    field
      {length} : ℕ
      vec      : Vec ℕ length
      -- More fields…

  xs : R
  xs = record { vec = 0 ∷ 1 ∷ 2 ∷ [] }

  ys = record xs { vec = 0 ∷ [] }
  ```

  Without the special treatment the last expression would need to
  include a new binding for length (for instance `length = _`).

* Record patterns which do not contain data type patterns, but which
  do contain dot patterns, are no longer rejected.

* When the `--without-K` flag is used literals are now treated as
  constructors.

* Under-applied functions can now reduce.

  Consider the following definition:

  ```agda
  id : {A : Set} → A → A
  id x = x
  ```

  Previously the expression `id` would not reduce. This has been
  changed so that it now reduces to `λ x → x`. Usually this makes
  little difference, but it can be important in conjunction with
  `with`. See Issue [#365](https://github.com/agda/agda/issues/365)
  for an example.

* Unused AgdaLight legacy syntax `(x y : A; z v : B)` for telescopes
  has been removed.

### Universe polymorphism

* Universe polymorphism is now enabled by default.  Use
  `--no-universe-polymorphism` to disable it.

* Universe levels are no longer defined as a data type.

  The basic level combinators can be introduced in the following way:

  ```agda
  postulate
    Level : Set
    zero  : Level
    suc   : Level → Level
    max   : Level → Level → Level

  {-# BUILTIN LEVEL     Level #-}
  {-# BUILTIN LEVELZERO zero  #-}
  {-# BUILTIN LEVELSUC  suc   #-}
  {-# BUILTIN LEVELMAX  max   #-}
  ```

* The BUILTIN equality is now required to be universe-polymorphic.

* `trustMe` is now universe-polymorphic.

### Meta-variables and unification

* Unsolved meta-variables are now frozen after every mutual block.
  This means that they cannot be instantiated by subsequent code. For
  instance,

  ```agda
  one : Nat
  one = _

  bla : one ≡ suc zero
  bla = refl
  ```

  leads to an error now, whereas previously it lead to the
  instantiation of `_` with `suc zero`. If you want to make use of the
  old behaviour, put the two definitions in a mutual block.

  All meta-variables are unfrozen during interactive editing, so that
  the user can fill holes interactively. Note that type-checking of
  interactively given terms is not perfect: Agda sometimes refuses to
  load a file, even though no complaints were raised during the
  interactive construction of the file. This is because certain checks
  (for instance, positivity) are only invoked when a file is loaded.

* Record types can now be inferred.

  If there is a unique known record type with fields matching the
  fields in a record expression, then the type of the expression will
  be inferred to be the record type applied to unknown parameters.

  If there is no known record type with the given fields the type
  checker will give an error instead of producing lots of unsolved
  meta-variables.

  Note that "known record type" refers to any record type in any
  imported module, not just types which are in scope.

* The occurrence checker distinguishes rigid and strongly rigid
  occurrences [Reed, LFMTP 2009; Abel & Pientka, TLCA 2011].

  The completeness checker now accepts the following code:

  ```agda
  h : (n : Nat) → n ≡ suc n → Nat
  h n ()
  ```

  Internally this generates a constraint `_n = suc _n` where the
  meta-variable `_n` occurs strongly rigidly, i.e. on a constructor
  path from the root, in its own defining term tree. This is never
  solvable.

  Weakly rigid recursive occurrences may have a solution [Jason Reed's
  PhD thesis, page 106]:

  ```agda
  test : (k : Nat) →
         let X : (Nat → Nat) → Nat
             X = _
         in
         (f : Nat → Nat) → X f ≡ suc (f (X (λ x → k)))
  test k f = refl
  ```

  The constraint `_X k f = suc (f (_X k (λ x → k)))` has the solution
  `_X k f = suc (f (suc k))`, despite the recursive occurrence of
  `_X`.  Here `_X` is not strongly rigid, because it occurs under the
  bound variable `f`. Previously Agda rejected this code; now it instead
  complains about an unsolved meta-variable.

* Equation constraints involving the same meta-variable in the head
  now trigger pruning [Pientka, PhD, Sec. 3.1.2; Abel & Pientka, TLCA
  2011]. Example:

  ```agda
  same : let X : A → A → A → A × A
             X = _
         in {x y z : A} → X x y y ≡ (x , y)
                        × X x x y ≡ X x y y
  same = refl , refl
  ```

  The second equation implies that `X` cannot depend on its second
  argument. After pruning the first equation is linear and can be
  solved.

* Instance arguments.

  A new type of hidden function arguments has been added: instance
  arguments. This new feature is based on influences from Scala's
  implicits and Agda's existing implicit arguments.

  Plain implicit arguments are marked by single braces: `{…}`. Instance
  arguments are instead marked by double braces: `{{…}}`. Example:

  ```agda
  postulate
    A : Set
    B : A → Set
    a : A
    f : {{a : A}} → B a
  ```

  Instead of the double braces you can use the symbols `⦃` and `⦄`,
  but these symbols must in many cases be surrounded by
  whitespace. (If you are using Emacs and the Agda input method, then
  you can conjure up the symbols by typing `\{{` and `\}}`,
  respectively.)

  Instance arguments behave as ordinary implicit arguments, except for
  one important aspect: resolution of arguments which are not provided
  explicitly. For instance, consider the following code:

  ```agda
    test = f
  ```

  Here Agda will notice that `f`'s instance argument was not provided
  explicitly, and try to infer it. All definitions in scope at `f`'s
  call site, as well as all variables in the context, are considered.
  If exactly one of these names has the required type `A`, then the
  instance argument will be instantiated to this name.

  This feature can be used as an alternative to Haskell type classes.
  If we define

  ```agda
  record Eq (A : Set) : Set where
    field equal : A → A → Bool,
  ```

  then we can define the following projection:

  ```agda
  equal : {A : Set} {{eq : Eq A}} → A → A → Bool
  equal {{eq}} = Eq.equal eq
  ```

  Now consider the following expression:

  ```agda
  equal false false ∨ equal 3 4
  ```

  If the following `Eq` "instances" for `Bool` and `ℕ` are in scope, and no
  others, then the expression is accepted:

  ```agda
  eq-Bool : Eq Bool
  eq-Bool = record { equal = … }

  eq-ℕ : Eq ℕ
  eq-ℕ = record { equal = … }
  ```

  A shorthand notation is provided to avoid the need to define
  projection functions manually:

  ```agda
  module Eq-with-implicits = Eq {{...}}
  ```

  This notation creates a variant of `Eq`'s record module, where the
  main `Eq` argument is an instance argument instead of an explicit one.
  It is equivalent to the following definition:

  ```agda
  module Eq-with-implicits {A : Set} {{eq : Eq A}} = Eq eq
  ```

  Note that the short-hand notation allows you to avoid naming the
  "-with-implicits" module:

  ```agda
  open Eq {{...}}
  ```

  Instance argument resolution is not recursive. As an example,
  consider the following "parametrised instance":

  ```agda
  eq-List : {A : Set} → Eq A → Eq (List A)
  eq-List {A} eq = record { equal = eq-List-A }
    where
    eq-List-A : List A → List A → Bool
    eq-List-A []       []       = true
    eq-List-A (a ∷ as) (b ∷ bs) = equal a b ∧ eq-List-A as bs
    eq-List-A _        _        = false
  ```

  Assume that the only `Eq` instances in scope are `eq-List` and
  `eq-ℕ`.  Then the following code does not type-check:

  ```agda
  test = equal (1 ∷ 2 ∷ []) (3 ∷ 4 ∷ [])
  ```

  However, we can make the code work by constructing a suitable
  instance manually:

  ```agda
  test′ = equal (1 ∷ 2 ∷ []) (3 ∷ 4 ∷ [])
    where eq-List-ℕ = eq-List eq-ℕ
  ```

  By restricting the "instance search" to be non-recursive we avoid
  introducing a new, compile-time-only evaluation model to Agda.

  For more information about instance arguments, see Devriese &
  Piessens [ICFP 2011]. Some examples are also available in the
  examples/instance-arguments subdirectory of the Agda distribution.

### Irrelevance

* Dependent irrelevant function types.

  Some examples illustrating the syntax of dependent irrelevant
  function types:

  ```
  .(x y : A) → B    .{x y z : A} → B
  ∀ x .y → B        ∀ x .{y} {z} .v → B
  ```

  The declaration

  ```
  f : .(x : A) → B[x]
  f x = t[x]
  ```

  requires that `x` is irrelevant both in `t[x]` and in `B[x]`. This
  is possible if, for instance, `B[x] = B′ x`, with `B′ : .A → Set`.

  Dependent irrelevance allows us to define the eliminator for the
  `Squash` type:

  ```agda
  record Squash (A : Set) : Set where
    constructor squash
    field
      .proof : A

  elim-Squash : {A : Set} (P : Squash A → Set)
                (ih : .(a : A) → P (squash a)) →
                (a⁻ : Squash A) → P a⁻
  elim-Squash P ih (squash a) = ih a
  ```

  Note that this would not type-check with

  ```agda
  (ih : (a : A) -> P (squash a)).
  ```

* Records with only irrelevant fields.

  The following now works:

  ```agda
  record IsEquivalence {A : Set} (_≈_ : A → A → Set) : Set where
    field
      .refl  : Reflexive _≈_
      .sym   : Symmetric _≈_
      .trans : Transitive _≈_

  record Setoid : Set₁ where
    infix 4 _≈_
    field
      Carrier        : Set
      _≈_            : Carrier → Carrier → Set
      .isEquivalence : IsEquivalence _≈_

    open IsEquivalence isEquivalence public
  ```

  Previously Agda complained about the application
  `IsEquivalence isEquivalence`, because `isEquivalence` is irrelevant
  and the `IsEquivalence` module expected a relevant argument. Now,
  when record modules are generated for records consisting solely of
  irrelevant arguments, the record parameter is made irrelevant:

   ```agda
  module IsEquivalence {A : Set} {_≈_ : A → A → Set}
                       .(r : IsEquivalence {A = A} _≈_) where
    …
  ```

* Irrelevant things are no longer erased internally. This means that
  they are printed as ordinary terms, not as `_` as before.

* The new flag `--experimental-irrelevance` enables irrelevant
  universe levels and matching on irrelevant data when only one
  constructor is available. These features are very experimental and
  likely to change or disappear.

### Reflection

* The reflection API has been extended to mirror features like
  irrelevance, instance arguments and universe polymorphism, and to
  give (limited) access to definitions. For completeness all the
  builtins and primitives are listed below:

  ```agda
  -- Names.

  postulate Name : Set

  {-# BUILTIN QNAME Name #-}

  primitive
    -- Equality of names.
    primQNameEquality : Name → Name → Bool

  -- Is the argument visible (explicit), hidden (implicit), or an
  -- instance argument?

  data Visibility : Set where
    visible hidden instance : Visibility

  {-# BUILTIN HIDING   Visibility #-}
  {-# BUILTIN VISIBLE  visible    #-}
  {-# BUILTIN HIDDEN   hidden     #-}
  {-# BUILTIN INSTANCE instance   #-}

  -- Arguments can be relevant or irrelevant.

  data Relevance : Set where
    relevant irrelevant : Relevance

  {-# BUILTIN RELEVANCE  Relevance  #-}
  {-# BUILTIN RELEVANT   relevant   #-}
  {-# BUILTIN IRRELEVANT irrelevant #-}

  -- Arguments.

  data Arg A : Set where
    arg : (v : Visibility) (r : Relevance) (x : A) → Arg A

  {-# BUILTIN ARG    Arg #-}
  {-# BUILTIN ARGARG arg #-}

  -- Terms.

  mutual
    data Term : Set where
      -- Variable applied to arguments.
      var     : (x : ℕ) (args : List (Arg Term)) → Term
      -- Constructor applied to arguments.
      con     : (c : Name) (args : List (Arg Term)) → Term
      -- Identifier applied to arguments.
      def     : (f : Name) (args : List (Arg Term)) → Term
      -- Different kinds of λ-abstraction.
      lam     : (v : Visibility) (t : Term) → Term
      -- Pi-type.
      pi      : (t₁ : Arg Type) (t₂ : Type) → Term
      -- A sort.
      sort    : Sort → Term
      -- Anything else.
      unknown : Term

    data Type : Set where
      el : (s : Sort) (t : Term) → Type

    data Sort : Set where
      -- A Set of a given (possibly neutral) level.
      set     : (t : Term) → Sort
      -- A Set of a given concrete level.
      lit     : (n : ℕ) → Sort
      -- Anything else.
      unknown : Sort

  {-# BUILTIN AGDASORT            Sort    #-}
  {-# BUILTIN AGDATYPE            Type    #-}
  {-# BUILTIN AGDATERM            Term    #-}
  {-# BUILTIN AGDATERMVAR         var     #-}
  {-# BUILTIN AGDATERMCON         con     #-}
  {-# BUILTIN AGDATERMDEF         def     #-}
  {-# BUILTIN AGDATERMLAM         lam     #-}
  {-# BUILTIN AGDATERMPI          pi      #-}
  {-# BUILTIN AGDATERMSORT        sort    #-}
  {-# BUILTIN AGDATERMUNSUPPORTED unknown #-}
  {-# BUILTIN AGDATYPEEL          el      #-}
  {-# BUILTIN AGDASORTSET         set     #-}
  {-# BUILTIN AGDASORTLIT         lit     #-}
  {-# BUILTIN AGDASORTUNSUPPORTED unknown #-}

  postulate
    -- Function definition.
    Function  : Set
    -- Data type definition.
    Data-type : Set
    -- Record type definition.
    Record    : Set

  {-# BUILTIN AGDAFUNDEF    Function  #-}
  {-# BUILTIN AGDADATADEF   Data-type #-}
  {-# BUILTIN AGDARECORDDEF Record    #-}

  -- Definitions.

  data Definition : Set where
    function     : Function  → Definition
    data-type    : Data-type → Definition
    record′      : Record    → Definition
    constructor′ : Definition
    axiom        : Definition
    primitive′   : Definition

  {-# BUILTIN AGDADEFINITION                Definition   #-}
  {-# BUILTIN AGDADEFINITIONFUNDEF          function     #-}
  {-# BUILTIN AGDADEFINITIONDATADEF         data-type    #-}
  {-# BUILTIN AGDADEFINITIONRECORDDEF       record′      #-}
  {-# BUILTIN AGDADEFINITIONDATACONSTRUCTOR constructor′ #-}
  {-# BUILTIN AGDADEFINITIONPOSTULATE       axiom        #-}
  {-# BUILTIN AGDADEFINITIONPRIMITIVE       primitive′   #-}

  primitive
    -- The type of the thing with the given name.
    primQNameType        : Name → Type
    -- The definition of the thing with the given name.
    primQNameDefinition  : Name → Definition
    -- The constructors of the given data type.
    primDataConstructors : Data-type → List Name
  ```

  As an example the expression

  ```agda
  primQNameType (quote zero)
  ```

  is definitionally equal to

  ```agda
  el (lit 0) (def (quote ℕ) [])
  ```

  (if `zero` is a constructor of the data type `ℕ`).

* New keyword: `unquote`.

  The construction `unquote t` converts a representation of an Agda term
  to actual Agda code in the following way:

  1. The argument `t` must have type `Term` (see the reflection API above).

  2. The argument is normalised.

  3. The entire construction is replaced by the normal form, which is
     treated as syntax written by the user and type-checked in the
     usual way.

  Examples:

  ```agda
  test : unquote (def (quote ℕ) []) ≡ ℕ
  test = refl

  id : (A : Set) → A → A
  id = unquote (lam visible (lam visible (var 0 [])))

  id-ok : id ≡ (λ A (x : A) → x)
  id-ok = refl
  ```

* New keyword: `quoteTerm`.

  The construction `quoteTerm t` is similar to `quote n`, but whereas
  `quote` is restricted to names `n`, `quoteTerm` accepts terms
  `t`. The construction is handled in the following way:

  1. The type of `t` is inferred. The term `t` must be type-correct.

  2. The term `t` is normalised.

  3. The construction is replaced by the Term representation (see the
     reflection API above) of the normal form. Any unsolved metavariables
     in the term are represented by the `unknown` term constructor.

  Examples:

  ```agda
  test₁ : quoteTerm (λ {A : Set} (x : A) → x) ≡
          lam hidden (lam visible (var 0 []))
  test₁ = refl

  -- Local variables are represented as de Bruijn indices.
  test₂ : (λ {A : Set} (x : A) → quoteTerm x) ≡ (λ x → var 0 [])
  test₂ = refl

  -- Terms are normalised before being quoted.
  test₃ : quoteTerm (0 + 0) ≡ con (quote zero) []
  test₃ = refl
  ```

Compiler backends
-----------------

### MAlonzo

* The MAlonzo backend's FFI now handles universe polymorphism in a
  better way.

  The translation of Agda types and kinds into Haskell now supports
  universe-polymorphic postulates. The core changes are that the
  translation of function types has been changed from

  ```
  T[[ Pi (x : A) B ]] =
    if A has a Haskell kind then
      forall x. () -> T[[ B ]]
    else if x in fv B then
      undef
    else
      T[[ A ]] -> T[[ B ]]
  ```

  into

  ```
  T[[ Pi (x : A) B ]] =
    if x in fv B then
      forall x. T[[ A ]] -> T[[ B ]]  -- Note: T[[A]] not Unit.
    else
      T[[ A ]] -> T[[ B ]],
  ```

  and that the translation of constants (postulates, constructors and
  literals) has been changed from

  ```
  T[[ k As ]] =
    if COMPILED_TYPE k T then
      T T[[ As ]]
    else
      undef
  ```

  into

  ```
  T[[ k As ]] =
    if COMPILED_TYPE k T then
      T T[[ As ]]
    else if COMPILED k E then
      ()
    else
      undef.
  ```

  For instance, assuming a Haskell definition

  ```haskell
    type AgdaIO a b = IO b,
  ```

  we can set up universe-polymorphic `IO` in the following way:

  ```agda
  postulate
    IO     : ∀ {ℓ} → Set ℓ → Set ℓ
    return : ∀ {a} {A : Set a} → A → IO A
    _>>=_  : ∀ {a b} {A : Set a} {B : Set b} →
             IO A → (A → IO B) → IO B

  {-# COMPILED_TYPE IO AgdaIO              #-}
  {-# COMPILED return  (\_ _ -> return)    #-}
  {-# COMPILED _>>=_   (\_ _ _ _ -> (>>=)) #-}
  ```

  This is accepted because (assuming that the universe level type is
  translated to the Haskell unit type `()`)

  ```haskell
  (\_ _ -> return)
    : forall a. () -> forall b. () -> b -> AgdaIO a b
    = T [[ ∀ {a} {A : Set a} → A → IO A ]]
  ```

  and

  ```haskell
  (\_ _ _ _ -> (>>=))
    : forall a. () -> forall b. () ->
        forall c. () -> forall d. () ->
          AgdaIO a c -> (c -> AgdaIO b d) -> AgdaIO b d
    = T [[ ∀ {a b} {A : Set a} {B : Set b} →
             IO A → (A → IO B) → IO B ]].
  ```

### Epic

* New Epic backend pragma: `STATIC`.

  In the Epic backend, functions marked with the `STATIC` pragma will be
  normalised before compilation. Example usage:

  ```
  {-# STATIC power #-}

  power : ℕ → ℕ → ℕ
  power 0       x = 1
  power 1       x = x
  power (suc n) x = power n x * x
  ```

  Occurrences of `power 4 x` will be replaced by `((x * x) * x) * x`.

* Some new optimisations have been implemented in the Epic backend:

  - Removal of unused arguments.

  A worker/wrapper transformation is performed so that unused
  arguments can be removed by Epic's inliner. For instance, the map
  function is transformed in the following way:

  ```agda
  map_wrap : (A B : Set) → (A → B) → List A → List B
  map_wrap A B f xs = map_work f xs

  map_work f []       = []
  map_work f (x ∷ xs) = f x ∷ map_work f xs
  ```

  If `map_wrap` is inlined (which it will be in any saturated call),
  then `A` and `B` disappear in the generated code.

  Unused arguments are found using abstract interpretation. The bodies
  of all functions in a module are inspected to decide which variables
  are used. The behaviour of postulates is approximated based on their
  types. Consider `return`, for instance:

  ```agda
  postulate return : {A : Set} → A → IO A
  ```

  The first argument of `return` can be removed, because it is of type
  Set and thus cannot affect the outcome of a program at runtime.

  - Injection detection.

  At runtime many functions may turn out to be inefficient variants of
  the identity function. This is especially true after forcing.
  Injection detection replaces some of these functions with more
  efficient versions. Example:

  ```agda
  inject : {n : ℕ} → Fin n → Fin (1 + n)
  inject {suc n} zero    = zero
  inject {suc n} (suc i) = suc (inject {n} i)
  ```

  Forcing removes the `Fin` constructors' `ℕ` arguments, so this
  function is an inefficient identity function that can be replaced by
  the following one:

  ```agda
  inject {_} x = x
  ```

  To actually find this function, we make the induction hypothesis
  that inject is an identity function in its second argument and look
  at the branches of the function to decide if this holds.

  Injection detection also works over data type barriers. Example:

  ```agda
  forget : {A : Set} {n : ℕ} → Vec A n → List A
  forget []       = []
  forget (x ∷ xs) = x ∷ forget xs
  ```

  Given that the constructor tags (in the compiled Epic code) for
  `Vec.[]` and `List.[]` are the same, and that the tags for `Vec._∷_`
  and `List._∷_` are also the same, this is also an identity
  function. We can hence replace the definition with the following
  one:

  ```agda
  forget {_} xs = xs
  ```

  To get this to apply as often as possible, constructor tags are
  chosen *after* injection detection has been run, in a way to make as
  many functions as possible injections.

  Constructor tags are chosen once per source file, so it may be
  advantageous to define conversion functions like forget in the same
  module as one of the data types. For instance, if `Vec.agda` imports
  `List.agda`, then the forget function should be put in `Vec.agda` to
  ensure that vectors and lists get the same tags (unless some other
  injection function, which puts different constraints on the tags, is
  prioritised).

  - Smashing.

  This optimisation finds types whose values are inferable at runtime:

    * A data type with only one constructor where all fields are
      inferable is itself inferable.

    * `Set ℓ` is inferable (as it has no runtime representation).

  A function returning an inferable data type can be smashed, which
  means that it is replaced by a function which simply returns the
  inferred value.

  An important example of an inferable type is the usual propositional
  equality type (`_≡_`). Any function returning a propositional
  equality can simply return the reflexivity constructor directly
  without computing anything.

  This optimisation makes more arguments unused. It also makes the
  Epic code size smaller, which in turn speeds up compilation.

### JavaScript

* ECMAScript compiler backend.

  A new compiler backend is being implemented, targetting ECMAScript
  (also known as JavaScript), with the goal of allowing Agda programs
  to be run in browsers or other ECMAScript environments.

  The backend is still at an experimental stage: the core language is
  implemented, but many features are still missing.

  The ECMAScript compiler can be invoked from the command line using
  the flag `--js`:

  ```
  agda --js --compile-dir=<DIR> <FILE>.agda
  ```

  Each source `<FILE>.agda` is compiled into an ECMAScript target
  `<DIR>/jAgda.<TOP-LEVEL MODULE NAME>.js`. The compiler can also be
  invoked using the Emacs mode (the variable `agda2-backend` controls
  which backend is used).

  Note that ECMAScript is a strict rather than lazy language. Since
  Agda programs are total, this should not impact program semantics,
  but it may impact their space or time usage.

  ECMAScript does not support algebraic datatypes or pattern-matching.
  These features are translated to a use of the visitor pattern. For
  instance, the standard library's `List` data type and `null`
  function are translated into the following code:

  ```javascript
  exports["List"] = {};
  exports["List"]["[]"] = function (x0) {
      return x0["[]"]();
    };
  exports["List"]["_∷_"] = function (x0) {
      return function (x1) {
        return function (x2) {
          return x2["_∷_"](x0, x1);
        };
      };
    };

  exports["null"] = function (x0) {
      return function (x1) {
        return function (x2) {
          return x2({
            "[]": function () {
              return jAgda_Data_Bool["Bool"]["true"];
            },
            "_∷_": function (x3, x4) {
              return jAgda_Data_Bool["Bool"]["false"];
            }
          });
        };
      };
    };
  ```

  Agda records are translated to ECMAScript objects, preserving field
  names.

  Top-level Agda modules are translated to ECMAScript modules,
  following the `common.js` module specification. A top-level Agda
  module `Foo.Bar` is translated to an ECMAScript module
  `jAgda.Foo.Bar`.

  The ECMAScript compiler does not compile to Haskell, so the pragmas
  related to the Haskell FFI (`IMPORT`, `COMPILED_DATA` and
  `COMPILED`) are not used by the ECMAScript backend. Instead, there
  is a `COMPILED_JS` pragma which may be applied to any
  declaration. For postulates, primitives, functions and values, it
  gives the ECMAScript code to be emitted by the compiler. For data
  types, it gives a function which is applied to a value of that type,
  and a visitor object. For instance, a binding of natural numbers to
  ECMAScript integers (ignoring overflow errors) is:

  ```agda
  data ℕ : Set where
    zero : ℕ
    suc  : ℕ → ℕ

  {-# COMPILED_JS ℕ function (x,v) {
      if (x < 1) { return v.zero(); } else { return v.suc(x-1); }
    } #-}
  {-# COMPILED_JS zero 0 #-}
  {-# COMPILED_JS suc function (x) { return x+1; } #-}

  _+_ : ℕ → ℕ → ℕ
  zero  + n = n
  suc m + n = suc (m + n)

  {-# COMPILED_JS _+_ function (x) { return function (y) {
                        return x+y; };
    } #-}
  ```

  To allow FFI code to be optimised, the ECMAScript in a `COMPILED_JS`
  declaration is parsed, using a simple parser that recognises a pure
  functional subset of ECMAScript, consisting of functions, function
  applications, return, if-statements, if-expressions,
  side-effect-free binary operators (no precedence, left associative),
  side-effect-free prefix operators, objects (where all member names
  are quoted), field accesses, and string and integer literals.
  Modules may be imported using the require (`<module-id>`) syntax: any
  impure code, or code outside the supported fragment, can be placed
  in a module and imported.

Tools
-----

* New flag `--safe`, which can be used to type-check untrusted code.

  This flag disables postulates, `primTrustMe`, and "unsafe" OPTION
  pragmas, some of which are known to make Agda inconsistent.

  Rejected pragmas:

  ```
  --allow-unsolved-metas
  --experimental-irrelevance
  --guardedness-preserving-type-construtors
  --injective-type-constructors
  --no-coverage-check
  --no-positivity-check
  --no-termination-check
  --sized-types
  --type-in-type
  ```

  Note that, at the moment, it is not possible to define the universe
  level or coinduction primitives when `--safe` is used (because they
  must be introduced as postulates). This can be worked around by
  type-checking trusted files in a first pass, without using `--safe`,
  and then using `--saf`e in a second pass. Modules which have already
  been type-checked are not re-type-checked just because `--safe` is
  used.

* Dependency graphs.

  The new flag `--dependency-graph=FILE` can be used to generate a DOT
  file containing a module dependency graph. The generated file (FILE)
  can be rendered using a tool like dot.

* The `--no-unreachable-check` flag has been removed.

* Projection functions are highlighted as functions instead of as
  fields. Field names (in record definitions and record values) are
  still highlighted as fields.

* Support for jumping to positions mentioned in the information
  buffer has been added.

* The `make install` command no longer installs Agda globally (by
  default).

Release notes for Agda 2 version 2.2.10
=======================================

Language
--------

* New flag: `--without-K`.

  This flag makes pattern matching more restricted. If the flag is
  activated, then Agda only accepts certain case-splits. If the type
  of the variable to be split is `D pars ixs`, where `D` is a data (or
  record) type, pars stands for the parameters, and `ixs` the indices,
  then the following requirements must be satisfied:

  - The indices `ixs` must be applications of constructors to distinct
    variables.

  - These variables must not be free in pars.

  The intended purpose of `--without-K` is to enable experiments with
  a propositional equality without the K rule. Let us define
  propositional equality as follows:

  ```agda
  data _≡_ {A : Set} : A → A → Set where
    refl : ∀ x → x ≡ x
  ```

  Then the obvious implementation of the J rule is accepted:

  ```agda
  J : {A : Set} (P : {x y : A} → x ≡ y → Set) →
      (∀ x → P (refl x)) →
      ∀ {x y} (x≡y : x ≡ y) → P x≡y
  J P p (refl x) = p x
  ```

  The same applies to Christine Paulin-Mohring's version of the J rule:

  ```agda
  J′ : {A : Set} {x : A} (P : {y : A} → x ≡ y → Set) →
       P (refl x) →
       ∀ {y} (x≡y : x ≡ y) → P x≡y
  J′ P p (refl x) = p
  ```

  On the other hand, the obvious implementation of the K rule is not
  accepted:

  ```agda
  K : {A : Set} (P : {x : A} → x ≡ x → Set) →
      (∀ x → P (refl x)) →
      ∀ {x} (x≡x : x ≡ x) → P x≡x
  K P p (refl x) = p x
  ```

  However, we have *not* proved that activation of `--without-K`
  ensures that the K rule cannot be proved in some other way.

* Irrelevant declarations.

  Postulates and functions can be marked as irrelevant by prefixing
  the name with a dot when the name is declared. Example:

  ```agda
  postulate
    .irrelevant : {A : Set} → .A → A
  ```

  Irrelevant names may only be used in irrelevant positions or in
  definitions of things which have been declared irrelevant.

  The axiom irrelevant above can be used to define a projection from
  an irrelevant record field:

  ```agda
  data Subset (A : Set) (P : A → Set) : Set where
    _#_ : (a : A) → .(P a) → Subset A P

  elem : ∀ {A P} → Subset A P → A
  elem (a # p) = a

  .certificate : ∀ {A P} (x : Subset A P) → P (elem x)
  certificate (a # p) = irrelevant p
  ```

  The right-hand side of certificate is relevant, so we cannot define

  ```agda
  certificate (a # p) = p
  ```

  (because `p` is irrelevant). However, certificate is declared to be
  irrelevant, so it can use the axiom irrelevant. Furthermore the
  first argument of the axiom is irrelevant, which means that
  irrelevant `p` is well-formed.

  As shown above the axiom irrelevant justifies irrelevant
  projections. Previously no projections were generated for irrelevant
  record fields, such as the field certificate in the following
  record type:

  ```agda
  record Subset (A : Set) (P : A → Set) : Set where
    constructor _#_
    field
      elem         : A
      .certificate : P elem
  ```

  Now projections are generated automatically for irrelevant fields
  (unless the flag `--no-irrelevant-projections` is used). Note that
  irrelevant projections are highly experimental.

* Termination checker recognises projections.

  Projections now preserve sizes, both in patterns and expressions.
  Example:

  ```agda
  record Wrap (A : Set) : Set where
    constructor wrap
    field
      unwrap : A

  open Wrap public

  data WNat : Set where
    zero : WNat
    suc  : Wrap WNat → WNat

  id : WNat → WNat
  id zero    = zero
  id (suc w) = suc (wrap (id (unwrap w)))
  ```

  In the structural ordering `unwrap w` ≤ `w`. This means that

  ```agda
    unwrap w ≤ w < suc w,
  ```

  and hence the recursive call to id is accepted.

  Projections also preserve guardedness.

Tools
-----

* Hyperlinks for top-level module names now point to the start of the
  module rather than to the declaration of the module name. This
  applies both to the Emacs mode and to the output of `agda --html`.

* Most occurrences of record field names are now highlighted as
  "fields". Previously many occurrences were highlighted as
  "functions".

* Emacs mode: It is no longer possible to change the behaviour of the
  `TAB` key by customising `agda2-indentation`.

* Epic compiler backend.

  A new compiler backend is being implemented. This backend makes use
  of Edwin Brady's language Epic
  (http://www.cs.st-andrews.ac.uk/~eb/epic.php) and its compiler. The
  backend should handle most Agda code, but is still at an
  experimental stage: more testing is needed, and some things written
  below may not be entirely true.

  The Epic compiler can be invoked from the command line using the
  flag `--epic`:

  ```
  agda --epic --epic-flag=<EPIC-FLAG> --compile-dir=<DIR> <FILE>.agda
  ```

  The `--epic-flag` flag can be given multiple times; each flag is
  given verbatim to the Epic compiler (in the given order). The
  resulting executable is named after the main module and placed in
  the directory specified by the `--compile-dir` flag (default: the
  project root). Intermediate files are placed in a subdirectory
  called `Epic`.

  The backend requires that there is a definition named main. This
  definition should be a value of type `IO Unit`, but at the moment
  this is not checked (so it is easy to produce a program which
  segfaults).  Currently the backend represents actions of type `IO A`
  as functions from `Unit` to `A`, and main is applied to the unit
  value.

  The Epic compiler compiles via C, not Haskell, so the pragmas
  related to the Haskell FFI (`IMPORT`, `COMPILED_DATA` and
  `COMPILED`) are not used by the Epic backend. Instead there is a new
  pragma `COMPILED_EPIC`. This pragma is used to give Epic code for
  postulated definitions (Epic code can in turn call C code). The form
  of the pragma is `{-# COMPILED_EPIC def code #-}`, where `def` is
  the name of an Agda postulate and `code` is some Epic code which
  should include the function arguments, return type and function
  body. As an example the `IO` monad can be defined as follows:

  ```agda
  postulate
    IO     : Set → Set
    return : ∀ {A} → A → IO A
    _>>=_  : ∀ {A B} → IO A → (A → IO B) → IO B

  {-# COMPILED_EPIC return (u : Unit, a : Any) -> Any =
                      ioreturn(a) #-}
  {-# COMPILED_EPIC
        _>>=_ (u1 : Unit, u2 : Unit, x : Any, f : Any) -> Any =
          iobind(x,f) #-}
  ```

  Here `ioreturn` and `iobind` are Epic functions which are defined in
  the file `AgdaPrelude.e` which is always included.

  By default the backend will remove so-called forced constructor
  arguments (and case-splitting on forced variables will be
  rewritten). This optimisation can be disabled by using the flag
  `--no-forcing`.

  All data types which look like unary natural numbers after forced
  constructor arguments have been removed (i.e. types with two
  constructors, one nullary and one with a single recursive argument)
  will be represented as "BigInts". This applies to the standard `Fin`
  type, for instance.

  The backend supports Agda's primitive functions and the BUILTIN
  pragmas. If the BUILTIN pragmas for unary natural numbers are used,
  then some operations, like addition and multiplication, will use
  more efficient "BigInt" operations.

  If you want to make use of the Epic backend you need to install some
  dependencies, see the README.

* The Emacs mode can compile using either the MAlonzo or the Epic
  backend. The variable `agda2-backend` controls which backend is
  used.

Release notes for Agda 2 version 2.2.8
======================================

Language
--------

* Record pattern matching.

  It is now possible to pattern match on named record constructors.
  Example:

  ```agda
  record Σ (A : Set) (B : A → Set) : Set where
    constructor _,_
    field
      proj₁ : A
      proj₂ : B proj₁

  map : {A B : Set} {P : A → Set} {Q : B → Set}
        (f : A → B) → (∀ {x} → P x → Q (f x)) →
        Σ A P → Σ B Q
  map f g (x , y) = (f x , g y)
  ```

  The clause above is internally translated into the following one:

  ```agda
  map f g p = (f (Σ.proj₁ p) , g (Σ.proj₂ p))
  ```

  Record patterns containing data type patterns are not translated.
  Example:

  ```agda
  add : ℕ × ℕ → ℕ
  add (zero  , n) = n
  add (suc m , n) = suc (add (m , n))
  ```

  Record patterns which do not contain data type patterns, but which
  do contain dot patterns, are currently rejected. Example:

  ```agda
  Foo : {A : Set} (p₁ p₂ : A × A) → proj₁ p₁ ≡ proj₁ p₂ → Set₁
  Foo (x , y) (.x , y′) refl = Set
  ```

* Proof irrelevant function types.

  Agda now supports irrelevant non-dependent function types:

  ```agda
  f : .A → B
  ```

  This type implies that `f` does not depend computationally on its
  argument. One intended use case is data structures with embedded
  proofs, like sorted lists:

  ```agda
  postulate
    _≤_ : ℕ → ℕ → Set
    p₁  : 0 ≤ 1
    p₂  : 0 ≤ 1

  data SList (bound : ℕ) : Set where
    []    : SList bound
    scons : (head : ℕ) →
            .(head ≤ bound) →
            (tail : SList head) →
            SList bound
  ```

  The effect of the irrelevant type in the signature of `scons` is
  that `scons`'s second argument is never inspected after Agda has
  ensured that it has the right type. It is even thrown away, leading
  to smaller term sizes and hopefully some gain in efficiency. The
  type-checker ignores irrelevant arguments when checking equality, so
  two lists can be equal even if they contain different proofs:

  ```agda
  l₁ : SList 1
  l₁ = scons 0 p₁ []

  l₂ : SList 1
  l₂ = scons 0 p₂ []

  l₁≡l₂ : l₁ ≡ l₂
  l₁≡l₂ = refl
  ```

  Irrelevant arguments can only be used in irrelevant contexts.
  Consider the following subset type:

  ```agda
  data Subset (A : Set) (P : A → Set) : Set where
    _#_ : (elem : A) → .(P elem) → Subset A P
  ```

  The following two uses are fine:

  ```agda
  elimSubset : ∀ {A C : Set} {P} →
               Subset A P → ((a : A) → .(P a) → C) → C
  elimSubset (a # p) k = k a p

  elem : {A : Set} {P : A → Set} → Subset A P → A
  elem (x # p) = x
  ```

  However, if we try to project out the proof component, then Agda
  complains that `variable p is declared irrelevant, so it cannot be
  used here`:

  ```agda
  prjProof : ∀ {A P} (x : Subset A P) → P (elem x)
  prjProof (a # p) = p
  ```

  Matching against irrelevant arguments is also forbidden, except in
  the case of irrefutable matches (record constructor patterns which
  have been translated away). For instance, the match against the
  pattern `(p , q)` here is accepted:

  ```agda
  elim₂ : ∀ {A C : Set} {P Q : A → Set} →
          Subset A (λ x → Σ (P x) (λ _ → Q x)) →
          ((a : A) → .(P a) → .(Q a) → C) → C
  elim₂ (a # (p , q)) k = k a p q
  ```

  Absurd matches `()` are also allowed.

  Note that record fields can also be irrelevant. Example:

  ```agda
  record Subset (A : Set) (P : A → Set) : Set where
    constructor _#_
    field
      elem   : A
      .proof : P elem
  ```

  Irrelevant fields are never in scope, neither inside nor outside the
  record. This means that no record field can depend on an irrelevant
  field, and furthermore projections are not defined for such fields.
  Irrelevant fields can only be accessed using pattern matching, as in
  `elimSubset` above.

  Irrelevant function types were added very recently, and have not
  been subjected to much experimentation yet, so do not be surprised
  if something is changed before the next release. For instance,
  dependent irrelevant function spaces (`.(x : A) → B`) might be added
  in the future.

* Mixfix binders.

  It is now possible to declare user-defined syntax that binds
  identifiers. Example:

  ```agda
  postulate
    State  : Set → Set → Set
    put    : ∀ {S} → S → State S ⊤
    get    : ∀ {S} → State S S
    return : ∀ {A S} → A → State S A
    bind   : ∀ {A B S} → State S B → (B → State S A) → State S A

  syntax bind e₁ (λ x → e₂) = x ← e₁ , e₂

  increment : State ℕ ⊤
  increment = x ← get ,
              put (1 + x)
  ```

  The syntax declaration for `bind` implies that `x` is in scope in
  `e₂`, but not in `e₁`.

  You can give fixity declarations along with syntax declarations:

  ```agda
  infixr 40 bind
  syntax bind e₁ (λ x → e₂) = x ← e₁ , e₂
  ```

  The fixity applies to the syntax, not the name; syntax declarations
  are also restricted to ordinary, non-operator names. The following
  declaration is disallowed:

  ```agda
  syntax _==_ x y = x === y
  ```agda

  Syntax declarations must also be linear; the following declaration
  is disallowed:

  ```agda
  syntax wrong x = x + x
  ```

  Syntax declarations were added very recently, and have not been
  subjected to much experimentation yet, so do not be surprised if
  something is changed before the next release.

* `Prop` has been removed from the language.

  The experimental sort `Prop` has been disabled. Any program using
  `Prop` should typecheck if `Prop` is replaced by `Set₀`. Note that
  `Prop` is still a keyword.

* Injective type constructors off by default.

  Automatic injectivity of type constructors has been disabled (by
  default). To enable it, use the flag
  `--injective-type-constructors`, either on the command line or in an
  OPTIONS pragma. Note that this flag makes Agda anti-classical and
  possibly inconsistent:

    Agda with excluded middle is inconsistent
    http://thread.gmane.org/gmane.comp.lang.agda/1367

  See `test/Succeed/InjectiveTypeConstructors.agda` for an example.

* Termination checker can count.

  There is a new flag `--termination-depth=N` accepting values `N >=
  1` (with `N = 1` being the default) which influences the behavior of
  the termination checker. So far, the termination checker has only
  distinguished three cases when comparing the argument of a recursive
  call with the formal parameter of the callee.

  `<`: the argument is structurally smaller than the parameter

  `=`: they are equal

  `?`: the argument is bigger or unrelated to the parameter

  This behavior, which is still the default (`N = 1`), will not
  recognise the following functions as terminating.

   ```agda
   mutual

      f : ℕ → ℕ
      f zero          = zero
      f (suc zero)    = zero
      f (suc (suc n)) = aux n

      aux : ℕ → ℕ
      aux m = f (suc m)
  ```

  The call graph

  ```
  f --(<)--> aux --(?)--> f
  ```

  yields a recursive call from `f` to `f` via `aux` where the relation
  of call argument to callee parameter is computed as "unrelated"
  (composition of `<` and `?`).

  Setting `N >= 2` allows a finer analysis: `n` has two constructors
  less than `suc (suc n)`, and `suc m` has one more than `m`, so we get the
  call graph:

  ```
  f --(-2)--> aux --(+1)--> f
  ```

  The indirect call `f --> f` is now labeled with `(-1)`, and the
  termination checker can recognise that the call argument is
  decreasing on this path.

  Setting the termination depth to `N` means that the termination
  checker counts decrease up to `N` and increase up to `N-1`. The
  default, `N=1`, means that no increase is counted, every increase
  turns to "unrelated".

  In practice, examples like the one above sometimes arise when `with`
  is used. As an example, the program

  ```agda
  f : ℕ → ℕ
  f zero          = zero
  f (suc zero)    = zero
  f (suc (suc n)) with zero
  ... | _ = f (suc n)
  ```

  is internally represented as

  ```agda
  mutual

    f : ℕ → ℕ
    f zero          = zero
    f (suc zero)    = zero
    f (suc (suc n)) = aux n zero

    aux : ℕ → ℕ → ℕ
    aux m k = f (suc m)
  ```

  Thus, by default, the definition of `f` using `with` is not accepted
  by the termination checker, even though it looks structural (`suc n`
  is a subterm of `suc suc n`). Now, the termination checker is
  satisfied if the option `--termination-depth=2` is used.

  Caveats:

  - This is an experimental feature, hopefully being replaced by
    something smarter in the near future.

  - Increasing the termination depth will quickly lead to very long
    termination checking times. So, use with care. Setting termination
    depth to `100` by habit, just to be on the safe side, is not a good
    idea!

  - Increasing termination depth only makes sense for linear data
    types such as `ℕ` and `Size`. For other types, increase cannot be
    recognised. For instance, consider a similar example with lists.

    ```agda
    data List : Set where
      nil  : List
      cons : ℕ → List → List

    mutual
      f : List → List
      f nil                  = nil
      f (cons x nil)         = nil
      f (cons x (cons y ys)) = aux y ys

      aux : ℕ → List → List
      aux z zs = f (cons z zs)
    ```

    Here the termination checker compares `cons z zs` to `z` and also
    to `zs`. In both cases, the result will be "unrelated", no matter
    how high we set the termination depth. This is because when
    comparing `cons z zs` to `zs`, for instance, `z` is unrelated to
    `zs`, thus, `cons z zs` is also unrelated to `zs`. We cannot say
    it is just "one larger" since `z` could be a very large term. Note
    that this points to a weakness of untyped termination checking.

    To regain the benefit of increased termination depth, we need to
    index our lists by a linear type such as `ℕ` or `Size`. With
    termination depth `2`, the above example is accepted for vectors
    instead of lists.

* The `codata` keyword has been removed. To use coinduction, use the
  following new builtins: `INFINITY`, `SHARP` and `FLAT`. Example:

  ```agda
  {-# OPTIONS --universe-polymorphism #-}

  module Coinduction where

  open import Level

  infix 1000 ♯_

  postulate
    ∞  : ∀ {a} (A : Set a) → Set a
    ♯_ : ∀ {a} {A : Set a} → A → ∞ A
    ♭  : ∀ {a} {A : Set a} → ∞ A → A

  {-# BUILTIN INFINITY ∞  #-}
  {-# BUILTIN SHARP    ♯_ #-}
  {-# BUILTIN FLAT     ♭  #-}
  ```

  Note that (non-dependent) pattern matching on `SHARP` is no longer
  allowed.

  Note also that strange things might happen if you try to combine the
  pragmas above with `COMPILED_TYPE`, `COMPILED_DATA` or `COMPILED`
  pragmas, or if the pragmas do not occur right after the postulates.

  The compiler compiles the `INFINITY` builtin to nothing (more or
  less), so that the use of coinduction does not get in the way of FFI
  declarations:

  ```agda
  data Colist (A : Set) : Set where
    []  : Colist A
    _∷_ : (x : A) (xs : ∞ (Colist A)) → Colist A

  {-# COMPILED_DATA Colist [] [] (:) #-}
  ```

* Infinite types.

  If the new flag `--guardedness-preserving-type-constructors` is
  used, then type constructors are treated as inductive constructors
  when we check productivity (but only in parameters, and only if they
  are used strictly positively or not at all). This makes examples
  such as the following possible:

  ```agda
  data Rec (A : ∞ Set) : Set where
    fold : ♭ A → Rec A

  -- Σ cannot be a record type below.

  data Σ (A : Set) (B : A → Set) : Set where
    _,_ : (x : A) → B x → Σ A B

  syntax Σ A (λ x → B) = Σ[ x ∶ A ] B

  -- Corecursive definition of the W-type.

  W : (A : Set) → (A → Set) → Set
  W A B = Rec (♯ (Σ[ x ∶ A ] (B x → W A B)))

  syntax W A (λ x → B) = W[ x ∶ A ] B

  sup : {A : Set} {B : A → Set} (x : A) (f : B x → W A B) → W A B
  sup x f = fold (x , f)

  W-rec : {A : Set} {B : A → Set}
          (P : W A B → Set) →
          (∀ {x} {f : B x → W A B} → (∀ y → P (f y)) → P (sup x f)) →
          ∀ x → P x
  W-rec P h (fold (x , f)) = h (λ y → W-rec P h (f y))

  -- Induction-recursion encoded as corecursion-recursion.

  data Label : Set where
    ′0 ′1 ′2 ′σ ′π ′w : Label

  mutual

    U : Set
    U = Σ Label U′

    U′ : Label → Set
    U′ ′0 = ⊤
    U′ ′1 = ⊤
    U′ ′2 = ⊤
    U′ ′σ = Rec (♯ (Σ[ a ∶ U ] (El a → U)))
    U′ ′π = Rec (♯ (Σ[ a ∶ U ] (El a → U)))
    U′ ′w = Rec (♯ (Σ[ a ∶ U ] (El a → U)))

    El : U → Set
    El (′0 , _)            = ⊥
    El (′1 , _)            = ⊤
    El (′2 , _)            = Bool
    El (′σ , fold (a , b)) = Σ[ x ∶ El a ]  El (b x)
    El (′π , fold (a , b)) =   (x : El a) → El (b x)
    El (′w , fold (a , b)) = W[ x ∶ El a ]  El (b x)

  U-rec : (P : ∀ u → El u → Set) →
          P (′1 , _) tt →
          P (′2 , _) true →
          P (′2 , _) false →
          (∀ {a b x y} →
           P a x → P (b x) y → P (′σ , fold (a , b)) (x , y)) →
          (∀ {a b f} →
           (∀ x → P (b x) (f x)) → P (′π , fold (a , b)) f) →
          (∀ {a b x f} →
           (∀ y → P (′w , fold (a , b)) (f y)) →
           P (′w , fold (a , b)) (sup x f)) →
          ∀ u (x : El u) → P u x
  U-rec P P1 P2t P2f Pσ Pπ Pw = rec
    where
    rec : ∀ u (x : El u) → P u x
    rec (′0 , _)            ()
    rec (′1 , _)            _              = P1
    rec (′2 , _)            true           = P2t
    rec (′2 , _)            false          = P2f
    rec (′σ , fold (a , b)) (x , y)        = Pσ (rec _ x) (rec _ y)
    rec (′π , fold (a , b)) f              = Pπ (λ x → rec _ (f x))
    rec (′w , fold (a , b)) (fold (x , f)) = Pw (λ y → rec _ (f y))
  ```

  The `--guardedness-preserving-type-constructors` extension is based
  on a rather operational understanding of `∞`/`♯_`; it's not yet
  clear if this extension is consistent.

* Qualified constructors.

  Constructors can now be referred to qualified by their data type.
  For instance, given

  ```agda
  data Nat : Set where
    zero : Nat
    suc  : Nat → Nat

  data Fin : Nat → Set where
    zero : ∀ {n} → Fin (suc n)
    suc  : ∀ {n} → Fin n → Fin (suc n)
  ```

  you can refer to the constructors unambiguously as `Nat.zero`,
  `Nat.suc`, `Fin.zero`, and `Fin.suc` (`Nat` and `Fin` are modules
  containing the respective constructors). Example:

  ```agda
  inj : (n m : Nat) → Nat.suc n ≡ suc m → n ≡ m
  inj .m m refl = refl
  ```

  Previously you had to write something like

  ```agda
  inj : (n m : Nat) → _≡_ {Nat} (suc n) (suc m) → n ≡ m
  ```

  to make the type checker able to figure out that you wanted the
  natural number suc in this case.

* Reflection.

  There are two new constructs for reflection:

    - `quoteGoal x in e`

      In `e` the value of `x` will be a representation of the goal type
      (the type expected of the whole expression) as an element in a
      datatype of Agda terms (see below). For instance,

      ```agda
      example : ℕ
      example = quoteGoal x in {! at this point x = def (quote ℕ) [] !}
      ```

    - `quote x : Name`

      If `x` is the name of a definition (function, datatype, record,
      or a constructor), `quote x` gives you the representation of `x`
      as a value in the primitive type `Name` (see below).

  Quoted terms use the following BUILTINs and primitives (available
  from the standard library module `Reflection`):

  ```agda
  -- The type of Agda names.

  postulate Name : Set

  {-# BUILTIN QNAME Name #-}

  primitive primQNameEquality : Name → Name → Bool

  -- Arguments.

  Explicit? = Bool

  data Arg A : Set where
    arg : Explicit? → A → Arg A

  {-# BUILTIN ARG    Arg #-}
  {-# BUILTIN ARGARG arg #-}

  -- The type of Agda terms.

  data Term : Set where
    var     : ℕ → List (Arg Term) → Term
    con     : Name → List (Arg Term) → Term
    def     : Name → List (Arg Term) → Term
    lam     : Explicit? → Term → Term
    pi      : Arg Term → Term → Term
    sort    : Term
    unknown : Term

  {-# BUILTIN AGDATERM            Term    #-}
  {-# BUILTIN AGDATERMVAR         var     #-}
  {-# BUILTIN AGDATERMCON         con     #-}
  {-# BUILTIN AGDATERMDEF         def     #-}
  {-# BUILTIN AGDATERMLAM         lam     #-}
  {-# BUILTIN AGDATERMPI          pi      #-}
  {-# BUILTIN AGDATERMSORT        sort    #-}
  {-# BUILTIN AGDATERMUNSUPPORTED unknown #-}
  ```

  Reflection may be useful when working with internal decision
  procedures, such as the standard library's ring solver.

* Minor record definition improvement.

  The definition of a record type is now available when type checking
  record module definitions. This means that you can define things
  like the following:

  ```agda
  record Cat : Set₁ where
    field
      Obj  : Set
      _=>_ : Obj → Obj → Set
      -- ...

    -- not possible before:
    op : Cat
    op = record { Obj = Obj; _=>_ = λ A B → B => A }
  ```

Tools
-----

* The `Goal type and context` command now shows the goal type before
  the context, and the context is shown in reverse order. The `Goal
  type, context and inferred type` command has been modified in a
  similar way.

* Show module contents command.

  Given a module name `M` the Emacs mode can now display all the
  top-level modules and names inside `M`, along with types for the
  names. The command is activated using `C-c C-o` or the menus.

* Auto command.

  A command which searches for type inhabitants has been added. The
  command is invoked by pressing `C-C C-a` (or using the goal menu).
  There are several flags and parameters, e.g. `-c` which enables
  case-splitting in the search. For further information, see the Agda
  wiki:

    http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.Auto

* HTML generation is now possible for a module with unsolved
  meta-variables, provided that the `--allow-unsolved-metas` flag is
  used.

Release notes for Agda 2 version 2.2.6
======================================

Language
--------

* Universe polymorphism (experimental extension).

  To enable universe polymorphism give the flag
  `--universe-polymorphism` on the command line or (recommended) as an
  OPTIONS pragma.

  When universe polymorphism is enabled `Set` takes an argument which is
  the universe level. For instance, the type of universe polymorphic
  identity is

  ```agda
  id : {a : Level} {A : Set a} → A → A.
  ```

  The type Level is isomorphic to the unary natural numbers and should
  be specified using the BUILTINs `LEVEL`, `LEVELZERO`, and
  `LEVELSUC`:

  ```agda
  data Level : Set where
    zero : Level
    suc  : Level → Level

  {-# BUILTIN LEVEL     Level #-}
  {-# BUILTIN LEVELZERO zero  #-}
  {-# BUILTIN LEVELSUC  suc   #-}
  ```

  There is an additional BUILTIN `LEVELMAX` for taking the maximum of two
  levels:

  ```agda
  max : Level → Level → Level
  max  zero    m      = m
  max (suc n)  zero   = suc n
  max (suc n) (suc m) = suc (max n m)

  {-# BUILTIN LEVELMAX max #-}
  ```

  The non-polymorphic universe levels `Set`, `Set₁` and so on are
  sugar for `Set zero`, `Set (suc zero)`, etc.

  At present there is no automatic lifting of types from one level to
  another. It can still be done (rather clumsily) by defining types
  like the following one:

  ```agda
  data Lifted {a} (A : Set a) : Set (suc a) where
    lift : A → Lifted A
  ```

  However, it is likely that automatic lifting is introduced at some
  point in the future.

* Multiple constructors, record fields, postulates or primitives can
  be declared using a single type signature:

  ```agda
  data Bool : Set where
    false true : Bool

  postulate
    A B : Set
  ```

* Record fields can be implicit:

  ```agda
  record R : Set₁ where
    field
      {A}         : Set
      f           : A → A
      {B C} D {E} : Set
      g           : B → C → E
  ```

  By default implicit fields are not printed.

* Record constructors can be defined:

  ```agda
  record Σ (A : Set) (B : A → Set) : Set where
    constructor _,_
    field
      proj₁ : A
      proj₂ : B proj₁
  ```

  In this example `_,_` gets the type

  ```agda
   (proj₁ : A) → B proj₁ → Σ A B.
  ```

  For implicit fields the corresponding constructor arguments become
  implicit.

  Note that the constructor is defined in the *outer* scope, so any
  fixity declaration has to be given outside the record definition.
  The constructor is not in scope inside the record module.

  Note also that pattern matching for records has not been implemented
  yet.

* BUILTIN hooks for equality.

  The data type

  ```agda
  data _≡_ {A : Set} (x : A) : A → Set where
    refl : x ≡ x
  ```

  can be specified as the builtin equality type using the following
  pragmas:

  ```agda
  {-# BUILTIN EQUALITY _≡_  #-}
  {-# BUILTIN REFL     refl #-}
  ```

  The builtin equality is used for the new rewrite construct and
  the `primTrustMe` primitive described below.

* New `rewrite` construct.

  If `eqn : a ≡ b`, where `_≡_` is the builtin equality (see above) you
  can now write

  ```agda
  f ps rewrite eqn = rhs
  ```

  instead of

  ```agda
    f ps with a | eqn
    ... | ._ | refl = rhs
  ```

  The `rewrite` construct has the effect of rewriting the goal and the
  context by the given equation (left to right).

  You can rewrite using several equations (in sequence) by separating
  them with vertical bars (|):

  ```agda
  f ps rewrite eqn₁ | eqn₂ | … = rhs
  ```

  It is also possible to add `with`-clauses after rewriting:

  ```agda
  f ps rewrite eqns with e
  ... | p = rhs
  ```

  Note that pattern matching happens before rewriting—if you want to
  rewrite and then do pattern matching you can use a with after the
  rewrite.

  See `test/Succeed/Rewrite.agda` for some examples.

* A new primitive, `primTrustMe`, has been added:

  ```agda
    primTrustMe : {A : Set} {x y : A} → x ≡ y
  ```

  Here `_≡_` is the builtin equality (see BUILTIN hooks for equality,
  above).

  If `x` and `y` are definitionally equal, then
  `primTrustMe {x = x} {y = y}` reduces to `refl`.

  Note that the compiler replaces all uses of `primTrustMe` with the
  `REFL` builtin, without any check for definitional
  equality. Incorrect uses of `primTrustMe` can potentially lead to
  segfaults or similar problems.

  For an example of the use of `primTrustMe`, see `Data.String` in
  version 0.3 of the standard library, where it is used to implement
  decidable equality on strings using the primitive boolean equality.

* Changes to the syntax and semantics of IMPORT pragmas, which are
  used by the Haskell FFI. Such pragmas must now have the following
  form:

  ```agda
  {-# IMPORT <module name> #-}
  ```

  These pragmas are interpreted as *qualified* imports, so Haskell
  names need to be given qualified (unless they come from the Haskell
  prelude).

* The horizontal tab character (U+0009) is no longer treated as white
  space.

* Line pragmas are no longer supported.

* The `--include-path` flag can no longer be used as a pragma.

* The experimental and incomplete support for proof irrelevance has
  been disabled.

Tools
-----

* New `intro` command in the Emacs mode. When there is a canonical way
  of building something of the goal type (for instance, if the goal
  type is a pair), the goal can be refined in this way. The command
  works for the following goal types:

    - A data type where only one of its constructors can be used to
      construct an element of the goal type. (For instance, if the
      goal is a non-empty vector, a `cons` will be introduced.)

    - A record type. A record value will be introduced. Implicit
      fields will not be included unless showing of implicit arguments
      is switched on.

    - A function type. A lambda binding as many variables as possible
      will be introduced. The variable names will be chosen from the
      goal type if its normal form is a dependent function type,
      otherwise they will be variations on `x`. Implicit lambdas will
      only be inserted if showing of implicit arguments is switched
      on.

  This command can be invoked by using the `refine` command
  (`C-c C-r`) when the goal is empty. (The old behaviour of the refine
  command in this situation was to ask for an expression using the
  minibuffer.)

* The Emacs mode displays `Checked` in the mode line if the current
  file type checked successfully without any warnings.

* If a file `F` is loaded, and this file defines the module `M`, it is
  an error if `F` is not the file which defines `M` according to the
  include path.

  Note that the command-line tool and the Emacs mode define the
  meaning of relative include paths differently: the command-line tool
  interprets them relative to the current working directory, whereas
  the Emacs mode interprets them relative to the root directory of the
  current project. (As an example, if the module `A.B.C` is loaded
  from the file `<some-path>/A/B/C.agda`, then the root directory is
  `<some-path>`.)

* It is an error if there are several files on the include path which
  match a given module name.

* Interface files are relocatable. You can move around source trees as
  long as the include path is updated in a corresponding way. Note
  that a module `M` may be re-typechecked if its time stamp is
  strictly newer than that of the corresponding interface file
  (`M.agdai`).

* Type-checking is no longer done when an up-to-date interface exists.
  (Previously the initial module was always type-checked.)

* Syntax highlighting files for Emacs (`.agda.el`) are no longer used.
  The `--emacs` flag has been removed. (Syntax highlighting
  information is cached in the interface files.)

* The Agate and Alonzo compilers have been retired. The options
  `--agate`, `--alonzo` and `--malonzo` have been removed.

* The default directory for MAlonzo output is the project's root
  directory. The `--malonzo-dir` flag has been renamed to
  `--compile-dir`.

* Emacs mode: `C-c C-x C-d` no longer resets the type checking state.
  `C-c C-x C-r` can be used for a more complete reset. `C-c C-x C-s`
  (which used to reload the syntax highlighting information) has been
  removed. `C-c C-l` can be used instead.

* The Emacs mode used to define some "abbrevs", unless the user
  explicitly turned this feature off. The new default is *not* to add
  any abbrevs. The old default can be obtained by customising
  `agda2-mode-abbrevs-use-defaults` (a customisation buffer can be
  obtained by typing `M-x customize-group agda2 RET` after an Agda
  file has been loaded).

Release notes for Agda 2 version 2.2.4
======================================

Important changes since 2.2.2:

* Change to the semantics of `open import` and `open module`. The
  declaration

  ```agda
  open import M <using/hiding/renaming>
  ```

  now translates to

  ```agda
  import A
  open A <using/hiding/renaming>
  ```

  instead of

  ```agda
  import A <using/hiding/renaming>
  open A
  ```

  The same translation is used for `open module M = E …`. Declarations
  involving the keywords as or public are changed in a corresponding
  way (`as` always goes with import, and `public` always with open).

  This change means that import directives do not affect the qualified
  names when open import/module is used. To get the old behaviour you
  can use the expanded version above.

* Names opened publicly in parameterised modules no longer inherit the
  module parameters. Example:

  ```agda
  module A where
    postulate X : Set

  module B (Y : Set) where
    open A public
  ```

  In Agda 2.2.2 `B.X` has type `(Y : Set) → Set`, whereas in
  Agda 2.2.4 `B.X` has type Set.

* Previously it was not possible to export a given constructor name
  through two different `open public` statements in the same module.
  This is now possible.

* Unicode subscript digits are now allowed for the hierarchy of
  universes (`Set₀`, `Set₁`, …): `Set₁` is equivalent to `Set1`.

Release notes for Agda 2 version 2.2.2
======================================

Tools
-----

* The `--malonzodir` option has been renamed to `--malonzo-dir`.

* The output of `agda --html` is by default placed in a directory
  called `html`.

Infrastructure
--------------

* The Emacs mode is included in the Agda Cabal package, and installed
  by `cabal install`. The recommended way to enable the Emacs mode is
  to include the following code in `.emacs`:

  ```elisp
  (load-file (let ((coding-system-for-read 'utf-8))
                  (shell-command-to-string "agda-mode locate")))
  ```

Release notes for Agda 2 version 2.2.0
======================================

Important changes since 2.1.2 (which was released 2007-08-16):

Language
--------

* Exhaustive pattern checking. Agda complains if there are missing
  clauses in a function definition.

* Coinductive types are supported. This feature is under
  development/evaluation, and may change.

  http://wiki.portal.chalmers.se/agda/agda.php?n=ReferenceManual.Codatatypes

* Another experimental feature: Sized types, which can make it easier
  to explain why your code is terminating.

* Improved constraint solving for functions with constructor headed
  right hand sides.

  http://wiki.portal.chalmers.se/agda/agda.php?n=ReferenceManual.FindingTheValuesOfImplicitArguments

* A simple, well-typed foreign function interface, which allows use of
  Haskell functions in Agda code.

  http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Docs.FFI

* The tokens `forall`, `->` and `\` can be written as `∀`, `→` and
  `λ`.

* Absurd lambdas: `λ ()` and `λ {}`.

  http://thread.gmane.org/gmane.comp.lang.agda/440

* Record fields whose values can be inferred can be omitted.

* Agda complains if it spots an unreachable clause, or if a pattern
  variable "shadows" a hidden constructor of matching type.

  http://thread.gmane.org/gmane.comp.lang.agda/720

Tools
-----

* Case-split: The user interface can replace a pattern variable with
  the corresponding constructor patterns. You get one new left-hand
  side for every possible constructor.

  http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.QuickGuideToEditingTypeCheckingAndCompilingAgdaCode

* The MAlonzo compiler.

  http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Docs.MAlonzo

* A new Emacs input method, which contains bindings for many Unicode
  symbols, is by default activated in the Emacs mode.

  http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Docs.UnicodeInput

* Highlighted, hyperlinked HTML can be generated from Agda source
  code.

  http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.HowToGenerateWebPagesFromSourceCode

* The command-line interactive mode (`agda -I`) is no longer
  supported, but should still work.

  http://thread.gmane.org/gmane.comp.lang.agda/245

* Reload times when working on large projects are now considerably
  better.

  http://thread.gmane.org/gmane.comp.lang.agda/551

Libraries
---------

* A standard library is under development.

  http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Libraries.StandardLibrary

Documentation
-------------

* The Agda wiki is better organised. It should be easier for a
  newcomer to find relevant information now.

  http://wiki.portal.chalmers.se/agda/

Infrastructure
--------------

* Easy-to-install packages for Windows and Debian/Ubuntu have been
  prepared.

  http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.Download

* Agda 2.2.0 is available from Hackage.

  http://hackage.haskell.org/
