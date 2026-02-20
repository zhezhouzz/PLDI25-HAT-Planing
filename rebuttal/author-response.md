

## Overview

We thank the reviewers for their detailed comments and suggestions.

We begin by clarifying the concerns shared by all reviewers, namely, the user effort required to write high-quality uHat specifications. We then present a detailed changelist, and conclude with detailed responses to the questions raised by individual reviewers.

## Shared Concern: The Quality Sensitivity of uHAT-based Specifications and Corresponding User Effort

As pointed out by Reviewer A, `the effectiveness of our approach depends on the quality of  manually-written uHats for effectful operators... on the other hand, the SOTA PBT systems the evaluation compares against also presumably suffer from the same issue`. In general, in order to bias test exploration toward desirable cases within a huge search space, both our approach and existing methods require test developers to embed their knowledge about the SUT in the structure of test generators.  This not only includes  `obvious functional correctness properties of the operations` (Reviewer A), but also domain knowledge that can help a test generator focus on interesting configurations.  uHATs enable test developers to formally express these insights in a way that informs our automated synthesis procedure, without need to `manually craft and tune generation strategies` directly into the implementation of test generator (Reviewer A).  To illustrate these differences, we will first revisit the three motivating examples from Section 2 and then discuss how weaker versions of the uHATs used in these examples would impact outcomes in Clouseau.

### Example 1: Atomicity

The specification of **readRsp** on line 198 encodes two properties of the SUT needed to build an effective test generator for this application:

1. **basic correctness**: a read response requires a previous read request with the same tag $\iota$ and a previous write operation;

2. **read atomicity**: the read result from the client side must be exactly the same as the last write on the server side _at the time the read response is received_. Note that the first constraint makes no assumption about what the read value should be, since it is potentially uncertain in this concurrent setting.

A weaker specification that encodes only the first (and fails to capture the second) would be:

$\textbf{readRsp}: [\bullet^* \cdot \langle \textbf{write}\;v \rangle \cdot \bullet^* \cdot \langle \textbf{readReq}\;\iota \rangle \cdot \bullet^* ]\{\nu{:}\texttt{int}~|~\nu = v\}^u[\langle \textbf{readRsp}\;\iota\;v \rangle]$

This specification only requires that there is a value $v$ written before the read request: the value returned by a read response need not be the _last_ value written before the corresponding request.  Given this spec, this generator is among those that would be synthesized by Clouseau:

$\texttt{let\;x\;=\;int\_gen\;()\;in}\;\textbf{write}\;\texttt{x\;in}$
$\texttt{let\;y\;=\;int\_gen\;()\;in}\;\textbf{write}\;\texttt{y\;in}$
$\texttt{let\;i\;=}\;\textbf{readReq}\texttt{\;in\;let\;z\;=}\;\textbf{readResp}\;\texttt{i\;in}$
$\texttt{assert\;(z\;==\;x || z\;==\;y) }$

It initiates two writes followed by a read, and asserts that the read value must be one of the two previously written ones.
Notably, although this program is type-safe according to the weaker uHAT, it is not allowed by the original specification, which requires the read value to be the last one.
Because this weaker specification fails to capture the core property of read atomicity, it admits generators are allowed to explore obviously safe cases that would fail to detect read atomicity violations. At the same time, the generator shown on lines 220–225 can also be derived from this weaker specification.  Thus, an imprecise specification simply means that our synthesis algorithm has less guidance on the structure of the generators it produces.  In the limit, a specification that places no constraints on the operations of the system under test results in synthesized generators that simply perform random test exploration.

### Example 2: Information-Flow Control

As mentioned on line 235, the IFC example aims to test end-to-end noninterference (EENI): if two inputs are indistinguishable at the low security level, their execution results should be as well. The specifications of **push** and **store** on line 266 also encode two kinds of salient properties:
1. **basic safety**: the `store` operation requires two parameters, so the stack should contain at least two values;
2. **noninterference of input**: two input programs should be indistinguishable at the low security level; for example, $\textbf{push}(\texttt{L}, 1)$ and $\textbf{push}(\texttt{L}, 2)$ are distinguishable, so they are not valid test inputs as they are inconsistent with the EENI setting.

Additionally, the test generator should bias integer generation towards valid addresses (e.g., small non-negative integers) to reduce errors caused by out-of-range memory accesses, that are irrelevant to discovering non-interference violations.  These properties were `critically important` to how the authors of [20] _manually_ crafted the input generators used to test information-flow abstract machine, and are described in more detail in that original paper.

A weaker specification for $\textbf{push}$ that omits the second property might be:

$\textbf{push}: [\bullet^* ]\texttt{unit}[\langle \textbf{push} \rangle]$

In contrast to the specification at L266, this specification allows the synthesized generator to also generate operations like $\textbf{push}(\texttt{L}, \langle 1, 2 \rangle)$, which have two different values at the low security level. Such a pair (i.e., $\textbf{push}(\texttt{L}, 1)$ and $\textbf{push}(\texttt{L}, 2)$) cannot be treated as valid input for EENI testing as mentioned above. Thus, many generated test cases will be rejected immediately, without even triggering the execution of the IFC machine.

On the other hand, a weaker specification of $\textbf{store}$ might omit the bias on address values (which is captured in the original spec at L267 via the **isAddr** predicate):

$\textbf{store}: [\bullet^* \cdot \langle \textbf{push}\;\mathit{lvl\;x_1\;y_2} \rangle \cdot (\bullet \setminus \langle \textbf{store} \rangle )^* \cdot \langle \textbf{push}\;\mathit{lvl\;x_2\;y_2} \rangle ]\texttt{unit}[\langle \textbf{store} \rangle]$

This change causes the synthesized generator to produce invalid addresses that trigger out-of-range memory errors, greatly reducing test efficiency.

### Example 3: STLC Terms

We clarify that the SUT in this example is an STLC interpreter, and the synthesized test generator produces a family of _serialized_ STLC terms, i.e., sequences of string tokens. Thus, there is only one effectful operation, namely **token**$: \texttt{String}\to\texttt{unit}$. For example, the identity function $(\lambda x.[0])$ can be expressed as the following trace:

$\textbf{token}(``(\lambda \texttt{int}."); \textbf{token}(``[0]"); \textbf{token}(``)")$

This trace is divided into three `token` events with different string parameters: abstraction start ($``(\lambda \texttt{int}."$), variable reference ($``[0]"$), and abstraction end ($``)"$). The specification shown on line 307 provides the uHAT for the case of "abstraction end," which requires that the tokens $``(\lambda \texttt{int}."$ and $``)"$ appear in pairs. As mentioned on line 341, more details of this example are provided in Section B of the supplementary material.

Two properties of sensible STLC terms that facilitate test exploration are that the token sequence corresponds to a term that is:

1. **well-formed**: an abstraction needs to be closed after it is opened, terms are closed, etc. to avoid terms that would be rejected by the STLC parser;
2. **well-typed**: to avoid it being rejected by the STLC type checker.

The specification on line 307 encodes only the first property, while the more precise specification that encodes both is shown in Figure 8 of the supplementary material. The weaker specification gives the synthesized test generator freedom to produce well-formed but ill-typed STLC terms (e.g., $3\;3$).  To go beyond these properties and handle more sophisticated notations like de Brujin indices as described in the paper, requires additional constraints on the specification, manifested in the specification as ghost variables that track abstraction depth (as discussed on lines 306 - 314).

### Summary

Taken together, these three examples demonstrate that, as in prior PBT frameworks [20], the effectiveness of our approach depends on test engineers' insights about the desirable properties and search biases of test generators.  In contrast to prior work, Clouseau allows both of these to be expressed formally and compositionally using uHATs, and the synthesized generators are both informed by and guaranteed to adhere to this knowledge. Thus, weak specifications simply result in less effective generators, a scenario no different than the one faced by PBT developers today.

## Summary of Proposed Changes

Concretely, we propose to implement the following changes in the revision, in order to clarify the issues discussed above and to address the specific criticisms posed by the reviewers below:

- We will integrate a qualitative discussion about Closseau's sensitivity to the quality of uHAT specifications, and the corresponding user effort required to write such specifications (All Reviewers).

- We will clarify the explanation of our motivating examples in Section 2 (Reviewer A).

- To empirically evaluate the impact of uHAT quality, we will additionally evaluate Clousseau using low-quality uHATs for all benchmarks in our evaluation. These new uHATs will encode weaker properties, similar to the examples above. We will include the complete set of uHATs used in our evaluation in the updated supplemental material. (Reviewer B)

- We will restructure the list of contributions to exclude the evaluation study as our fourth contribution (Reviewer A).

- We will fix all typos and formatting problems identified by the reviewers.

## Responses to Specific Questions

#### Reviewer A

- Q: How "obvious" are these uHATs?

- A: Some of the properties expected to encoded using uHATs are natural (e.g., the sorts of `functional correctness properties of the operations` you mentioned); others require a deeper understanding of the SUT and the kinds of search biases the generator should use (e.g., the pushed value should be a valid address in the IFC example mentioned above).

- Q: Could they be written by a lightly-trained average developer?

- A: As anecdotal evidence in the affirmative, the uHATs for the $\texttt{HashTable}$ and $\texttt{Courseware}$ benchmarks in Figure 1 were written by an undergraduate student, and those for $\texttt{Smallbank}$ and $\texttt{Twitter}$ by two first-year PhD students. All three students were new to our uHAT specification language and had no knowledge of our synthesis algorithm. After a couple of hands-on training sessions, each was able to independently encode their knowledge about the SUT as uHATs, requiring only a few person-hours to complete all the benchmarks.

#### Reviewer B

- Q: What happens when a uHAT used as a spec for synthesizing a generator is wrong?

- A: There are three kinds of incorrect specifications:

1. When given conflicting specifications, Closseau will not find a solution, as you suggest.
2. If the specifications are too general, Closseau will synthesize useless generators (note that our synthesizer will synthesize a family of unioned generators), which reduces the efficiency of test exploration.
3. If the specifications are too strong, relevant and interesting executions will not be explored.

#### Reviewer C

- Q: The paper relies upon angelic execution and no unreachable traces.

- A: You are right; the SUT will not always behave as we expect (e.g., a SUT that can potentially violate read atomicity may still work correctly most of the time). When this happens, our test runner simply tries again the test.

- Q: What happens when a specification is wrong or certain histories are unreachable?

- A: If the wrong specifications are conflicting, our synthesizer just finds no solution. If the wrong specifications are too general (as in the examples discussed in the shared concern), the synthesizer will synthesize useless generators (note that our synthesizer will produce a family of unioned generators), thereby reducing the efficiency of test exploration. The problem of "unreachable histories" can happen for uHATs of effectful operations, but it won't occur for the synthesized test generator. Note that our "global property" is indeed global, so the synthesized type-safe generator does not depend on any history trace, as guaranteed by our type soundness theorem (Corollary 3.5). In other words, the synthesized generator will generate "dependent histories" (traces) by itself for the operators it uses.

- Q: When a generator fails to be synthesized, what feedback is provided? What is the debugging process like?

- A: As shown in Figure 6, our algorithm consists of a refinement loop that maintains a set of candidate generators. When synthesis fails, we provide all previous sets of candidate generators at each refinement iteration.  As the reviewer suggests, a natural next step is integrating a refinement and debugging phase as part of the synthesizer and test execution pipeline.

#### Reviewer D

+ Q: In Figure 2, what is the last operation when defining traces α?

- A: The ${+}{+}$ symbol indicates the standard concatenation of two lists.

+ Q: Is the full uHAT type system required for synthesis correctness, or could synthesis operate purely at the SRE level?

- A: The synthesized generators are type-safe by construction, as guaranteed by Theorem 4.4. Thus, a standalone uHAT type checker is not required for synthesis correctness.

- Q: Can the approach handle concurrency interleavings beyond sequential traces (e.g., partial orders)?

- A: In our setting, we don't consider partial order reduction. For example, assume there are three concurrent events $e_1$, $e_2$, and $e_3$. A bug may require event $e_1$ to happen before both $e_2$ and $e_3$, while the order of $e_2$ and $e_3$ is not defined. Instead of unifying them as a single case, $\texttt{Clouseau}$ will treat $e_1;e_2;e_3$ and $e_1;e_3;e_2$ as two different buggy traces. Any one of them can serve as evidence of a bug.
