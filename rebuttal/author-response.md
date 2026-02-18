## Overview

We thank the reviewers for their detailed comments and suggestions.

We begin by clarifying the concerns shared by all reviewers, namely, the user effort required to write high-quality uHat specifications. We then present a detailed changelist, and conclude with detailed responses to the questions raised by individual reviewers.

## Shared Concern: The Quality Sensitivity of uHat Specifications and Corresponding User Effort

As pointed out by Reviewer A, `the effectiveness of our appraoch depends on the quality of  manually-written uHats for effectful operators... on the other hand, the SOTA PBT systems the evaluation  compares against also presumably suffer from the same issue`. In general, in order to bias test exploration toward desirable cases within a huge search space, both our approach and existing methods require test developers to provide their knowledge and understanding about the SUT. Specifically, this knowledge not only includes `obvious functional correctness properties of the operations` (as mentioned by Reviewer A), but also search bias strategies that guide the test generator to focus on interesting domains in the user’s opinion, rather than all valid cases. We revisit the three motivating examples in Section 2 to illustrate how our approach and other frameworks encode these knowledge — ours in a formal and compositional way, and others using `manually-crafted and tuned  generation strategies targeted at discovering bugs` (as mentioned by Reviewer A). We also show weaker versions of uHats in these examples and explain the corresponding outcomes of our tool.

### Example 1: Atomicity

The specification of $\textbf{readRsp}$ on line 198 encodes two kinds of knowledge: (1) basic correctness: a read response requires a previous read request with the same tag $\iota$ and a previous write operation; (2) read atomicity: the read result from the client side is exactly the same as the last write on the server side _at the time of the read response received_. Note that the first piece of knowledge makes no assumption about what the read value should be, since it is potentially uncertain in a concurrent setting.

One possible weaker specification encodes only the first:

$\textbf{readRsp}: [\bullet^* \cdot \langle \textbf{write}\;v_1 \rangle \cdot \bullet^* \cdot \langle \textbf{readReq}\;\iota \rangle \cdot \bullet^* ]\{\nu{:}\texttt{int}~|~\nu = v_2\}^u[\langle \textbf{readReq}\;\iota\;v_2 \rangle]$

This specification only requires that there exists a written value $v_2$ before the read request, and does not require the read value $v_1$ to match any write value. This weaker specification will allow more synthesized generators by our tool, e.g.,

$\texttt{let\;x\;=int\_gen\;()\;in}\;\textbf{write}\;\texttt{x\;in}$

$\texttt{let\;i1\;=}\textbf{readReq}\texttt{\;in\;let\;y1\;=}\;\textbf{readResp}\;\texttt{i1\;in}$

$\texttt{let\;i2\;=}\textbf{readReq}\texttt{\;in\;let\;y2\;=}\;\textbf{readResp}\;\texttt{i2\;in\;assert\;(x\;==\;y2)}$

This generator sends one write and two adjacent read requests, and includes assertions that treat the second read result being different from the written value as a bug (this situation is disallowed by the original uHat). This weaker specification is very likely inconsistent with the SUT; thus, these newly allowed generators are testing vacuously safe cases and cannot detect any bug. We also want to emphasize that the generator shown on lines 220–225 can also be allowed by the weaker specification. Thus, a low-quality specification means our synthesized generators lose the guidance of the second kind of knowledge and synthesize low-quality generators, which reduces the efficiency of our test exploration. The weakest specification will cause our tool to revert to considering all possible sequences of events, which is the same as naïve random test exploration.

In the P language, which is the one we compared in our evaluation, the user also encodes these two kinds of knowledge into their code. Their generators need to maintain a set of increasing (or unique) request ids $\iota$, and initialize the server with write operations. Additionally, the P language user must provide a "monitor" which observes the interaction between the generator and SUT to check the read atomicity property.

### Example 2: Information-Flow Control

As mentioned on line 235, the IFC example aims to test end-to-end noninterference (EENI): if two inputs are indistinguishable at the low security level, so too should their execution results be. The specifications of $\textbf{push}$ and $\textbf{store}$ on line 266 also encode three kinds of knowledge: (1) basic safety: the `store` operation requires two parameters, so the stack should contain at least two values; (2) noninterference of input: two input programs should be indistinguishable at the low security level; for example, $\textbf{push}(\texttt{L}, 1)$ and $\textbf{push}(\texttt{L}, 2)$ are distinguishable, so they are not valid test inputs as they are inconsistent with the EENI setting; (3) "smart integers" strategy [20]: in the original paper, Hritcu provides several test generation strategies in Section 4. The "smart integers" strategy tries to bias integer generation toward valid addresses (e.g., small non-negative integers) to reduce the number of errors caused by out-of-range memory that are independent of noninterference.

A weaker specification for $\textbf{push}$ omits the second kind of knowledge:

$\textbf{push}: [\bullet^* ]\texttt{unit}[\langle \textbf{push} \rangle]$

This change will cause the synthesized generator to also generate operation like $\textbf{push}(\texttt{L}, \langle 1, 2 \rangle)$, which have two different values at the low security level. Such a pair (i.e., $\textbf{push}(\texttt{L}, 1)$ and $\textbf{push}(\texttt{L}, 2)$) cannot be treated as valid input for EENI testing as mentioned above. Thus, many generated test cases will be rejected immediately, and cannot even trigger the execution of the IFC machine.

On the other hand, a weaker specification of $\textbf{store}$ might omit the third kind of knowledge:

$\textbf{store}: [\bullet^* \cdot \langle \textbf{push}\;\mathit{lvl\;x_1\;y_2} \rangle \cdot (\bullet \setminus \langle \textbf{store} \rangle )^* \cdot \langle \textbf{push}\;\mathit{lvl\;x_2\;y_2} \rangle ]\texttt{unit}[\langle \textbf{store} \rangle]$

This change will also cause the synthesized generator to produce invalid addresses that trigger out-of-range memory errors, which reduces test efficiency.

We emphasize that all of these three kinds of knowledge are mentioned in Hritcu's original paper. Hritcu introduces another "generation by execution" strategy to avoid naïve crashes (e.g., `push` on an empty heap), which corresponds to the first knowledge. Similarly, $\textbf{push}(\texttt{L}, \langle 1, 2 \rangle)$ is an invalid test case and will be directly dropped. In their work, applying these kinds of knowledge also requires careful manual tweaking of the test generator implementation.

### Example 3: STLC Terms

We clarify that the SUT in this example is an STLC interpreter, so the synthesized test generator should produce a family of _serialized_ STLC terms, which are sequences of string tokens. Thus, there is only one effect operation, namely $\textbf{token} : \texttt{String}\to\texttt{unit}$. For example, an identity function $(\lambda x.[0])$ in the STLC language can be expressed as the following trace:

$\textbf{token}(``(\lambda \texttt{int}."); \textbf{token}(``[0]"); \textbf{token}(``)")$

which is divided into three `token` events with different string parameters: abstraction start ($``(\lambda \texttt{int}."$), variable reference ($``[0]"$), and abstraction end ($``)"$). The specification shown on line 307 provides the uHat for the case of "abstraction end," which requires that the tokens $``(\lambda \texttt{int}."$ and $``)"$ appear in pairs. As mentioned on line 341, more details of this example are provided in Section B of the supplementary material.

There are still two kinds of knowledge that facilitate test exploration: (1) well-formed STLC terms—the token sequence should be well-formed (e.g., abstraction needs to be closed after open, the variables are referred correctly), where a syntactically incorrect input like $``(\lambda \texttt{int}.)"$ will be directly rejected by the STLC parser; (2) the token sequence should indicate a well-typed STLC term, otherwise it will be rejected by the STLC type checker. In short, the test developer wants to test the reduction implementation within the STLC interpreter, so the desirable generator should only produce well-typed STLC terms to bypass the STLC parser and type checker. The specification on line 307 encodes only the first kind of knowledge, while the more precise specification that encodes both is shown in Figure 8 of the supplementary material. The weaker specification will make the synthesized test generator potentially produce well-formed but ill-typed STLC terms (e.g., $3\;3$). As mentioned above, these STLC terms cannot pass the type checker, so the bug described on line 287 cannot be detected.

In PBT, generating a sequence of tokens for an STLC interpreter is not easy. One potential approach is to define the STLC as pure datatypes and then serialize the datatype instances as strings. Even then, encoding the first knowledge still requires tracking the depth of abstractions, which is difficult for a test generator to handle programmatically. To encode the second knowledge, the user needs to provide a generator for well-typed STLC terms, which is also non-trivial.

### Summary

The motivating examples shown above demonstrate that both our approach and other test frameworks require users’ knowledge to guide test exploration. The difference is that our approach encodes this knowledge in uHats formally, and uses a type-guided synthesis approach to automatically specialize the test generator, rather than modifying the test generator manually. Thus, we can answer two questions:

- Q: How hard is it to write good uHats? (All Reviewers)

- A: The difficulty of providing "good" uHats is not higher than rewriting a "good" test generator in a PBT framework, since these user efforts are based on the same knowledge, but expressed in a different form. We also believe that uHats can be applied compositionally, which is much more efficient than manually tweaking the test generator.

- Q: How sensitive is the quality of uHats? (Reviewer A, B, C)

- A: The quality of uHats depends on the actual knowledge encoded. As the examples above show, lower quality may reduce testing efficiency by exploring more uninteresting cases; the worst case is falling back to naïve random exploration.

## Summary of Proposed Changes

Concretely, we propose to implement the following changes in the revision, in order to clarify the issues discussed above and to address the specific criticisms posed by the reviewers below:

- We will integrate the discussion about the quality sensitivity and user effort related to uHat specifications above in the revision (All Reviewers).

- We will clarify the explanation of our motivating examples in Section 2 (Reviewer A).

- To show the impact of uHat quality, we will additionally evaluate our tool with low-quality uHats for all benchmarks in our evaluation. These new uHats will encode less knowledge, similar to the examples above (Reviewer B).

- We will restructure the list of contributions to exclude the evaluation study as our fourth contribution (Reviewer A).

- We will fix all typos and spacing problems identified by the reviewers.

## Responses to Specific Questions

#### Reviewer A

- Q: How "obvious" are these uHats?

- A: Some of the knowledge encoded in uHats is straightforward (e.g., "functional correctness properties of the operations" as you mentioned); some of it requires understanding the SUT (e.g., the pushed value should be a valid address in the IFC example mentioned above). We want to highlight that this knowledge is also needed in other test frameworks; thus, uHats are just as "obvious" as the search strategies used in those frameworks.

- Q: Could they be written by a lightly-trained average developer?

- A: As empirical evidence, the uHats for the $\texttt{HashTable}$ and $\texttt{Courseware}$ benchmark in Figure 1 are provided by two undergraduate students, and for $\texttt{Smallbank}$ and $\texttt{Twitter}$ benchmark by a junior PhD student. All of them were new to our uHat specification language and had no knowledge of our synthesis algorithm. However, they were still able to encode their knowledge about the SUT as uHats and successfully solve these benchmarks.

#### Reviewer B

- Q: What happens when a uHat used as a spec for synthesizing a generator is wrong?

- A: If the wrong specifications are conflicting, our synthesizer will not find a solution, as you mentioned. If the wrong specifications are too general (as in the examples in the shared concern), the synthesizer will synthesize useless generators (note that our synthesizer will synthesize a family of unioned generators), which reduces the efficiency of test exploration.

#### Reviewer C

- Q: The paper relies upon angelic execution and no unreachable traces.

- A: You are right; the SUT will not always behave as we expect (e.g., a SUT that can potentially violate read atomicity may still work correctly most of the time). In this case, we simply rerun the test. The corresponding practical issues can be considered as future research directions.

- Q: What happens when a specification is wrong or certain histories are unreachable?

- A: If the wrong specifications are conflicting, our synthesizer just finds no solution. If the wrong specifications are too general (as in the examples discussed in the shared concern), the synthesizer will synthesize useless generators (note that our synthesizer will produce a family of unioned generators), thereby reducing the efficiency of test exploration. The problem of "unreachable histories" can happen for uHats of effectful operations, but it won't occur for the synthesized test generator. Note that our "global property" is indeed global, so the synthesized type-safe generator does not depend on any history trace, as guaranteed by our type soundness theorem (Corollary 3.5). In other words, the synthesized generator will generate "dependent histories" (traces) by itself for the operators it uses.

- Q: When a generator fails to be synthesized, what feedback is provided? What is the debugging process like?

- A: As shown in Figure 6, our algorithm consists of a refinement loop that maintains a set of candidate generators. When synthesis fails, we can provide all previous sets of candidate generators at each refinement iteration. A better debugging process can be considered as future work.

#### Reviewer D

+ Q: In Figure 2, what is the last operation when defining traces α?

- A: The ${+}{+}$ symbol indicates the standard concatenation of two lists.

+ Q: Is the full uHat type system required for synthesis correctness, or could synthesis operate purely at the SRE level?

- A: The synthesized generators are type-safe by construction, as guaranteed by Theorem 4.4. Thus, a standalone uHat type system is not required for synthesis correctness.

- Q: Can the approach handle concurrency interleavings beyond sequential traces (e.g., partial orders)?

- A: In our setting, we don't consider partial order reduction. For example, assume there are three events $e_1$, $e_2$, and $e_3$. A bug may require event $e_1$ to happen before both $e_2$ and $e_3$, while the order of $e_2$ and $e_3$ is not defined. Instead of unifying them as a single case, $\texttt{Clouseau}$ will treat $e_1;e_2;e_3$ and $e_1;e_3;e_2$ as two different buggy traces. Any one of them can serve as evidence of a bug.