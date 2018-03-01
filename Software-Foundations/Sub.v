(** * Sub: Subtyping *)


Require Export Types.

(* ###################################################### *)
(** * Concepts *)

(** We now turn to the study of _subtyping_, perhaps the most
    characteristic feature of the static type systems of recently
    designed programming languages and a key feature needed to support
    the object-oriented programming style. *)

(* ###################################################### *)
(** ** A Motivating Example *)

(** Suppose we are writing a program involving two record types
    defined as follows:
<<
    Person  = {name:String, age:Nat}
    Student = {name:String, age:Nat, gpa:Nat}
>>
*)

(** In the simply typed lamdba-calculus with records, the term
<<
    (\r:Person. (r.age)+1) {name="Pat",age=21,gpa=1}
>>
   is not typable: it involves an application of a function that wants
   a one-field record to an argument that actually provides two
   fields, while the [T_App] rule demands that the domain type of the
   function being applied must match the type of the argument
   precisely.

   But this is silly: we're passing the function a _better_ argument
   than it needs!  The only thing the body of the function can
   possibly do with its record argument [r] is project the field [age]
   from it: nothing else is allowed by the type, and the presence or
   absence of an extra [gpa] field makes no difference at all.  So,
   intuitively, it seems that this function should be applicable to
   any record value that has at least an [age] field.

   Looking at the same thing from another point of view, a record with
   more fields is "at least as good in any context" as one with just a
   subset of these fields, in the sense that any value belonging to
   the longer record type can be used _safely_ in any context
   expecting the shorter record type.  If the context expects
   something with the shorter type but we actually give it something
   with the longer type, nothing bad will happen (formally, the
   program will not get stuck).

   The general principle at work here is called _subtyping_.  We say
   that "[S] is a subtype of [T]", informally written [S <: T], if a
   value of type [S] can safely be used in any context where a value
   of type [T] is expected.  The idea of subtyping applies not only to
   records, but to all of the type constructors in the language --
   functions, pairs, etc. *)

(** ** Subtyping and Object-Oriented Languages *)

(** Subtyping plays a fundamental role in many programming
    languages -- in particular, it is closely related to the notion of
    _subclassing_ in object-oriented languages.

    An _object_ in Java, C[#], etc. can be thought of as a record,
    some of whose fields are functions ("methods") and some of whose
    fields are data values ("fields" or "instance variables").
    Invoking a method [m] of an object [o] on some arguments [a1..an]
    consists of projecting out the [m] field of [o] and applying it to
    [a1..an].

    The type of an object can be given as either a _class_ or an
    _interface_.  Both of these provide a description of which methods
    and which data fields the object offers.

    Classes and interfaces are related by the _subclass_ and
    _subinterface_ relations.  An object belonging to a subclass (or
    subinterface) is required to provide all the methods and fields of
    one belonging to a superclass (or superinterface), plus possibly
    some more.

    The fact that an object from a subclass (or sub-interface) can be
    used in place of one from a superclass (or super-interface)
    provides a degree of flexibility that is is extremely handy for
    organizing complex libraries.  For example, a GUI toolkit like
    Java's Swing framework might define an abstract interface
    [Component] that collects together the common fields and methods
    of all objects having a graphical representation that can be
    displayed on the screen and that can interact with the user.
    Examples of such object would include the buttons, checkboxes, and
    scrollbars of a typical GUI.  A method that relies only on this
    common interface can now be applied to any of these objects.

    Of course, real object-oriented languages include many other
    features besides these.  For example, fields can be updated.
    Fields and methods can be declared [private].  Classes also give
    _code_ that is used when constructing objects and implementing
    their methods, and the code in subclasses cooperate with code in
    superclasses via _inheritance_.  Classes can have static methods
    and fields, initializers, etc., etc.

    To keep things simple here, we won't deal with any of these
    issues -- in fact, we won't even talk any more about objects or
    classes.  (There is a lot of discussion in _Types and Programming
    Languages_, if you are interested.)  Instead, we'll study the core
    concepts behind the subclass / subinterface relation in the
    simplified setting of the STLC. *)

(** *** *)
(** Of course, real OO languages have lots of other features...
       - mutable fields
       - [private] and other visibility modifiers
       - method inheritance
       - static components
       - etc., etc.

    We'll ignore all these and focus on core mechanisms. *)

(** ** The Subsumption Rule *)

(** Our goal for this chapter is to add subtyping to the simply typed
    lambda-calculus (with some of the basic extensions from [MoreStlc]).
    This involves two steps:

      - Defining a binary _subtype relation_ between types.

      - Enriching the typing relation to take subtyping into account.

    The second step is actually very simple.  We add just a single rule
    to the typing relation: the so-called _rule of subsumption_:
                         Gamma |- t : S     S <: T
                         -------------------------                      (T_Sub)
                               Gamma |- t : T
    This rule says, intuitively, that it is OK to "forget" some of
    what we know about a term. *)
(** For example, we may know that [t] is a record with two
    fields (e.g., [S = {x:A->A, y:B->B}]), but choose to forget about
    one of the fields ([T = {y:B->B}]) so that we can pass [t] to a
    function that requires just a single-field record. *)

(** ** The Subtype Relation *)

(** The first step -- the definition of the relation [S <: T] -- is
    where all the action is.  Let's look at each of the clauses of its
    definition.  *)

(** *** Structural Rules *)

(** To start off, we impose two "structural rules" that are
    independent of any particular type constructor: a rule of
    _transitivity_, which says intuitively that, if [S] is better than
    [U] and [U] is better than [T], then [S] is better than [T]...
                              S <: U    U <: T
                              ----------------                        (S_Trans)
                                   S <: T
    ... and a rule of _reflexivity_, since certainly any type [T] is
    as good as itself:
                                   ------                              (S_Refl)
                                   T <: T
*)

(** *** Products *)

(** Now we consider the individual type constructors, one by one,
    beginning with product types.  We consider one pair to be "better
    than" another if each of its components is.
                            S1 <: T1    S2 <: T2
                            --------------------                        (S_Prod)
                             S1 * S2 <: T1 * T2
*)

(** *** Arrows *)

(** Suppose we have two functions [f] and [g] with these types:
       f : C -> Student
       g : (C->Person) -> D
    That is, [f] is a function that yields a record of type [Student],
    and [g] is a (higher-order) function that expects its (function)
    argument to yield a record of type [Person].  Also suppose, even
    though we haven't yet discussed subtyping for records, that
    [Student] is a subtype of [Person].  Then the application [g f] is
    safe even though their types do not match up precisely, because
    the only thing [g] can do with [f] is to apply it to some
    argument (of type [C]); the result will actually be a [Student],
    while [g] will be expecting a [Person], but this is safe because
    the only thing [g] can then do is to project out the two fields
    that it knows about ([name] and [age]), and these will certainly
    be among the fields that are present.

    This example suggests that the subtyping rule for arrow types
    should say that two arrow types are in the subtype relation if
    their results are:
                                  S2 <: T2
                              ----------------                     (S_Arrow_Co)
                            S1 -> S2 <: S1 -> T2
    We can generalize this to allow the arguments of the two arrow
    types to be in the subtype relation as well:
                            T1 <: S1    S2 <: T2
                            --------------------                      (S_Arrow)
                            S1 -> S2 <: T1 -> T2
    Notice that the argument types are subtypes "the other way round":
    in order to conclude that [S1->S2] to be a subtype of [T1->T2], it
    must be the case that [T1] is a subtype of [S1].  The arrow
    constructor is said to be _contravariant_ in its first argument
    and _covariant_ in its second.

    Here is an example that illustrates this:
       f : Person -> C
       g : (Student -> C) -> D
    The application [g f] is safe, because the only thing the body of
    [g] can do with [f] is to apply it to some argument of type
    [Student].  Since [f] requires records having (at least) the
    fields of a [Person], this will always work. So [Person -> C] is a
    subtype of [Student -> C] since [Student] is a subtype of
    [Person].

    The intuition is that, if we have a function [f] of type [S1->S2],
    then we know that [f] accepts elements of type [S1]; clearly, [f]
    will also accept elements of any subtype [T1] of [S1]. The type of
    [f] also tells us that it returns elements of type [S2]; we can
    also view these results belonging to any supertype [T2] of
    [S2]. That is, any function [f] of type [S1->S2] can also be
    viewed as having type [T1->T2].
*)

(** *** Records *)

(** What about subtyping for record types? *)

(** The basic intuition about subtyping for record types is that it is
   always safe to use a "bigger" record in place of a "smaller" one.
   That is, given a record type, adding extra fields will always
   result in a subtype.  If some code is expecting a record with
   fields [x] and [y], it is perfectly safe for it to receive a record
   with fields [x], [y], and [z]; the [z] field will simply be ignored.
   For example,
       {name:String, age:Nat, gpa:Nat} <: {name:String, age:Nat}
       {name:String, age:Nat} <: {name:String}
       {name:String} <: {}
   This is known as "width subtyping" for records. *)

(** We can also create a subtype of a record type by replacing the type
   of one of its fields with a subtype.  If some code is expecting a
   record with a field [x] of type [T], it will be happy with a record
   having a field [x] of type [S] as long as [S] is a subtype of
   [T]. For example,
       {x:Student} <: {x:Person}
   This is known as "depth subtyping". *)

(** Finally, although the fields of a record type are written in a
   particular order, the order does not really matter. For example,
       {name:String,age:Nat} <: {age:Nat,name:String}
   This is known as "permutation subtyping". *)

(** We could formalize these requirements in a single subtyping rule
   for records as follows:
                        for each jk in j1..jn,
                    exists ip in i1..im, such that
                          jk=ip and Sp <: Tk
                  ----------------------------------                    (S_Rcd)
                  {i1:S1...im:Sm} <: {j1:T1...jn:Tn}
   That is, the record on the left should have all the field labels of
   the one on the right (and possibly more), while the types of the
   common fields should be in the subtype relation. However, this rule
   is rather heavy and hard to read.  If we like, we can decompose it
   into three simpler rules, which can be combined using [S_Trans] to
   achieve all the same effects. *)

(** First, adding fields to the end of a record type gives a subtype:
                               n > m
                 ---------------------------------                 (S_RcdWidth)
                 {i1:T1...in:Tn} <: {i1:T1...im:Tm}
   We can use [S_RcdWidth] to drop later fields of a multi-field
   record while keeping earlier fields, showing for example that
   [{age:Nat,name:String} <: {name:String}]. *)

(** Second, we can apply subtyping inside the components of a compound
   record type:
                       S1 <: T1  ...  Sn <: Tn
                  ----------------------------------               (S_RcdDepth)
                  {i1:S1...in:Sn} <: {i1:T1...in:Tn}
   For example, we can use [S_RcdDepth] and [S_RcdWidth] together to
   show that [{y:Student, x:Nat} <: {y:Person}]. *)

(** Third, we need to be able to reorder fields.  For example, we
   might expect that [{name:String, gpa:Nat, age:Nat} <: Person].  We
   haven't quite achieved this yet: using just [S_RcdDepth] and
   [S_RcdWidth] we can only drop fields from the _end_ of a record
   type.  So we need:
         {i1:S1...in:Sn} is a permutation of {i1:T1...in:Tn}
         ---------------------------------------------------        (S_RcdPerm)
                  {i1:S1...in:Sn} <: {i1:T1...in:Tn}
*)

(** It is worth noting that full-blown language designs may choose not
    to adopt all of these subtyping rules. For example, in Java:

    - A subclass may not change the argument or result types of a
      method of its superclass (i.e., no depth subtyping or no arrow
      subtyping, depending how you look at it).

    - Each class has just one superclass ("single inheritance" of
      classes).

    - Each class member (field or method) can be assigned a single
      index, adding new indices "on the right" as more members are
      added in subclasses (i.e., no permutation for classes).

    - A class may implement multiple interfaces -- so-called "multiple
      inheritance" of interfaces (i.e., permutation is allowed for
      interfaces). *)

(** **** Exercise: 2 stars (arrow_sub_wrong)  *)
(** Suppose we had incorrectly defined subtyping as covariant on both
    the right and the left of arrow types:
                            S1 <: T1    S2 <: T2
                            --------------------                (S_Arrow_wrong)
                            S1 -> S2 <: T1 -> T2
    Give a concrete example of functions [f] and [g] with the following types...
       f : Student -> Nat
       g : (Person -> Nat) -> Nat
    ... such that the application [g f] will get stuck during
    execution.
f : get gpa
g : apply the 1st arg with a person (without gpa)
[] *)

(** *** Top *)

(** Finally, it is natural to give the subtype relation a maximal
    element -- a type that lies above every other type and is
    inhabited by all (well-typed) values.  We do this by adding to the
    language one new type constant, called [Top], together with a
    subtyping rule that places it above every other type in the
    subtype relation:
                                   --------                             (S_Top)
                                   S <: Top
    The [Top] type is an analog of the [Object] type in Java and C[#]. *)

(* ############################################### *)
(** *** Summary *)

(** In summary, we form the STLC with subtyping by starting with the
    pure STLC (over some set of base types) and...

    - adding a base type [Top],

    - adding the rule of subsumption
                         Gamma |- t : S     S <: T
                         -------------------------                      (T_Sub)
                               Gamma |- t : T
      to the typing relation, and

    - defining a subtype relation as follows:
                              S <: U    U <: T
                              ----------------                        (S_Trans)
                                   S <: T

                                   ------                              (S_Refl)
                                   T <: T

                                   --------                             (S_Top)
                                   S <: Top

                            S1 <: T1    S2 <: T2
                            --------------------                       (S_Prod)
                             S1 * S2 <: T1 * T2

                            T1 <: S1    S2 <: T2
                            --------------------                      (S_Arrow)
                            S1 -> S2 <: T1 -> T2

                               n > m
                 ---------------------------------                 (S_RcdWidth)
                 {i1:T1...in:Tn} <: {i1:T1...im:Tm}

                       S1 <: T1  ...  Sn <: Tn
                  ----------------------------------               (S_RcdDepth)
                  {i1:S1...in:Sn} <: {i1:T1...in:Tn}

         {i1:S1...in:Sn} is a permutation of {i1:T1...in:Tn}
         ---------------------------------------------------        (S_RcdPerm)
                  {i1:S1...in:Sn} <: {i1:T1...in:Tn}
*)



(* ############################################### *)
(** ** Exercises *)

(** **** Exercise: 1 star, optional (subtype_instances_tf_1)  *)
(** Suppose we have types [S], [T], [U], and [V] with [S <: T]
    and [U <: V].  Which of the following subtyping assertions
    are then true?  Write _true_ or _false_ after each one.
    ([A], [B], and [C] here are base types.)

    - [T->S <: T->S]
true
    - [Top->U <: S->Top]
true
    - [(C->C) -> (A*B)  <:  (C->C) -> (Top*B)]
true
    - [T->T->U <: S->S->V]
true
    - [(T->T)->U <: (S->S)->V]
false
    - [((T->S)->T)->U <: ((S->T)->S)->V]
true
    - [S*V <: T*U]
false
[] *)

(** **** Exercise: 2 stars (subtype_order)  *)
(** The following types happen to form a linear order with respect to subtyping:
    - [Top]
    - [Top -> Student]
    - [Student -> Person]
    - [Student -> Top]
    - [Person -> Student]

Write these types in order from the most specific to the most general.
2 5 3 4 1

Where does the type [Top->Top->Student] fit into this order?
between 2 and 4

*)

(** **** Exercise: 1 star (subtype_instances_tf_2)  *)
(** Which of the following statements are true?  Write _true_ or
    _false_ after each one.
      forall S T,
          S <: T  ->
          S->S   <:  T->T
false
      forall S,
           S <: A->A ->
           exists T,
              S = T->T  /\  T <: A
false
      forall S T1 T2,
           (S <: T1 -> T2) ->
           exists S1 S2,
              S = S1 -> S2  /\  T1 <: S1  /\  S2 <: T2
true
      exists S,
           S <: S->S
false
      exists S,
           S->S <: S
true
      forall S T1 T2,
           S <: T1*T2 ->
           exists S1 S2,
              S = S1*S2  /\  S1 <: T1  /\  S2 <: T2
true
[] *)

(** **** Exercise: 1 star (subtype_concepts_tf)  *)
(** Which of the following statements are true, and which are false?
    - There exists a type that is a supertype of every other type.
true
    - There exists a type that is a subtype of every other type.
false
    - There exists a pair type that is a supertype of every other
      pair type.
true
    - There exists a pair type that is a subtype of every other
      pair type.
false
    - There exists an arrow type that is a supertype of every other
      arrow type.
false
    - There exists an arrow type that is a subtype of every other
      arrow type.
false
    - There is an infinite descending chain of distinct types in the
      subtype relation---that is, an infinite sequence of types
      [S0], [S1], etc., such that all the [Si]'s are different and
      each [S(i+1)] is a subtype of [Si].
true records
    - There is an infinite _ascending_ chain of distinct types in
      the subtype relation---that is, an infinite sequence of types
      [S0], [S1], etc., such that all the [Si]'s are different and
      each [S(i+1)] is a supertype of [Si].
true Si = "Di -> Top" where Di is a descending chain
[] *)

(** **** Exercise: 2 stars (proper_subtypes)  *)
(** Is the following statement true or false?  Briefly explain your
    answer.
    forall T,
         ~(exists n, T = TBase n) ->
         exists S,
            S <: T  /\  S <> T
false, TUnit TBool
]]
[] *)

(** **** Exercise: 2 stars (small_large_1)  *)
(**
   - What is the _smallest_ type [T] ("smallest" in the subtype
     relation) that makes the following assertion true?  (Assume we
     have [Unit] among the base types and [unit] as a constant of this
     type.)
       empty |- (\p:T*Top. p.fst) ((\z:A.z), unit) : A->A
   A -> A
   - What is the _largest_ type [T] that makes the same assertion true?
   Top
[] *)

(** **** Exercise: 2 stars (small_large_2)  *)
(**
   - What is the _smallest_ type [T] that makes the following
     assertion true?
       empty |- (\p:(A->A * B->B). p) ((\z:A.z), (\z:B.z)) : T
   (A -> A * B -> B)
   - What is the _largest_ type [T] that makes the same assertion true?
   Top
[] *)

(** **** Exercise: 2 stars, optional (small_large_3)  *)
(**
   - What is the _smallest_ type [T] that makes the following
     assertion true?
       a:A |- (\p:(A*T). (p.snd) (p.fst)) (a , \z:A.z) : A
   A -> A
   - What is the _largest_ type [T] that makes the same assertion true?
   Top
[] *)




(** **** Exercise: 2 stars (small_large_4)  *)
(**
   - What is the _smallest_ type [T] that makes the following
     assertion true?
       exists S,
         empty |- (\p:(A*T). (p.snd) (p.fst)) : S
   Top -> Unit
   - What is the _largest_ type [T] that makes the same
     assertion true?
   A -> Top
[] *)

(** **** Exercise: 2 stars (smallest_1)  *)
(** What is the _smallest_ type [T] that makes the following
    assertion true?
      exists S, exists t,
        empty |- (\x:T. x x) t : S
    Top
]]
[] *)

(** **** Exercise: 2 stars (smallest_2)  *)
(** What is the _smallest_ type [T] that makes the following
    assertion true?
      empty |- (\x:Top. x) ((\z:A.z) , (\z:B.z)) : T
    A -> A * B -> B
]]
[] *)

(** **** Exercise: 3 stars, optional (count_supertypes)  *)
(** How many supertypes does the record type [{x:A, y:C->C}] have?  That is,
    how many different types [T] are there such that [{x:A, y:C->C} <:
    T]?  (We consider two types to be different if they are written
    differently, even if each is a subtype of the other.  For example,
    [{x:A,y:B}] and [{y:B,x:A}] are different.)
2*2*3 + 5 + 1 + 1 = 19

[] *)

(** **** Exercise: 2 stars (pair_permutation)  *)
(** The subtyping rule for product types
                            S1 <: T1    S2 <: T2
                            --------------------                        (S_Prod)
                               S1*S2 <: T1*T2
intuitively corresponds to the "depth" subtyping rule for records. Extending the analogy, we might consider adding a "permutation" rule
                                   --------------
                                   T1*T2 <: T2*T1
for products.
Is this a good idea? Briefly explain why or why not.
no, fst/snd may be messed
[] *)

(* ###################################################### *)
(** * Formal Definitions *)

(** Most of the definitions -- in particular, the syntax and
    operational semantics of the language -- are identical to what we
    saw in the last chapter.  We just need to extend the typing
    relation with the subsumption rule and add a new [Inductive]
    definition for the subtyping relation.  Let's first do the
    identical bits. *)

(* ###################################################### *)
(** ** Core Definitions *)

(* ################################### *)
(** *** Syntax *)

(** For the sake of more interesting examples below, we'll allow an
    arbitrary set of additional base types like [String], [Float],
    etc.  We won't bother adding any constants belonging to these
    types or any operators on them, but we could easily do so. *)

(** In the rest of the chapter, we formalize just base types,
    booleans, arrow types, [Unit], and [Top], omitting record types
    and leaving product types as an exercise. *)

Inductive ty : Type :=
  | TTop   : ty
  | TBool  : ty
  | TBase  : id -> ty
  | TArrow : ty -> ty -> ty
  | TUnit  : ty
  | TProd  : ty -> ty -> ty
.

Tactic Notation "T_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "TTop" | Case_aux c "TBool"
  | Case_aux c "TBase" | Case_aux c "TArrow"
  | Case_aux c "TUnit" | Case_aux c "TProd"
  ].

Inductive tm : Type :=
  | tvar : id -> tm
  | tapp : tm -> tm -> tm
  | tabs : id -> ty -> tm -> tm
  | ttrue : tm
  | tfalse : tm
  | tif : tm -> tm -> tm -> tm
  | tpair : tm -> tm -> tm
  | tfst : tm -> tm
  | tsnd : tm -> tm
  | tunit : tm
.

Tactic Notation "t_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "tvar" | Case_aux c "tapp"
  | Case_aux c "tabs" | Case_aux c "ttrue"
  | Case_aux c "tfalse" | Case_aux c "tif"
  | Case_aux c "tpair" | Case_aux c "tfst" | Case_aux c "tsnd"
  | Case_aux c "tunit"
  ].

(* ################################### *)
(** *** Substitution *)

(** The definition of substitution remains exactly the same as for the
    pure STLC. *)

Fixpoint subst (x:id) (s:tm)  (t:tm) : tm :=
  match t with
  | tvar y =>
      if eq_id_dec x y then s else t
  | tabs y T t1 =>
      tabs y T (if eq_id_dec x y then t1 else (subst x s t1))
  | tapp t1 t2 =>
      tapp (subst x s t1) (subst x s t2)
  | ttrue =>
      ttrue
  | tfalse =>
      tfalse
  | tif t1 t2 t3 =>
      tif (subst x s t1) (subst x s t2) (subst x s t3)
  | tpair t1 t2 =>
      tpair (subst x s t1) (subst x s t2)
  | tfst t1 =>
      tfst (subst x s t1)
  | tsnd t1 =>
      tsnd (subst x s t1)
  | tunit =>
      tunit
  end.

Notation "'[' x ':=' s ']' t" := (subst x s t) (at level 20).

(* ################################### *)
(** *** Reduction *)

(** Likewise the definitions of the [value] property and the [step]
    relation. *)

Inductive value : tm -> Prop :=
  | v_abs : forall x T t,
      value (tabs x T t)
  | v_true :
      value ttrue
  | v_false :
      value tfalse
  | v_pair : forall v1 v2,
      value v1 ->
      value v2 ->
      value (tpair v1 v2)
  | v_unit :
      value tunit
.

Hint Constructors value.

Reserved Notation "t1 '==>' t2" (at level 40).

Inductive step : tm -> tm -> Prop :=
  | ST_AppAbs : forall x T t12 v2,
         value v2 ->
         (tapp (tabs x T t12) v2) ==> [x:=v2]t12
  | ST_App1 : forall t1 t1' t2,
         t1 ==> t1' ->
         (tapp t1 t2) ==> (tapp t1' t2)
  | ST_App2 : forall v1 t2 t2',
         value v1 ->
         t2 ==> t2' ->
         (tapp v1 t2) ==> (tapp v1  t2')
  | ST_IfTrue : forall t1 t2,
      (tif ttrue t1 t2) ==> t1
  | ST_IfFalse : forall t1 t2,
      (tif tfalse t1 t2) ==> t2
  | ST_If : forall t1 t1' t2 t3,
      t1 ==> t1' ->
      (tif t1 t2 t3) ==> (tif t1' t2 t3)
  | ST_Pair1 : forall t1 t1' t2,
        t1 ==> t1' ->
        (tpair t1 t2) ==> (tpair t1' t2)
  | ST_Pair2 : forall v1 t2 t2',
        value v1 ->
        t2 ==> t2' ->
        (tpair v1 t2) ==> (tpair v1 t2')
  | ST_Fst1 : forall t1 t1',
        t1 ==> t1' ->
        (tfst t1) ==> (tfst t1')
  | ST_FstPair : forall v1 v2,
        value v1 ->
        value v2 ->
        (tfst (tpair v1 v2)) ==> v1
  | ST_Snd1 : forall t1 t1',
        t1 ==> t1' ->
        (tsnd t1) ==> (tsnd t1')
  | ST_SndPair : forall v1 v2,
        value v1 ->
        value v2 ->
        (tsnd (tpair v1 v2)) ==> v2
where "t1 '==>' t2" := (step t1 t2).

Tactic Notation "step_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "ST_AppAbs" | Case_aux c "ST_App1"
  | Case_aux c "ST_App2" | Case_aux c "ST_IfTrue"
  | Case_aux c "ST_IfFalse" | Case_aux c "ST_If"
  | Case_aux c "ST_Pair1" | Case_aux c "ST_Pair2"
  | Case_aux c "ST_Fst1" | Case_aux c "ST_FstPair"
  | Case_aux c "ST_Snd1" | Case_aux c "ST_SndPair"
  ].

Hint Constructors step.

(* ###################################################################### *)
(** ** Subtyping *)

(** Now we come to the most interesting part.  We begin by
    defining the subtyping relation and developing some of its
    important technical properties. *)

(** The definition of subtyping is just what we sketched in the
    motivating discussion. *)

Reserved Notation "T '<:' U" (at level 40).

Inductive subtype : ty -> ty -> Prop :=
  | S_Refl : forall T,
      T <: T
  | S_Trans : forall S U T,
      S <: U ->
      U <: T ->
      S <: T
  | S_Top : forall S,
      S <: TTop
  | S_Arrow : forall S1 S2 T1 T2,
      T1 <: S1 ->
      S2 <: T2 ->
      (TArrow S1 S2) <: (TArrow T1 T2)
  | S_Prod : forall S1 S2 T1 T2,
      S1 <: T1 ->
      S2 <: T2 ->
      (TProd S1 S2) <: (TProd T1 T2)
where "T '<:' U" := (subtype T U).

(** Note that we don't need any special rules for base types: they are
    automatically subtypes of themselves (by [S_Refl]) and [Top] (by
    [S_Top]), and that's all we want. *)

Hint Constructors subtype.

Tactic Notation "subtype_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "S_Refl" | Case_aux c "S_Trans"
  | Case_aux c "S_Top" | Case_aux c "S_Arrow"
  | Case_aux c "S_Prod"
  ].

Module Examples.

Notation x := (Id 0).
Notation y := (Id 1).
Notation z := (Id 2).

Notation A := (TBase (Id 6)).
Notation B := (TBase (Id 7)).
Notation C := (TBase (Id 8)).

Notation String := (TBase (Id 9)).
Notation Float := (TBase (Id 10)).
Notation Integer := (TBase (Id 11)).

(** **** Exercise: 2 stars, optional (subtyping_judgements)  *)

(** (Do this exercise after you have added product types to the
    language, at least up to this point in the file).

    Using the encoding of records into pairs, define pair types
    representing the record types
    Person   := { name : String }
    Student  := { name : String ;
                  gpa  : Float }
    Employee := { name : String ;
                  ssn  : Integer }

Recall that in chapter MoreStlc, the optional subsection "Encoding
Records" describes how records can be encoded as pairs.

*)

Definition Person : ty :=
  TProd String TTop.
Definition Student : ty :=
  TProd String Float.
Definition Employee : ty :=
  TProd String Integer.

Example sub_student_person :
  Student <: Person.
Proof.
  unfold Student. unfold Person. auto.
Qed.

Example sub_employee_person :
  Employee <: Person.
Proof.
  unfold Employee. unfold Person. auto.
Qed.
(** [] *)

Example subtyping_example_0 :
  (TArrow C Person) <: (TArrow C TTop).
  (* C->Person <: C->Top *)
Proof.
  apply S_Arrow.
    apply S_Refl. auto.
Qed.

(** The following facts are mostly easy to prove in Coq.  To get
    full benefit from the exercises, make sure you also
    understand how to prove them on paper! *)

(** **** Exercise: 1 star, optional (subtyping_example_1)  *)
Example subtyping_example_1 :
  (TArrow TTop Student) <: (TArrow (TArrow C C) Person).
  (* Top->Student <: (C->C)->Person *)
Proof with eauto.
  eapply S_Arrow...
  apply sub_student_person.
Qed.
(** [] *)

(** **** Exercise: 1 star, optional (subtyping_example_2)  *)
Example subtyping_example_2 :
  (TArrow TTop Person) <: (TArrow Person TTop).
  (* Top->Person <: Person->Top *)
Proof with eauto.
  auto.
Qed.
(** [] *)

End Examples.


(* ###################################################################### *)
(** ** Typing *)

(** The only change to the typing relation is the addition of the rule
    of subsumption, [T_Sub]. *)

Definition context := id -> (option ty).
Definition empty : context := (fun _ => None).
Definition extend (Gamma : context) (x:id) (T : ty) :=
  fun x' => if eq_id_dec x x' then Some T else Gamma x'.

Reserved Notation "Gamma '|-' t '\in' T" (at level 40).

Inductive has_type : context -> tm -> ty -> Prop :=
  (* Same as before *)
  | T_Var : forall Gamma x T,
      Gamma x = Some T ->
      Gamma |- (tvar x) \in T
  | T_Abs : forall Gamma x T11 T12 t12,
      (extend Gamma x T11) |- t12 \in T12 ->
      Gamma |- (tabs x T11 t12) \in (TArrow T11 T12)
  | T_App : forall T1 T2 Gamma t1 t2,
      Gamma |- t1 \in (TArrow T1 T2) ->
      Gamma |- t2 \in T1 ->
      Gamma |- (tapp t1 t2) \in T2
  | T_True : forall Gamma,
       Gamma |- ttrue \in TBool
  | T_False : forall Gamma,
       Gamma |- tfalse \in TBool
  | T_If : forall t1 t2 t3 T Gamma,
       Gamma |- t1 \in TBool ->
       Gamma |- t2 \in T ->
       Gamma |- t3 \in T ->
       Gamma |- (tif t1 t2 t3) \in T
  | T_Pair : forall Gamma t1 t2 T1 T2,
      Gamma |- t1 \in T1 ->
      Gamma |- t2 \in T2 ->
      Gamma |- (tpair t1 t2) \in (TProd T1 T2)
  | T_Fst : forall Gamma t T1 T2,
      Gamma |- t \in (TProd T1 T2) ->
      Gamma |- (tfst t) \in T1
  | T_Snd : forall Gamma t T1 T2,
      Gamma |- t \in (TProd T1 T2) ->
      Gamma |- (tsnd t) \in T2
  | T_Unit : forall Gamma,
      Gamma |- tunit \in TUnit
  (* New rule of subsumption *)
  | T_Sub : forall Gamma t S T,
      Gamma |- t \in S ->
      S <: T ->
      Gamma |- t \in T

where "Gamma '|-' t '\in' T" := (has_type Gamma t T).

Hint Constructors has_type.

Tactic Notation "has_type_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "T_Var" | Case_aux c "T_Abs"
  | Case_aux c "T_App" | Case_aux c "T_True"
  | Case_aux c "T_False" | Case_aux c "T_If"
  | Case_aux c "T_Pair" | Case_aux c "T_Fst"
  | Case_aux c "T_Snd" | Case_aux c "T_Unit"
  | Case_aux c "T_Sub" ].

(* To make your job simpler, the following hints help construct typing
   derivations. *)
Hint Extern 2 (has_type _ (tapp _ _) _) =>
  eapply T_App; auto.
Hint Extern 2 (_ = _) => compute; reflexivity.


(* ############################################### *)
(** ** Typing examples *)

Module Examples2.
Import Examples.

(** Do the following exercises after you have added product types to
    the language.  For each informal typing judgement, write it as a
    formal statement in Coq and prove it. *)

(** **** Exercise: 1 star, optional (typing_example_0)  *)
(* empty |- ((\z:A.z), (\z:B.z))
          : (A->A * B->B) *)
Hint Resolve eq_id.
Hint Resolve neq_id.

Example typing_example_0 : forall A B,
  empty |- (tpair (tabs z A (tvar z)) (tabs z B (tvar z)))
            \in (TProd (TArrow A A) (TArrow B B)).
Proof with eauto.
  intros. eapply T_Pair; apply T_Abs; apply T_Var;
  unfold extend...
Qed.
(** [] *)

(** **** Exercise: 2 stars, optional (typing_example_1)  *)
(* empty |- (\x:(Top * B->B). x.snd) ((\z:A.z), (\z:B.z))
          : B->B *)
Example typing_example_1 : forall A B,
  empty |- (tapp (tabs x (TProd TTop (TArrow B B)) (tsnd (tvar x))))
            (tpair (tabs z A (tvar z)) (tabs z B (tvar z)))
            \in (TArrow B B).
Proof with eauto.
  intros. eapply T_App... eapply T_Pair...
Qed.
(** [] *)

(** **** Exercise: 2 stars, optional (typing_example_2)  *)
(* empty |- (\z:(C->C)->(Top * B->B). (z (\x:C.x)).snd)
              (\z:C->C. ((\z:A.z), (\z:B.z)))
          : B->B *)
Example typing_example_2 : forall A B,
  empty |- (tapp (tabs z (TArrow (TArrow C C) (TProd TTop (TArrow B B)))
                      (tsnd (tapp (tvar z) (tabs x C (tvar x)))))
                (tabs z (TArrow C C) (tpair (tabs z A (tvar z)) (tabs z B (tvar z)))))
            \in (TArrow B B).
Proof with eauto.
  intros. eapply T_App... eapply T_Abs... eapply T_Pair...
Qed.
(** [] *)

End Examples2.

(* ###################################################################### *)
(** * Properties *)

(** The fundamental properties of the system that we want to check are
    the same as always: progress and preservation.  Unlike the
    extension of the STLC with references, we don't need to change the
    _statements_ of these properties to take subtyping into account.
    However, their proofs do become a little bit more involved. *)

(* ###################################################################### *)
(** ** Inversion Lemmas for Subtyping *)

(** Before we look at the properties of the typing relation, we need
    to record a couple of critical structural properties of the subtype
    relation:
       - [Bool] is the only subtype of [Bool]
       - every subtype of an arrow type is itself an arrow type. *)

(** These are called _inversion lemmas_ because they play the same
    role in later proofs as the built-in [inversion] tactic: given a
    hypothesis that there exists a derivation of some subtyping
    statement [S <: T] and some constraints on the shape of [S] and/or
    [T], each one reasons about what this derivation must look like to
    tell us something further about the shapes of [S] and [T] and the
    existence of subtype relations between their parts. *)

(** **** Exercise: 2 stars, optional (sub_inversion_Bool)  *)
Lemma sub_inversion_Bool : forall U,
     U <: TBool ->
       U = TBool.
Proof with auto.
  intros U Hs.
  remember TBool as V.
  induction Hs; try solve by inversion... assert (U = T)... subst...
Qed.

(** **** Exercise: 3 stars, optional (sub_inversion_arrow)  *)
Lemma sub_inversion_arrow : forall U V1 V2,
     U <: (TArrow V1 V2) ->
     exists U1, exists U2,
       U = (TArrow U1 U2) /\ (V1 <: U1) /\ (U2 <: V2).
Proof with eauto.
  intros U V1 V2 Hs.
  remember (TArrow V1 V2) as V.
  generalize dependent V2. generalize dependent V1.
  induction Hs; intros; try solve by inversion. exists V1...
  apply IHHs2 in HeqV. destruct HeqV as [T1 [T2 [H1 [H2 H3]]]].
  apply IHHs1 in H1. destruct H1 as [T1' [T2' [H1' [H2' H3']]]].
  exists T1'... exists T2'... inversion HeqV; subst...
Qed.

Lemma sub_inversion_prod : forall U V1 V2,
     U <: (TProd V1 V2) ->
     exists U1, exists U2,
       U = (TProd U1 U2) /\ (U1 <: V1) /\ (U2 <: V2).
Proof with eauto.
  intros.
  remember (TProd V1 V2) as V.
  generalize dependent V2. generalize dependent V1.
  induction H; intros; try solve by inversion. exists V1...
  apply IHsubtype2 in HeqV. destruct HeqV as [T1 [T2 [H1 [H2 H3]]]].
  apply IHsubtype1 in H1. destruct H1 as [T1' [T2' [H1' [H2' H3']]]].
  exists T1'... exists T2'... inversion HeqV; subst...
Qed.

(** [] *)

(* ########################################## *)
(** ** Canonical Forms *)

(** We'll see first that the proof of the progress theorem doesn't
    change too much -- we just need one small refinement.  When we're
    considering the case where the term in question is an application
    [t1 t2] where both [t1] and [t2] are values, we need to know that
    [t1] has the _form_ of a lambda-abstraction, so that we can apply
    the [ST_AppAbs] reduction rule.  In the ordinary STLC, this is
    obvious: we know that [t1] has a function type [T11->T12], and
    there is only one rule that can be used to give a function type to
    a value -- rule [T_Abs] -- and the form of the conclusion of this
    rule forces [t1] to be an abstraction.

    In the STLC with subtyping, this reasoning doesn't quite work
    because there's another rule that can be used to show that a value
    has a function type: subsumption.  Fortunately, this possibility
    doesn't change things much: if the last rule used to show [Gamma
    |- t1 : T11->T12] is subsumption, then there is some
    _sub_-derivation whose subject is also [t1], and we can reason by
    induction until we finally bottom out at a use of [T_Abs].

    This bit of reasoning is packaged up in the following lemma, which
    tells us the possible "canonical forms" (i.e. values) of function
    type. *)

(** **** Exercise: 3 stars, optional (canonical_forms_of_arrow_types)  *)
Lemma canonical_forms_of_arrow_types : forall Gamma s T1 T2,
  Gamma |- s \in (TArrow T1 T2) ->
  value s ->
  exists x, exists S1, exists s2,
     s = tabs x S1 s2.
Proof with eauto.
  intros. remember (TArrow T1 T2) as T.
  generalize dependent T1. generalize dependent T2.
  induction H; intros; try solve by inversion...
  subst. apply sub_inversion_arrow in H1. destruct H1 as [V1 [V2 [H2 H3]]]...
Qed.
(** [] *)

(** Similarly, the canonical forms of type [Bool] are the constants
    [true] and [false]. *)

Lemma canonical_forms_of_Bool : forall Gamma s,
  Gamma |- s \in TBool ->
  value s ->
  (s = ttrue \/ s = tfalse).
Proof with eauto.
  intros Gamma s Hty Hv.
  remember TBool as T.
  has_type_cases (induction Hty) Case; try solve by inversion...
  Case "T_Sub".
    subst. apply sub_inversion_Bool in H. subst...
Qed.

Lemma canonical_forms_of_prod_types : forall Gamma s T1 T2,
  Gamma |- s \in (TProd T1 T2) ->
  value s ->
  exists t1, exists t2, s = tpair t1 t2 /\ value t1 /\ value t2.
Proof with eauto.
  intros. remember (TProd T1 T2) as T.
  generalize dependent T1. generalize dependent T2.
  induction H; intros; try solve by inversion...
  inversion HeqT; subst. inversion H0; subst.
  exists t1... subst. apply sub_inversion_prod in H1.
  destruct H1 as [V1 [V2 [H2 H3]]]...
Qed.
(* ########################################## *)
(** ** Progress *)

(** The proof of progress proceeds like the one for the pure
    STLC, except that in several places we invoke canonical forms
    lemmas... *)

(** _Theorem_ (Progress): For any term [t] and type [T], if [empty |-
    t : T] then [t] is a value or [t ==> t'] for some term [t'].

    _Proof_: Let [t] and [T] be given, with [empty |- t : T].  Proceed
    by induction on the typing derivation.

    The cases for [T_Abs], [T_Unit], [T_True] and [T_False] are
    immediate because abstractions, [unit], [true], and [false] are
    already values.  The [T_Var] case is vacuous because variables
    cannot be typed in the empty context.  The remaining cases are
    more interesting:

    - If the last step in the typing derivation uses rule [T_App],
      then there are terms [t1] [t2] and types [T1] and [T2] such that
      [t = t1 t2], [T = T2], [empty |- t1 : T1 -> T2], and [empty |-
      t2 : T1].  Moreover, by the induction hypothesis, either [t1] is
      a value or it steps, and either [t2] is a value or it steps.
      There are three possibilities to consider:

      - Suppose [t1 ==> t1'] for some term [t1'].  Then [t1 t2 ==> t1' t2]
        by [ST_App1].

      - Suppose [t1] is a value and [t2 ==> t2'] for some term [t2'].
        Then [t1 t2 ==> t1 t2'] by rule [ST_App2] because [t1] is a
        value.

      - Finally, suppose [t1] and [t2] are both values.  By Lemma
        [canonical_forms_for_arrow_types], we know that [t1] has the
        form [\x:S1.s2] for some [x], [S1], and [s2].  But then
        [(\x:S1.s2) t2 ==> [x:=t2]s2] by [ST_AppAbs], since [t2] is a
        value.

    - If the final step of the derivation uses rule [T_If], then there
      are terms [t1], [t2], and [t3] such that [t = if t1 then t2 else
      t3], with [empty |- t1 : Bool] and with [empty |- t2 : T] and
      [empty |- t3 : T].  Moreover, by the induction hypothesis,
      either [t1] is a value or it steps.

       - If [t1] is a value, then by the canonical forms lemma for
         booleans, either [t1 = true] or [t1 = false].  In either
         case, [t] can step, using rule [ST_IfTrue] or [ST_IfFalse].

       - If [t1] can step, then so can [t], by rule [ST_If].

    - If the final step of the derivation is by [T_Sub], then there is
      a type [S] such that [S <: T] and [empty |- t : S].  The desired
      result is exactly the induction hypothesis for the typing
      subderivation.
*)

Theorem progress : forall t T,
     empty |- t \in T ->
     value t \/ exists t', t ==> t'.
Proof with eauto.
  intros t T Ht.
  remember empty as Gamma.
  revert HeqGamma.
  has_type_cases (induction Ht) Case;
    intros HeqGamma; subst...
  Case "T_Var".
    inversion H.
  Case "T_App".
    right.
    destruct IHHt1; subst...
    SCase "t1 is a value".
      destruct IHHt2; subst...
      SSCase "t2 is a value".
        destruct (canonical_forms_of_arrow_types empty t1 T1 T2)
          as [x [S1 [t12 Heqt1]]]...
        subst. exists ([x:=t2]t12)...
      SSCase "t2 steps".
        inversion H0 as [t2' Hstp]. exists (tapp t1 t2')...
    SCase "t1 steps".
      inversion H as [t1' Hstp]. exists (tapp t1' t2)...
  Case "T_If".
    right.
    destruct IHHt1.
    SCase "t1 is a value"...
      assert (t1 = ttrue \/ t1 = tfalse)
        by (eapply canonical_forms_of_Bool; eauto).
      inversion H0; subst...
      inversion H. rename x into t1'. eauto.
  Case "T_Pair".
    destruct IHHt1;
    destruct IHHt2...
    destruct H0.
    right. exists (tpair t1 x)...
    destruct H.
    right. exists (tpair x t2)...
    destruct H.
    right. exists (tpair x t2)...
  Case "T_Fst".
    destruct IHHt...
    destruct (canonical_forms_of_prod_types empty t T1 T2)
      as [x [S1 [t12 Heqt1]]]...
    destruct Heqt1.
    subst. right. exists x...
    destruct H. right.
    exists (tfst x)...
  Case "T_Snd".
    destruct IHHt...
    destruct (canonical_forms_of_prod_types empty t T1 T2)
      as [x [S1 [t12 Heqt1]]]...
    destruct Heqt1.
    subst. right. exists S1...
    destruct H. right.
    exists (tsnd x)...
Qed.

(* ########################################## *)
(** ** Inversion Lemmas for Typing *)

(** The proof of the preservation theorem also becomes a little more
    complex with the addition of subtyping.  The reason is that, as
    with the "inversion lemmas for subtyping" above, there are a
    number of facts about the typing relation that are "obvious from
    the definition" in the pure STLC (and hence can be obtained
    directly from the [inversion] tactic) but that require real proofs
    in the presence of subtyping because there are multiple ways to
    derive the same [has_type] statement.

    The following "inversion lemma" tells us that, if we have a
    derivation of some typing statement [Gamma |- \x:S1.t2 : T] whose
    subject is an abstraction, then there must be some subderivation
    giving a type to the body [t2]. *)

(** _Lemma_: If [Gamma |- \x:S1.t2 : T], then there is a type [S2]
    such that [Gamma, x:S1 |- t2 : S2] and [S1 -> S2 <: T].

    (Notice that the lemma does _not_ say, "then [T] itself is an arrow
    type" -- this is tempting, but false!)

    _Proof_: Let [Gamma], [x], [S1], [t2] and [T] be given as
     described.  Proceed by induction on the derivation of [Gamma |-
     \x:S1.t2 : T].  Cases [T_Var], [T_App], are vacuous as those
     rules cannot be used to give a type to a syntactic abstraction.

     - If the last step of the derivation is a use of [T_Abs] then
       there is a type [T12] such that [T = S1 -> T12] and [Gamma,
       x:S1 |- t2 : T12].  Picking [T12] for [S2] gives us what we
       need: [S1 -> T12 <: S1 -> T12] follows from [S_Refl].

     - If the last step of the derivation is a use of [T_Sub] then
       there is a type [S] such that [S <: T] and [Gamma |- \x:S1.t2 :
       S].  The IH for the typing subderivation tell us that there is
       some type [S2] with [S1 -> S2 <: S] and [Gamma, x:S1 |- t2 :
       S2].  Picking type [S2] gives us what we need, since [S1 -> S2
       <: T] then follows by [S_Trans]. *)

Lemma typing_inversion_abs : forall Gamma x S1 t2 T,
     Gamma |- (tabs x S1 t2) \in T ->
     (exists S2, (TArrow S1 S2) <: T
              /\ (extend Gamma x S1) |- t2 \in S2).
Proof with eauto.
  intros Gamma x S1 t2 T H.
  remember (tabs x S1 t2) as t.
  has_type_cases (induction H) Case;
    inversion Heqt; subst; intros; try solve by inversion.
  Case "T_Abs".
    exists T12...
  Case "T_Sub".
    destruct IHhas_type as [S2 [Hsub Hty]]...
  Qed.

(** Similarly... *)

Lemma typing_inversion_var : forall Gamma x T,
  Gamma |- (tvar x) \in T ->
  exists S,
    Gamma x = Some S /\ S <: T.
Proof with eauto.
  intros Gamma x T Hty.
  remember (tvar x) as t.
  has_type_cases (induction Hty) Case; intros;
    inversion Heqt; subst; try solve by inversion.
  Case "T_Var".
    exists T...
  Case "T_Sub".
    destruct IHHty as [U [Hctx HsubU]]... Qed.

Lemma typing_inversion_app : forall Gamma t1 t2 T2,
  Gamma |- (tapp t1 t2) \in T2 ->
  exists T1,
    Gamma |- t1 \in (TArrow T1 T2) /\
    Gamma |- t2 \in T1.
Proof with eauto.
  intros Gamma t1 t2 T2 Hty.
  remember (tapp t1 t2) as t.
  has_type_cases (induction Hty) Case; intros;
    inversion Heqt; subst; try solve by inversion.
  Case "T_App".
    exists T1...
  Case "T_Sub".
    destruct IHHty as [U1 [Hty1 Hty2]]...
Qed.

Lemma typing_inversion_true : forall Gamma T,
  Gamma |- ttrue \in T ->
  TBool <: T.
Proof with eauto.
  intros Gamma T Htyp. remember ttrue as tu.
  has_type_cases (induction Htyp) Case;
    inversion Heqtu; subst; intros...
Qed.

Lemma typing_inversion_false : forall Gamma T,
  Gamma |- tfalse \in T ->
  TBool <: T.
Proof with eauto.
  intros Gamma T Htyp. remember tfalse as tu.
  has_type_cases (induction Htyp) Case;
    inversion Heqtu; subst; intros...
Qed.

Lemma typing_inversion_if : forall Gamma t1 t2 t3 T,
  Gamma |- (tif t1 t2 t3) \in T ->
  Gamma |- t1 \in TBool
  /\ Gamma |- t2 \in T
  /\ Gamma |- t3 \in T.
Proof with eauto.
  intros Gamma t1 t2 t3 T Hty.
  remember (tif t1 t2 t3) as t.
  has_type_cases (induction Hty) Case; intros;
    inversion Heqt; subst; try solve by inversion.
  Case "T_If".
    auto.
  Case "T_Sub".
    destruct (IHHty H0) as [H1 [H2 H3]]...
Qed.

Lemma typing_inversion_unit : forall Gamma T,
  Gamma |- tunit \in T ->
    TUnit <: T.
Proof with eauto.
  intros Gamma T Htyp. remember tunit as tu.
  has_type_cases (induction Htyp) Case;
    inversion Heqtu; subst; intros...
Qed.

Lemma typing_inversion_pair : forall Gamma T t1 t2,
  Gamma |- tpair t1 t2 \in T ->
  (exists S1, exists S2, (TProd S1 S2) <: T
              /\ Gamma |- t1 \in S1 /\ Gamma |- t2 \in S2).
Proof with eauto.
  intros. remember (tpair t1 t2) as tp.
  induction H; try solve by inversion.
  inversion Heqtp; subst. exists T1...
  apply IHhas_type in Heqtp. destruct Heqtp as [V1 [V2 [H1 H2]]]...
Qed.

Lemma typing_inversion_fst : forall Gamma t T,
  Gamma |- tfst t \in T ->
  (exists S, Gamma |- t \in (TProd T S)).
Proof with eauto.
  intros. remember (tfst t) as tf.
  induction H; try solve by inversion. inversion Heqtf; subst...
  apply IHhas_type in Heqtf. destruct Heqtf...
Qed.

Lemma typing_inversion_snd : forall Gamma t T,
  Gamma |- tsnd t \in T ->
  (exists S, Gamma |- t \in (TProd S T)).
Proof with eauto.
  intros. remember (tsnd t) as tf.
  induction H; try solve by inversion. inversion Heqtf; subst...
  apply IHhas_type in Heqtf. destruct Heqtf...
Qed.
(** The inversion lemmas for typing and for subtyping between arrow
    types can be packaged up as a useful "combination lemma" telling
    us exactly what we'll actually require below. *)

Lemma abs_arrow : forall x S1 s2 T1 T2,
  empty |- (tabs x S1 s2) \in (TArrow T1 T2) ->
     T1 <: S1
  /\ (extend empty x S1) |- s2 \in T2.
Proof with eauto.
  intros x S1 s2 T1 T2 Hty.
  apply typing_inversion_abs in Hty.
  inversion Hty as [S2 [Hsub Hty1]].
  apply sub_inversion_arrow in Hsub.
  inversion Hsub as [U1 [U2 [Heq [Hsub1 Hsub2]]]].
  inversion Heq; subst...  Qed.

Lemma prod_types : forall S1 S2 T1 T2,
  TProd S1 S2 <: TProd T1 T2 ->
  S1 <: T1 /\ S2 <: T2.
Proof with eauto.
  intros. remember (TProd S1 S2) as S. remember (TProd T1 T2) as T.
  generalize dependent T1.
  generalize dependent T2.
  induction H; intros; try solve by inversion; subst.
  inversion HeqT; subst...
  destruct (sub_inversion_prod _ _ _ H0) as [T1' [T2' [H1 [H2 H3]]]].
  apply IHsubtype1 in H1... destruct H1...
  inversion HeqT; subst. inversion HeqS; subst...
Qed.

Lemma pair_partial : forall t1 t2 T1 T2,
  empty |- (tpair t1 t2) \in (TProd T1 T2) ->
  empty |- t1 \in T1 /\ empty |- t2 \in T2.
Proof with eauto.
  intros. destruct (typing_inversion_pair _ _ _ _ H) as [V [H1 [H2 [H3 H4]]]].
  destruct (prod_types _ _ _ _ H2)...
Qed.
(* ########################################## *)
(** ** Context Invariance *)

(** The context invariance lemma follows the same pattern as in the
    pure STLC. *)

Inductive appears_free_in : id -> tm -> Prop :=
  | afi_var : forall x,
      appears_free_in x (tvar x)
  | afi_app1 : forall x t1 t2,
      appears_free_in x t1 -> appears_free_in x (tapp t1 t2)
  | afi_app2 : forall x t1 t2,
      appears_free_in x t2 -> appears_free_in x (tapp t1 t2)
  | afi_abs : forall x y T11 t12,
        y <> x  ->
        appears_free_in x t12 ->
        appears_free_in x (tabs y T11 t12)
  | afi_if1 : forall x t1 t2 t3,
      appears_free_in x t1 ->
      appears_free_in x (tif t1 t2 t3)
  | afi_if2 : forall x t1 t2 t3,
      appears_free_in x t2 ->
      appears_free_in x (tif t1 t2 t3)
  | afi_if3 : forall x t1 t2 t3,
      appears_free_in x t3 ->
      appears_free_in x (tif t1 t2 t3)
  | afi_pair1 : forall x t1 t2,
      appears_free_in x t1 ->
      appears_free_in x (tpair t1 t2)
  | afi_pair2 : forall x t1 t2,
      appears_free_in x t2 ->
      appears_free_in x (tpair t1 t2)
  | afi_fst : forall x t,
      appears_free_in x t ->
      appears_free_in x (tfst t)
  | afi_snd : forall x t,
      appears_free_in x t ->
      appears_free_in x (tsnd t)
.

Hint Constructors appears_free_in.

Lemma context_invariance : forall Gamma Gamma' t S,
     Gamma |- t \in S  ->
     (forall x, appears_free_in x t -> Gamma x = Gamma' x)  ->
     Gamma' |- t \in S.
Proof with eauto.
  intros. generalize dependent Gamma'.
  has_type_cases (induction H) Case;
    intros Gamma' Heqv...
  Case "T_Var".
    apply T_Var... rewrite <- Heqv...
  Case "T_Abs".
    apply T_Abs... apply IHhas_type. intros x0 Hafi.
    unfold extend. destruct (eq_id_dec x x0)...
  Case "T_If".
    apply T_If...
  Case "T_Pair".
    apply T_Pair...
Qed.

Lemma free_in_context : forall x t T Gamma,
   appears_free_in x t ->
   Gamma |- t \in T ->
   exists T', Gamma x = Some T'.
Proof with eauto.
  intros x t T Gamma Hafi Htyp.
  has_type_cases (induction Htyp) Case;
      subst; inversion Hafi; subst...
  Case "T_Abs".
    destruct (IHHtyp H4) as [T Hctx]. exists T.
    unfold extend in Hctx. rewrite neq_id in Hctx...  Qed.

(* ########################################## *)
(** ** Substitution *)

(** The _substitution lemma_ is proved along the same lines as
    for the pure STLC.  The only significant change is that there are
    several places where, instead of the built-in [inversion] tactic,
    we need to use the inversion lemmas that we proved above to
    extract structural information from assumptions about the
    well-typedness of subterms. *)

Lemma substitution_preserves_typing : forall Gamma x U v t S,
     (extend Gamma x U) |- t \in S  ->
     empty |- v \in U   ->
     Gamma |- ([x:=v]t) \in S.
Proof with eauto.
  intros Gamma x U v t S Htypt Htypv.
  generalize dependent S. generalize dependent Gamma.
  t_cases (induction t) Case; intros; simpl.
  Case "tvar".
    rename i into y.
    destruct (typing_inversion_var _ _ _ Htypt)
        as [T [Hctx Hsub]].
    unfold extend in Hctx.
    destruct (eq_id_dec x y)...
    SCase "x=y".
      subst.
      inversion Hctx; subst. clear Hctx.
      apply context_invariance with empty...
      intros x Hcontra.
      destruct (free_in_context _ _ S empty Hcontra)
          as [T' HT']...
      inversion HT'.
  Case "tapp".
    destruct (typing_inversion_app _ _ _ _ Htypt)
        as [T1 [Htypt1 Htypt2]].
    eapply T_App...
  Case "tabs".
    rename i into y. rename t into T1.
    destruct (typing_inversion_abs _ _ _ _ _ Htypt)
      as [T2 [Hsub Htypt2]].
    apply T_Sub with (TArrow T1 T2)... apply T_Abs...
    destruct (eq_id_dec x y).
    SCase "x=y".
      eapply context_invariance...
      subst.
      intros x Hafi. unfold extend.
      destruct (eq_id_dec y x)...
    SCase "x<>y".
      apply IHt. eapply context_invariance...
      intros z Hafi. unfold extend.
      destruct (eq_id_dec y z)...
      subst. rewrite neq_id...
  Case "ttrue".
      assert (TBool <: S)
        by apply (typing_inversion_true _ _  Htypt)...
  Case "tfalse".
      assert (TBool <: S)
        by apply (typing_inversion_false _ _  Htypt)...
  Case "tif".
    assert ((extend Gamma x U) |- t1 \in TBool
            /\ (extend Gamma x U) |- t2 \in S
            /\ (extend Gamma x U) |- t3 \in S)
      by apply (typing_inversion_if _ _ _ _ _ Htypt).
    inversion H as [H1 [H2 H3]].
    apply IHt1 in H1. apply IHt2 in H2. apply IHt3 in H3.
    auto.
  Case "tpair".
    destruct (typing_inversion_pair _ _ _ _ Htypt)
    as [V1 [V2 [H1 [H2 H3]]]].
    apply IHt1 in H2. apply IHt2 in H3...
  Case "tfst".
    destruct (typing_inversion_fst _ _ _ Htypt)...
  Case "tsnd".
    destruct (typing_inversion_snd _ _ _ Htypt)...
  Case "tunit".
    assert (TUnit <: S)
      by apply (typing_inversion_unit _ _  Htypt)...
Qed.

(* ########################################## *)
(** ** Preservation *)

(** The proof of preservation now proceeds pretty much as in earlier
    chapters, using the substitution lemma at the appropriate point
    and again using inversion lemmas from above to extract structural
    information from typing assumptions. *)

(** _Theorem_ (Preservation): If [t], [t'] are terms and [T] is a type
    such that [empty |- t : T] and [t ==> t'], then [empty |- t' :
    T].

    _Proof_: Let [t] and [T] be given such that [empty |- t : T].  We
    proceed by induction on the structure of this typing derivation,
    leaving [t'] general.  The cases [T_Abs], [T_Unit], [T_True], and
    [T_False] cases are vacuous because abstractions and constants
    don't step.  Case [T_Var] is vacuous as well, since the context is
    empty.

     - If the final step of the derivation is by [T_App], then there
       are terms [t1] and [t2] and types [T1] and [T2] such that
       [t = t1 t2], [T = T2], [empty |- t1 : T1 -> T2], and
       [empty |- t2 : T1].

       By the definition of the step relation, there are three ways
       [t1 t2] can step.  Cases [ST_App1] and [ST_App2] follow
       immediately by the induction hypotheses for the typing
       subderivations and a use of [T_App].

       Suppose instead [t1 t2] steps by [ST_AppAbs].  Then [t1 =
       \x:S.t12] for some type [S] and term [t12], and [t' =
       [x:=t2]t12].

       By lemma [abs_arrow], we have [T1 <: S] and [x:S1 |- s2 : T2].
       It then follows by the substitution lemma
       ([substitution_preserves_typing]) that [empty |- [x:=t2]
       t12 : T2] as desired.

      - If the final step of the derivation uses rule [T_If], then
        there are terms [t1], [t2], and [t3] such that [t = if t1 then
        t2 else t3], with [empty |- t1 : Bool] and with [empty |- t2 :
        T] and [empty |- t3 : T].  Moreover, by the induction
        hypothesis, if [t1] steps to [t1'] then [empty |- t1' : Bool].
        There are three cases to consider, depending on which rule was
        used to show [t ==> t'].

           - If [t ==> t'] by rule [ST_If], then [t' = if t1' then t2
             else t3] with [t1 ==> t1'].  By the induction hypothesis,
             [empty |- t1' : Bool], and so [empty |- t' : T] by [T_If].

           - If [t ==> t'] by rule [ST_IfTrue] or [ST_IfFalse], then
             either [t' = t2] or [t' = t3], and [empty |- t' : T]
             follows by assumption.

     - If the final step of the derivation is by [T_Sub], then there
       is a type [S] such that [S <: T] and [empty |- t : S].  The
       result is immediate by the induction hypothesis for the typing
       subderivation and an application of [T_Sub].  [] *)
Theorem preservation : forall t t' T,
     empty |- t \in T  ->
     t ==> t'  ->
     empty |- t' \in T.
Proof with eauto.
  intros t t' T HT.
  remember empty as Gamma. generalize dependent HeqGamma.
  generalize dependent t'.
  has_type_cases (induction HT) Case;
    intros t' HeqGamma HE; subst; inversion HE; subst...
  Case "T_App".
    inversion HE; subst...
    SCase "ST_AppAbs".
      destruct (abs_arrow _ _ _ _ _ HT1) as [HA1 HA2].
      apply substitution_preserves_typing with T...
  Case "T_Fst".
    destruct (pair_partial _ _ _ _ HT)...
  Case "T_Snd".
    destruct (pair_partial _ _ _ _ HT)...
Qed.

(** ** Records, via Products and Top *)

(** This formalization of the STLC with subtyping has omitted record
    types, for brevity.  If we want to deal with them more seriously,
    we have two choices.

    First, we can treat them as part of the core language, writing
    down proper syntax, typing, and subtyping rules for them.  Chapter
    [RecordSub] shows how this extension works.

    On the other hand, if we are treating them as a derived form that
    is desugared in the parser, then we shouldn't need any new rules:
    we should just check that the existing rules for subtyping product
    and [Unit] types give rise to reasonable rules for record
    subtyping via this encoding. To do this, we just need to make one
    small change to the encoding described earlier: instead of using
    [Unit] as the base case in the encoding of tuples and the "don't
    care" placeholder in the encoding of records, we use [Top].  So:
<<
    {a:Nat, b:Nat} ----> {Nat,Nat}       i.e. (Nat,(Nat,Top))
    {c:Nat, a:Nat} ----> {Nat,Top,Nat}   i.e. (Nat,(Top,(Nat,Top)))
>>
    The encoding of record values doesn't change at all.  It is
    easy (and instructive) to check that the subtyping rules above are
    validated by the encoding.  For the rest of this chapter, we'll
    follow this encoding-based approach. *)

(* ###################################################### *)
(** ** Exercises *)

(** **** Exercise: 2 stars (variations)  *)
(** Each part of this problem suggests a different way of
    changing the definition of the STLC with Unit and
    subtyping.  (These changes are not cumulative: each part
    starts from the original language.)  In each part, list which
    properties (Progress, Preservation, both, or neither) become
    false.  If a property becomes false, give a counterexample.
    - Suppose we add the following typing rule:
                            Gamma |- t : S1->S2
                    S1 <: T1      T1 <: S1     S2 <: T2
                    -----------------------------------              (T_Funny1)
                            Gamma |- t : T1->T2
neither
    - Suppose we add the following reduction rule:
                             ------------------                     (ST_Funny21)
                             unit ==> (\x:Top. x)
Preservation, unit ==> (\x:Top. x)
    - Suppose we add the following subtyping rule:
                               --------------                        (S_Funny3)
                               Unit <: Top->Top
Progress, tapp tunit ttrue
    - Suppose we add the following subtyping rule:
                               --------------                        (S_Funny4)
                               Top->Top <: Unit
neither
    - Suppose we add the following evaluation rule:
                             -----------------                      (ST_Funny5)
                             (unit t) ==> (t unit)
neither
    - Suppose we add the same evaluation rule _and_ a new typing rule:
                             -----------------                      (ST_Funny5)
                             (unit t) ==> (t unit)

                           ----------------------                    (T_Funny6)
                           empty |- Unit : Top->Top
Preservation, tapp tunit ttrue(Top) ==> tapp ttrue tunit
    - Suppose we _change_ the arrow subtyping rule to:
                          S1 <: T1       S2 <: T2
                          -----------------------                    (S_Arrow')
                               S1->S2 <: T1->T2
Preservation, (\x:Person -> Nat. (x A_person)) \x:Student. x.gpa ==>
   (\x:Student. x.gpa) A_person
[] *)

(* ###################################################################### *)
(** * Exercise: Adding Products *)

(** **** Exercise: 4 stars (products)  *)
(** Adding pairs, projections, and product types to the system we have
    defined is a relatively straightforward matter.  Carry out this
    extension:

    - Add constructors for pairs, first and second projections, and
      product types to the definitions of [ty] and [tm].  (Don't
      forget to add corresponding cases to [T_cases] and [t_cases].)

    - Extend the substitution function and value relation as in
      MoreSTLC.

    - Extend the operational semantics with the same reduction rules
      as in MoreSTLC.

    - Extend the subtyping relation with this rule:

                        S1 <: T1     S2 <: T2
                        ---------------------                     (Sub_Prod)
                          S1 * S2 <: T1 * T2

    - Extend the typing relation with the same rules for pairs and
      projections as in MoreSTLC.

    - Extend the proofs of progress, preservation, and all their
      supporting lemmas to deal with the new constructs.  (You'll also
      need to add some completely new lemmas.)
[] *)


(** $Date: 2014-12-31 11:17:56 -0500 (Wed, 31 Dec 2014) $ *)