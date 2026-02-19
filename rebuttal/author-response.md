

## Overview

We thank the reviewers for their detailed comments and suggestions.

We begin by clarifying the concerns shared by all reviewers, namely, the user effort required to write high-quality uHat specifications. We then present a detailed changelist, and conclude with detailed responses to the questions raised by individual reviewers.

## Shared Concern: The Quality Sensitivity of uHat Specifications and Corresponding User Effort

As pointed out by R.A, `the effectiveness of our approach depends on the quality of  manually-written uHats for effectful operators... on the other hand, the SOTA PBT systems the evaluation  compares against also presumably suffer from the same issue`. In general, in order to bias test exploration toward desirable cases within a huge search space, both our approach and existing methods require test developers to have their knowledge about the SUT reflected in the structure of test generators.  Specifically, this not only includes  `obvious functional correctness properties of the operations` (as mentioned by R.A), but also search bias strategies that guide the test generator to focus on interesting configurations.  uHATs allow the formal expression of these insights and inform an automated synthesis procedure from them, unlike existing systems which directly bake these properties into the implementation (and which must  therefore 'manually-craft and tune generation strategies' (R.A)).  We revisit the three motivating examples in Section 2 to illustrate these points of difference and also show weaker versions of uHats in these examples to explain the corresponding outcomes in Clouseau.

### Example 1: Atomicity

The specification of $\textbf{readRsp}$ on line 198 encodes two properties of the SUT needed to build an effective test generator for this application: (1) basic correctness: a read response requires a previous read request with the same tag $\iota$ and a previous write operation; (2) read atomicity: the read result from the client side must be exactly the same as the last write on the server side _at the time the read response is received_. Note that the first constraint makes no assumption about what the read value should be, since it is potentially uncertain in a concurrent setting.

A weaker specification that encodes only the first (and fails to capture the second) would be:

$\textbf{readRsp}: [\bullet^* \cdot \langle \textbf{write}\;v \rangle \cdot \bullet^* \cdot \langle \textbf{readReq}\;\iota \rangle \cdot \bullet^* ]\{\nu{:}\texttt{int}~|~\nu = v\}^u[\langle \textbf{readRsp}\;\iota\;v \rangle]$

This specification only requires that there exists a written value $v$ before the read request, and not that the value returned by a read response be the _last_ written value before the corresponding request.   Given this spec, this generator is among those that would be synthesized by Clouseau:

$\texttt{let\;x\;=\;int\_gen\;()\;in}\;\textbf{write}\;\texttt{x\;in}$
$\texttt{let\;y\;=\;int\_gen\;()\;in}\;\textbf{write}\;\texttt{y\;in}$
$\texttt{let\;\_\;=}\;\textbf{readReq}\texttt{\;in\;let\;z\;=}\;\textbf{readResp}\;\texttt{i1\;in}$
$\texttt{assert\;(z\;==\;x || z == y) }$

It initiates two writes followed by a read, and asserts that the read value must be one of the two previously written ones. Because this weaker specification fails to capture the core property of read atomicity, its derived generators explore obviously safe cases, and would fail to detect read atomicity violations. Note that the generator shown on lines 220–225 can also be synthesized from this weaker specification.  Thus, an imprecise specification simply means that our synthesis algorithm has less guidance on the structure of the generators it produces.  In the limit, the weakest specification for a given problem results in synthesized generators simply performing random test exploration. 

### Example 2: Information-Flow Control

As mentioned on line 235, the IFC example aims to test end-to-end noninterference (EENI): if two inputs are indistinguishable at the low security level, their execution results should be as well. The specifications of $\textbf{push}$ and $\textbf{store}$ on line 266 also encode two kinds of salient properties: (1) basic safety: the `store` operation requires two parameters, so the stack should contain at least two values; (2) noninterference of input: two input programs should be indistinguishable at the low security level; for example, $\textbf{push}(\texttt{L}, 1)$ and $\textbf{push}(\texttt{L}, 2)$ are distinguishable, so they are not valid test inputs as they are inconsistent with the EENI setting.  Additionally, the test generator should bias integer generation towards valid addresses (e.g., small non-negative integers) to reduce errors caused by out-of-range memory accesses, that are irrelevant to discovering non-interference violations.   These properties are described in detail in the original paper [20].

A weaker specification for $\textbf{push}$ that omits property (2) might be:

$\textbf{push}: [\bullet^* ]\texttt{unit}[\langle \textbf{push} \rangle]$

In contrast to the specification at L266, this spec will cause the synthesized generator to also generate operation like $\textbf{push}(\texttt{L}, \langle 1, 2 \rangle)$, which have two different values at the low security level. Such a pair (i.e., $\textbf{push}(\texttt{L}, 1)$ and $\textbf{push}(\texttt{L}, 2)$) cannot be treated as valid input for EENI testing as mentioned above. Thus, many generated test cases will be rejected immediately, and would not even trigger the execution of the IFC machine.

On the other hand, a weaker specification of $\textbf{store}$ might omit the bias on address values (which is captured in the original spec at L267 via the "isAddr" predicate):

$\textbf{store}: [\bullet^* \cdot \langle \textbf{push}\;\mathit{lvl\;x_1\;y_2} \rangle \cdot (\bullet \setminus \langle \textbf{store} \rangle )^* \cdot \langle \textbf{push}\;\mathit{lvl\;x_2\;y_2} \rangle ]\texttt{unit}[\langle \textbf{store} \rangle]$

This change will also cause the synthesized generator to produce invalid addresses that trigger out-of-range memory errors, greatly reducing test efficiency.

### Example 3: STLC Terms

We clarify that the SUT in this example is an STLC interpreter, so the synthesized test generator should produce a family of _serialized_ STLC terms, which are sequences of string tokens. Thus, there is only one effect operation, namely $\textbf{token} : \texttt{String}\to\texttt{unit}$. For example, an identity function $(\lambda x.[0])$ in the STLC language can be expressed as the following trace:

$\textbf{token}(``(\lambda \texttt{int}."); \textbf{token}(``[0]"); \textbf{token}(``)")$

which is divided into three `token` events with different string parameters: abstraction start ($``(\lambda \texttt{int}."$), variable reference ($``[0]"$), and abstraction end ($``)"$). The specification shown on line 307 provides the uHat for the case of "abstraction end," which requires that the tokens $``(\lambda \texttt{int}."$ and $``)"$ appear in pairs. As mentioned on line 341, more details of this example are provided in Section B of the supplementary material.

Two properties of sensible STLC terms that facilitate test exploration are that the token sequence: (1)  is well-formed - e.g, abstraction needs to be closed after open, terms are closed, etc. to avoid terms being rejected by the STLC parser; (2) indicates a well-typed STLC term to avoid it being rejected by the STLC type checker.  The specification on line 307 encodes only the first property, while the more precise specification that encodes both is shown in Figure 8 of the supplementary material. The weaker specification gives the synthesized test generator freedom to produce well-formed but ill-typed STLC terms (e.g., $3\;3$).  To go beyond these properties and handle more sophisticated notations like de Brujin indices as described in the paper, requires additional constraints on the specification, manifested in the specification as ghost variables that track abstraction depth.

### Summary

The motivating examples shown above demonstrate that both our approach and other test frameworks require test engineers to reflect desired properties and search biases in formulating the design and implementation of the test generator.  Clouseau allows this to be expressed formally and compositionally using uHATs with synthesized generators guaranteed to be adhere to specification constraints.   Weak specifications simply result in less effective generators, a scenario no different than faced by PBT developers today.


## Summary of Proposed Changes

Concretely, we propose to implement the following changes in the revision, in order to clarify the issues discussed above and to address the specific criticisms posed by the reviewers below:

- We will integrate the discussion about the quality sensitivity and user effort related to uHat specifications above in the revision (All Reviewers).

- We will clarify the explanation of our motivating examples in Section 2 (Reviewer A).

- To show the impact of uHat quality, we will additionally evaluate our tool with low-quality uHats for all benchmarks in our evaluation. These new uHats will encode weaker properties, similar to the examples above (Reviewer B).

- We will restructure the list of contributions to exclude the evaluation study as our fourth contribution (Reviewer A).

- We will fix all typos and spacing problems identified by the reviewers.

## Responses to Specific Questions

#### Reviewer A

- Q: How "obvious" are these uHats?

- A: Some of the properties expected to encoded using uHats are natural (e.g., "functional correctness properties of the operations" as you mentioned); others require a deeper understanding of the SUT and the kinds of search biases the generator should be equipped with (e.g., the pushed value should be a valid address in the IFC example mentioned above). 

- Q: Could they be written by a lightly-trained average developer?

- A: As anecdotal evidence in the affirmative, the uHats for the $\texttt{HashTable}$ and $\texttt{Courseware}$ benchmarks in Figure 1 were written by an undergraduate student, and the $\texttt{Smallbank}$ and $\texttt{Twitter}$ benchmarks by two first-year PhD students. All of them were new to our uHat specification language and had no knowledge of our synthesis algorithm. However, they were still able to encode their knowledge about the SUT as uHats to successfully test these benchmarks.

#### Reviewer B

- Q: What happens when a uHat used as a spec for synthesizing a generator is wrong?

- A: If the wrong specifications are conflicting, our synthesizer will not find a solution, as you mentioned. If the specifications are too general, the synthesizer will synthesize useless generators (note that our synthesizer will synthesize a family of unioned generators), which reduces the efficiency of test exploration.  If the specifications are too strong, relevant/interesting executions will not be explored.

#### Reviewer C

- Q: The paper relies upon angelic execution and no unreachable traces.

- A: You are right; the SUT will not always behave as we expect (e.g., a SUT that can potentially violate read atomicity may still work correctly most of the time). In this case, we simply rerun the test. 

- Q: What happens when a specification is wrong or certain histories are unreachable?

- A: If the wrong specifications are conflicting, our synthesizer just finds no solution. If the wrong specifications are too general (as in the examples discussed in the shared concern), the synthesizer will synthesize useless generators (note that our synthesizer will produce a family of unioned generators), thereby reducing the efficiency of test exploration. The problem of "unreachable histories" can happen for uHats of effectful operations, but it won't occur for the synthesized test generator. Note that our "global property" is indeed global, so the synthesized type-safe generator does not depend on any history trace, as guaranteed by our type soundness theorem (Corollary 3.5). In other words, the synthesized generator will generate "dependent histories" (traces) by itself for the operators it uses.

- Q: When a generator fails to be synthesized, what feedback is provided? What is the debugging process like?

- A: As shown in Figure 6, our algorithm consists of a refinement loop that maintains a set of candidate generators. When synthesis fails, we can provide all previous sets of candidate generators at each refinement iteration.  We agree that a natural next step is integrating a refinement and debugging phase as part of the synthesizer and test execution pipeline.

#### Reviewer D

+ Q: In Figure 2, what is the last operation when defining traces α?

- A: The ${+}{+}$ symbol indicates the standard concatenation of two lists.

+ Q: Is the full uHat type system required for synthesis correctness, or could synthesis operate purely at the SRE level?

- A: The synthesized generators are type-safe by construction, as guaranteed by Theorem 4.4. Thus, a standalone uHat type system is not required for synthesis correctness.

- Q: Can the approach handle concurrency interleavings beyond sequential traces (e.g., partial orders)?

- A: In our setting, we don't consider partial order reduction. For example, assume there are three concurrent events $e_1$, $e_2$, and $e_3$. A bug may require event $e_1$ to happen before both $e_2$ and $e_3$, while the order of $e_2$ and $e_3$ is not defined. Instead of unifying them as a single case, $\texttt{Clouseau}$ will treat $e_1;e_2;e_3$ and $e_1;e_3;e_2$ as two different buggy traces. Any one of them can serve as evidence of a bug.
