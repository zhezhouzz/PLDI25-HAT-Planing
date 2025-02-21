## Overview

We thank the reviewers for their detailed comments and suggestions.


We begin by clarifying concerns that were shared by multiple
reviewers. Specifically, we: (a) characterize the expressivity and limitations of our
PAT-based type abstraction; (b) relateg the novelty of our
methodology to other PBT and model-checking techniques; and (c)
justify our use of PATs as being particularly well-suited to
property-based testing of distributed system models.

_BD: We do not specifically target the last point._

We then present a detailed changelist that proposes to (a) better
clarify our methodology and its applicability to distributed systems
testing; (b) incorporate additional related work as suggested by the
reviewers; and (c) elaborate and expand our evaluation by providing
additional experimental details as well as additional experiments
demonstrating that our technique applies to test well-understood
consistency and network delivery properties.

Finally, we provide detailed responses to the questions raised by
individual reviewers.

## Shared Concerns

### Expressivity

Beyond the ability to express temporal modalities on events, the PAT
specification language allows the use of ghost variables to capture
data dependencies among specification events, resulting in a level of
expressive power akin to data/register automata that are equipped with
memory (Reviewer E), while still being amenable to efficient SMT
encodings. This additional power allows us to capture fine-grained
dependencies between the actors in the SUT, while at the same time not
overly constraining the behavior of the complete system. These
behaviors are delegated to the synthesized controllers, allowing us to
capture and test for wide range of consistency, (e.g., XXX) and
network delivery properties (e.g., YYY) relevant to distributed
systems (Reviewers E); we elaborate on this point in the individual
responses, and provide detailed examples of these in the attached
file.

Our PAT-based specifications inherit the limitations of the SFAs that
they compile into. As one example, SFAs (even when equipped with ghost
variables) cannot express counting properties (e.g., an event
appearing twice as often as another event), as this exceeds the
expressive power of regular languages. Additionally, since we only
consider finite traces, we cannot express properties involving
infinite traces (e.g., an event appearing infinitely many times in the
future). For properties that are amenable to PBT-style automated
testing, however, our SFA representations appears to be particularly
well-suited and effective.

### Model Checking Open Distributed Systems

There are (at least) three main challenges to applying model checking
the sorts of open distributed systems we target. First, these systems
must be completed by providing a model of the unknown components. More
importantly, our PAT specifications approximate the behavior of the
underlying actors-- any violations found by model checking these
specifications would have to be validated on the underlying P
implementation of the system. Finally, the state space of these
systems is enormous-- to fully explore the traces would require us to
engineer state (and path) equivalence checkers, frame rules, and other
mechanisms to minimize redundant and uninteresting exploration. This
is precisely why P's existing model checker opts to trade off
engineering complexity for a potentially incomplete search through the
space, driven by a controller. The key insight of this work is that we
can use partial specifications of actors to synthesize controllers
that explore the space of executions in a targeted, property-directed.
As the reviewers note, these controllers are typically incomplete: our
algorithm is only guaranteed to produce a set of controllers that
capture a subset of the feasible executions consistent with provided
specifications (lines 627-629, 776-778). Our experimental evidence
supports our contention that this tradeoff works well in practice.

### Property-Based Testing of Distributed Systems

There are two distinguishing features of our framework whose
combination (we believe) separate it from other proposed PBT-style
techniques for distributed systems. First, we target open systems, in
which external clients can inject messages into the SUT. Second, in
contrast to other PBT-style systems that treat the SUT as a black box,
the (local) PAT specifications of the actors provide visibility into
the system in terms of which (global) traces are feasible. This
information enables us to be significantly more targeted in our search
for a violating execution, allowing us to synthesize schedules
_tailored to the property of interest_--- history automata induce
"precondition" constraints on allowed behaviors that permit the
actor to generate a new event, while prophecy automata induce
"postcondition" constraints that regulate future actions by the
actor. The capability of dividing symbolic traces into a history and a
future is especially valuable in the concurrent/asynchronous setting
we target.

## Summary of Proposed Changes
Concretely, we propose the implement the following changes in the
revision, in order to clarify the issues discussed above and the
specific criticisms posed by the reviewers addressed below:

-  We will clarify that PATs are indeed implemented using SFAs,
  and support both symbolic LTL$_f$ and symbolic regex as frontend
  languages (Reviewers A, B, and E). We will also clarify the
  definition of abstract traces and provide a correctness proof of
  normalization (Reviewer E).

- To provide a better interpretation of PATs, we will include
  the type denotation from our supplemental material in the
  revision (Reviewer A).

- To demonstrate that PATs enable a high degree of automation,
  we will highlight that the qualifiers in PAT are quantifier-free,
  which guarantees that the VCs are in EPR (Reviewer C). We will also
  provide additional examples of VCs derived from auxiliary type
  judgments (Reviewer A).

- We will extend our discussion in the evaluation section to
  provide additional details on the testing difficulty of the sorts of
  properties in benchmarks (Reviewer A), elaborate on the
  experimental setup of the second baseline "P+M" (Reviewer A), and
  explain how bugs are injected into our benchmarks (Reviewer B). We
  will also report the average execution time (Reviewer A) and set a
  2-hour time bound (Reviewer B) for the P baseline.

- We will incorporate all the suggestions made by the reviewers to
  expand our discussion of related work, better contextualizing our
  contributions with respect to other approaches to validating
  distributed systems, including PBT-style approaches (Reviewer D),
  model checking (Reviewer E), and verification (Reviewers B and E).
  Thank you for bringing many of these works to our attention!

- We will fix all typos and spacing problems identified by the
  reviewers.

## Responses to Specific Questions

#### Reviewer A

1. Behavior of `DeriveTerm`. The reviewer correctly notes that
`DeriveTerm` removes any remaining $$\globalA A$$ when building a
controller program from an abstract trace. Intuitively, the violation
encoded in the abstract trace is independent of any events in
$$\globalA A$$, eliding them allows Clouseau to safely focus on the
events that are core to the violation.

2. SMT solver usage and VCs.


The reviewer is correct; solvers are used
in SFA inclusion checks in \textsc{WfHAF} and \textsc{SubHAF}.
Following the standard minterm-based SFA algorithm [12], the VCs are
proof obligations that all qualifiers of symbolic events (i.e., $\phi$
in $\msgB{op}{\overline{x}}{\phi}$) are satisfiable. We will add VC
examples in the revision of our paper.

- Execution and assume/assert. The reviewer is correct; the
execution needs to ensure that assertions hold, and we do use an SMT
solver here.

- Data sensitivity. Our properties are data-dependent, so bugs are
also data-sensitive, but not in the sense that "a bug is very
sensitive to particular values." For example, in the motivating
example, we need at least two $\eff{write}$ operations on the same key
with different data (as in $A'_\Code{violateRYW}$ on line 357) to lead
to a potential inconsistent situation. There are no specific
constraints about the values of the key or data here.

- More information about "P+M". The "M" is provided from the source of
benchmarks, which also contains the human-written "controller" to
close the open system. Reviewer is correct that "the best such M would
be equivalent to one of your synthesized controllers," but most of the
time, M is not, as it is not aware of the property to test.

- SubHAF. The reviewer is correct; it is a typo, and the version in
the supplemental material is correct. We will include the type
denotation from our supplemental material in the revision.

- Abstract traces. The reviewer is correct; $A \untilA B$ should be
normalized as $\globalA A \seqA B$ (no negation). This is a typo. The
meaning of $\globalA \evparenth{\phi}\seqA\Pi$ is exactly as the
reviewer states. \end{enumerate}

#### Reviewer B
- Bug injection. The bugs are injected by deleting control flow from
the original distributed models directly or by simulating a weakly
consistent model (e.g., returning some value written before instead of
the last written one).

- LTL$_f$ vs. (symbolic) regex. We clarify that PAT is indeed based on
SFAs, and we can accept any front-end language (e.g., symbolic regex,
as suggested by reviewers) that can be compiled into SFAs.
\end{enumerate} We will clarify all these in the paper's revision.

#### Reviewer C
- Guarantee constraints are in EPR. We require the qualifiers to be
quantifier-free formulas to guarantee that the derived VCs are in EPR.
Following the standard minterm-based SFA algorithm [12], the VCs are
proof obligations that all qualifiers of symbolic events (i.e., $\phi$
in $\msgB{op}{\overline{x}}{\phi}$) are satisfiable under the type
context. The type context is interpreted as prefix universally
quantified substitutions (lines $565$ and $580$), which guarantees
that the derived VCs are in EPR. We will highlight the constraints on
qualifiers in the revision.

- Incomplete and getting stuck. The reviewer is correct that our
approach is not complete. We would like to clarify that our algorithm
is based on backtracking (line 628) and thus will not get stuck when
"picking the wrong values or choices." In our motivating example, we
show how we shift to another choice when picking the wrong one (lines
753-755). \end{enumerate}

#### Reviewer D

Thank you for pointing out the spacing issues in our submission. We
will definitely fix them in the revision of our paper!

#### Reviewer E

- Guarantee of witnessing a bug. As mentioned by the reviewer, Theorem
4.5 guarantees that the synthesized controller is type-safe, which
provides the bug witness guarantee. Precisely, this guarantee is
defined as type soundness (Theorem 3.7), which states "will realize at
least one trace consistent with $A$." When the execution is
non-deterministic (i.e., the system may randomly pick different
executions), we only guarantee that there \emph{exists} one execution
that triggers the bug. This is also consistent with the runtime
failures observed by reviewer in some benchmarks (e.g.,
EspressoMachine), as explained in lines 873-876, whose handlers
(actors) can non-deterministically fail. The reviewer is correct that
runtime failures come from assertion violations, which indicate that
the controller's view conflicts with the handlers' view.

- Abstract trace and normalization. We clarify that {\sf Clouseau} is
indeed based on SFAs, and it can accept any frontend language (e.g.,
symbolic regex) that can be compiled into SFAs. Our abstract trace can
be treated as a symbolic regex without a \emph{top-level} union
$\Pi ::= \msgB{op}{\overline{x}}{\phi} ~|~ \Pi \seqA \Pi ~|~ A^*$.
Then, we can normalize each SFA into a finite set of abstract traces,
as the normalization process preserves the star term instead of
unfolding it. The current presentation in our paper attempts to mimic
this simple idea in LTL$_f$, which has led to a lot of confusion. We
promise to clarify this and provide a correctness proof of
normalization in our revised paper.

- Liveness. The "liveness property" mentioned in our paper actually
refers to "eventually exists within a finite number of steps,"
following an informal interpretation of liveness: "something good will
eventually happen." We apologize for this misuse and promise to
clarify it in our paper revision.

- Expressivity. We would also like to highlight that PAT provides
constraints over each actor on its \emph{local} view, while the
controller has a \emph{global} view. This design ensures that the
trace in our approach is not just "one global trace of all events in
the system" (Reviewer E), but a merged view of all actors. There can
be multiple events for the same operation, coming from different
actors under different local views. The global property can then
specify whether these events are consistent or not. We provide PAT
examples of "multiple traces per thread" properties (e.g., sequential
consistency) and network behaviors expressed in this way, as well as a
detailed explanation of PAT in our benchmarks (e.g., 2PC and
RingLeaderElection) in the attached file of the author response.

- Using trace instead of DSL. The DSL is different from "traces
together with some assumption(s) and assertion(s)" because of the
local variables, which the controller can use to \emph{store} the
results from handlers (like register automata). In our case study
(lines 961-965), we highlight that our synthesized controller is
better than a random controller because it can request a transaction
id $\I{tid}$ from the database and use it in future messages. The DSL
cannot express this situation without local variables.

- Comparison with state-of-the-art baseline. We do compare with the P
language, which is indeed a state-of-the-art baseline that has
verified realistic distributed models from major cloud vendors in
recent years. The reviewer is correct that Mocket is a relevant tool;
however, we will not add this comparison in our plan due to the
limited revision period.
