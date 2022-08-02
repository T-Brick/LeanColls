/-
Copyright (c) 2022 James Gallicchio.

Authors: James Gallicchio
-/

import LeanColls.List
import LeanColls.AuxLemmas

namespace LeanColls

/-! # Range

Represents the first `n` natural numbers, e.g. [0, n).
-/
structure Range where
  n : Nat

namespace Range

instance : Membership Nat Range where
  mem x r := x < r.n

def fold' : (r : Range) → (β → (i : Nat) → i ∈ r → β) → β → β :=
  let rec @[inline] loop {α} (stop)
    (f : α → (i : Nat) → i ∈ (⟨stop⟩ : Range) → α) acc i : α :=
    if h:i < stop then
      have : stop - (i + 1) < stop - i := by
        rw [Nat.sub_dist]
        apply Nat.sub_lt
        exact Nat.zero_lt_sub_of_lt h
        decide
      have : i ∈ (⟨stop⟩ : Range) := h
      loop stop f (f acc i this) (i+1)
    else
      acc
  λ ⟨n⟩ f acc =>
    loop n f acc 0
  termination_by loop _ _ i => stop - i

def fold (f : β → Nat → β) (acc) (r : Range) :=
  fold' r (fun acc x _ => f acc x) acc

theorem fold'_ind {stop : Nat}
  {f : β → (i : Nat) → i ∈ (⟨stop⟩ : Range) → β}
  {acc : β} {motive : (i : Nat) → i ≤ stop → β → Prop}
  (base : motive 0 (Nat.zero_le _) acc)
  (ind_step : ∀ i acc, (h : i < stop) →
      motive i (Nat.le_of_lt h) acc → motive (i+1) h (f acc i h))
  : motive stop (Nat.le_refl _) (fold' (⟨stop⟩ : Range) f acc)
  :=
  let rec loop i (acc : β) (h_i : i ≤ stop) (h_acc : motive i h_i acc)
    : motive stop (Nat.le_refl _) (fold'.loop stop f acc i) :=
    if h:i < stop then by
      unfold fold'.loop
      simp [h]
      exact loop (i+1) (f acc i h) h (ind_step i acc h h_acc)
    else by
      have : i = stop := (Nat.eq_or_lt_of_le h_i).elim (id) (False.elim ∘ h)
      unfold fold'.loop
      simp [h]
      cases this
      exact h_acc
  loop 0 acc (Nat.zero_le _) base
  termination_by loop _ _ _i => stop - i

theorem fold_ind {stop : Nat}
  {f : β → Nat → β}
  {acc : β} {motive : (i : Nat) → i ≤ stop → β → Prop}
  (base : motive 0 (Nat.zero_le _) acc)
  (ind_step : ∀ i acc, (h : i < stop) →
      motive i (Nat.le_of_lt h) acc → motive (i+1) h (f acc i))
  : motive stop (Nat.le_refl _) (fold f acc (⟨stop⟩ : Range))
  := by
  unfold fold
  apply fold'_ind <;> assumption

def toList (c : Range) : List Nat :=
  let rec list : Nat → List Nat
  | 0 => []
  | n+1 => list n ++ [n]
  list c.n

@[csimp]
theorem toList_eq_range
  : toList.list = List.range
  := funext λ n => by
  simp [List.range]
  induction n with
  | zero => simp
  | succ n ih =>
    simp [toList.list, List.rangeAux]
    rw [List.rangeAux_eq_append, ih]

theorem canonicalToList_eq_toList
  : canonicalToList (fun {β} => fold) = toList
  := funext λ c => by
  cases c; case mk n =>
  simp [canonicalToList]
  apply fold_ind (motive := λ i h a => a = toList ⟨i⟩)
  case base => simp [toList]
  case ind_step =>
    intro i acc h_i h_acc
    simp [toList, toList.list, h_acc]

theorem memCorrect (x : Nat) (c : Range)
  : x ∈ c ↔ x ∈ canonicalToList (fun {β} => fold) c
  := by
  cases c; case mk n =>
  simp [Foldable.fold, Membership.mem, canonicalToList_eq_toList]
  induction n with
  | zero =>
    constructor <;> (intro h; apply False.elim)
    apply Nat.not_lt_zero _ h
    cases h
  | succ n ih =>
    constructor <;> intro h
    case mp =>
      have := Nat.eq_or_lt_of_le (Nat.le_of_succ_le_succ h)
      clear h
      cases this
      case inl h =>
        cases h
        apply List.mem_append_of_mem_right
        apply List.Mem.head
      case inr h =>
        apply List.mem_append_of_mem_left
        apply ih.mp h
    case mpr =>
      apply Nat.succ_le_succ
      have := List.mem_of_append _ _ h
      clear h
      cases this
      case a.inl h =>
        apply Nat.le_of_lt
        apply ih.mpr h
      case a.inr h =>
        simp [Membership.mem] at h
        cases h
        simp
        contradiction

theorem foldCorrect {β : Type} (f : β → Nat → β) (init : β) (c : Range)
  : fold f init c = List.fold f init (canonicalToList fold c)
  := by
  simp [canonicalToList_eq_toList]
  cases c with
  | mk n =>
  apply fold_ind (motive := λ i h a => a = List.fold f init (toList.list i))
  case base =>
    simp [List.fold, List.foldl]
  case ind_step =>
    intro i acc h_i h_acc
    simp [List.fold] at h_acc ⊢
    unfold List.foldl
    simp [toList.list]
    split
    case h_1 h =>
      have : List.length (toList.list i ++ [i]) = List.length [] := by 
        rw [h]
      simp at this
      contradiction
    case h_2 init _ smth x xs h =>
      suffices
        List.foldl f acc [i] = List.foldl f (f init x) xs
        from this
      rw [h_acc, ←List.foldl_append, h]
      simp [List.foldl]

theorem fold'Correct {β : Type} (c : Range) (f : β → (x : Nat) → x ∈ c → β) (init : β)
  : fold' c f init = List.fold' (canonicalToList fold c)
    (fun acc x h => f acc x ((memCorrect _ _).mpr h)) init
  := by
  stop
  rw [canonicalToList_eq_toList]
  cases c with
  | mk n =>
  apply fold'_ind (motive := λ i h a => a = _)
  case base =>
    simp [List.fold', List.fold'.go]
  case ind_step =>
    intro i acc h_i h_acc
    simp [List.fold] at h_acc ⊢
    unfold List.foldl
    simp [toList.list]
    split
    case h_1 h =>
      have : List.length (toList.list i ++ [i]) = List.length [] := by 
        rw [h]
      simp at this
      contradiction
    case h_2 init _ smth x xs h =>
      suffices
        List.foldl f acc [i] = List.foldl f (f init x) xs
        from this
      rw [h_acc, ←List.foldl_append, h]
      simp [List.foldl]

instance : Foldable'.Correct Range Nat inferInstance where
  fold := fold
  fold' := fold'
  memCorrect := memCorrect
  foldCorrect := foldCorrect
  fold'Correct := fold'Correct

instance : FoldableOps Range Nat := {
  (default : FoldableOps Range Nat) with
  contains := λ r _ i => i < r.n
}

instance : Iterable Range Nat where
  ρ := Nat × Nat
  step := λ (i,stop) => if h:i < stop then some (i, (i.succ, stop)) else none
  toIterator := λ r => (0,r.n)

end Range

/-! # Range.Complex

A more complicated range, defined by a `start`, `step`, and `stop` value.

The sequence proceeds: `start`, `start + step`, `start + 2 * step`, ...

... until the value passes `stop`. For `step > 0`, the values are upper bounded
by `stop`, while for `step < 0` the values are lower bounded by `stop`.

Similar to `Std.Range`, but allows negative values for start/stop/step.
-/
structure Range.Complex where
  start : Int
  stop : Int
  step : Int
  h_step : step ≠ 0

namespace Range.Complex

/-
def fold : (β → Int → β) → β → Range.Complex → β :=
  let rec @[inline] loop {α} (start stop step h_step) (f : α → Int → α) acc i : α :=
    if h:i < stop then
      have : stop - (i + step) < stop - i := by
        rw [Int.]
        apply Nat.sub_lt
        exact Nat.zero_lt_sub_of_lt h
        exact h_step
      loop start stop step h_step f (f acc i) (i+step)
    else
      acc
  λ f acc ⟨start,stop,step, h_step⟩ =>
    if h:step > 0 then loop start stop step h_step f acc 0 else acc
  termination_by loop _ _ i => stop - i

instance : Membership Nat Range where
  mem x r := x < r.stop ∧ ∃ k, x = r.start + k * r.step

def fold' : (r : Range) → (β → (i : Nat) → i ∈ r → β) → β → β :=
  let rec @[inline] loop {α} (start stop step h_step)
    (f : α → (i : Nat) → i ∈ (⟨start,stop,step,h_step⟩ : Range) → α) acc
    i (h_i : ∃ k, i = start + k * step) : α :=
    if h:i < stop then
      have : stop - (i + step) < stop - i := by
        rw [Nat.sub_dist]
        apply Nat.sub_lt
        exact Nat.zero_lt_sub_of_lt h
        assumption
      have : i ∈ (⟨start,stop,step,h_step⟩ : Range) := ⟨h_step, h, h_i⟩
      loop start stop step h_step f (f acc i this) (i+step) (by
        cases h_i; case intro k h_i =>
        apply Exists.intro (k+1)
        simp [Nat.succ_mul]
        rw [←Nat.add_assoc, h_i]
      )
    else
      acc
  λ ⟨start,stop,step,h_step⟩ f acc =>
    loop start stop step h_step f acc start ⟨0,by simp⟩
  termination_by loop _ _ i _ => stop - i

def last (r : Range) := r.start + ((r.stop - r.start) / r.step) * r.step

theorem mem_last (r : Range) : r.last ∈ r := by
  simp [last, Membership.mem]
  sorry

theorem fold_ind {start stop step : Nat}
  {f : β → (i : Nat) → i ∈ (⟨start,stop,step⟩ : Range) → β}
  {acc : β} {motive : Nat → β → Prop}
  (base : motive 0 acc)
  (ind_step : ∀ i acc, (h : i ∈ (⟨start,stop,step⟩ : Range)) → motive i acc → motive (i+step) (f acc i h))
  : motive n (fold' (⟨start,stop,step⟩ : Range) f acc)
  :=
  let rec loop i (acc : β) (h_i : i ≤ n) (h_acc : motive i acc)
    : motive i () :=
    if h:i < n then by
      unfold fold.loop
      simp [h]
      exact loop i.succ (f acc ⟨i,h⟩) h (step i acc h h_acc)
    else by
      have : i = n := (Nat.eq_or_lt_of_le h_i).elim (id) (False.elim ∘ h)
      unfold fold.loop
      simp [h]
      rw [this] at h_acc
      exact h_acc
  loop 0 acc (Nat.zero_le _) init
  termination_by loop _ _ _i => n - i


instance : Foldable Range Nat where
  fold := fold 

instance : FoldableOps Range Nat := default

instance : Foldable' Range Nat inferInstance where
  fold' := fold'

instance : Iterable Range Nat where
  ρ := Nat
  step := λ i => if h:i < n then some ⟨⟨i,h⟩,i.succ⟩ else none
  toIterator := λ _ => 0
-/

end Range.Complex

end LeanColls