## Overview

We thank the reviewers for their detailed comments and suggestions.

We begin by clarifying concerns that were shared by multiple
reviewers.  Specifically, we: (a) characterize the expressivity and
limitations of our PAT-based type abstraction and (b) relate the
novelty of our methodology to other PBT and model-checking techniques
for distributed systems.

We then present a detailed changelist that proposes to (a) better
clarify our methodology and its applicability to testing of
distributed systems; (b) incorporate additional related work as
suggested by the reviewers; and (c) elaborate and expand our
evaluation by providing further experimental details as well as
additional experiments demonstrating that our technique can be applied
to test e.g., well-understood consistency and network delivery
properties.

Finally, we conclude with detailed responses to the questions raised
by individual reviewers.

## Shared Concerns

### Expressivity of PATs

Beyond the ability to express temporal modalities on events, the PAT
specification language supports the use of ghost variables to capture
data dependencies among specification events, resulting in a level of
expressive power akin to data/register automata (Reviewer E), while
still being amenable to efficient SMT encodings. This additional power
allows us to capture fine-grained dependencies between the actors in
the SUT, while at the same time not overly constraining the behavior
of the complete system. Enforcing these behaviors are delegated to the
synthesized controllers, allowing us to capture and test for wide
range of consistency, (e.g., sequential consistency and deadlock
freedom) and network delivery properties (e.g., in-order/out-of-order
delivery and node failures) relevant to distributed systems (Reviewer
E); we elaborate on this point in the individual responses, provide
detailed examples of these in the attached file, and will incorporate
these obesrvations in the revised version.

Our PAT-based specifications inherit the limitations of the SFAs that
they compile into. As one example, SFAs (even when equipped with ghost
variables) cannot express counting properties (e.g., specifying that
an event appears twice as often as another event in a trace), as this
exceeds the expressive power of regular languages. Additionally, since
we only consider finite traces, we cannot express properties over
infinite executions (e.g., an event appearing infinitely many times in the
future). For properties that are amenable to PBT-style automated
testing, however, SFAs appear to be particularly well-suited and
effective.

### Comparison with Property-Based Testing and Verification of Open Distributed Systems

While Clouseau's use of LTL in PATs and top-level specifications
evokes their traditional use in the _verification_ of distributed and
concurrent systems, we emphasize that our focus is on _automatically
testing_ these systems in a rigorous way.  As a consequence, PAT
specifications are expected to be tailored to the property whose
violation we are interested in exhibiting; they are _not_ intended to
serve as a complete functional specification of an actor's behavior.

In this sense, our overall methodology is more reminiscent of other
PBT-style techniques for distributed systems.  However, there are
three distinguishing features of our framework whose combination
distinguish it from existing work. First, we target open systems, in
which external clients can inject messages into the SUT. Second, in
contrast to other PBT-style systems that treat the SUT as a black box,
the (local) PAT specifications of the actors provide visibility into
the system in terms of which (global) traces are feasible. This
information enables us to be significantly more targeted in our search
for a violating execution, allowing us to synthesize schedules
_tailored to the property of interest_--- specifically, the history
automata part of a PAT induces "precondition" constraints on allowed
behaviors that permit the actor to generate a new event, while the
prophecy automata component induces "postcondition" constraints that
regulate future actions by the actor. The capability of dividing
symbolic traces into a history and a future is especially valuable in
the concurrent/asynchronous setting we target.  Third, the synthesized
controller effectively represents a state machine model that mediates
the allowed actions actors may perform; unlike prior approaches that
require this structure to be either explicitly specified or
implemented, Clouseau automatically generates this component from the
set of PAT specifications attached to actors, and the global property
being tested.

As with any testing methodology, our controllers are typically
incomplete: our algorithm is only guaranteed to produce a set of
controllers that capture a subset of the feasible executions
consistent with provided specifications (lines 627-629, 776-778),
although our experimental evidence supports our contention that this
tradeoff works well in practice.

## Summary of Proposed Changes
Concretely, we propose to implement the following changes in the
revision, in order to clarify the issues discussed above and the
specific criticisms posed by the reviewers addressed below:

-  We will clarify that PATs are indeed implemented using SFAs, and
  can support both symbolic LTL$_f$ and symbolic regexes as frontend
  languages (Reviewers A, B, and E). We will also clarify the
  definition of abstract traces and provide a correctness proof of
  normalization (Reviewer E).

- To provide a better interpretation of PATs, we will include
  the type denotation from our supplemental material in the
  revision (Reviewer A).

- To demonstrate that PATs enable a high degree of automation, we will
  highlight that we target PATs whose qualifiers are quantifier-free,
  which guarantees that the VCs are in EPR (Reviewer C). We will also
  provide additional examples of VCs derived from auxiliary type
  judgments (Reviewer A).

- We will extend our discussion in the evaluation section to provide
  additional details on the testing difficulty of the sorts of
  properties in benchmarks (Reviewer A), elaborate on the experimental
  setup of the second baseline "P+M" (Reviewer A), and explain how
  bugs are injected into our benchmarks (Reviewer B). We will also
  report the average execution time (Reviewer A) and set a multi-hour
  (3+) time bound (Reviewer B) for the P (and P+M) baselines,[^1] rather
  than just limiting the number of executions.

- We will incorporate all the suggestions made by the reviewers to
  expand our discussion of related work, better contextualizing our
  contributions with respect to other approaches to validating
  distributed systems, including PBT-style approaches (Reviewer D),
  model checking (Reviewer E), and verification (Reviewers B and E).
  Thank you for bringing many of these works to our attention!

- We will fix all typos and spacing problems identified by the
  reviewers.

[^1] We have already run a preliminary version of this experiment on
  both the Paxos and Raft benchmarks using the random controller and a
  timeout of 3 hours; in both cases no violations were detected.

## Responses to Specific Questions

#### Reviewer A

- Q: How does `DeriveTerm` handle $$\square A$$?

+ A: The reviewer correctly notes that `DeriveTerm` removes any
  remaining $$\square A$$s when building a controller program from an
  abstract trace. Intuitively, the violation encoded in the abstract
  trace is independent of any events in $$\square A$$; eliding them
  allows Clouseau to safely focus on the events that are core to the
  violation.

- Q: Where is the SMT solver invoked?

+ A: Our framework uses an SMT solver in two places: first, a solver
  is used to perform the SFA inclusion checks in the **WfHAF** and
  **SubHAF** rules; these are implemented using a standard
  minterm-based SFA algorithm [12]. We will clarify this point in
  future versions of the paper and provide a simplified example of the
  SMT query, if space permits. Second, we use a solver to handle
  `assume` and `assert` statements when executing test controllers.

- Q: Are the properties data-dependent?

+ A: Many of the properties we target are data-dependent, in that many
  of these properties impose a particular relationship between the
  contents of the messages in the system; in general, it is not the
  case that "a bug is very sensitive to particular values." In the
  motivating example, for instance, we must see at least two
  $\mathbf{write}$ operations on the same key with different data (as in
  $A'_\mathtt{violateRYW}$ on line 357) in order to trigger a
  violation--- however, manifesting this bug does not depend on a
  specific key or value.

- Q: Where do the manually written controllers come from?

+ A: Several of our benchmarks include a manually written controller
  that closes the system-- we use these independently written
  controllers as the "M"s in our "P+M" benchmarks. Indeed, "the best
  such M would be equivalent to one of your synthesized controllers,"
  but as our experiments show, this is not the case for many of our
  benchmarks, partly due to the fact that these controllers were
  written independently of the property under test.

- Q: Is F in SubHAF co- or contravariant?

+ A: The rule in Figure 8 is incorrect-- F is indeed is indeed
  contravariant, per the supplementary material. Thanks for catching
  this!

- Q: How is $A \;\mathcal{U}\; B$ normalized?

+ A: This is a typo: $A \;\mathcal{U}\; B$ actually normalizes into $\square
  A \;\cdot\; B$ (no negation). The meaning of $\square
  \langle\phi\rangle\;\cdot\;\Pi$ is exactly as the reviewer states.

#### Reviewer B

- Q: Why bound the number of executions instead of setting a timeout
  of a few hours?

- A: This is an excellent suggestion! To support our hypothesis that
  doing so will not improve the effectiveness of the P baseline,
  we have run this experiment on both the Paxos and Raft benchmarks
  using P's random controller and a timeout of 3 hours; in both cases
  no violations were detected. We plan to run a more comprehensive
  version of this experiment for all of our benchmarks and include the
  results in the next iteration of the paper.

- Q: How are bugs injected into the benchmarks?

+ A: We introduce bugs in two ways: 1) by deleting control flow paths
  from the original distributed models, and 2) by introducing weakly
  consistent behaviors (e.g., returning some value written before the
  last one written).

- Q: Could PATs also use (symbolic) regexes?

+ A: Indeed, since PATs are based on SFAs, we can accept any front-end
  language that can be compiled into SFAs, including symbolic regexes.

#### Reviewer C

- Q: Aren't LTL specifications complicated and error-prone?

+ A: Many contemporary testing and verification tools use variants of
  LTL to express the behavior of concurrent/distributed systems,
  including both model checkers (e.g., the popular and well-studied
  TLA+ toolchain) and automated testing frameworks (e.g., Quickstrom).
  We do not believe our specification framework is any more complex or
  error-prone than these.

- Q: Why are constraints guaranteed to be in EPR?

+ A: The reviewer is correct that our rules as currently defined do
  not ensure that all VCs are in EPR. This can be easily accomplished,
  however, by restricting qualifiers to be quantifier-free formulas (a
  restriction satisfied by all of our benchmarks). Under the standard
  minterm-based SFA algorithm [12], the VCs are proof obligations that
  all qualifiers of symbolic events (i.e., $\phi$ in
  $\langle\mathbf{op}\ \overline{x} ~|~ \phi\rangle$) are satisfiable under the current
  typing context. Typing contexts are interpreted as a prefix of
  universally quantified substitutions (lines $565$ and $580$), thus
  guaranteeing that the resulting VCs are in EPR.  We will update the
  well-formedness rules to enforce this constraint, which can be
  accomplished via a simple syntactic check on PATs.

- Q: What happens if the synthesis algorithm gets stuck?

+ A: Our implementation of the synthesis algorithm uses a backtracking
  search procedure (line 628), and thus cannot get stuck by "picking
  the wrong values or choices." Example 4.4 gives an example of how
  the algorithm recovers from a bad choice (lines 753-755).

#### Reviewer D

- Q: How does Clouseau compare to Claessen et al. / Concuerror / Quickstrom?

+ A: Like Clouseau, all three of these works rely on some
  specification of what actions are allowed at each step to drive
  testing: Claessen et al. use Quviq QuickCheck's support for state
  machine models to produce sequences of calls to the system under
  test, Concuerror systematically explores possible process
  interleavings, and Quickstrom uses specifications of the possible
  actions in its Specstrom language to dynamically choose the next
  step to take.  Importantly, however, Quviq and Quickstrom require
  users to explicitly constrain the set of allowable actions at each
  step, while Concuerror chooses the next action in the schedule in a
  property independent way.  Clouseau, in contrast, automatically
  synthesizes its search strategy based on both the global property of
  interest and the local PAT specifications of the components in the
  SUT. Importantly, it uses prophecy automata to intelligent choose
  actions that are relevant to the eventual violation of the target
  property, a major point of distinction from these other efforts.
  Another way to think about these different systems is that while all
  four effectively use some kind of model-based state machine
  structure to regulate interactions among the components under test,
  only Clouseau considers how we might generate this state machine
  model (aka test controller) automatically from actor-local
  specifications.

- Q: Why so many spacing problems?

+ A: Our apologies; although the spacing issues were triggered by
  `acmart`, we will certainly work to fixing them in the next version
  of the paper.

#### Reviewer E

- Q: Why do controller executions sometimes fail to manifest the bug?

+ A: Our type soundness guarantee only promises that our controllers
  "will realize _at least one_ trace consistent with $A$". The actors
  in a sytem may be nondeterministic, and may not thus may opt to act
  in ways that (while consistent with their PATs) do not induce the
  desired trace. Indeed, this is the case with the EspressoMachine
  benchmark, which has actors that can non-deterministically fail
  (lines 873-875).  Since our controllers use assertions to check
  whether an actor behaved in a way that could trigger a violation,
  Closeau reports a runtime failure in these cases and tries again.

- Q: Why LTL$_f$?

+ A: Indeed, PATs use SFAs "under the hood" and could in principle
  accept any frontend language (e.g., symbolic regex) that can be
  compiled into SFAs. Accordingly, our abstract traces can actually be
  thought of as a symbolic regex without a _top-level_ union:

  $\Pi ::= \langle\mathbf{op}\ \overline{x} ~|~ \phi\rangle ~|~ \Pi \cdot \Pi ~|~ A^*$.

  This is actually how we normalize SFAs into a finite set of abstract
  traces, with the normalization process preserving Kleene star
  instead of unrolling it. Our current presentation attempted to mimic
  this idea in the less expressive setting of LTL$_f$, in order to
  simplify the presentation, but we will be more explicit about the
  underlying SFA representation and the normalization procedure in the
  revision.  We will clarify our description on this issue and provide
  a correctness proof of normalization in the next iteration of the
  paper.

- Q: Can Closseau test liveness properties?

+ A: Our paper uses the informal definition of a "liveness" property
  as "something good will eventually happen." Since we only consider
  finite traces, this means we can only check that something good will
  eventually happen after a finite number of states, and not, e.g.,
  that something good will happen infinitely often. We will either be
  precise about what we mean by liveness or drop the claim altogether
  in subsequent versions of the paper.

- Q: Is it possible to test properties such as sequential consistency,
  linearizability, and deadlock freedom in Closeau?

+ A: It is indeed possible to capture these properties: the attached
  file includes examples of properties involving the need to deal with
  "multiple traces", like sequential consistency and deadlock freedom,
  as well as explanations of the PATs in our benchmarks (e.g., 2PC and
  RingLeaderElection).  The key insight is that the same logical
  operation can trigger multiple events, spawned from different actors
  with different local views. The global property can then specify
  whether these events are consistent or not.  Similar reasoning can
  be used to specify deadlocks; please see the attached file for
  details.

- Q: Is a controller DSL anything more than a single trace with some
  constraints?

+ A: Controller programs are distinguished from "a single trace
  together with some assumption(s) and assertion(s)" in two important
  respects: First, controller DSLs can use local variables to store
  the contents of received messages (akin to register automata). In
  our case study (lines 961-965), for example, the synthesized
  controller requests a transaction id `tid` from the database that is
  used in future messages, something that is not possible without
  local variables. Second, our DSL's nondeterministic choice operator
  `⊕`, allows a controller to comprise multiple different abstract
  traces, which can be chosen between during execution.

- Q: How does Clouseau compare to a state-of-the-art baseline?

+ A: We argue that our comparison with P constitues such a baseline,
  as P is a state-of-the-art tool that has been used to validate
  realistic distributed models at major cloud vendors such as Amazon
  in recent years.

- Q: Why not just use model checking?

+ A: There are (at least) three main challenges to applying model
  checking to the sorts of open distributed systems we target. First,
  these systems must be completed by providing a model of the unknown
  components (e.g., the client). More importantly, because our PAT
  specifications _approximate_ the behavior of the underlying actors--
  any violations found by model checking these specifications would
  still have to be validated on the underlying P model of the
  system. Finally, the state space of these systems is enormous-- to
  fully explore the traces would require us to engineer state (and
  path) equivalence checkers, frame rules, and other mechanisms to
  minimize redundant and uninteresting exploration.  For these
  reasons, we choose to trade off the inherent engineering complexity
  that would be required to build an effective model-checking
  implementation for a potentially incomplete search through the
  space, driven by a controller.
